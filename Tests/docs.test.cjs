const assert=require('node:assert/strict');
const {chromium}=require(process.env.PLAYWRIGHT_PATH || 'playwright');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 try{
  const context=await browser.newContext({viewport:{width:1100,height:800}});
  await context.route('https://docs.google.com/document/**',route=>route.fulfill({contentType:'text/html',body:'<div class="kix-cursor"><div class="kix-cursor-caret" style="position:absolute;left:600px;top:300px;width:1px;height:25px"></div></div><div class="kix-appview-editor" style="width:900px;height:700px" tabindex="0"></div>'}));
  const page=await context.newPage();await page.goto('https://docs.google.com/document/d/nailong-isolated-fixture/edit');await page.locator('.kix-appview-editor').focus();
  await page.addScriptTag({path:require('node:path').resolve(__dirname,'../BrowserExtension/docs.js')});
  assert.equal((await page.evaluate(()=>nailongDocsSnapshot())).state,'docs-wait');
  await page.waitForFunction(()=>nailongDocsSnapshot().state==='visual');
  const result=await page.evaluate(()=>nailongDocsSnapshot());assert(result.rect.x<=600 && result.rect.x+result.rect.width>=600);assert(result.rect.y<=300 && result.rect.y+result.rect.height>=325);
  await page.evaluate(()=>document.querySelector('.kix-cursor-caret').style.left='650px');
  assert.equal((await page.evaluate(()=>nailongDocsSnapshot())).state,'docs-wait');
  await page.evaluate(()=>document.querySelector('.kix-cursor-caret').remove());
  assert.equal((await page.evaluate(()=>nailongDocsSnapshot())).state,'docs-unavailable');
  console.log('PASS: Google Docs caret adapter, typing debounce, visible OCR region, explicit missing-caret state (isolated fixture; no Google document read or edited).');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
