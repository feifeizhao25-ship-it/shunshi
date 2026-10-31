import json, sys, concurrent.futures as cf
sys.path.insert(0,'/workspace/ui_full_test/run')
from ssapi import *
from personas_ss import CN, EN
PW='Test@12345Aa'
def setup(p, en):
    body={'password':PW,'name':p['name']}
    if en: body['email']=p['email']
    else: body['phone']=p['phone']; body['password']='Test@12345'
    st,j,_=call('POST','/api/v1/auth/register',body)
    login={'password':body['password']}; login['email' if en else 'phone']=p['email'] if en else p['phone']
    st,j,_=call('POST','/api/v1/auth/login',login)
    return j.get('access_token') if isinstance(j,dict) else None, j
def run(p, en):
    tok,j=setup(p,en)
    res={'persona':p,'login':bool(tok),'chats':[]}
    hdr={'Accept-Language':'en-US'} if en else {'Accept-Language':'zh-CN'}
    for m in p['msgs']:
        st,r,t=call('POST','/api/v1/chat/send',{'message':m},tok,hdr)
        res['chats'].append({'message':m,'status':st,'seconds':t,'response':r})
    json.dump(res,open(f"/workspace/ui_full_test/out/ss_chat_{p['id']}.json",'w'),ensure_ascii=False,indent=1)
    return p['id']
with cf.ThreadPoolExecutor(4) as ex:
    futs=[ex.submit(run,p,False) for p in CN]+[ex.submit(run,p,True) for p in EN]
    for f in futs: print(f.result(), flush=True)
