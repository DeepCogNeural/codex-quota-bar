"""Apply the opt-in native integration to matching local upstream checkouts.
This edits source only. It never builds, installs, or changes a running service.
"""
import argparse
from pathlib import Path
import shutil

parser = argparse.ArgumentParser()
parser.add_argument('--codexbar', required=True, type=Path)
parser.add_argument('--subrouter', required=True, type=Path)
a = parser.parse_args()
base = Path(__file__).resolve().parent
cb = a.codexbar / 'Sources/CodexBar'
sr = a.subrouter / 'internal/proxy'
changes = [
    (cb / 'StatusItemController+Menu.swift',
     '        let enabledProviders = self.store.enabledFirstPartyProvidersForDisplay()\n        let includesOverview',
     '\n'.join([
         '        let enabledProviders = self.store.enabledFirstPartyProvidersForDisplay()',
         '        if QuotaBar.shared.enabled && enabledProviders.isEmpty {',
         '            menu.removeAllItems()',
         '            self.addUserPluginMenuCards(to: menu, width: 320)',
         '            menu.addItem(.separator())',
         '            let settings = NSMenuItem(title: QuotaBar.text("Settings…", "设置…"), action: #selector(self.showSettingsGeneral), keyEquivalent: ",")',
         '            settings.target = self',
         '            menu.addItem(settings)',
         '            let quit = NSMenuItem(title: QuotaBar.text("Quit CodexBar", "退出 CodexBar"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")',
         '            quit.target = NSApp',
         '            menu.addItem(quit)',
         '            self.flushHostedMenuRowRendering(in: menu)',
         '            return',
         '        }',
         '        let includesOverview'])),
    (cb / 'StatusItemController+UserPlugins.swift',
     '        let plugins = UserProviderPluginRegistry.all.filter { self.settings.isPluginEnabled($0.manifest.id) }',
     '        let plugins = UserProviderPluginRegistry.all.filter { self.settings.isPluginEnabled($0.manifest.id) && !(QuotaBar.shared.enabled && $0.manifest.id.rawValue == "subrouter") }'),
    (cb / 'StatusItemController.swift',
     '        self.settings.mergeIcons && self.store.enabledProvidersForDisplay().count > 1',
     '        QuotaBar.shared.enabled || (self.settings.mergeIcons && self.store.enabledProvidersForDisplay().count > 1)'),
    (cb / 'StatusItemController.swift',
     '            let shouldBeVisible = anyEnabled || force',
     '            let shouldBeVisible = QuotaBar.shared.enabled || anyEnabled || force'),
    (cb / 'StatusItemController.swift',
     '        super.init()\n',
     '''        super.init()
        if QuotaBar.shared.enabled && !SettingsStore.isRunningTests {
            QuotaBar.shared.onUpdate = { [weak self] in _ = self?.applyIcon(phase: nil) }
            QuotaBar.shared.start()
        }
'''),
    (cb / 'StatusItemController+Animation.swift',
     '        guard let button = self.statusItem.button else { return false }\n',
     '''        guard let button = self.statusItem.button else { return false }
        if QuotaBar.shared.enabled {
            button.title = ""
            button.attributedTitle = NSAttributedString(string: "")
            button.image = QuotaBar.shared.image()
            button.imagePosition = .imageOnly
            self.statusItem.length = 44
            return true
        }
'''),
    (cb / 'StatusItemController+UserPlugins.swift',
     '    func addUserPluginMenuCards(to menu: NSMenu, width: CGFloat) {\n',
     '''    func addUserPluginMenuCards(to menu: NSMenu, width: CGFloat) {
        if QuotaBar.shared.enabled {
            menu.addItem(self.makeMenuCardItem(
                QuotaBarControls(width: width), id: "quotaBarControls", width: width,
                containsInteractiveControls: false))
            QuotaBarMenuActions.shared.append(to: menu)
        }
'''),
    (sr / 'proxy.go',
     '\tmux.HandleFunc("/_subrouter/usage-status", s.requireAdmin(s.handleUsageStatus))\n',
     '\tmux.HandleFunc("/_subrouter/routing-policy", s.handleQuotaBarPolicy)\n\tmux.HandleFunc("/_subrouter/usage-status", s.requireAdmin(s.handleUsageStatus))\n'),
    (sr / 'proxy.go',
     '\t\t// A caller-supplied account selector is a strict per-request binding, not\n',
     '''        if boundLease == nil && !modelCatalogRequest && requestProvider == accounts.ProviderCodex {
            if err := s.applyQuotaBarPolicy(routingRequest, agentType, sessionID); err != nil {
                http.Error(w, "cannot apply local routing policy", http.StatusServiceUnavailable)
                return
            }
        }
\t\t// A caller-supplied account selector is a strict per-request binding, not
'''),
]
# Check all insertion points before writing anything. Already-applied patches are skipped.
pending = {}
for path, old, new in changes:
    text = pending.get(path, path.read_text())
    if path.name == 'StatusItemController+UserPlugins.swift':
        text = text.replace(
            'QuotaBarControls(width: width), id: "quotaBarControls", width: width,\n                containsInteractiveControls: true))',
            'QuotaBarControls(width: width), id: "quotaBarControls", width: width,\n                containsInteractiveControls: false))\n            QuotaBarMenuActions.shared.append(to: menu)')
        if text != path.read_text():
            pending[path] = text
    if new in text:
        continue
    if text.count(old) != 1:
        raise SystemExit(f'Upstream insertion point changed: {path.name}; no changes written')
    pending[path] = text.replace(old, new, 1)
for path, text in pending.items():
    path.write_text(text)
shutil.copyfile(base / 'codexbar/QuotaBar.swift', cb / 'QuotaBar.swift')
shutil.copyfile(base / 'subrouter/quota_bar_policy.go', sr / 'quota_bar_policy.go')
print('Native integration source applied. Build and deployment are separate steps.')
