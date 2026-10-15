'use strict';
let port, sequence = 0;
const pending = new Map();
let lastError = 'Ready. Open Nailong to connect.';
function nativeRequest(message) {
  return new Promise((resolve, reject) => {
    if (!port) {
      port = chrome.runtime.connectNative('local.nailong.bridge');
      port.onMessage.addListener(reply => {
        const entry = pending.get(reply.id);
        if (entry) { clearTimeout(entry.timeout); pending.delete(reply.id); entry.resolve(reply); }
      });
      port.onDisconnect.addListener(() => {
        lastError = chrome.runtime.lastError?.message || 'Nailong bridge disconnected.';
        port = undefined;
        for (const entry of pending.values()) { clearTimeout(entry.timeout); entry.reject(new Error(lastError)); }
        pending.clear();
      });
    }
    const id = ++sequence;
    const timeout = setTimeout(() => { pending.delete(id); reject(new Error('Nailong did not respond.')); }, 4000);
    pending.set(id, { resolve, reject, timeout });
    try { port.postMessage({ ...message, id }); } catch (e) { clearTimeout(timeout); pending.delete(id); reject(e); }
  });
}
function browserKind() {
  if (navigator.userAgent.includes('Edg/')) return 'edge';
  if (navigator.brave) return 'brave';
  return 'chrome';
}
async function handle(message, sender) {
  const internalPage = sender.url?.startsWith(chrome.runtime.getURL('test.html'));
  if ((message.type === 'status' || message.type === 'launch') && (!sender.tab || internalPage)) {
    if (message.type === 'launch') return nativeRequest({type:'launch'});
    try {
      const reply=await nativeRequest({type:'ping'});
      lastError=reply.running ? (reply.enabled ? 'Connected. Nailong is running.' : 'Nailong is paused. Resume detection from its yellow menu icon.') : 'Bridge installed, but Nailong is closed. Click Start Nailong.';
      return {...reply,message:lastError};
    } catch(error) { lastError='Bridge unavailable: '+error.message+' In Nailong click Connect / repair browser, then reload this extension.'; return {ok:false,message:lastError}; }
  }
  if (!sender.tab || sender.frameId !== 0 || sender.tab.incognito || (!/^https?:/.test(sender.url || '') && !internalPage)) return { ok: false };
  const tab = await chrome.tabs.get(sender.tab.id);
  const win = await chrome.windows.get(tab.windowId);
  if (!tab.active || !win.focused) return { ok: false };
  const settings = await chrome.storage.local.get({ enabled: true, offsetX: 0, offsetY: 0 });
  if (!settings.enabled) return { ok: false, error: 'Extension paused' };
  if (message.type === 'check') {
    if (typeof message.text !== 'string' || message.text.length > 12000 || !Number.isInteger(message.caret) || message.caret < 0 || message.caret > message.text.length) return { ok: false };
    const reply = await nativeRequest({ type: 'check', text: message.text, caret: message.caret });
    lastError = reply.ok ? 'Connected to Nailong. Text stays on this Mac.' : reply.error;
    return reply;
  }
  if (message.type === 'target') {
    const { state, rect, viewport } = message;
    if (['visual','docs-unavailable'].includes(state) && !/^https:\/\/docs\.google\.com\/document\//.test(sender.url || '')) return {ok:false};
    if (!['target', 'clear', 'blocked', 'idle', 'visual', 'docs-unavailable'].includes(state)) return { ok: false };
    const target = { state, time: Date.now() / 1000, browser: browserKind(), windowX: win.left, windowY: win.top, windowWidth: win.width, windowHeight: win.height };
    if (state === 'target' || state === 'visual') {
      if (!rect || !viewport || ![rect.x, rect.y, rect.width, rect.height, viewport.width, viewport.height].every(Number.isFinite)) return { ok: false };
      if (rect.width <= 0 || rect.height <= 0 || rect.x < 0 || rect.y < 0 || rect.x + rect.width > viewport.width + 2 || rect.y + rect.height > viewport.height + 2) return { ok: false };
      const zoom = await chrome.tabs.getZoom(tab.id);
      // Browser window bounds are desktop points; DOM bounds are zoomed CSS pixels.
      const toolbarHeight = Math.max(0, win.height - viewport.height * zoom);
      Object.assign(target, { x: win.left + rect.x * zoom + Number(settings.offsetX), y: win.top + toolbarHeight + rect.y * zoom + Number(settings.offsetY), width: rect.width * zoom, height: rect.height * zoom });
    }
    return nativeRequest({ type: 'target', target });
  }
  return { ok: false };
}
chrome.runtime.onMessage.addListener((message, sender, respond) => {
  handle(message, sender).then(respond).catch(error => { lastError = error.message; respond({ ok: false, error: error.message }); });
  return true;
});
