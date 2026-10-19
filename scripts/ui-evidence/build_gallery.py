"""Build a full-content, local-only review gallery. Historical captures are not retests."""
import collections, html, json, re, shutil
from pathlib import Path
ROOT=Path('/Users/feifei00/Documents')
SRC=ROOT/'四项目完整UI测试-20261016'
OUT=ROOT/'四项目UI完整证据-20261019'
OUT.mkdir(exist_ok=True)
(OUT/'records').mkdir(exist_ok=True)
(OUT/'images').mkdir(exist_ok=True)
secret=re.compile(r'^(password|access_token|refresh_token|csrfToken|token|authorization|cookies?|secret|api.?key|verification.?code|sms.?code|private.?key)$',re.I)
jwt=re.compile(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+')
def clean(value,key=''):
 if secret.search(key): return '[凭据已隐藏；业务内容保留]'
 if isinstance(value,dict): return {k:clean(v,k) for k,v in value.items()}
 if isinstance(value,list): return [clean(v) for v in value]
 if isinstance(value,str):
  try:
   obj=json.loads(value)
   if isinstance(obj,(dict,list)):return json.dumps(clean(obj),ensure_ascii=False)
  except (ValueError,TypeError):pass
  return jwt.sub('[测试访问令牌已隐藏]',value)
 return value
css='''body{margin:0;background:#f3f6f8;color:#182d38;font:16px/1.7 system-ui}main{max-width:1440px;margin:auto;padding:28px}h1{font-size:32px}a{color:#086b64}header,article,section{background:white;padding:24px;margin:18px 0;border-radius:14px;border:1px solid #dce6e8}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.8 ui-monospace,monospace;background:#f3f6f8;padding:20px}img{width:100%;height:auto;display:block}table{width:100%;border-collapse:collapse}td,th{padding:12px;text-align:left;border-bottom:1px solid #ddd;vertical-align:top}select,input{font:inherit;padding:9px;max-width:100%}.muted{color:#526975}.pill{background:#eef6f5;padding:4px 9px;border-radius:8px}nav{display:flex;gap:16px;flex-wrap:wrap}.scroll{overflow-x:auto}@media(max-width:600px){main{padding:10px}header,article,section{padding:14px}h1{font-size:25px}}'''
def page(title,body):return '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style><main>'+body+'</main></html>'
e=html.escape
rows=[json.loads(s) for s in (SRC/'index.jsonl').read_text().splitlines() if s.strip()]
summary=collections.defaultdict(lambda:{'records':0,'personas':set(),'routes':set(),'api':0,'errors':0,'zero_api':0,'missing':0,'statuses':collections.Counter()})
catalog=[]
for i,r in enumerate(rows,1):
 rid=f'old-{i:04d}';stats=summary[(r['product'],r['version'])];stats['records']+=1;stats['personas'].add(r['persona']);stats['routes'].add(r['route'])
 txt=(SRC/r['text']).read_text();apis=json.loads((SRC/r['api']).read_text());apis=clean(apis)
 statuses=collections.Counter(str(a.get('status','unknown')) for a in apis)
 errors=sum(n for s,n in statuses.items() if s.isdigit() and int(s)>=400)
 stats['api']+=len(apis);stats['errors']+=errors;stats['zero_api']+=not apis;stats['statuses'].update(statuses)
 image_name=rid+Path(r['image']).suffix;shutil.copyfile(SRC/r['image'],OUT/'images'/image_name)
 (OUT/'records'/f'{rid}.txt').write_text(clean(txt));(OUT/'records'/f'{rid}.json').write_text(json.dumps(apis,ensure_ascii=False,indent=2))
 status='请求失败，需核查' if errors else ('没有接口记录，不能据此判断输出成功' if not apis else '有接口记录，业务正确性未逐项验收')
 body=f'<nav><a href="../index.html">返回总览</a><a href="{rid}.txt">页面全文</a><a href="{rid}.json">完整接口记录（凭据隐藏）</a></nav><header><span class="pill">历史采集 · {e(r["ts"])}</span><h1>{e(r["product"])} / {e(r["version"])} / {e(r["persona"])}</h1><p>{e(r["route"])} — {e(r["name"])}</p><p>{e(status)}</p><p>{e(r["note"])}。旧记录未绑定Git提交，不能代表当前版本通过。</p></header><section><h2>实际截图 · 原图全部显示</h2><p>图片不裁切、不固定高度。Flutter原始采集若仅覆盖单屏，本总览不补造未拍摄内容。</p><a href="../images/{image_name}">打开原始分辨率</a><img src="../images/{image_name}" alt="{e(r["product"])}真实页面"></section><section><h2>采集的页面全文</h2><pre>{e(clean(txt))}</pre></section><section><h2>采集的完整接口输出</h2><p>保留全部业务字段及错误；仅隐藏口令、验证码、令牌等凭据。空数组表示没有采集到接口，不表示通过。</p><pre>{e(json.dumps(apis,ensure_ascii=False,indent=2))}</pre></section>'
 (OUT/'records'/f'{rid}.html').write_text(page(r['product']+'完整输出',body))
 catalog.append({'id':rid,**{k:r[k] for k in ['product','version','persona','route','name','ts']},'status':status,'api_count':len(apis),'errors':errors,'href':'records/'+rid+'.html'})
summary_data=[]
for (product,version),s in summary.items():summary_data.append({'product':product,'version':version,**{k:(len(v) if isinstance(v,set) else dict(v) if isinstance(v,collections.Counter) else v) for k,v in s.items()}})
(OUT/'historical-audit.json').write_text(json.dumps(summary_data,ensure_ascii=False,indent=2))
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
body='''<header><span class="pill">四产品 · 国内与国际独立验收</span><h1>把完整输出放到你眼前</h1><p>977条历史记录逐条展开：原始截图、页面全文、完整业务响应。没有文字省略、固定高度或缩略图替代原图。</p><p><b>这是一份证据审计，不是“全部功能通过”证明。</b>历史采集为2026-10-16至17日；今日重测单列。多种用户名称不能证明真实个性化；没有API请求也不能证明模型输出成功。</p><nav><a href="验收方案.md">五用户七天与19项验收方案</a><a href="current.html">今日真实页面重测</a><a href="historical-audit.json">统计原始数据</a></nav></header><section><h2>历史证据覆盖</h2><div class="scroll"><table><tr><th>产品</th><th>版本</th><th>记录</th><th>用户标签</th><th>路由</th><th>接口记录</th><th>HTTP ≥400</th><th>无接口记录页</th></tr>'''
for s in summary_data:body+='<tr>'+''.join('<td>'+e(str(s[k]))+'</td>' for k in ['product','version','records','personas','routes','api','errors','zero_api'])+'</tr>'
body+='</table></div><p>见己国际版：无采集记录。顺时原始Flutter分屏连续性需重新核对。错误接口计数可能包含同一接口多次调用，不等于独立缺陷数。</p></section><section><h2>全部977条记录</h2><p>按产品、版本、用户或路由筛选；符合条件的记录全部展示，无分页省略。</p><input id="search" placeholder="例如：分发侠 国际版 create" aria-label="筛选记录"><div id="list"></div></section>'
body+='<script>const rows='+json.dumps(catalog,ensure_ascii=False).replace('<','\\u003c')+''';function render(){const terms=document.querySelector('#search').value.toLowerCase().split(/\s+/).filter(Boolean);const host=document.querySelector('#list');host.replaceChildren();for(const r of rows){const text=[r.product,r.version,r.persona,r.route,r.name,r.status].join(' ');if(!terms.every(t=>text.toLowerCase().includes(t)))continue;const a=document.createElement('a');a.href=r.href;a.textContent=r.id+' · '+text;const p=document.createElement('p');p.append(a);host.append(p)}}document.querySelector('#search').addEventListener('input',render);render()</script>'''
(OUT/'index.html').write_text(page('四项目完整UI证据',body))
print(json.dumps(summary_data,ensure_ascii=False,indent=2))
