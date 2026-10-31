import asyncio, sys, json; sys.path.insert(0,'/workspace/ui_full_test/run')
from fw import *
from personas_ss import EN
Y=[244,329,414,499,584]
CFG={'en1':dict(tz='America/Chicago',mood=1,help=[0,1],stage=1,sup=2,guide=1),
     'en2':dict(tz='Asia/Tokyo',mood=2,help=[3,0],stage=2,sup=0,guide=0),
     'en3':dict(tz='Asia/Kolkata',mood=4,help=[3],stage=3,sup=0,guide=1),
     'en4':dict(tz='Europe/Stockholm',mood=2,help=[4,2],stage=4,sup=1,guide=1),
     'en5':dict(tz='Asia/Dubai',mood=0,help=[0,3],stage=1,sup=2,guide=2)}
ROUTES_EN=['/today','/home','/chat','/solar','/wellness','/profile','/seasons','/library','/discover','/constitution','/diary','/records','/daily-checkin','/wellness-report','/meditation','/mood','/tea','/community','/achievement','/growth','/family','/favorites','/subscription','/settings','/notifications','/search','/privacy','/about','/feedback','/reflection','/journal','/sleep-report']
async def main(pid, explore_only=False):
    p=[x for x in EN if x['id']==pid][0]; c=CFG[pid]
    s=await Sess('ss_'+pid, locale='en-US', tz=c['tz']).start()
    await s.goto('http://127.0.0.1:8002/', wait=7000)
    seen=set()
    for i in range(10):
        t=await s.texts(); title=next((x for x in t if x not in ('SEASONS',)),'')
        print(i,s.pg.url,t,flush=True); await s.shot(f'onb{i}')
        if 'feeling' in title: await s.tap_xy(195,Y[c['mood']])
        elif 'help with' in title:
            for k in c['help']: await s.tap_xy(195,Y[k])
        elif 'stage of life' in title: await s.tap_xy(195,Y[c['stage']])
        elif 'like support' in title: await s.tap_xy(195,Y[c['sup']])
        elif 'should' in title: await s.tap_xy(195,Y[c['guide']])
        else:
            opts=[x for x in t if '\n' in x]
            if title in seen: break
            if opts: await s.tap_xy(195,Y[0])
        seen.add(title)
        ok=False
        for b in ['Continue','Get started','Next','Skip for now','Skip','Start','Begin','Done']:
            if any(b in x for x in t) and await s.tap_text(b): ok=True; break
        if not ok: break
        await s.pg.wait_for_timeout(2200)
    await s.pg.wait_for_timeout(5000)
    print('END',s.pg.url, await s.texts(),flush=True)
    await s.shot('home',tall=1900)
    await s.ctx.storage_state(path=f'/workspace/ui_full_test/data/state_ss_{pid}.json')
    res=await route_tour(s,'',ROUTES_EN, textsfile=f'/workspace/ui_full_test/out/ss_tour_{pid}.json'); print('tour done',len(res),flush=True)
    await s.close()
asyncio.run(main(sys.argv[1]))
