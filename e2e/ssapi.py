import json, urllib.request, time
BASE='http://127.0.0.1:4000'
def call(method, path, data=None, tok=None, hdr=None, timeout=150):
    h={'content-type':'application/json'}
    if tok: h['Authorization']='Bearer '+tok
    if hdr: h.update(hdr)
    r=urllib.request.Request(BASE+path, data=(json.dumps(data).encode() if data is not None else None), headers=h, method=method)
    t=time.time()
    try:
        resp=urllib.request.urlopen(r, timeout=timeout); b=resp.read()
        try: b=json.loads(b)
        except Exception: b=b.decode('utf8','replace')
        return resp.status, b, round(time.time()-t,1)
    except urllib.error.HTTPError as e:
        b=e.read().decode('utf8','replace')
        try: b=json.loads(b)
        except Exception: pass
        return e.code, b, round(time.time()-t,1)
    except Exception as e:
        return 0, str(e), round(time.time()-t,1)
