"use strict";
const zh = document.documentElement.lang === "zh-CN";
document.querySelector("#copy-sample").addEventListener("click", async () => {
  const status = document.querySelector("#copy-status");
  try {
    await navigator.clipboard.writeText("This is a beautifull day. ");
    status.textContent = zh ? "已复制。" : "Copied.";
  } catch {
    const range = document.createRange();
    range.selectNodeContents(document.querySelector(".sample code"));
    const selection = window.getSelection();
    selection.removeAllRanges(); selection.addRange(range);
    status.textContent = zh ? "已选中文字，请按 ⌘C 复制。" : "Text selected. Press ⌘C to copy.";
  }
});
