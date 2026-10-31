"""Retest battery for the SEASONS fix branches (backend REGION=global on :4401). Writes /workspace/ui_full_test/retest/ss3_<id>.json"""
import sys, json, re, time, uuid, urllib.request, urllib.error
sys.path.insert(0,'/workspace/ui_full_test/run')
import ssapi2
ssapi2.B = 'http://127.0.0.1:4401/api/v1'
from ssapi2 import call
from ss2_battery import P
OUT='/workspace/ui_full_test/retest/seasons/after/api'
CJK=re.compile(r'[\u3400-\u9fff]')
LAT={'US':30.3,'JP':34.7,'IN':19.0,'SE':59.3,'AE':25.2,'AU':-33.9}
A12={'s1':[2,3,3,1,1,1,2,2,1,3,2,3],'s2':[1,1,1,1,1,1,1,1,1,1,1,5],'s3':[4,3,3,1,1,1,1,5,1,1,1,3],
     's4':[2,2,2,2,2,2,2,4,2,2,4,2],'s5':[1,1,1,4,1,1,5,1,1,1,1,4],'s6':[1,1,1,1,1,1,1,1,1,1,1,5]}
def run(pid):
    c=P[pid]; r={'persona':c['name'],'country':c['country']}
    pw='Harness-pass-1!'; em=c['email'].replace('@','+rt%s@'%uuid.uuid4().hex[:4])
    su=call('POST','/auth/signup',{'email':em,'password':pw,'name':c['name'],'region':'global'}); t=su['body'].get('access_token'); r['signup']=su['status']
    # forgot-password must not return a token
    fp=call('POST','/auth/forgot-password',{'email':em}); r['forgot_password']={'status':fp['status'],'body':fp['body'],'leaks_token':'token' in json.dumps(fp['body']).lower()}
    pr=call('PUT','/users/me/profile',{'country':c['country'],'city':c['city'],'latitude':LAT[c['country']],'timezone':c['tz'],'goals':c['goals'],'dietary_preferences':c['diet'],'health_conditions':c['cond'],'birth_date':c['birth']},token=t)
    r['profile']={'status':pr['status'],'hemisphere':pr['body'].get('hemisphere') if isinstance(pr['body'],dict) else None,'climate':pr['body'].get('climate') if isinstance(pr['body'],dict) else None}
    ms=call('GET','/intl/me/season',token=t); r['my_season']={k:(ms['body'].get(k) if isinstance(ms['body'],dict) else None) for k in ('season_key','hemisphere','climate','name')}
    r['dashboard']=call('GET','/intl/home/dashboard',token=t)['body']
    co=call('POST','/users/me/constitution',{'answers':A12[pid]},token=t); r['constitution']={'status':co['status'],'type':co['body'].get('constitution_type') if isinstance(co['body'],dict) else None,'scores':co['body'].get('scores') if isinstance(co['body'],dict) else None}
    r['settings']=call('GET','/users/me/settings',token=t)['body']
    r['achievements']=call('GET','/users/me/achievements',token=t)['status']
    r['jieqi_404']=call('GET','/jieqi/today',token=t)['status']
    r['wechat_state_404']=call('GET','/auth/oauth/wechat/state')['status']
    cl=call('GET','/content/',token=t); r['content']={'status':cl['status'],'hanzi':bool(CJK.search(json.dumps(cl['body'],ensure_ascii=False))),'langs':sorted({i['language'] for i in cl['body'].get('items',[])}) if isinstance(cl['body'],dict) else None}
    r['tiers']=call('GET','/intl/payment/tiers',token=t)['body']
    r['orders']=call('GET','/intl/orders',token=t)['status']
    r['habit_log']=call('POST','/wellness/habit-logs',{'sleep_quality':2,'energy_level':2,'mood':'tired','plan_adherence':0.25,'notes':'rt'},token=t)['status']
    pl=call('POST','/wellness/coach/daily-plan',{},token=t); r['daily_plan']={'status':pl['status'],'sec':pl['sec'],'body':pl['body']}
    r['chats']=[]
    for m in c['chats']:
        ch=call('POST','/wellness/coach/chat',{'message':m,'region':'global'},token=t)
        d=ch['body'].get('data',{}) if isinstance(ch['body'],dict) else {}
        r['chats'].append({'q':m,'status':ch['status'],'sec':ch['sec'],'blocked':d.get('blocked'),'crisis':d.get('crisis'),'reply':d.get('content')})
        r['chats'][-1]['hanzi']=bool(CJK.search(d.get('content') or ''))
    json.dump(r,open(f'{OUT}/ss3_{pid}.json','w'),ensure_ascii=False,indent=1)
    print(pid,c['name'],'season',r['my_season'],'const',r['constitution']['type'],'fp_leak',r['forgot_password']['leaks_token'],'chats',[(x['status'],x['blocked'],x['sec']) for x in r['chats']],flush=True)
if __name__=='__main__':
    for p in sys.argv[1:] or ['s1','s2','s3','s4','s5','s6']: run(p)
