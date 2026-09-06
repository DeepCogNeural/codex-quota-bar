"""Disable editor-only previews unavailable in Apple's Command Line Tools."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('codexbar',type=Path);a=p.parse_args()
f=a.codexbar/'.build/checkouts/KeyboardShortcuts/Sources/KeyboardShortcuts/Recorder.swift'
s=f.read_text()
if '// Quota Bar: CLT build excludes editor previews' not in s:
    start=s.index('\n#Preview {')
    end=s.rindex('\n#endif')
    s=s[:start]+'\n// Quota Bar: CLT build excludes editor previews\n#if CODEX_QUOTA_BAR_XCODE_PREVIEWS\n'+s[start:end]+'\n#endif'+s[end:]
    f.chmod(f.stat().st_mode | 0o200)
    f.write_text(s)
# Expand two SwiftUI @Entry declarations without the Xcode-only macro plugin.
f=a.codexbar/'Sources/CodexBar/MenuHighlightStyle.swift'
s=f.read_text()
if '@Entry' in s:
    s=s.replace('    @Entry var menuItemHighlighted: Bool = false', '''    var menuItemHighlighted: Bool {
        get { self[QuotaBarHighlightKey.self] }
        set { self[QuotaBarHighlightKey.self] = newValue }
    }''').replace('    @Entry var menuCardRefreshMonitor: MenuCardRefreshMonitor?', '''    var menuCardRefreshMonitor: MenuCardRefreshMonitor? {
        get { self[QuotaBarRefreshKey.self] }
        set { self[QuotaBarRefreshKey.self] = newValue }
    }''')
    s+='''
private struct QuotaBarHighlightKey: EnvironmentKey {
    static let defaultValue = false
}
private struct QuotaBarRefreshKey: EnvironmentKey {
    static let defaultValue: MenuCardRefreshMonitor? = nil
}
'''
    f.write_text(s)
