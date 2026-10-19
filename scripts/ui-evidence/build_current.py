import html,json
from pathlib import Path
OUT=Path('/Users/feifei00/Documents/四项目UI完整证据-20261019')
e=html.escape
css='body{font:16px/1.8 system-ui;background:#f1f5f7;color:#18323a;margin:0}main{max-width:1250px;margin:auto;padding:24px}article,header{background:white;padding:24px;border-radius:14px;margin-bottom:20px}img{width:100%;height:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#edf3f5;padding:16px}a{color:#086a60}h1{font-size:32px}nav{display:flex;gap:20px;flex-wrap:wrap}'
def page(t,b):return '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+e(t)+'</title><style>'+css+'</style><main>'+b+'</main></html>'
allrows=[];groups=[]
for name in ['contentflow-output','after-energy-cn','membership-energy-cn','after-membership-boundaries','after-energy-global','before-membership-boundaries','current-energy-cn','current-energy-global']:
 folder=OUT/name
 if not (folder/'manifest.json').exists():continue
 rows=json.loads((folder/'manifest.json').read_text());groups.append((name,rows))
 for r in rows:
  text=(folder/r['text']).read_text();api=(folder/r['api']).read_text();meta={k:v for k,v in r.items() if k not in ['image','text','api']}
  body=f'<nav><a href="../current.html">返回本日重测</a><a href="{e(r["image"])}">原始图片</a><a href="{e(r["text"])}">完整页面文字</a><a href="{e(r["api"])}">完整接口响应</a></nav><header><h1>{e(name)} · {e(r["profile"])}</h1><p>{e(r.get("scenario",""))}</p><p>测试条件详见本条记录。接口替身或本地种子不代表真实模型、真实付款或会员闭环；七步输入测试不等于真实七天登录。</p></header><article><h2>完整实际截图</h2><img src="{e(r["image"])}"></article><article><h2>完整页面输出</h2><pre>{e(text)}</pre></article><article><h2>完整业务API响应</h2><pre>{e(api)}</pre></article><article><h2>测试条件与记录</h2><pre>{e(json.dumps(meta,ensure_ascii=False,indent=2))}</pre></article>'
  (folder/(r['id']+'.html')).write_text(page('真实UI完整输出',body));allrows.append((name,r))
body='<header><a href="index.html">返回四产品总览</a><h1>本日真实运行与修复前后对照</h1><p>按国内、国际、修复前、修复后分组。全部记录均可展开查看原始截图、页面全文、业务响应。</p><nav><a href="contentflow-output/005.html">分发侠手机长文显示（接口替身）</a><a href="contentflow-output/010.html">分发侠桌面长文显示（接口替身）</a><a href="after-energy-cn/001.html">国内手机完整测算结果</a><a href="after-energy-cn/008.html">国内桌面完整测算结果</a><a href="membership-energy-cn/2.html">会员中心与实际用量</a><a href="after-energy-global/009.html">国际版负值输入修复后</a></nav></header>'
for name,rs in groups:
 body+='<article><h2>'+e(name)+' · '+str(len(rs))+' 条</h2>'
 for r in rs:body+='<p><a href="'+name+'/'+r['id']+'.html">'+e(r['id']+' · '+r['profile']+' · '+str(r.get('day',''))+' · '+r.get('scenario',''))+'</a></p>'
 body+='</article>'
(OUT/'current.html').write_text(page('本日UI完整重测',body))
print('current captures:',len(allrows))
