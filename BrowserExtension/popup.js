chrome.storage.local.get({enabled:true,offsetX:0,offsetY:0}, settings=>{
  for(const key of Object.keys(settings)) {
    const input=document.getElementById(key);
    if(key==='enabled') input.checked=settings[key]; else input.value=settings[key];
    input.addEventListener('change',()=>chrome.storage.local.set({[key]:key==='enabled'?input.checked:Math.max(-500,Math.min(500,Number(input.value)||0))}));
  }
});
chrome.runtime.sendMessage({type:'status'},r=>document.getElementById('status').textContent=r?.message||'Open Nailong and a website text field.');
document.getElementById('test').onclick=()=>chrome.tabs.create({url:chrome.runtime.getURL('test.html')});
document.getElementById('launch').onclick=async()=>{await chrome.runtime.sendMessage({type:'launch'});setTimeout(()=>chrome.runtime.sendMessage({type:'status'},r=>document.getElementById('status').textContent=r?.message||'No response'),1500);};
