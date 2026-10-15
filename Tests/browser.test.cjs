const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const root=path.resolve(__dirname,'..');
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
  try {
    const page=await browser.newPage({viewport:{width:1100,height:800}});
    await page.setContent(`<style>body{padding:40px;font:22px Arial}textarea,input,[contenteditable]{display:block;font:22px Arial;padding:12px;width:600px;margin:20px;border:1px solid black}textarea{height:150px}</style><textarea id="area"></textarea><input id="single"><div id="rich" contenteditable="true"></div><input id="secret" type="password"><input id="off" spellcheck="false"><div id="host"></div>`);
    await page.evaluate(()=>{
      window.messages=[];
      window.chrome={runtime:{sendMessage:async message=>{
        messages.push(message);
        if(message.type==='check') { const i=message.text.indexOf('beautifull');return {ok:true,range:i<0?null:{location:i,length:10}}; }
        return {ok:true};
      }}};
    });
    await page.addScriptTag({path:path.join(root,'BrowserExtension/content.js')});
    async function reset() { await page.evaluate(()=>window.messages=[]); }
    async function target() { await page.waitForFunction(()=>messages.some(m=>m.type==='target'&&m.state==='target'),{},{timeout:7000}); return page.evaluate(()=>messages.filter(m=>m.state==='target').at(-1)); }
    await page.fill('#area','Hello 🦕 a beautifull day. ');
    let t=await target(); assert(t.rect.width>30 && t.rect.x>40 && t.rect.y>40);
    await reset(); await page.fill('#area','Hello a beautiful day. ');
    await page.waitForFunction(()=>messages.some(m=>m.state==='clear'),{},{timeout:7000});
    await reset(); await page.fill('#single','A beautifull morning. '); t=await target(); assert(t.rect.height>15);
    await reset(); await page.locator('#rich').fill('A beautifull morning. '); t=await target(); assert(t.rect.width>30);
    await reset(); await page.fill('#secret','beautifull-secret');
    await page.waitForFunction(()=>messages.some(m=>m.state==='blocked'),{},{timeout:7000});
    assert(!(await page.evaluate(()=>messages.some(m=>m.type==='check'))));
    await reset(); await page.fill('#off','beautifull-disabled');
    await target();
    await page.evaluate(()=>{ const shadow=document.querySelector('#host').attachShadow({mode:'open'});shadow.innerHTML='<textarea style="width:500px;height:70px;font:20px Arial"></textarea>'; });
    await reset(); await page.locator('#host textarea').fill('A beautifull day. '); await target();
    console.log('PASS: textarea, input, contenteditable, open shadow DOM, corrections, password exclusion, spellcheck=false editor support, geometry');
  } finally { await browser.close(); }
  let handler, received=[], active=true;
  const context={setTimeout,clearTimeout,console,navigator:{userAgent:'Chrome/140'},chrome:{
    storage:{local:{get:async()=>({enabled:true,offsetX:0,offsetY:0})}},
    tabs:{get:async()=>({id:1,windowId:1,active}),getZoom:async()=>1.25},
    windows:{get:async()=>({left:100,top:50,width:1200,height:900,focused:true})},
    runtime:{getURL:p=>'chrome-extension://test/'+p,onMessage:{addListener:fn=>handler=fn},connectNative:()=>{
      let cb;return {onMessage:{addListener:fn=>cb=fn},onDisconnect:{addListener:()=>{}},postMessage:m=>{received.push(m);setTimeout(()=>cb({id:m.id,ok:true}),0)}};
    }}
  }};
  vm.runInNewContext(fs.readFileSync(path.join(root,'BrowserExtension/background.js'),'utf8'),context);
  const sender={frameId:0,url:'https://example.org/',tab:{id:1}};
  const invoke=(m,s=sender)=>new Promise(resolve=>handler(m,s,resolve));
  await invoke({type:'target',state:'target',rect:{x:20,y:30,width:60,height:20},viewport:{width:900,height:600}});
  assert.equal(received[0].target.x,125);assert.equal(received[0].target.y,237.5);
  active=false; await invoke({type:'check',text:'beautifull ',caret:11});assert.equal(received.length,1);
  active=true; await invoke({type:'check',text:'secret',caret:6},{...sender,tab:{id:1,incognito:true}});assert.equal(received.length,1);
  await invoke({type:'target',state:'target',rect:{x:-1,y:0,width:50,height:20},viewport:{width:900,height:600}});assert.equal(received.length,1);
  console.log('PASS: native bridge routing, zoom coordinate mapping, inactive tab/private window/invalid geometry rejection');
})().catch(e=>{console.error(e);process.exitCode=1});
