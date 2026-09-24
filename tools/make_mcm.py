"""Generate Overture's MCM page and its settings file from the builder's own table.

    python tools/make_mcm.py

Writes data/MCM/Config/Overture/config.json (the page) and settings.ini (the
defaults MCM starts from). One switch is bound to a plugin global
("GlobalValue"): the greeting's own conditions read OvertureEnabled, so it has to
be one. Everything else -- the scenes switch and every number -- is an MCM
ModSetting: a global's value is written into every save, so a better default in a
later Overture would never reach a game that already had the plugin (microscope
pass 1, lens 6).

settings.ini also carries [Meta] iDefaults=1, on no control: the script's proof
that MCM read THIS file, which no player's slider can fake (microscope pass 2).

The table is overture_stages.SETTINGS and SWITCHES, and the scripts are held to it:
every Tuned call in ANY Overture script (Approach's own, and the companion module's,
which reads its numbers through Approach.Tuned) must name a row and fall back to
that row's default, every row must be read, every switch must be read, and the guard
that turns the defaults on must be in Approach. Comments are stripped first and
names matched without case, as Papyrus reads them. Otherwise nothing is written.
"""
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_overture_esp as m  # noqa: E402
import overture_stages as s  # noqa: E402

OUT = m.ROOT / 'data' / 'MCM' / 'Config' / 'Overture'
APPROACH = m.ROOT / 'papyrus' / 'Overture' / 'Approach.psc'
SCRIPTS = sorted((m.ROOT / 'papyrus' / 'Overture').rglob('*.psc'))
# A wrapper that hands its caller's key and default straight on (Feeders.Tuned):
# the literals it forwards are checked at ITS callers.
FORWARD = r'(?i)\bTuned\s*\(\s*asKey\s*,\s*afDefault\s*\)'
PLUGIN = 'Overture.esp'


def source(object_id):
    # MCM's form reference: the plugin, then the object id without a load-order
    # byte -- it resolves the plugin wherever the player's load order put it.
    return f'{PLUGIN}|{object_id & 0xFFF:X}'


def strip_comments(psc):
    """Papyrus source without its comments: ; to the end of a line, ;/ ... /;
    blocks and { ... } doc comments -- never inside a string literal."""
    out, i, n = [], 0, len(psc)
    while i < n:
        ch = psc[i]
        if ch == '"':
            j = i + 1
            while j < n and psc[j] != '"':
                j += 2 if psc[j] == '\\' else 1
            out.append(psc[i:j + 1])
            i = j + 1
        elif psc.startswith(';/', i):
            end = psc.find('/;', i + 2)
            i = n if end < 0 else end + 2
        elif ch == ';':
            end = psc.find('\n', i)
            i = n if end < 0 else end
        elif ch == '{':
            end = psc.find('}', i + 1)
            i = n if end < 0 else end + 1
        else:
            out.append(ch)
            i += 1
    return ''.join(out)


def body(code, name):
    found = re.search(rf'(?is)\bFunction\s+{name}\s*\(.*?\bEndFunction\b', code)
    if not found:
        raise SystemExit(f'Approach.psc has no Function {name}')
    return found.group(0)


def check_script(table, switches):
    approach = strip_comments(APPROACH.read_text(encoding='utf-8'))
    code = '\n'.join(strip_comments(f.read_text(encoding='utf-8')) for f in SCRIPTS)
    calls = re.findall(r'(?i)\bTuned\s*\(\s*"([^"]+)"\s*,\s*(-?[0-9.]+)\s*\)', code)
    every = (len(re.findall(r'(?i)\bTuned\s*\(', code))
             - len(re.findall(r'(?i)\bFunction\s+Tuned\s*\(', code))
             - len(re.findall(FORWARD, code)))
    if every != len(calls):
        raise SystemExit(f'the scripts have {every} Tuned calls and only {len(calls)} of them read '
                         f'Tuned("key:Section", number) - a default that is not a literal cannot be checked')
    lowered = {k.lower(): k for k in table}
    read = set()
    for name, default in calls:
        key = lowered.get(name.lower())
        if key is None:
            raise SystemExit(f'a script reads {name}, which overture_stages.SETTINGS does not have')
        if abs(float(default) - table[key]) > 1e-9:
            raise SystemExit(f'a script falls back to {default} for {name}; SETTINGS says {table[key]}')
        read.add(key)
    unread = sorted(set(table) - read)
    if unread:
        raise SystemExit(f'SETTINGS has {unread}, which no script reads')
    # The guard. Without it MCM's 0 for a file it never read would be every number.
    guard = re.compile(rf'(?i)MCM\.GetModSettingInt\(\s*"Overture"\s*,\s*"{re.escape(s.META)}"\s*\)\s*==\s*1')
    if not guard.search(body(approach, 'HasSettings')):
        raise SystemExit(f'Approach.HasSettings does not test {s.META} == 1')
    if not re.search(r'(?is)If\s+!\s*Self\.HasSettings\(\)\s*Return\s+afDefault', body(approach, 'Tuned')):
        raise SystemExit('Approach.Tuned does not return its default when HasSettings() is False')
    for name in switches:
        if not re.search(rf'(?i)MCM\.GetModSettingBool\(\s*"Overture"\s*,\s*"{re.escape(name)}"\s*\)', code):
            raise SystemExit(f'the switch {name} is on the page and no script reads it')
    return len(calls)


content = [
    {'type': 'text', 'text': 'Walk up to someone and try. How it went is told by Rapport\'s Narrator '
                             '(its "addon moments" switch). Changes apply from the next reply; the lover '
                             'bond, from the next conversation that ends.'},
    {'type': 'section', 'text': 'Overture'},
    {'type': 'switcher', 'text': 'Approaches', 'help': 'Talking to someone opens the approach, once a game '
     'day. Off: everyone has only their own dialogue.',
     'valueOptions': {'sourceType': 'GlobalValue', 'sourceForm': source(m.ENABLED_GLOBAL)}},
]
table, ini, switches = {}, {}, []
for key, ini_section, default, label, help_ in s.SWITCHES:
    name = f'{key}:{ini_section}'
    switches.append(name)
    ini.setdefault(ini_section, {})[key] = '1' if default else '0'
    content.append({'type': 'switcher', 'id': name, 'text': label, 'help': help_,
                    'valueOptions': {'sourceType': 'ModSettingBool'}})
section = None
for key, ini_section, default, sec, label, help_, lo, hi, step in s.SETTINGS:
    if not lo <= default <= hi:
        raise SystemExit(f'{label}: the default {default} is outside its own slider ({lo}..{hi})')
    name = f'{key}:{ini_section}'
    if name in table or name in switches:
        raise SystemExit(f'{name} is in the table twice')
    table[name] = default
    ini.setdefault(ini_section, {})[key] = f'{float(default):.6f}'
    if sec != section:
        content.append({'type': 'section', 'text': sec})
        section = sec
    content.append({'type': 'slider', 'id': name, 'text': label, 'help': help_,
                    'valueOptions': {'min': lo, 'max': hi, 'step': step, 'sourceType': 'ModSettingFloat'}})
meta_key, meta_section = s.META.split(':')
ini.setdefault(meta_section, {})[meta_key] = '1'
calls = check_script(table, switches)

# R-23 (owner poll, 2026-09-24): Overture's entry points on demand, each twice -- FORCED
# skips the soft gates, REAL goes through the player's own door -- as buttons and as
# hotkeys. The functions are papyrus/Overture/DebugTriggers.psc's parameterless globals.
DEBUG_SCRIPT = 'Overture:DebugTriggers'
DEBUG = [
    # (function, button text, hotkey text, help)
    ('ApproachForced', 'Approach the one I face - FORCED', 'Approach - forced',
     'Overture\'s approach scene on the NPC you are facing, eligible or not (what F4MCP\'s '
     '"approach <npc>" does).'),
    ('ApproachReal', 'Approach the one I face - REAL', 'Approach - real',
     'You talk to them, and the game picks the greeting exactly as in play: the approach only when '
     'every condition holds. From this page it opens once the menu is closed.'),
    ('YesForced', 'Straight to a yes - FORCED', 'Yes - forced',
     'A yes from the NPC you are facing without asking: the same markers, Narrator line and scene '
     'request a real yes gets - the scene even with "A yes starts a scene" off.'),
    ('YesReal', 'Straight to a yes - REAL', 'Yes - real',
     'The stage-3 verdict decides (bond, room, setting, Rapport free); the HUD says why when it is '
     'not a yes. A yes asks for its scene only with "A yes starts a scene" on.'),
]
debug_content = [
    {'type': 'text', 'text': 'Overture\'s entry points on demand, for testing. Face the NPC you mean, then click - '
                             'or bind a key below. FORCED skips the checks; REAL goes through the same door '
                             'as play and says on the HUD what refused.'},
    {'type': 'section', 'text': 'Approach'},
]
for function, text, _, help_ in DEBUG[:2]:
    debug_content.append({'type': 'button', 'text': text, 'help': help_,
                          'action': {'type': 'CallGlobalFunction', 'script': DEBUG_SCRIPT,
                                     'function': function, 'params': []}})
debug_content.append({'type': 'section', 'text': 'A yes'})
for function, text, _, help_ in DEBUG[2:]:
    debug_content.append({'type': 'button', 'text': text, 'help': help_,
                          'action': {'type': 'CallGlobalFunction', 'script': DEBUG_SCRIPT,
                                     'function': function, 'params': []}})
debug_content.append({'type': 'section', 'text': 'Hotkeys'})
for function, _, hotkey, help_ in DEBUG:
    debug_content.append({'id': 'Overture' + function, 'text': hotkey, 'type': 'hotkey', 'help': help_})

config = {'modName': 'Overture', 'displayName': 'Overture', 'minMcmVersion': 1,
          'pluginRequirements': [PLUGIN], 'pages': [{'pageDisplayName': 'Overture', 'content': content},
                                                    {'pageDisplayName': 'Debug', 'content': debug_content}]}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'config.json').write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
keybinds = {'modName': 'Overture',
            'keybinds': [{'id': 'Overture' + function, 'desc': 'Overture debug: ' + hotkey,
                          'action': {'type': 'CallGlobalFunction', 'script': DEBUG_SCRIPT, 'function': function}}
                         for function, _, hotkey, _ in DEBUG]}
(OUT / 'keybinds.json').write_text(json.dumps(keybinds, indent=2) + '\n', encoding='utf-8')
lines = ['; GENERATED by tools/make_mcm.py from tools/overture_stages.py - edit that, not this.']
for ini_section, keys in ini.items():
    lines.append(f'[{ini_section}]')
    lines += [f'{k}={v}' for k, v in keys.items()]
    lines.append('')
(OUT / 'settings.ini').write_text('\n'.join(lines), encoding='utf-8')
print(f'wrote {OUT / "config.json"} and settings.ini: 1 global switch, {len(switches)} setting switch(es), '
      f'{len(s.SETTINGS)} numbers; {calls} Tuned calls in {len(SCRIPTS)} scripts checked against the table')
