async function status(){try{const result=await chrome.runtime.sendMessage({type:'status'});document.getElementById('connection').textContent=result.message||'No response';}catch(error){document.getElementById('connection').textContent=error.message;}}
document.getElementById('check').onclick=status;
document.getElementById('launch').onclick=async()=>{await chrome.runtime.sendMessage({type:'launch'});setTimeout(status,1500);};
status();
