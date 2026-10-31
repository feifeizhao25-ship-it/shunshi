"""fix2 UI retest 顺时: before/after Flutter web builds (same fix2 backend :4293), seeded guest session. usage: fix2_ui_ss.py gl|cn before|after"""
import asyncio, sys, json, urllib.request, os
sys.path.insert(0, '/workspace/ui_full_test/run')
import fw
OUT = '/workspace/ui_full_test/retest/fix2/shots'
fw.SHOTS = OUT
from fw import *
PORT = {('gl', 'after'): 8712, ('gl', 'before'): 8714, ('cn', 'after'): 8711, ('cn', 'before'): 8713}
API = 'http://127.0.0.1:4293'
def api(method, path, body=None, tok=None, gl=True):
    h = {'content-type': 'application/json'}
    if tok: h['Authorization'] = 'Bearer ' + tok
    if gl: h.update({'Accept-Language': 'en-US', 'X-App-Market': 'global'})
    r = urllib.request.Request(API + path, data=json.dumps(body).encode() if body is not None else None, headers=h, method=method)
    return json.loads(urllib.request.urlopen(r, timeout=60).read() or b'{}')
ROUTES = {'gl': ['/home', '/plan-usage', '/settings', '/culture-settings'], 'cn': ['/today', '/plan-usage', '/settings']}
async def main(ed, ver):
    gl = ed == 'gl'
    tok = api('POST', '/api/v1/auth/guest-login', {}, gl=gl)['access_token']
    if gl: api('PUT', '/api/v1/profile/culture', {'diet': ['halal'], 'units': 'imperial', 'hemisphere': 'south'}, tok)
    s = await Sess(f'ss_{ed}_{ver}', locale='en-US' if gl else 'zh-CN', tz='Australia/Sydney' if gl else 'Asia/Shanghai').start()
    async def to_local(route):
        u = route.request.url.replace('https://api.seasonsapp.com', API)
        try:
            r = await route.fetch(url=u)
            await route.fulfill(response=r, headers={**r.headers, 'access-control-allow-origin': '*', 'access-control-allow-headers': '*', 'access-control-allow-methods': '*'})
        except Exception:
            await route.abort()
    await s.ctx.route('https://api.seasonsapp.com/**', to_local)  # prod host is hard-coded in several services; point it at the local backend
    await set_prefs(s, {'onboarding_completed': True, 'auth_token': tok, 'is_logged_in': True, 'access_token': tok})
    await s.goto(f'http://127.0.0.1:{PORT[(ed, ver)]}/', wait=9000)
    log = []
    for r in ROUTES[ed]:
        s.net.clear()
        await s.pg.evaluate("(h)=>{location.hash=h}", '#' + r); await s.pg.wait_for_timeout(4500); await s.sem()
        t = await s.texts(); f = await s.shot(r.strip('/'), tall=1700)
        log.append({'route': r, 'url': s.pg.url, 'shot': f.split('/')[-1], 'texts': t, 'api': [a for a in s.net][-8:]}); print(r, [x[:40] for x in t][:10], flush=True)
    # chat: ask a seasonal question
    await s.pg.evaluate("(h)=>{location.hash=h}", '#/chat'); await s.pg.wait_for_timeout(4000); await s.sem()
    rect = await s.pg.evaluate("()=>{const e=[...document.querySelectorAll('textarea,input')].find(e=>e.getBoundingClientRect().width>0);if(!e)return null;const r=e.getBoundingClientRect();return [r.x,r.y,r.width,r.height]}")
    print('input rect', rect, flush=True)
    if rect: await s.tap_xy(rect[0] + rect[2] / 2, rect[1] + rect[3] / 2, 800)
    else: await s.tap_xy(150, 790, 800)
    await s.type('What season is it for me and what should I eat tonight?' if gl else '今天适合吃什么？', delay=15)
    await s.pg.wait_for_timeout(800); await s.shot('chat_typed'); await s.tap_xy(354, 749, 1500)
    for w in range(14):
        await s.pg.wait_for_timeout(3000)
    await s.sem(); t = await s.texts(); f = await s.shot('chat_answer', tall=2000)
    log.append({'route': '/chat', 'shot': f.split('/')[-1], 'texts': t, 'api': list(s.net)[-8:]}); print('chat', [x[:60] for x in t][-6:], flush=True)
    json.dump(log, open(f'{OUT}/ss_{ed}_{ver}.json', 'w'), ensure_ascii=False, indent=1)
    await s.close()
asyncio.run(main(sys.argv[1], sys.argv[2]))
