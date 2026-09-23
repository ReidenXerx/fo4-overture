"""Generate Overture's MCM page from the builder's own table.

    python tools/make_mcm.py

Writes data/MCM/Config/Overture/config.json. Every control is bound straight to
one of the plugin's globals ("sourceType": "GlobalValue"), so there is no
settings.ini and nothing for a script to poll: MCM writes the global, and
Overture:Approach reads it the next time it needs the number. The numbers and
their defaults come from overture_stages.SETTINGS, the same table the plugin's
GLOB records are written from, so the page cannot drift from the plugin.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_overture_esp as m  # noqa: E402
import overture_stages as s  # noqa: E402

OUT = m.ROOT / 'data' / 'MCM' / 'Config' / 'Overture'
PLUGIN = 'Overture.esp'


def source(object_id):
    # MCM's form reference: the plugin, then the object id without a load-order
    # byte -- it resolves the plugin wherever the player's load order put it.
    return f'{PLUGIN}|{object_id & 0xFFF:X}'


content = [
    {'type': 'text', 'text': 'Walk up to someone and try. How it went is told by Rapport\'s Narrator '
                             '(its "addon moments" switch). Numbers below apply at once.'},
    {'type': 'section', 'text': 'Overture'},
    {'type': 'switcher', 'text': 'Approaches', 'help': 'Talking to someone opens the approach, once a game '
     'day. Off: everyone has only their own dialogue.',
     'valueOptions': {'sourceType': 'GlobalValue', 'sourceForm': source(m.ENABLED_GLOBAL)}},
    {'type': 'switcher', 'text': 'A yes starts a scene', 'help': 'When someone says yes, Rapport starts '
     'the scene. Off: they say yes and nothing more happens.',
     'valueOptions': {'sourceType': 'GlobalValue', 'sourceForm': source(s.SCENES_GLOBAL)}},
]
section = None
for object_id, _edid, default, sec, label, help_, lo, hi, step in s.SETTINGS:
    if not lo <= default <= hi:
        raise SystemExit(f'{label}: the default {default} is outside its own slider ({lo}..{hi})')
    if sec != section:
        content.append({'type': 'section', 'text': sec})
        section = sec
    content.append({'type': 'slider', 'text': label, 'help': help_,
                    'valueOptions': {'min': lo, 'max': hi, 'step': step,
                                     'sourceType': 'GlobalValue', 'sourceForm': source(object_id)}})

config = {'modName': 'Overture', 'displayName': 'Overture', 'minMcmVersion': 1,
          'pluginRequirements': [PLUGIN], 'pages': [{'pageDisplayName': 'Overture', 'content': content}]}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'config.json').write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
print(f'wrote {OUT / "config.json"}: 2 switches and {len(s.SETTINGS)} sliders')
