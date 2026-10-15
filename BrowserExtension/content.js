(() => {
  'use strict';
  let version = 0, composing = false, busy = false, lastActivity = Date.now(), snapshotKey = '', cached, cachedAt=0;
  const isTest=location.protocol==='chrome-extension:' && location.pathname==='/test.html';
  function report(message) { if(isTest) { const out=document.getElementById('editor-status'); if(out) out.textContent=message; } }
  const send = message => chrome.runtime.sendMessage(message).catch(error => { report('Connection error: '+error.message); return { ok:false }; });
  function focused() {
    let element = document.activeElement;
    while (element?.shadowRoot?.activeElement) element = element.shadowRoot.activeElement;
    return element;
  }
  function excluded(element) {
    const hint = `${element.autocomplete || ''} ${element.name || ''} ${element.id || ''}`;
    return element.matches('input[type=password],input[type=email],input[type=tel],input[type=number]') || /password|passwd|credit|card.?number|cc-|one-time-code|otp|social.?security/i.test(hint) || element.closest('[data-nailong-ignore]');
  }
  function editorSnapshot() {
    let el = focused();
    if (!el || !document.hasFocus() || document.hidden) return { state: 'idle' };
    if (excluded(el)) return { state: 'blocked' };
    if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
      if (el.readOnly || el.disabled || (el instanceof HTMLInputElement && !['text', 'search', 'url', ''].includes(el.type))) return { state: 'idle' };
      return { el, text: el.value, caret: el.selectionStart ?? el.value.length, state: 'editor' };
    }
    if (!el.isContentEditable) return { state: 'idle' };
    while (el.parentElement?.isContentEditable) el = el.parentElement;
    if (excluded(el)) return { state: 'blocked' };
    const nodes = [], walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, { acceptNode(node) {
      if (node.parentElement?.closest('script,style,[contenteditable="false"],[hidden]')) return NodeFilter.FILTER_REJECT;
      const style = getComputedStyle(node.parentElement);
      return style.display === 'none' || style.visibility === 'hidden' ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
    }});
    let text = '', caret = null, node;
    const selection = el.getRootNode().getSelection?.() || window.getSelection();
    while ((node = walker.nextNode())) {
      if (selection?.focusNode === node) caret = text.length + selection.focusOffset;
      nodes.push({ node, start: text.length }); text += node.data;
      if (text.length > 12000) return { state: 'idle' };
    }
    // Element-boundary carets (e.g. after a <br>) are mapped through a DOM range.
    if (caret === null && selection?.focusNode && el.contains(selection.focusNode)) {
      try { const r = document.createRange(); r.selectNodeContents(el); r.setEnd(selection.focusNode, selection.focusOffset); caret = r.toString().length; } catch {}
    }
    return { el, nodes, text, caret: Math.min(caret ?? text.length, text.length), state: 'editor' };
  }
  function wordRect(snapshot, match) {
    const { el, text, nodes } = snapshot;
    if (!nodes && getComputedStyle(el).transform !== 'none') return null;
    let rect;
    if (nodes) {
      const start = nodes.find(n => n.start <= match.location && n.start + n.node.length > match.location);
      const end = nodes.find(n => n.start < match.location + match.length && n.start + n.node.length >= match.location + match.length);
      if (!start || !end) return null;
      const range = document.createRange(); range.setStart(start.node, match.location - start.start); range.setEnd(end.node, match.location + match.length - end.start);
      rect = range.getClientRects()[0];
    } else {
      const mirror = document.createElement('div'), style = getComputedStyle(el), box = el.getBoundingClientRect();
      for (const property of ['fontFamily','fontSize','fontWeight','fontStyle','fontVariant','letterSpacing','wordSpacing','lineHeight','textTransform','textIndent','textAlign','direction','paddingTop','paddingRight','paddingBottom','paddingLeft','borderTopWidth','borderRightWidth','borderBottomWidth','borderLeftWidth','boxSizing','tabSize']) mirror.style[property] = style[property];
      Object.assign(mirror.style, { position:'fixed',left:`${box.left}px`,top:`${box.top}px`,width:`${box.width}px`,height:`${box.height}px`,borderStyle:'solid',visibility:'hidden',pointerEvents:'none',overflow:'hidden',whiteSpace:el instanceof HTMLTextAreaElement && el.wrap !== 'off' ? 'pre-wrap' : 'pre',overflowWrap:'break-word' });
      mirror.setAttribute('aria-hidden','true');
      mirror.append(document.createTextNode(text.slice(0, match.location)));
      const span=document.createElement('span'); span.textContent=text.slice(match.location, match.location + match.length); mirror.append(span, document.createTextNode(text.slice(match.location + match.length) || ' '));
      document.documentElement.append(mirror); mirror.scrollTop=el.scrollTop; mirror.scrollLeft=el.scrollLeft;
      rect=span.getClientRects()[0];
      rect=rect && { left:rect.left,top:rect.top,right:rect.right,bottom:rect.bottom,width:rect.width,height:rect.height };
      mirror.remove();
    }
    if (!rect || rect.width <= 0 || rect.height <= 0) return null;
    const box=el.getBoundingClientRect();
    if (rect.left<Math.max(0,box.left)-1 || rect.top<Math.max(0,box.top)-1 || rect.right>Math.min(innerWidth,box.right)+1 || rect.bottom>Math.min(innerHeight,box.bottom)+1) return null;
    // Avoid pointing at clipped or obscured content.
    const hit = el.getRootNode().elementFromPoint?.(rect.left+rect.width/2,rect.top+rect.height/2) || document.elementFromPoint(rect.left+rect.width/2,rect.top+rect.height/2);
    if (hit && hit!==el && !el.contains(hit)) return null;
    return { x:rect.left,y:rect.top,width:rect.width,height:rect.height };
  }
  async function scan() {
    if (busy || composing || Date.now()-lastActivity<700) return;
    busy=true;
    const generation=version;
    try {
      const docs=globalThis.nailongDocsSnapshot?.();
      if(docs){
        if(docs.state==='visual') await send({type:'target',state:'visual',rect:docs.rect,viewport:{width:innerWidth,height:innerHeight}});
        else if(docs.state==='docs-unavailable') await send({type:'target',state:'docs-unavailable'});
        else if(docs.state==='idle') await send({type:'target',state:'idle'});
        return;
      }
      const s=editorSnapshot();
      if (s.state!=='editor' || s.text.length>12000) { report(s.state==='blocked'?'Private field excluded.':'Click an editor below and type a misspelled word followed by a space.'); cached=undefined; snapshotKey=''; await send({type:'target',state:s.state==='blocked'?'blocked':'idle'}); return; }
      const key=`${s.caret}:${s.text}`;
      if (key!==snapshotKey || !cached || Date.now()-cachedAt>4000) {
        const reply=await send({type:'check',text:s.text,caret:s.caret});
        if (!reply.ok) { report(reply.error || 'Bridge not responding. Use Check connection above.'); return; }
        if (generation!==version || focused()!==s.el && !s.el.contains(focused())) return;
        cached=reply; snapshotKey=key; cachedAt=Date.now();
      }
      if (generation!==version || editorSnapshot().text!==s.text) return;
      const rect=cached.range && wordRect(s,cached.range);
      const result=await send({type:'target',state:cached.range ? (rect?'target':'idle') : 'clear',rect,viewport:{width:innerWidth,height:innerHeight}});
      report(!result.ok ? (result.error || 'Could not deliver word position.') : cached.range ? (rect ? 'Typo found and position sent to Nailong. Look for the orange outline.' : 'Typo found, but word is offscreen or covered.') : 'All clear — Nailong should return home.');
    } finally { busy=false; }
  }
  function changed() { version++; lastActivity=Date.now(); cached=undefined; }
  for (const name of ['input','focusin','focusout','selectionchange','scroll','resize']) addEventListener(name,changed,true);
  addEventListener('compositionstart',()=>{ composing=true; changed(); },true);
  addEventListener('compositionend',()=>{ composing=false; changed(); },true);
  addEventListener('visibilitychange',()=>{ changed(); send({type:'target',state:'idle'}); });
  addEventListener('pagehide',()=>send({type:'target',state:'idle'}));
  setInterval(scan,850);
})();
