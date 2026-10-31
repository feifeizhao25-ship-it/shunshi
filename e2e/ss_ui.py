import asyncio, sys, json; sys.path.insert(0,'/workspace/ui_full_test/run')
from fw import *
from personas_ss import CN, EN
CFG={'cn1':dict(g='女',y=1958,c='气虚质',d='入睡困难，容易疲乏，在吃降压药'),
     'cn2':dict(g='男',y=1994,c='湿热质',d='长期加班，眼睛干涩，下午犯困'),
     'cn3':dict(g='女',y=1997,c='阳虚质',d='产后8个月，怕冷，容易出汗'),
     'cn4':dict(g='女',y=2007,c='气郁质',d='考试压力大，情绪低落，睡不好'),
     'cn5':dict(g='男',y=1981,c='痰湿质',d='体检血糖偏高，久坐，体重偏重')}
ROUTES_CN=['/today','/solar','/wellness','/profile','/chat','/solar-wellness','/seasons','/library','/discover','/constitution','/constitution-test','/constitution-report','/diary','/diary-report','/sleep-report','/records','/daily-checkin','/wellness-dashboard','/wellness-report','/meditation','/mood','/tea','/body-type-essence','/community','/achievement','/growth','/family','/family-home','/favorites','/subscription','/settings','/notifications','/notification-settings','/search','/boundaries','/privacy','/about','/feedback','/reflection','/diet-recommend']
async def login(s, ident, pw, en=False):
    if en: return
    await s.tap_text('密码登录'); await s.pg.wait_for_timeout(500)
    await s.tap_xy(195,294); await s.type(ident)
    await s.tap_xy(144,362); await s.type(pw)
    await s.tap_text('登录', exact=True); await s.pg.wait_for_timeout(4500)
async def onboard(s,p,pid):
    c=CFG[pid]
    await s.tap_xy(195,236); await s.type(p['name']); await s.tap_text('下一步'); await s.pg.wait_for_timeout(900)
    await s.tap_text(c['g']); await s.tap_text('下一步'); await s.pg.wait_for_timeout(900)
    xy=await s.pg.evaluate("()=>{const e=[...document.querySelectorAll('flt-semantics')].find(e=>e.getAttribute('role')==='slider');if(!e)return null;const r=e.getBoundingClientRect();return [r.x,r.y+r.height/2,r.width]}")
    if xy:
        x=xy[0]+xy[2]*(c['y']-1940)/70; await s.tap_xy(x,xy[1])
    await s.shot('age_step'); print('year texts',[t for t in await s.texts() if t.isdigit() or '岁' in t])
    await s.tap_text('下一步'); await s.pg.wait_for_timeout(900)
    await s.tap_text(c['c']); await s.tap_xy(195,485); await s.type(c['d']); await s.shot('constitution_step')
    await s.tap_text('完成'); await s.pg.wait_for_timeout(5000)
async def main(pid):
    p=[x for x in CN if x['id']==pid][0]
    s=await Sess('ss_'+pid).start()
    await set_prefs(s,{'onboarding_completed':True})
    await s.goto('http://127.0.0.1:8001/', wait=7000)
    await s.shot('login_empty')
    await login(s,p['phone'],'Test@12345')
    await onboard(s,p,pid)
    print(pid,'after onboarding',s.pg.url, await s.texts())
    await s.ctx.storage_state(path=f'/workspace/ui_full_test/data/state_ss_{pid}.json')
    await s.shot('home', tall=1900)
    res=await route_tour(s,'',ROUTES_CN, textsfile=f'/workspace/ui_full_test/out/ss_tour_{pid}.json')
    print(pid,'tour done',len(res)); await s.close()
asyncio.run(main(sys.argv[1]))
