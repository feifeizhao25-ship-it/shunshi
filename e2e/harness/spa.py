import sys, os, http.server, socketserver
root, port = sys.argv[1], int(sys.argv[2])
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(s,*a,**k): super().__init__(*a,directory=root,**k)
    def log_message(s,*a): pass
    def do_GET(s):
        p=s.translate_path(s.path.split('?')[0])
        if not os.path.exists(p) or os.path.isdir(p) and not os.path.exists(os.path.join(p,'index.html')): s.path='/index.html'
        return super().do_GET()
class T(socketserver.ThreadingMixIn, http.server.HTTPServer): daemon_threads=True
T(('127.0.0.1',port),H).serve_forever()
