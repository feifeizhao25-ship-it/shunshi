"""Flutter-web / web driver helpers for UI test (Playwright + system Chrome)."""
import asyncio, json, os, re, time
from playwright.async_api import async_playwright
SHOTS='/workspace/ui_full_test/shots'
ARGS=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--autoplay-policy=no-user-gesture-required']
class Sess:
    def __init__(s, name, locale='zh-CN', tz='Asia/Shanghai', w=390, h=844, dpr=2, mock_date=None, media=False):
        s.name=name; s.locale=locale; s.tz=tz; s.w=w; s.h=h; s.dpr=dpr; s.mock_date=mock_date
        s.dir=f'{SHOTS}/{name}'; os.makedirs(s.dir, exist_ok=True); s.n=0; s.log=[]; s.net=[]
    async def start(s, headless=True):
        s.pw=await async_playwright().start()
        s.b=await s.pw.chromium.launch(executable_path='/usr/bin/google-chrome', args=ARGS)
        s.ctx=await s.b.new_context(viewport={'width':s.w,'height':s.h}, device_scale_factor=s.dpr, ignore_https_errors=True, locale=s.locale, timezone_id=s.tz, is_mobile=False, permissions=['microphone','notifications'])
        if s.mock_date:
            ms=int(s.mock_date)  # epoch ms
            await s.ctx.add_init_script(f"""(()=>{{const R=Date,off={ms}-R.now();class D extends R{{constructor(...a){{if(a.length===0)super(R.now()+off);else super(...a)}}static now(){{return R.now()+off}}}};window.Date=D;}})();""")
        s.pg=await s.ctx.new_page()
        s.pg.on('console', lambda m: s.log.append(m.text[:300]))
        s.pg.on('response', lambda r: s.net.append((r.status, r.request.method, r.url[:200])) if '/api' in r.url else None)
        return s
    async def goto(s, url, wait=5000):
        await s.pg.goto(url, wait_until='load'); await s.pg.wait_for_timeout(wait)
        await s.sem()
    async def sem(s):
        try:
            await s.pg.evaluate("()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p){p.click(); p.dispatchEvent(new MouseEvent('click',{bubbles:true}));}}")
            await s.pg.wait_for_timeout(600)
        except Exception as e: pass
    async def texts(s):
        js="""()=>{const out=[];document.querySelectorAll('flt-semantics').forEach(e=>{const l=(e.getAttribute('aria-label')||'').trim(); const t=(e.textContent||'').trim(); const leaf=[...e.children].every(c=>c.tagName!=='FLT-SEMANTICS'); if(l) out.push(l); else if(t && leaf) out.push(t);});return out}"""
        r=await s.pg.evaluate(js)
        seen=[];[seen.append(x) for x in r if not seen or seen[-1]!=x]
        return seen
    async def shot(s, label, tall=None, full=True):
        s.n+=1; f=f'{s.dir}/{s.n:02d}_{re.sub(r"[^0-9A-Za-z_一-鿿-]+","_",label)}.png'
        if tall:
            await s.pg.set_viewport_size({'width':s.w,'height':tall}); await s.pg.wait_for_timeout(1200)
            await s.pg.screenshot(path=f)
            await s.pg.set_viewport_size({'width':s.w,'height':s.h}); await s.pg.wait_for_timeout(500)
        else:
            await s.pg.screenshot(path=f)
        return f
    async def tap_text(s, text, exact=False, timeout=4000):
        js="""(a)=>{const [t,ex]=a;const els=[...document.querySelectorAll('flt-semantics')].map(e=>{const l=((e.getAttribute('aria-label')||'')+' '+(e.textContent||'')).trim();const r=e.getBoundingClientRect();return {l,r,a:r.width*r.height,role:e.getAttribute('role')}}).filter(o=>o.a>0&&(ex? o.l.split(/\s+/).join(' ')===t : o.l.includes(t)));if(!els.length)return null;els.sort((x,y)=>x.a-y.a);const r=els[0].r;return [r.x+r.width/2,r.y+r.height/2]}"""
        xy=await s.pg.evaluate(js,[text,exact])
        if not xy: return False
        await s.pg.mouse.click(xy[0],xy[1]); await s.pg.wait_for_timeout(1200); return True
    async def tap_xy(s, x, y, wait=1200):
        await s.pg.mouse.click(x,y); await s.pg.wait_for_timeout(wait)
    async def type(s, text, delay=30):
        await s.pg.keyboard.type(text, delay=delay); await s.pg.wait_for_timeout(300)
    async def close(s):
        await s.b.close(); await s.pw.stop()

async def set_prefs(s, prefs):
    """Seed Flutter shared_preferences (localStorage 'flutter.<k>') before app boot."""
    import json as _j
    items={('flutter.'+k):(_j.dumps(v) if not isinstance(v,str) else _j.dumps(v)) for k,v in prefs.items()}
    await s.ctx.add_init_script("(()=>{const it=%s;for(const k in it){if(!localStorage.getItem(k))localStorage.setItem(k,it[k]);}})();" % _j.dumps(items, ensure_ascii=False))

async def route_tour(s, base, routes, tall=1700, wait=3500, textsfile=None):
    """Visit hash routes in-SPA, screenshot tall viewport, dump semantic text + failing API calls."""
    import json as _j
    out=[]
    for r in routes:
        s.net.clear(); s.log.clear()
        try:
            await s.pg.evaluate("(h)=>{location.hash=h}", '#'+r)
            await s.pg.wait_for_timeout(wait)
            await s.sem()
            txt=await s.texts()
            f=await s.shot(r.strip('/').replace('/','_') or 'root', tall=tall)
            bad=[(a,b,c) for a,b,c in s.net if a>=400]
            out.append({'route':r,'shot':f.split('/')[-1],'texts':txt,'api_calls':list(s.net),'api_errors':bad,'console_err':[l for l in s.log if 'rror' in l or 'Failed' in l][:5]})
        except Exception as e:
            out.append({'route':r,'error':str(e)[:200]})
    if textsfile: open(textsfile,'w').write(_j.dumps(out,ensure_ascii=False,indent=1))
    return out
