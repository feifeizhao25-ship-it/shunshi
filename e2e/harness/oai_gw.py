"""Local OpenAI-compatible shim -> MiniMax CN (test harness only; key from env, never written)."""
import json, os, re, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
KEY=os.environ['MINIMAX_CN_API_KEY']; MODEL='MiniMax-Text-01'
class H(BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_GET(self): self.send_response(200); self.end_headers(); self.wfile.write(b'{"status":"ok"}')
    def do_POST(self):
        open('/workspace/ui_full_test/logs/oai_req.log','a').write('req\n')
        body=json.loads(self.rfile.read(int(self.headers.get('Content-Length',0)) or 0) or b'{}')
        req={k:body[k] for k in ('messages','temperature','top_p','max_tokens','stop') if k in body}; req['model']=MODEL; req['max_tokens']=min(int(req.get('max_tokens') or 2500),3000)
        r=urllib.request.Request('https://api.minimax.cn/v1/chat/completions',data=json.dumps(req).encode(),headers={'Authorization':'Bearer '+KEY,'content-type':'application/json'})
        try:
            d=json.loads(urllib.request.urlopen(r,timeout=170).read())
            for c in d.get('choices',[]):
                m=c.get('message',{}); m['content']=re.sub(r'<think>.*?</think>','',m.get('content') or '',flags=re.S).strip(); m.pop('reasoning_content',None)
            open('/workspace/ui_full_test/logs/oai_req.log','a').write(repr([(c.get('finish_reason'),len(c['message'].get('content') or '')) for c in d.get('choices',[])])+' '+str(d.get('usage',{}).get('completion_tokens'))+' base_resp='+str(d.get('base_resp'))+'\n')
            out=json.dumps(d,ensure_ascii=False).encode(); code=200
        except Exception as e:
            open('/workspace/ui_full_test/logs/oai_gw_err.log','a').write(repr(e)[:300]+'\n')
            out=json.dumps({'error':{'message':'gateway '+type(e).__name__}}).encode(); code=502
        self.send_response(code); self.send_header('content-type','application/json'); self.end_headers(); self.wfile.write(out)
ThreadingHTTPServer(('127.0.0.1',9110),H).serve_forever()
