import json, os, re, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
KEY = os.environ['MINIMAX_CN_API_KEY']
def complete(messages):
    req = urllib.request.Request('https://api.minimax.cn/v1/chat/completions',
        data=json.dumps({'model':'MiniMax-M3.1-Flash','messages':messages,'max_tokens':3500,'temperature':0.7}).encode(),
        headers={'Authorization':'Bearer '+KEY,'content-type':'application/json'})
    d = json.loads(urllib.request.urlopen(req, timeout=90).read())
    text = d['choices'][0]['message']['content']
    text = re.sub(r'<think>.*?</think>', '', text, flags=re.S).strip()
    return text, d.get('usage',{}).get('total_tokens',0)
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b'{"status":"ok"}')
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        msgs = body.get('messages') or ([{'role':'user','content':body['prompt']}] if body.get('prompt') else [])
        try:
            text, tok = complete(msgs)
            out = {'text':text,'model':'MiniMax-M3.1-Flash','provider':'minimax-cn','scene':body.get('scene','chat'),'tokens_used':tok,'finish_reason':'stop'}
            code = 200
        except Exception as e:
            out, code = {'detail': f'gateway error: {type(e).__name__}'}, 502
        data = json.dumps(out, ensure_ascii=False).encode()
        self.send_response(code); self.send_header('content-type','application/json'); self.end_headers(); self.wfile.write(data)
HTTPServer(('127.0.0.1', 9100), H).serve_forever()
