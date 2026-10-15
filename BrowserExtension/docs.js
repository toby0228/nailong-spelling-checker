// Google Docs draws its document on a canvas. Send a small visible area around
// the editing caret to local macOS OCR; never treat the hidden input iframe as text.
(() => {
  let previous='',stableAt=Date.now();
  globalThis.nailongDocsSnapshot=()=>{
    if(location.hostname!=='docs.google.com' || !location.pathname.startsWith('/document/')) return null;
    if(!document.hasFocus() || document.hidden) return {state:'idle'};
    const active=document.activeElement;
    if(active?.matches('input,textarea') && !active.className.includes('kix')) return null; // Title/search fields use ordinary DOM handling.
    const carets=[...document.querySelectorAll('.kix-cursor-caret')].filter(el=>{
      const r=el.getBoundingClientRect(),s=getComputedStyle(el);
      return r.height>3 && r.top>=0 && r.bottom<=innerHeight && r.left>=0 && r.right<=innerWidth && s.display!=='none';
    });
    const own=carets.find(el=>!el.closest('.kix-cursor')?.querySelector('.kix-cursor-name')) || carets[0];
    if(!own) return {state:'docs-unavailable'};
    const r=own.getBoundingClientRect(),key=[Math.round(r.x),Math.round(r.y),Math.round(r.height)].join(':');
    if(key!==previous){previous=key;stableAt=Date.now();}
    if(Date.now()-stableAt<850) return {state:'docs-wait'};
    // The previous part of the current line is most likely to contain the newly completed word.
    const x=Math.max(0,r.left-520), y=Math.max(0,r.top-28);
    const right=Math.min(innerWidth,r.right+160), bottom=Math.min(innerHeight,r.bottom+28);
    return {state:'visual',rect:{x,y,width:right-x,height:bottom-y},caret:{x:r.x,y:r.y,width:Math.max(1,r.width),height:r.height}};
  };
})();
