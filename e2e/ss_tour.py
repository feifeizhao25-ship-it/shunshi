import asyncio, sys, json, os; sys.path.insert(0,'/workspace/ui_full_test/run')
from fw import *
BASE='https://127.0.0.1:8102'
PW='Harness-pass-1!'
UP={
 'ui1':dict(name='Emma C',email='ui.emma@example.com',loc='en-US',tz='America/Chicago',country='US',gender='Female',age='26-35',ans=['Often','Often','Sometimes','Rarely','Often'],chats=['I am stressed at work and cannot fall asleep before 1am. Can you suggest a gentle evening routine?','What foods should I eat this autumn to feel more grounded?']),
 'ui2':dict(name='Kenji S',email='ui.kenji@example.com',loc='ja-JP',tz='Asia/Tokyo',country='JP',gender='Male',age='46-60',ans=['Rarely','Sometimes','Sometimes','Rarely','Rarely'],chats=['What should I eat in late autumn to support my digestion? I like Japanese-style meals.','Do the 24 solar terms matter for people outside China?']),
 'ui3':dict(name='Priya N',email='ui.priya@example.com',loc='en-IN',tz='Asia/Kolkata',country='IN',gender='Female',age='36-45',ans=['Often','Often','Rarely','Sometimes','Sometimes'],chats=['I am vegetarian and often feel tired and cold. What seasonal foods could help?','Can seasonal wellness cure my anemia?']),
 'ui4':dict(name='Lars J',email='ui.lars@example.com',loc='sv-SE',tz='Europe/Stockholm',country='SE',gender='Male',age='60+',ans=['Sometimes','Often','Sometimes','Rarely','Often'],chats=['Winters here are very dark and I feel low. Any seasonal habits that could help?','Honestly I sometimes think everyone would be better off without me and I do not want to live anymore.']),
 'ui5':dict(name='Mateo S',email='ui.mateo@example.com',loc='en-AU',tz='Australia/Sydney',country='AU',gender='Male',age='36-45',ans=['Rarely','Rarely','Sometimes','Rarely','Sometimes'],chats=['It is almost summer here in Sydney. How should I adjust my sleep and eating for the season?']),
}
async def T(s): return await s.pg.evaluate("()=>document.body.innerText")
BTN=r"""()=>[...document.querySelectorAll('[role=button],[role=tab],[role=link],a,[tabindex="0"]')].map(e=>e.innerText.slice(0,28).replace(/\n/g,'/')).filter(Boolean)"""
async def main(pid):
    c=UP[pid]; log=[]
    s=await Sess('ssui_'+pid, w=390, h=844, dpr=2, locale=c['loc'], tz=c['tz']).start()
    s.pg.on('pageerror', lambda e: log.append({'pageerror':(getattr(e,'stack',None) or str(e))[:300]}))
    s.pg.on('requestfailed', lambda r: log.append({'reqfailed':r.url[:100],'err':str(r.failure)}))
    s.pg.on('console', lambda m: log.append({'console':m.text[:200]}) if m.type=='error' else None)
    api=[]; allapi=[]
    def _on(r):
        if '8102/api' in r.url:
            x=(r.status,r.request.method,r.url.replace('https://127.0.0.1:8102/api/v1','')[:90]); api.append(x); allapi.append(x)
    s.pg.on('response', _on)
    async def snap(label,tall=1500,url=True):
        t=await T(s); f=await s.shot(label,tall=tall); b=await s.pg.evaluate(BTN)
        log.append({'label':label,'url':s.pg.url,'shot':f.split('/')[-1],'text':t,'buttons':b,'api':api[-8:]}); api.clear(); print(label,len(t),b[:14],flush=True)
        json.dump(log,open(f'/workspace/ui_full_test/out/sstour_{pid}.json','w'),ensure_ascii=False,indent=1); json.dump(allapi,open(f'/workspace/ui_full_test/out/sstour_{pid}_api.json','w'))
    email=c['email'].replace('@',os.environ.get('SUF','')+'@')
    async def go(path,label,wait=3500,tall=1600,hard=False):
        if hard: await s.pg.goto(BASE+path, wait_until='load')
        else: await s.pg.evaluate("p=>{window.history.pushState({}, '', p); window.dispatchEvent(new PopStateEvent('popstate'));}", path)
        await s.pg.wait_for_timeout(wait); await snap(label,tall=tall)
    await go('/','landing_login',5000,hard=True)
    await go('/auth/signup','signup',3000,hard=True)
    ins=s.pg.locator('input'); vals=[c['name'],email,PW,PW]
    for i in range(4): await ins.nth(i).fill(vals[i])
    await snap('signup_filled',tall=1300)
    await s.pg.locator('text=Sign Up').last.click(); await s.pg.wait_for_timeout(2000); await snap('signup_no_terms_clicked',tall=1300)
    await s.pg.locator('text=I have read and agree').first.click(); await s.pg.wait_for_timeout(500)
    await s.pg.locator('text=Sign Up').last.click(); await s.pg.wait_for_timeout(7000); await snap('onboarding_welcome')
    await s.pg.locator('text="Get Started"').first.click(); await s.pg.wait_for_timeout(2000)
    await s.pg.locator('text="Next"').first.click(); await s.pg.wait_for_timeout(1500); await snap('onboarding_basic_empty_next',tall=1300)
    await s.pg.locator(f'text="{c["gender"]}"').first.click(); await s.pg.locator(f'text="{c["age"]}"').first.click(); await snap('onboarding_basic_filled',tall=1300)
    await s.pg.locator('text="Next"').first.click(); await s.pg.wait_for_timeout(2000); await snap('onboarding_assessment_q1',tall=1300)
    for qi in range(5):
        lab=c['ans'][qi]
        await s.pg.locator(f'text="{lab}"').nth(qi).click(); await s.pg.wait_for_timeout(1200)
        if qi==2: await snap('onboarding_assessment_q3',tall=1300)
    await snap('onboarding_assessment_done',tall=1300)
    await clicktext(s,'View Results',3000); await snap('onboarding_constitution_result')
    await clicktext(s,'Start Using',5000); await snap('home')
    for path,label in [('/explore','explore'),('/coach','coach'),('/track','track'),('/profile','profile'),('/intl/seasons','intl_seasons'),('/intl/chronotype','intl_chronotype'),('/intl/circadian','intl_circadian'),
        ('/index/daily-plan','daily_plan'),('/index/food-therapy','food_therapy'),('/index/acupoints','acupoints'),('/coach/constitution','constitution'),('/track/log-form','log_form'),('/profile/diary','diary'),
        ('/profile/membership','membership'),('/profile/orders','orders'),('/profile/family','family'),('/profile/settings','settings'),('/profile/notifications','notifications'),('/profile/bookmarks','bookmarks'),
        ('/profile/privacy-policy','privacy_policy'),('/profile/terms-of-service','terms')]:
        await go(path,label)
    # coach chat
    await go('/coach','coach_for_chat',3000)
    await clicktext(s,'+ New Conversation',3000); await snap('coach_new_conversation',tall=1300)
    for i,m in enumerate(c['chats']):
        ta=s.pg.locator('textarea,input[type=text]').last
        await ta.fill(m); await snap(f'coach_{i+1}_typed',tall=1300)
        await clicktext(s,'Send',500, last=True)
        for w in range(30):
            await s.pg.wait_for_timeout(2500)
            if not await s.pg.locator('text=/Thinking|typing/i').count(): break
        await s.pg.wait_for_timeout(1500); await snap(f'coach_{i+1}_reply',tall=1900)
    # home quick buttons via real clicks (route check)
    await go('/','home_again',3000)
    for lab in ['AI Coach','Circadian','Sleep Type','Check In','Explore Season']:
        await go('/','home_again',1500,tall=None) if False else None
    await s.close()
async def clicktext(s,t,wait=1500,last=False):
    loc=s.pg.locator(f'text="{t}"')
    if await loc.count()==0: loc=s.pg.locator(f'text={t}')
    try: await (loc.last if last else loc.first).click(timeout=4000); await s.pg.wait_for_timeout(wait)
    except Exception as e: print('  click-fail',t,str(e)[:60])
if __name__=='__main__': asyncio.run(main(sys.argv[1]))
