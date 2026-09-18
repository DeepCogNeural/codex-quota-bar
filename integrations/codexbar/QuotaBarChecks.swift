import AppKit
import Foundation

@main struct QuotaBarChecks {
    @MainActor static func main() throws {
        let payload = """
        [{"email":"plus@example.com","plan_type":"plus","auth_valid":true,"auth_checked":true,"windows":[{"UsedPercent":10,"LimitWindowSeconds":18000},{"UsedPercent":80,"LimitWindowSeconds":604800}]},{"email":"pro@example.com","plan_type":"pro","auth_valid":true,"auth_checked":true,"windows":[{"UsedPercent":5,"LimitWindowSeconds":604800}]}]
        """
        let model = QuotaBar()
        model.accounts = try JSONDecoder().decode([QuotaBar.Account].self, from: Data(payload.utf8))
        precondition(model.ordered.map(\.email) == ["pro@example.com", "plus@example.com"])
        precondition(model.ordered.last?.remaining == 20)
        for (value, expected) in [(19.0, NSColor.systemRed), (20, .systemYellow), (49, .systemYellow), (50, .systemGreen), (79, .systemGreen), (80, .white), (100, .white)] {
            precondition(QuotaBar.tint(value) == expected)
        }
        let exhaustedPayload = """
        [{"email":"empty@example.com","plan_type":"plus","auth_valid":true,"auth_checked":true,"windows":[{"UsedPercent":7,"LimitWindowSeconds":18000,"ResetAfterSeconds":60},{"UsedPercent":100,"LimitWindowSeconds":604800,"ResetAfterSeconds":3600}]}]
        """
        let exhausted = try JSONDecoder().decode([QuotaBar.Account].self, from: Data(exhaustedPayload.utf8))[0]
        model.displayedWindows[exhausted.id] = QuotaBar.DisplayWindow.fiveHours.rawValue
        precondition(model.remaining(exhausted) == 0)
        precondition(model.exhaustedWeeklyWindow(exhausted)?.ResetAfterSeconds == 3600)
        precondition(model.window(exhausted)?.UsedPercent == 7, "Do not change raw 5h quota")
        precondition(model.remaining(model.accounts[0]) == 90, "Available weekly quota must not clamp 5h")
        precondition(model.exhaustedWeeklyWindow(model.accounts[0]) == nil)
        let overlayPayload = """
        [{"email":"limited@example.com","plan_type":"plus","auth_valid":true,"auth_checked":true,"windows":[{"Name":"request-limit","UsedPercent":100,"LimitWindowSeconds":604800,"ResetAfterSeconds":60},{"Name":"5h","UsedPercent":100,"LimitWindowSeconds":18000,"ResetAfterSeconds":120},{"Name":"weekly","UsedPercent":53,"LimitWindowSeconds":604800,"ResetAfterSeconds":3600}]}]
        """
        let limited = try JSONDecoder().decode([QuotaBar.Account].self, from: Data(overlayPayload.utf8))[0]
        precondition(model.exhaustedWeeklyWindow(limited) == nil)
        precondition(model.remaining(limited) == 0)
        precondition(model.window(limited)?.ResetAfterSeconds == 120)
        model.displayedWindows[limited.id] = QuotaBar.DisplayWindow.weekly.rawValue
        precondition(model.remaining(limited) == 47)
        precondition(model.window(limited)?.ResetAfterSeconds == 3600)
        precondition(model.window(exhausted)?.ResetAfterSeconds == 60)
        let pro = model.accounts[1]
        model.displayedWindows[pro.id] = QuotaBar.DisplayWindow.fiveHours.rawValue
        precondition(model.displayWindow(pro) == .weekly)
        model.toggleWindow(pro)
        precondition(model.displayWindow(pro) == .weekly && model.remaining(pro) == 95)
        let image = model.image()
        precondition(image.size == NSSize(width: 36, height: 18) && !image.isTemplate)
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("No rendered image") }
        try png.write(to: URL(fileURLWithPath: "/tmp/quota-bar-fixture.png"))
        model.accounts = try JSONDecoder().decode([QuotaBar.Account].self, from: Data("[{\"email\":\"unknown@example.com\"}]".utf8))
        precondition(model.accounts[0].remaining == nil)
        print("PASS: request-limit excluded, real weekly clamp, selected reset, Pro weekly lock, display fixtures")
    }
}
