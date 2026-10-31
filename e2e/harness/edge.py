"""Tiny TLS static+reverse-proxy server. usage: edge.py PORT STATIC_DIR PREFIX=http://backend ..."""
import sys, ssl, asyncio, mimetypes, os
from aiohttp import web, ClientSession
port=int(sys.argv[1]); root=sys.argv[2]; proxies=[a.split('=',1) for a in sys.argv[3:]]
async def handler(req):
    for pre,back in proxies:
        if req.path.startswith(pre):
            async with ClientSession() as s:
                body=await req.read()
                h={k:v for k,v in req.headers.items() if k.lower() not in ('host','content-length')}
                async with s.request(req.method, back+req.path_qs, data=body, headers=h, allow_redirects=False) as r:
                    data=await r.read()
                    hh={k:v for k,v in r.headers.items() if k.lower() not in ('transfer-encoding','content-encoding','content-length','connection')}
                    return web.Response(body=data, status=r.status, headers=hh)
    p=os.path.normpath(os.path.join(root, req.path.lstrip('/')))
    if not p.startswith(root) or not os.path.isfile(p):
        p=os.path.join(root,'index.html')
    ct=mimetypes.guess_type(p)[0] or 'application/octet-stream'
    resp=web.FileResponse(p, headers={'Content-Type':ct,'Cache-Control':'no-store'})
    return resp
app=web.Application(client_max_size=50*1024**2); app.router.add_route('*','/{tail:.*}',handler)
ctx=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.load_cert_chain('/workspace/ui_full_test/tools/cert.pem','/workspace/ui_full_test/tools/key.pem')
web.run_app(app, host='127.0.0.1', port=port, ssl_context=ctx, print=None)
