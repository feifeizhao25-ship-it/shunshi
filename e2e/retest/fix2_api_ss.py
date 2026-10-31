"""fix2 retest for 顺时: same calls against the base backend (:4296) and the fix2 backend (:4293). Writes retest/fix2/ss_api_<label>.json"""
import json, re, sys, urllib.request, urllib.error, time, os
CJK = re.compile(r'[\u3400-\u9fff]')
GL = {'Accept-Language': 'en-US', 'X-App-Market': 'global'}
def call(base, method, path, body=None, tok=None, hdr=None, timeout=170):
    h = {'content-type': 'application/json'}
    if tok: h['Authorization'] = 'Bearer ' + tok
    if hdr: h.update(hdr)
    r = urllib.request.Request(base + path, data=(json.dumps(body).encode() if body is not None else None), headers=h, method=method)
    try:
        resp = urllib.request.urlopen(r, timeout=timeout); b = resp.read(); st = resp.status
    except urllib.error.HTTPError as e: b = e.read(); st = e.code
    try: b = json.loads(b)
    except Exception: b = b.decode('utf8', 'replace')[:400]
    return st, b
def run(label, base):
    out = {'label': label, 'base': base}
    st, j = call(base, 'POST', '/api/v1/auth/guest-login'); tok = j['access_token']
    out['plan_usage'] = dict(zip(('status', 'body'), call(base, 'GET', '/api/v1/subscription/plan-usage', tok=tok, hdr=GL)))
    out['culture_get'] = dict(zip(('status', 'body'), call(base, 'GET', '/api/v1/profile/culture', tok=tok, hdr=GL)))
    put = {'diet': ['halal'], 'observances': ['ramadan_fasting'], 'units': 'imperial', 'hemisphere': 'south'}
    out['culture_put'] = dict(zip(('status', 'body'), call(base, 'PUT', '/api/v1/profile/culture', put, tok, GL)))
    out['culture_put_bad'] = dict(zip(('status', 'body'), call(base, 'PUT', '/api/v1/profile/culture', {'diet': ['not-a-diet']}, tok, GL)))
    st, home = call(base, 'GET', '/api/v1/seasons/home/dashboard', tok=tok, hdr=GL)
    out['home'] = {'status': st, 'hemisphere': (home.get('hemisphere') if isinstance(home, dict) else None),
                   'season': (home.get('season') if isinstance(home, dict) else None),
                   'keys': sorted(home.keys()) if isinstance(home, dict) else None,
                   'milestone': home.get('milestone') if isinstance(home, dict) else None, 'recall': home.get('recall') if isinstance(home, dict) else None}
    q = 'What should I eat for dinner tonight and when should I eat it? Metric or imperial amounts please, and what season is it for me?'
    t = time.time(); st, chat = call(base, 'POST', '/api/v1/chat/send', {'message': q}, tok, GL)
    reply = (chat.get('reply') or chat.get('content') or chat.get('message') or json.dumps(chat, ensure_ascii=False)) if isinstance(chat, dict) else str(chat)
    out['chat'] = {'status': st, 'seconds': round(time.time() - t, 1), 'question': q, 'reply': reply[:1800], 'has_cjk': bool(CJK.search(reply)),
                   'keys': sorted(chat.keys()) if isinstance(chat, dict) else None,
                   'sources': chat.get('sources') if isinstance(chat, dict) else None}
    out['plan_usage_after_chat'] = dict(zip(('status', 'body'), call(base, 'GET', '/api/v1/subscription/plan-usage', tok=tok, hdr=GL)))
    # domestic client: Chinese answer and quota text
    st, jd = call(base, 'POST', '/api/v1/auth/guest-login'); td = jd['access_token']
    out['plan_usage_cn'] = dict(zip(('status', 'body'), call(base, 'GET', '/api/v1/subscription/plan-usage', tok=td)))
    return out
if __name__ == '__main__':
    os.makedirs('/workspace/ui_full_test/retest/fix2', exist_ok=True)
    for label, base in (('before', 'http://127.0.0.1:4296'), ('after', 'http://127.0.0.1:4293')):
        o = run(label, base)
        json.dump(o, open(f'/workspace/ui_full_test/retest/fix2/ss_api_{label}.json', 'w'), ensure_ascii=False, indent=1)
        print(label, {k: (v.get('status') if isinstance(v, dict) and 'status' in v else '') for k, v in o.items()}, flush=True)
