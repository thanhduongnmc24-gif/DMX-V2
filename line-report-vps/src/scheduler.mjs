import { api } from "./api.mjs";
import { createLineClient } from "./client.mjs";

function reportType(value) {
  return String(value || "").split("~", 1)[0];
}

async function stillActive(id) {
  const data = await api("/api/dmx/bot/nhom", { body: { hanhDong: "kiem_tra_lich", id } });
  return data.conHieuLuc === true;
}

async function mark(id) {
  await api("/api/dmx/bot/nhom", { body: { hanhDong: "da_gui", id } });
}

const due = await api("/api/dmx/bot/nhom", { body: { hanhDong: "lich_den_han" } });
if (!Array.isArray(due.lich) || due.lich.length === 0) {
  console.log("NO_DUE_REPORTS");
  process.exit(0);
}

const { base, client } = await createLineClient();
const chats = await client.fetchJoinedChats();
const chatByMid = new Map(chats.map((chat) => [chat.mid.toLowerCase(), chat]));

for (const schedule of due.lich) {
  try {
    if (!await stillActive(schedule.id)) continue;
    const groupKey = String(schedule.line_group_id || "").toLowerCase();
    const chat = chatByMid.get(groupKey);
    if (!chat) throw new Error(`Tài khoản BOT chưa ở trong nhóm ${schedule.line_group_id}`);

    let success = true;
    for (const rawType of schedule.cac_noi_dung || []) {
      if (!await stillActive(schedule.id)) { success = false; break; }
      const type = reportType(rawType);
      const query = new URLSearchParams({ loai: String(rawType) });
      const report = await api(`/api/dmx/bot/bao-cao?${query}`, {
        method: "GET",
        headers: {
          "X-DMX-User-ID": String(schedule.nguoi_dung_id || ""),
          "X-DMX-Store-ID": String(schedule.sieu_thi_id || ""),
        },
      });

      if (schedule.kieu_gui === "text") {
        await chat.sendMessage(String(report.fullText || report.noiDung || report.text || "Báo cáo chưa có nội dung.").slice(0, 5000));
        continue;
      }

      const imageUrl = String(report.imageUrl || "");
      if (imageUrl) {
        const version = [report.reportType || type, report.date || "", report.updatedAt || "", report.updatedAt ? "" : imageUrl].join("|");
        const check = await api("/api/dmx/bot/nhom", { body: {
          hanhDong: "kiem_tra_anh_moi", lineGroupId: schedule.line_group_id,
          nguoiDungId: schedule.nguoi_dung_id, sieuThiId: schedule.sieu_thi_id,
          loai: type, phienBanAnh: version,
        } });
        if (check.canGui === false) continue;
        const imageResponse = await fetch(imageUrl);
        if (!imageResponse.ok) throw new Error(`Không tải được ảnh ${type}: HTTP ${imageResponse.status}`);
        await base.obs.uploadMediaByE2EE({
          data: await imageResponse.blob(), oType: "image", to: chat.mid, filename: `${type}.jpg`,
        });
        await api("/api/dmx/bot/nhom", { body: {
          hanhDong: "danh_dau_anh_da_gui", lineGroupId: schedule.line_group_id,
          nguoiDungId: schedule.nguoi_dung_id, sieuThiId: schedule.sieu_thi_id,
          loai: type, phienBanAnh: version,
        } });
      }
      const title = String(report.text || report.noiDung || "").trim();
      if (title) await chat.sendMessage(title.slice(0, 5000));
    }
    if (success) await mark(schedule.id);
    console.log(`SENT_SCHEDULE=${schedule.id}`);
  } catch (error) {
    console.error(`SCHEDULE_FAILED=${schedule.id}`, error);
    process.exitCode = 1;
  }
}
