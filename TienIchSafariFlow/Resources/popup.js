(() => {
  const statusEl = document.getElementById("status");
  const previewEl = document.getElementById("preview");
  const btnFill = document.getElementById("btnFill");

  async function init() {
    try {
      const tabs = await browser.tabs.query({ active: true, currentWindow: true });
      const tab = tabs && tabs[0];
      if (!tab || !tab.id) {
        statusEl.textContent = "Hãy mở trang flow.google.com từ tab Truyền thông của app ĐMX.";
        return;
      }
      const res = await browser.tabs.sendMessage(tab.id, { action: "get_status" });
      if (res && res.hasPrompt) {
        statusEl.textContent = "Đã sẵn sàng prompt từ app ĐMX:";
        previewEl.textContent = res.prompt;
        previewEl.style.display = "block";
        btnFill.disabled = false;
        btnFill.addEventListener("click", async () => {
          const r = await browser.tabs.sendMessage(tab.id, { action: "fill_now" });
          statusEl.textContent = (r && r.ok)
            ? "Đã điền prompt vào Google Flow!"
            : "Chưa thấy ô nhập prompt. Hãy mở một dự án trong Flow rồi bấm lại.";
        });
      } else {
        statusEl.textContent = "Chưa có prompt chờ. Vào app Tổng Hợp ĐMX → tab Truyền thông → bấm Mở Google Flow.";
      }
    } catch (_) {
      statusEl.textContent = "Tiện ích này hoạt động trên trang flow.google.com.";
    }
  }

  init();
})();
