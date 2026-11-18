#!/usr/bin/env python3
"""Generate offline HTML from our deliberately small Markdown subset; no dependencies."""
from pathlib import Path
import html
import re
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Docs/Anleitung.md'
TARGET = ROOT / 'Docs/Anleitung.html'

def slug(value):
    return re.sub(r'[^a-z0-9 -]', '', unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode().lower()).replace(' ', '-')

def inline(value):
    # Extract code first so punctuation within code is never parsed as Markdown.
    tokens = []
    def code(match):
        tokens.append('<code>' + html.escape(match[1]) + '</code>')
        return f'\x00{len(tokens)-1}\x00'
    value = re.sub(r'`([^`]+)`', code, value)
    value = html.escape(value)
    value = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', lambda m: '<a href="' + m[2] + '">' + m[1] + '</a>', value)
    value = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', value)
    for i, token in enumerate(tokens):
        value = value.replace(f'\x00{i}\x00', token)
    return value

def render(source):
    lines = source.splitlines(); blocks = []; i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip(): i += 1; continue
        if line.startswith('```'):
            i += 1; code = []
            while i < len(lines) and not lines[i].startswith('```'):
                code.append(lines[i]); i += 1
            if i == len(lines): raise ValueError('Unclosed code fence')
            blocks.append('<pre><code>' + html.escape('\n'.join(code)) + '</code></pre>'); i += 1
        elif line.startswith('#'):
            m = re.fullmatch(r'(#{1,6}) (.+)', line)
            if not m: raise ValueError(line)
            level = len(m[1]); blocks.append(f'<h{level} id="{slug(m[2])}">{inline(m[2])}</h{level}>'); i += 1
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                rows.append([cell.strip() for cell in lines[i].strip('|').split('|')]); i += 1
            if len(rows) < 2 or not all(re.fullmatch(r':?-+:?', x) for x in rows[1]): raise ValueError('Invalid table')
            blocks.append('<div class="table"><table><thead><tr>' + ''.join('<th>'+inline(x)+'</th>' for x in rows[0]) + '</tr></thead><tbody>' + ''.join('<tr>'+''.join('<td>'+inline(x)+'</td>' for x in row)+'</tr>' for row in rows[2:])+'</tbody></table></div>')
        elif re.match(r'(- |\d+\. )', line):
            ordered = not line.startswith('- '); tag = 'ol' if ordered else 'ul'; items = []
            pattern = r'\d+\. (.*)' if ordered else r'- (.*)'
            while i < len(lines) and (m := re.fullmatch(pattern, lines[i])):
                items.append('<li>'+inline(m[1])+'</li>'); i += 1
            blocks.append('<'+tag+'>'+''.join(items)+'</'+tag+'>')
        else:
            text = [line]; i += 1
            while i < len(lines) and lines[i].strip() and not re.match(r'(#|\||```|- |\d+\. )', lines[i]):
                text.append(lines[i]); i += 1
            blocks.append('<p>'+inline(' '.join(text))+'</p>')
    body = '\n'.join(blocks)
    anchors = set(re.findall(r' id="([^"]+)"', body))
    for anchor in re.findall(r'href="#([^"]+)"', body):
        if anchor not in anchors: raise ValueError('Missing heading: '+anchor)
    chapters = [{"id": "willkommen", "title": "Willkommen", "blocks": []}]
    skip_contents = False
    for block in blocks:
        heading = re.match(r'<h2 id="([^"]+)">(.+)</h2>', block)
        if heading:
            skip_contents = heading[1] == 'inhalt'
            if not skip_contents:
                chapters.append({"id": heading[1], "title": heading[2], "blocks": []})
        if not skip_contents:
            chapters[-1]['blocks'].append(block)
    navigation = ''.join('<a href="#'+c['id']+'" data-chapter="'+c['id']+'">'+c['title']+'</a>' for c in chapters)
    content = ''.join('<section data-chapter="'+c['id']+'"'+(' hidden' if i else '')+'>'+"\n".join(c['blocks'])+'</section>' for i, c in enumerate(chapters))
    return '''<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'"><title>PresentInk · Anleitung</title><style>
:root {color-scheme:light dark} * {box-sizing:border-box} body {font:16px/1.65 -apple-system,BlinkMacSystemFont,sans-serif; margin:0; color:light-dark(#263141,#e6eaf0); background:light-dark(#f8fafc,#171b23);display:grid;grid-template-columns:250px minmax(0,1fr);height:100vh;overflow:hidden}
nav {overflow:auto;padding:26px 12px;background:light-dark(#edf1f7,#202733);border-right:1px solid light-dark(#dbe1ea,#384251)} nav header {font-size:21px;font-weight:700;padding:0 12px 20px} nav small {display:block;font-size:12px;font-weight:500;color:light-dark(#59677c,#a3b0c3)} nav a {display:block;color:inherit;text-decoration:none;font-size:14px;line-height:1.4;padding:10px 12px;margin:3px 0;border-radius:8px} nav a:hover {background:light-dark(#e0e7f1,#2a3546)} nav a[aria-current="page"] {color:light-dark(#16479c,#c9ddff);background:light-dark(#d6e4fb,#30486c);font-weight:600} a:focus-visible {outline:3px solid #568ce6;outline-offset:2px}
main {overflow:auto;min-width:0;padding:32px 36px 80px} section {max-width:900px;margin:auto} section[hidden] {display:none} h1 {font-size:32px;letter-spacing:-.6px;line-height:1.2} h2 {margin:0 0 24px;font-size:27px;line-height:1.3} h3 {margin-top:28px;font-size:19px} a {color:light-dark(#2456ba,#8cb7ff)} li {margin:7px 0} code {font: .9em ui-monospace,monospace;background:light-dark(#e8edf5,#2a3444);padding:2px 5px;border-radius:4px} pre {overflow:auto;background:light-dark(#e8edf5,#252e3d);padding:18px;border-radius:10px;line-height:1.5} pre code {padding:0;background:none} .table {overflow-x:auto} table {width:100%;border-collapse:collapse;font-size:14px;background:light-dark(#fff,#202733)} td,th {padding:11px 13px;border-bottom:1px solid light-dark(#dbe1ea,#384251);text-align:left;vertical-align:top} th {background:light-dark(#e7edf7,#2b3546)} h1,h2,h3 {scroll-margin-top:20px} @media(max-width:800px){body{grid-template-columns:210px minmax(0,1fr)}main{padding:24px}h1{font-size:28px}} @media print{body{display:block;height:auto;overflow:visible;background:white;color:black}nav{display:none}main{overflow:visible;padding:0}section[hidden]{display:block}h2{margin-top:32px;break-after:avoid}tr,pre{break-inside:avoid}}
</style></head><body><nav aria-label="Inhaltsverzeichnis"><header>PresentInk<small>Bedienungsanleitung</small></header>''' + navigation + '''</nav><main id="reading-pane">''' + content + '''</main><script>
const chapters = Array.from(document.querySelectorAll('section[data-chapter]'));
const links = Array.from(document.querySelectorAll('nav a[data-chapter]'));
function selectChapter() {
  let anchor; try { anchor = decodeURIComponent(location.hash.slice(1)); } catch { anchor = ''; }
  const target = document.getElementById(anchor);
  const selected = chapters.find(s => s.dataset.chapter === anchor) || (target && target.closest('section')) || chapters[0];
  chapters.forEach(s => { s.hidden = s !== selected; });
  links.forEach(a => { if (a.dataset.chapter === selected.dataset.chapter) a.setAttribute('aria-current','page'); else a.removeAttribute('aria-current'); });
  document.getElementById('reading-pane').scrollTop = 0;
  if (target && target !== selected.querySelector('h2')) target.scrollIntoView();
}
window.addEventListener('hashchange', selectChapter);
// Clicking the selected entry also returns its reading pane to the beginning.
links.forEach(a => a.addEventListener('click', () => { if (a.hash === location.hash) selectChapter(); }));
selectChapter();
</script></body></html>\n'''

if __name__ == '__main__':
    TARGET.write_text(render(SOURCE.read_text()))
    print(TARGET)
    english = ROOT / 'Docs/UserGuide.md'
    if english.exists():
        output = render(english.read_text()).replace('lang="de"', 'lang="en-US"').replace('PresentInk · Anleitung', 'PresentInk · User Guide').replace('Inhaltsverzeichnis', 'Table of Contents').replace('Bedienungsanleitung', 'User Guide')
        target = ROOT / 'Docs/UserGuide.html'
        target.write_text(output)
        print(target)
