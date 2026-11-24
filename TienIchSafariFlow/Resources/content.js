(() => {
  "use strict";

  const STORAGE_KEY = "dmx_flow_pending_prompt_v1";
  const TTL_MS = 10 * 60 * 1000; // 10 phút
  const PILL_ID = "dmx-flow-autofill-pill";

  function decodeBase64UrlUtf8(b64url) {
    try {
      let b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
      while (b64.length % 4 !== 0) b64 += "=";
      const binary = atob(b64);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
      }
      return new TextDecoder("utf-8").decode(bytes);
    } catch (_) {
      return null;
    }
  }

  function savePendingPrompt(prompt) {
    if (!prompt || !prompt.trim()) return;
    const payload = { prompt: prompt.trim(), ts: Date.now(), filledCount: 0 };
    const raw = JSON.stringify(payload);
    try { sessionStorage.setItem(STORAGE_KEY, raw); } catch (_) {}
    try { localStorage.setItem(STORAGE_KEY, raw); } catch (_) {}
    try {
      if (typeof browser !== "undefined" && browser.storage && browser.storage.local) {
        browser.storage.local.set({ [STORAGE_KEY]: payload });
      }
    } catch (_) {}
  }

  function readPendingPromptSync() {
    for (const store of [sessionStorage, localStorage]) {
      try {
        const raw = store.getItem(STORAGE_KEY);
        if (!raw) continue;
        const obj = JSON.parse(raw);
        if (obj && obj.prompt && Date.now() - (obj.ts || 0) <= TTL_MS) {
          return obj;
        }
      } catch (_) {}
    }
    return null;
  }

  async function readPendingPromptAsync() {
    const syncVal = readPendingPromptSync();
    if (syncVal) return syncVal;
    try {
      if (typeof browser !== "undefined" && browser.storage && browser.storage.local) {
        const res = await browser.storage.local.get(STORAGE_KEY);
        const obj = res && res[STORAGE_KEY];
        if (obj && obj.prompt && Date.now() - (obj.ts || 0) <= TTL_MS) {
          savePendingPrompt(obj.prompt);
          return obj;
        }
      }
    } catch (_) {}
    return null;
  }

  function clearPendingPrompt() {
    try { sessionStorage.removeItem(STORAGE_KEY); } catch (_) {}
    try { localStorage.removeItem(STORAGE_KEY); } catch (_) {}
    try {
      if (typeof browser !== "undefined" && browser.storage && browser.storage.local) {
        browser.storage.local.remove(STORAGE_KEY);
      }
    } catch (_) {}
  }

  // Bước 1: Bắt ngay #dmx_prompt=... tại document_start trước khi SPA redirect
  function capturePromptFromHash() {
    const hash = window.location.hash || "";
    const match = hash.match(/dmx_prompt=([A-Za-z0-9\-_]+)/);
    if (!match) return false;
    const decoded = decodeBase64UrlUtf8(match[1]);
    if (decoded && decoded.trim()) {
      savePendingPrompt(decoded.trim());
      try {
        const cleanUrl = window.location.pathname + window.location.search;
        window.history.replaceState(null, "", cleanUrl);
      } catch (_) {}
      return true;
    }
    return false;
  }

  capturePromptFromHash();

  // Bước 2: Tìm ô nhập prompt của Google Flow (kể cả trong Shadow DOM)
  function collectEditableElements(root, out) {
    if (!root) return;
    const nodes = root.querySelectorAll
      ? root.querySelectorAll('textarea, [contenteditable="true"], [contenteditable=""], [role="textbox"]')
      : [];
    for (const el of nodes) out.push(el);
    const all = root.querySelectorAll ? root.querySelectorAll("*") : [];
    for (const el of all) {
      if (el.shadowRoot) collectEditableElements(el.shadowRoot, out);
    }
  }

  function isElementVisible(el) {
    if (!el || !el.isConnected) return false;
    const style = window.getComputedStyle(el);
    if (!style || style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) {
      return false;
    }
    const rect = el.getBoundingClientRect();
    return rect.width >= 80 && rect.height >= 24;
  }

  function findFlowPromptBox() {
    const candidates = [];
    collectEditableElements(document, candidates);
    let best = null;
    let bestScore = -1;

    for (const el of candidates) {
      if (!isElementVisible(el)) continue;
      if (el.disabled || el.readOnly || el.getAttribute("aria-disabled") === "true") continue;

      const meta = [
        el.getAttribute("placeholder") || "",
        el.getAttribute("aria-label") || "",
        el.getAttribute("data-placeholder") || "",
        el.id || "",
        typeof el.className === "string" ? el.className : ""
      ].join(" ").toLowerCase();

      // Bỏ qua ô tìm kiếm hoặc đặt tên dự án
      if (/(search|tìm kiếm|rename|project name|tên dự án|title)/i.test(meta)) continue;

      let score = 0;
      const rect = el.getBoundingClientRect();
      if (el.tagName === "TEXTAREA") score += 40;
      if (el.getAttribute("contenteditable") === "true" || el.getAttribute("role") === "textbox") score += 30;
      if (/(prompt|describe|create|imagine|generate|what|idea|scene|mô tả|nhập|tạo)/i.test(meta)) score += 60;
      if (rect.width >= 200) score += 20;
      if (rect.top > window.innerHeight * 0.35) score += 15; // Ô prompt Flow thường nằm nửa dưới
      score += Math.min(rect.width / 20, 25);

      if (score > bestScore) {
        bestScore = score;
        best = el;
      }
    }
    return best;
  }

  function getElementText(el) {
    if (!el) return "";
    if (el.tagName === "TEXTAREA" || el.tagName === "INPUT") {
      return (el.value || "").trim();
    }
    return (el.innerText || el.textContent || "").trim();
  }

  function setElementText(el, text) {
    if (!el) return false;
    try {
      el.focus();
      if (el.tagName === "TEXTAREA" || el.tagName === "INPUT") {
        const proto = el.tagName === "TEXTAREA"
          ? window.HTMLTextAreaElement.prototype
          : window.HTMLInputElement.prototype;
        const setter = Object.getOwnPropertyDescriptor(proto, "value")?.set;
        if (setter) {
          setter.call(el, text);
        } else {
          el.value = text;
        }
        el.dispatchEvent(new InputEvent("input", { bubbles: true, cancelable: true, inputType: "insertText", data: text }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
        return true;
      }

      // ContentEditable (Slate / ProseMirror / TipTap / Angular / React)
      const sel = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(el);
      sel.removeAllRanges();
      sel.addRange(range);

      const ok = document.execCommand && document.execCommand("insertText", false, text);
      if (!ok || getElementText(el).length < Math.min(10, text.length)) {
        el.textContent = text;
        el.dispatchEvent(new InputEvent("input", { bubbles: true, cancelable: true, inputType: "insertText", data: text }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Bước 3: Thanh nổi gọn nhẹ trên góc phải để báo trạng thái & hỗ trợ bấm "Điền lại" khi tạo dự án mới
  function renderPill(statusText, isFilled) {
    if (!document.body) return;
    let pill = document.getElementById(PILL_ID);
    if (!pill) {
      pill = document.createElement("div");
      pill.id = PILL_ID;
      pill.style.cssText = [
        "position: fixed",
        "top: 12px",
        "right: 12px",
        "z-index: 2147483647",
        "display: flex",
        "align-items: center",
        "gap: 8px",
        "padding: 8px 12px",
        "border-radius: 999px",
        "background: rgba(13, 110, 253, 0.94)",
        "color: #ffffff",
        "font-family: -apple-system, BlinkMacSystemFont, sans-serif",
        "font-size: 13px",
        "font-weight: 600",
        "box-shadow: 0 4px 14px rgba(0,0,0,0.22)",
        "backdrop-filter: blur(8px)",
        "-webkit-backdrop-filter: blur(8px)"
      ].join(";");
      document.body.appendChild(pill);
    }

    pill.style.background = isFilled ? "rgba(21, 128, 61, 0.94)" : "rgba(13, 110, 253, 0.94)";
    pill.innerHTML = "";

    const label = document.createElement("span");
    label.textContent = statusText;
    pill.appendChild(label);

    const btnFill = document.createElement("button");
    btnFill.type = "button";
    btnFill.textContent = isFilled ? "Điền lại" : "Điền ngay";
    btnFill.style.cssText = [
      "border: none",
      "border-radius: 999px",
      "padding: 4px 10px",
      "background: #ffffff",
      "color: #0f172a",
      "font-size: 12px",
      "font-weight: 700",
      "cursor: pointer"
    ].join(";");
    btnFill.addEventListener("click", () => {
      tryAutoFill(true);
    });
    pill.appendChild(btnFill);

    const btnClose = document.createElement("button");
    btnClose.type = "button";
    btnClose.textContent = "×";
    btnClose.style.cssText = [
      "border: none",
      "background: transparent",
      "color: #ffffff",
      "font-size: 16px",
      "line-height: 1",
      "padding: 0 2px",
      "cursor: pointer"
    ].join(";");
    btnClose.addEventListener("click", () => {
      pill.remove();
      clearPendingPrompt();
    });
    pill.appendChild(btnClose);
  }

  let autoFilledElement = null;

  async function tryAutoFill(force) {
    const data = await readPendingPromptAsync();
    if (!data || !data.prompt) return false;

    const box = findFlowPromptBox();
    if (!box) {
      renderPill("DMX: Mở dự án để điền Prompt", false);
      return false;
    }

    const currentText = getElementText(box);
    if (!force && autoFilledElement === box && currentText.length > 0) {
      return true;
    }
    if (!force && currentText.length > 0 && currentText !== data.prompt) {
      // Người dùng đang gõ sẵn nội dung khác -> không tự ghi đè, hiện nút để bấm nếu muốn
      renderPill("DMX: Có sẵn Prompt", false);
      return false;
    }

    const ok = setElementText(box, data.prompt);
    if (ok) {
      autoFilledElement = box;
      renderPill("DMX: Đã điền Prompt ✓", true);
      return true;
    }
    renderPill("DMX: Chạm để điền Prompt", false);
    return false;
  }

  function startWatcher() {
    readPendingPromptAsync().then((data) => {
      if (!data) return;
      tryAutoFill(false);

      const observer = new MutationObserver(() => {
        if (!readPendingPromptSync()) return;
        tryAutoFill(false);
      });
      if (document.documentElement) {
        observer.observe(document.documentElement, { childList: true, subtree: true });
      }

      let ticks = 0;
      const timer = setInterval(() => {
        ticks += 1;
        if (ticks > 90 || !readPendingPromptSync()) {
          clearInterval(timer);
          return;
        }
        tryAutoFill(false);
      }, 800);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", startWatcher, { once: true });
  } else {
    startWatcher();
  }

  window.addEventListener("hashchange", () => {
    if (capturePromptFromHash()) {
      autoFilledElement = null;
      tryAutoFill(true);
    }
  });

  // Nhận lệnh từ popup của Safari Extension
  try {
    if (typeof browser !== "undefined" && browser.runtime && browser.runtime.onMessage) {
      browser.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
        if (!msg) return;
        if (msg.action === "get_status") {
          const data = readPendingPromptSync();
          sendResponse({ hasPrompt: !!(data && data.prompt), prompt: data ? data.prompt : "" });
          return;
        }
        if (msg.action === "fill_now") {
          tryAutoFill(true).then((ok) => sendResponse({ ok }));
          return true;
        }
      });
    }
  } catch (_) {}
})();
