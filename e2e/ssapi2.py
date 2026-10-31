import json, time, urllib.request, urllib.error, urllib.parse
B='http://127.0.0.1:4400/api/v1'
def call(method, path, body=None, token=None, timeout=170):
    h={'content-type':'application/json'}
    if token: h['authorization']='Bearer '+token
    data=json.dumps(body,ensure_ascii=False).encode() if body is not None else None
    path=urllib.parse.quote(path,safe="/?=&:,")
    r=urllib.request.Request(B+path,data=data,headers=h,method=method); t=time.time()
    try: resp=urllib.request.urlopen(r,timeout=timeout); b=resp.read(); st=resp.status
    except urllib.error.HTTPError as e: b=e.read(); st=e.code
    except Exception as e: return {'status':0,'sec':round(time.time()-t,1),'body':repr(e)[:300]}
    try: bd=json.loads(b)
    except Exception: bd=b[:600].decode('utf8','replace')
    return {'status':st,'sec':round(time.time()-t,1),'body':bd}
