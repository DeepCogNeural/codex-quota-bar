import AppKit
import SwiftUI
import Observation

// Opt-in native integration. Keeps the existing CodexBar menu and provider UI.
@MainActor @Observable final class QuotaBar {
    static let shared = QuotaBar()
    struct Window: Decodable {
        let UsedPercent: Double
        let LimitWindowSeconds: Double
        let Feature: String?
        let ResetAfterSeconds: Double?
    }
    struct Account: Decodable, Identifiable {
        let email: String
        let plan_type: String?
        let auth_valid: Bool?
        let auth_checked: Bool?
        let windows: [Window]?
        var id: String { email }
        var planRank: Int {
            let plan = (plan_type ?? "").lowercased()
            if plan.contains("pro") { return plan.contains("20") ? 400 : 300 }
            if plan.contains("plus") { return 100 }
            return 0
        }
        var limitingWindow: Window? {
            (windows ?? []).filter { ($0.Feature ?? "").isEmpty && $0.LimitWindowSeconds > 0 }
                .max { $0.UsedPercent < $1.UsedPercent }
        }
        var remaining: Double? {
            let limits = (windows ?? []).filter { ($0.Feature ?? "").isEmpty && $0.LimitWindowSeconds > 0 }
            guard auth_valid == true, auth_checked == true, !limits.isEmpty,
                  limits.allSatisfy({ $0.UsedPercent.isFinite && (0...100).contains($0.UsedPercent) }) else { return nil }
            // The most constrained base window determines whether the account has room.
            return limits.map { 100 - $0.UsedPercent }.min()
        }
    }
    enum DisplayWindow: String {
        case fiveHours, weekly
        var seconds: Double { self == .fiveHours ? 18000 : 604800 }
        @MainActor var title: String { self == .fiveHours ? "5h" : QuotaBar.text("Weekly", "每周") }
    }
    var displayedWindows: [String: String] = UserDefaults.standard.dictionary(forKey: "quotaBarDisplayWindows") as? [String: String] ?? [:]
    func displayWindow(_ account: Account) -> DisplayWindow? {
        if let raw = displayedWindows[account.id], let selected = DisplayWindow(rawValue: raw) { return selected }
        if account.planRank == 100 { return .fiveHours }
        switch account.limitingWindow?.LimitWindowSeconds {
        case 18000: return .fiveHours
        case 604800: return .weekly
        default: return nil
        }
    }
    func window(_ account: Account) -> Window? {
        guard let selected = displayWindow(account) else { return account.limitingWindow }
        return account.windows?.first { ($0.Feature ?? "").isEmpty && $0.LimitWindowSeconds == selected.seconds }
    }
    func remaining(_ account: Account) -> Double? {
        guard account.auth_valid == true, account.auth_checked == true,
              let value = window(account)?.UsedPercent,
              value.isFinite, (0...100).contains(value) else { return nil }
        return 100 - value
    }
    func toggleWindow(_ account: Account) {
        displayedWindows[account.id] = (displayWindow(account) == .weekly ? DisplayWindow.fiveHours : .weekly).rawValue
        UserDefaults.standard.set(displayedWindows, forKey: "quotaBarDisplayWindows")
        onUpdate?()
    }
    struct Policy: Codable { var mode: String; var accountID: String? }
    var accounts: [Account] = []
    var policy: Policy?
    var error: String?
    var busy = false
    var fetchedAt: Date?
    @ObservationIgnored var onUpdate: (() -> Void)?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let transport = RedirectBlocker()
    @ObservationIgnored private lazy var session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.connectionProxyDictionary = [:]
        c.httpCookieStorage = nil
        c.urlCredentialStorage = nil
        c.timeoutIntervalForRequest = 10
        return URLSession(configuration: c, delegate: transport, delegateQueue: nil)
    }()
    var enabled: Bool { UserDefaults.standard.bool(forKey: "quotaBarEnabled") }
    var aliases: [String: String] { UserDefaults.standard.dictionary(forKey: "quotaBarAliases") as? [String: String] ?? [:] }
    var ordered: [Account] {
        let order = UserDefaults.standard.stringArray(forKey: "quotaBarAccountOrder") ?? []
        return accounts.sorted {
            if $0.planRank != $1.planRank { return $0.planRank > $1.planRank }
            let a = order.firstIndex(of: $0.email) ?? Int.max
            let b = order.firstIndex(of: $1.email) ?? Int.max
            return a == b ? $0.email < $1.email : a < b
        }
    }
    func name(_ a: Account) -> String { aliases[a.email] ?? a.email }
    static func text(_ en: String, _ zh: String) -> String {
        let override = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        let lang = override.isEmpty ? (Locale.preferredLanguages.first ?? "en") : override
        return lang.hasPrefix("zh") ? zh : en
    }
    func start() {
        guard enabled, timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in await QuotaBar.shared.refresh() }
        }
        Task { await refresh() }
    }
    func request(_ suffix: String, body: Policy? = nil) throws -> URLRequest {
        var r = URLRequest(url: URL(string: "http://127.0.0.1:31415/_subrouter/" + suffix)!)
        if suffix == "routing-policy" {
            guard let path = UserDefaults.standard.string(forKey: "quotaBarTokenFile"),
                  let raw = try? String(contentsOfFile: path, encoding: .utf8),
                  raw.trimmingCharacters(in: .whitespacesAndNewlines).count >= 32 else { throw URLError(.userAuthenticationRequired) }
            r.setValue(raw.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "X-Quota-Bar-Token")
        }
        if let body {
            r.httpMethod = "POST"
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONEncoder().encode(body)
        }
        return r
    }
    func data(_ r: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: r)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count <= 1_048_576 else { throw URLError(.badServerResponse) }
        return data
    }
    func refresh() async {
        guard !busy else { return }
        busy = true
        defer { busy = false; onUpdate?() }
        do {
            accounts = try JSONDecoder().decode([Account].self, from: await data(request("usage-status")))
            fetchedAt = Date()
            error = nil
        } catch {
            accounts = []
            fetchedAt = nil
            self.error = Self.text("Quota unavailable", "额度暂不可用")
        }
        do { policy = try JSONDecoder().decode(Policy.self, from: await data(request("routing-policy"))) }
        catch { policy = nil }
    }
    func choose(_ accountID: String?) async {
        guard !busy else { return }
        busy = true
        defer { busy = false; onUpdate?() }
        do {
            let desired = Policy(mode: accountID == nil ? "auto" : "manual", accountID: accountID)
            let actual = try JSONDecoder().decode(Policy.self, from: await data(request("routing-policy", body: desired)))
            guard actual.mode == desired.mode, (actual.accountID ?? "") == (desired.accountID ?? "") else { throw URLError(.badServerResponse) }
            policy = actual
            error = nil
        } catch { self.error = Self.text("Selection was not saved", "选择未保存") }
    }
    static func tint(_ value: Double) -> NSColor {
        if value < 20 { return .systemRed }
        if value < 50 { return .systemYellow }
        if value < 80 { return .systemGreen }
        return .white
    }
    func image() -> NSImage {
        let values = Array(ordered.prefix(2)).map { remaining($0) }
        let image = NSImage(size: NSSize(width: 36, height: 18), flipped: false) { rect in
            for i in 0..<2 {
                let track = NSRect(x: 1, y: i == 0 ? 10 : 2, width: 34, height: 5)
                let outline = NSBezierPath(roundedRect: track, xRadius: 2.5, yRadius: 2.5)
                NSColor(white: 0.65, alpha: 0.28).setFill()
                outline.fill()
                NSColor(white: 0.9, alpha: 0.5).setStroke()
                outline.lineWidth = 0.5
                outline.stroke()
                if i < values.count, let value = values[i], value > 0 {
                    NSGraphicsContext.saveGraphicsState()
                    outline.addClip()
                    Self.tint(value).setFill()
                    NSRect(x: track.minX, y: track.minY, width: track.width * value / 100, height: track.height).fill()
                    NSGraphicsContext.restoreGraphicsState()
                }
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
private final class RedirectBlocker: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}

struct QuotaBarControls: View {
    let model = QuotaBar.shared
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Codex Quota Bar").font(.headline)
            ForEach(Array(model.ordered.prefix(2))) { account in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(model.name(account)).fontWeight(.medium)
                        Text((account.plan_type ?? "").uppercased()).foregroundStyle(.secondary)
                        Spacer()
                        if model.policy?.mode == "manual" && model.policy?.accountID == account.email {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        }
                        Text(model.displayWindow(account)?.title ?? "").foregroundStyle(.secondary)
                        Text(model.remaining(account).map { String(format: "%.0f%%", $0) } ?? "—").monospacedDigit()
                    }.font(.caption)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.quaternary)
                            if let value = model.remaining(account) {
                                Capsule().fill(Color(nsColor: QuotaBar.tint(value)))
                                    .frame(width: geometry.size.width * value / 100)
                            }
                        }
                    }.frame(height: 5)
                    if model.remaining(account) != nil, let seconds = model.window(account)?.ResetAfterSeconds,
                       seconds.isFinite, seconds >= 0, let fetched = model.fetchedAt {
                        Text(QuotaBar.text("Resets ≈ ", "预计重置 ≈ ") + fetched.addingTimeInterval(seconds).formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { model.toggleWindow(account) }
                    .accessibilityAction(named: Text(QuotaBar.text("Switch quota window", "切换额度窗口"))) {
                        model.toggleWindow(account)
                    }
                    .help(QuotaBar.text("Click to switch between 5h and Weekly", "点击切换 5 小时与每周额度"))
            }
            Text(QuotaBar.text("Remaining quota · click a row for 5h / Weekly", "剩余额度 · 点击账号切换 5 小时 / 每周")).font(.caption2).foregroundStyle(.secondary)
            if let error = model.error { Text(error).font(.caption).foregroundStyle(.red) }
            if model.policy != nil {
                QuotaBarAccountPicker().frame(width: 180, height: 28)
                Text(QuotaBar.text("New chats only. Existing chats keep their account. Manual chats never fall back to another account.", "仅影响新对话。旧对话保留原账号；手动对话不会自动换账号。"))
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Text(QuotaBar.text("Manual control is unavailable", "手动控制暂不可用")).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(12).frame(width: width)
    }
}

// AppKit owns selection events in NSMenu; keep actions out of the hosted SwiftUI card.
@MainActor final class QuotaBarMenuActions: NSObject {
    static let shared = QuotaBarMenuActions()

    func append(to menu: NSMenu) {
        menu.addItem(.separator())
        let refresh = NSMenuItem(title: QuotaBar.text("Refresh", "刷新"),
                                 action: #selector(refreshQuota(_:)), keyEquivalent: "")
        refresh.target = self
        menu.addItem(refresh)
    }

    func selectAccount(_ accountID: String?) {
        Task {
            // A scheduled quota refresh must not silently discard a user's selection.
            while QuotaBar.shared.busy { try? await Task.sleep(for: .milliseconds(50)) }
            await QuotaBar.shared.choose(accountID)
        }
    }

    @objc private func refreshQuota(_ sender: NSMenuItem) {
        Task { await QuotaBar.shared.refresh() }
    }
}

// A real NSControl receives mouse events directly inside the hosted menu card.
struct QuotaBarAccountPicker: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.controlSize = .regular
        button.font = .systemFont(ofSize: NSFont.systemFontSize)
        button.target = context.coordinator
        button.action = #selector(Coordinator.changed(_:))
        button.setAccessibilityLabel(QuotaBar.text("New chat account", "新对话账号"))
        return button
    }
    func updateNSView(_ button: NSPopUpButton, context: Context) {
        let model = QuotaBar.shared
        button.removeAllItems()
        button.addItem(withTitle: QuotaBar.text("Automatic", "自动"))
        for account in model.ordered {
            let item = NSMenuItem(title: model.name(account), action: nil, keyEquivalent: "")
            item.representedObject = account.email
            button.menu?.addItem(item)
        }
        let selected = model.policy?.mode == "manual" ? model.policy?.accountID : nil
        let index = button.itemArray.firstIndex { ($0.representedObject as? String) == selected } ?? 0
        button.selectItem(at: index)
        button.isEnabled = model.policy != nil
    }
    @MainActor final class Coordinator: NSObject {
        @objc func changed(_ sender: NSPopUpButton) {
            QuotaBarMenuActions.shared.selectAccount(sender.selectedItem?.representedObject as? String)
        }
    }
}

// A native panel keeps account controls out of NSMenu's tracking loop.
@MainActor final class QuotaBarPopover: NSObject {
    static let shared = QuotaBarPopover()
    private var panel: NSPanel?
    private var settings: (() -> Void)?
    private var outsideClick: Any?

    func attach(to item: NSStatusItem, settings: @escaping () -> Void) {
        self.settings = settings
        item.menu = nil
        item.button?.target = self
        item.button?.action = #selector(toggle(_:))
    }

    @objc private func toggle(_ sender: NSStatusBarButton) {
        if panel?.isVisible == true {
            close()
            return
        }
        guard let anchorWindow = sender.window else { return }
        let anchor = anchorWindow.convertToScreen(sender.convert(sender.bounds, to: nil))
        let controller = NSHostingController(rootView: QuotaBarPanel {
            self.close()
            self.settings?()
        })
        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 360),
                             styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "Codex Quota Bar"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.level = .popUpMenu
        window.collectionBehavior = [.transient, .moveToActiveSpace]
        window.contentViewController = controller
        window.setContentSize(NSSize(width: 320, height: 360))
        let screen = anchorWindow.screen?.visibleFrame ?? anchor
        let x = min(max(anchor.midX - 160, screen.minX), screen.maxX - 320)
        window.setFrameOrigin(NSPoint(x: x, y: anchor.minY - window.frame.height - 4))
        panel = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        if outsideClick == nil {
            outsideClick = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.close()
            }
        }
    }

    private func close() {
        panel?.orderOut(nil)
        panel = nil
        if let outsideClick { NSEvent.removeMonitor(outsideClick) }
        outsideClick = nil
    }
}

private struct QuotaBarPanel: View {
    let settings: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            QuotaBarControls(width: 320)
            Divider()
            HStack {
                Button(QuotaBar.text("Refresh", "刷新")) {
                    Task { await QuotaBar.shared.refresh() }
                }
                Spacer()
                Button(QuotaBar.text("Settings…", "设置…"), action: settings)
                Button(QuotaBar.text("Quit", "退出")) { NSApp.terminate(nil) }
            }.controlSize(.small).padding(12)
        }.frame(width: 320)
    }
}
