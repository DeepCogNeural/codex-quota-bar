#!/usr/bin/env python3
"""Read public repository counters and owner-only 14-day traffic via gh."""
import datetime
import json
import subprocess

REPO = 'DeepCogNeural/codex-quota-bar'

def api(path):
    result = subprocess.run(['gh', 'api', f'repos/{REPO}{path}'], capture_output=True, text=True)
    if result.returncode:
        return {'unavailable': True, 'reason': 'GitHub API access failed; authenticate with repository traffic access.'}
    return json.loads(result.stdout)

repo = api('')
report = {'observed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'repository': REPO, 'stars': repo.get('stargazers_count'), 'forks': repo.get('forks_count')}
for kind in ('views', 'clones'):
    data = api('/traffic/' + kind)
    report[kind + '_14d'] = {k: data[k] for k in ('count', 'uniques', 'unavailable', 'reason') if k in data}
print(json.dumps(report, indent=2))
