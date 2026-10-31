import asyncio, sys, json; sys.path.insert(0,'/workspace/ui_full_test/run')
from fw import *
async def main(pid, port, route, *rest):
    st=json.load(open(f'/workspace/ui_full_test/data/state_ss_{pid}.json'))
    ls={i['name']:i['value'] for o in st['origins'] for i in o['localStorage']}
    s=await Sess('ssaudio_'+pid).start()
    await s.ctx.add_init_script("(()=>{const it=%s;for(const k in it)localStorage.setItem(k,it[k]);})();"%json.dumps(ls))
    await s.goto(f'http://127.0.0.1:{port}/', wait=7000)
    await s.pg.evaluate("(h)=>{location.hash=h}", '#'+route); await s.pg.wait_for_timeout(4000); await s.sem()
    print(await s.texts()); await s.shot('before',tall=None)
    btns=await s.pg.evaluate("()=>[...document.querySelectorAll('flt-semantics')].filter(e=>e.getAttribute('role')==='button').map(e=>[e.textContent.slice(0,20),Math.round(e.getBoundingClientRect().x),Math.round(e.getBoundingClientRect().y),Math.round(e.getBoundingClientRect().width),Math.round(e.getBoundingClientRect().height)])")
    print(btns)
    json.dump(btns,open(f'../out/ss_audio_btns_{pid}.json','w'),ensure_ascii=False)
    if len(sys.argv)>4:
        await s.tap_xy(195,519,6000); await s.shot('playing_6s')
        st1=await s.pg.evaluate("()=>[...document.querySelectorAll('audio')].map(a=>[a.src.slice(-60),a.currentTime,a.duration,a.paused,a.error&&a.error.code])")
        print('audio elems',st1); print(await s.texts())
        await s.tap_xy(195,519,1500); await s.tap_xy(76,654,5000); await s.shot('ambient_rain')
        print(await s.texts()); print('net',[n for n in s.net][:6]); print('log',[l for l in s.log if 'udio' in l or 'rror' in l][:5])
    await s.close()
asyncio.run(main(*sys.argv[1:]))
