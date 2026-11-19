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

async function sendText(chat, text) {
  try {
    return await chat.sendMessage(text);
  } catch (error) {
    if (error?.data?.code !== "E2EE_RETRY_PLAIN") throw error;
    await base.talk.sendMessage({ to: chat.mid, text, e2ee: false });
  }
}

async function acceptInvitations() {
  const all = await base.talk.getAllChatMids({
    request: { withMemberChats: true, withInvitedChats: true },
    syncReason: "INTERNAL",
  });
  for (const chatMid of all.invitedChatMids || []) {
    await base.talk.acceptChatInvitation({
      request: { reqSeq: await base.getReqseq(), chatMid },
    });
    console.log(`ACCEPTED_GROUP=${chatMid}`);
  }
}

const { base, client } = await createLineClient();
await acceptInvitations();
const chats = await client.fetchJoinedChats();

// Nhóm LINE cá nhân được gắn vào đúng tài khoản DMX bằng cùng lệnh mà app
// đang hướng dẫn. Vì mã dùng một lần, việc đọc lại tin cũ không thể gắn trùng.
for (const chat of chats) {
  try {
    const messages = await chat.fetchMessages(10);
    for (const message of messages) {
      if (message.isMyMessage) continue;
      const match = String(message.text || "").trim().match(/^\/gannhom\s+(\d{6})$/i);
      if (!match) continue;
      try {
        await api("/api/dmx/bot/nhom", { body: {
          hanhDong: "gan_nhom", ma: match[1], lineGroupId: chat.mid, tenNhom: chat.name,
        } });
        await sendText(chat, "✅ Đã gắn nhóm với ứng dụng DMX. Bây giờ có thể chọn nhóm này và lưu lịch gửi trong app.");
        console.log(`LINKED_GROUP=${chat.mid}`);
      } catch {
        // Mã đã dùng/hết hạn hoặc tin nhắn cũ: bỏ qua để không làm phiền nhóm.
      }
    }
  } catch (error) {
    console.error(`GROUP_SCAN_FAILED=${chat.mid}`, error);
  }
}

const due = await api("/api/dmx/bot/nhom", { body: { hanhDong: "lich_den_han" } });
if (!Array.isArray(due.lich) || due.lich.length === 0) {
  console.log("NO_DUE_REPORTS");
  process.exit(0);
}

const chatByMid = new Map(chats.map((chat) => [chat.mid.toLowerCase(), chat]));
const chatsByName = new Map();
for (const chat of chats) {
  const key = chat.name.trim().toLocaleLowerCase("vi-VN");
  chatsByName.set(key, [...(chatsByName.get(key) || []), chat]);
}

for (const schedule of due.lich) {
  try {
    if (!await stillActive(schedule.id)) continue;
    const groupKey = String(schedule.line_group_id || "").toLowerCase();
    let chat = chatByMid.get(groupKey);
    let savedGroupName = "";
    if (!chat) {
      const relation = Array.isArray(schedule.dmx_line_nhom)
        ? schedule.dmx_line_nhom[0]
        : schedule.dmx_line_nhom;
      savedGroupName = String(relation?.ten_nhom || "").trim();
      const matches = chatsByName.get(savedGroupName.toLocaleLowerCase("vi-VN")) || [];
      if (matches.length === 1) chat = matches[0];
    }
    if (!chat) throw new Error(`Tài khoản BOT chưa ở trong nhóm "${savedGroupName || schedule.line_group_id}"`);

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
        await sendText(chat, String(report.fullText || report.noiDung || report.text || "Báo cáo chưa có nội dung.").slice(0, 5000));
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
        if (!imageResponse.ok) {
          const fallback = String(report.fullText || report.noiDung || report.text || "").trim();
          if (!fallback) throw new Error(`Không tải được ảnh ${type}: HTTP ${imageResponse.status} (${imageUrl})`);
          await sendText(chat, `⚠️ Ảnh báo cáo không còn trên kho, gửi nội dung thay thế:\n\n${fallback}`.slice(0, 5000));
          continue;
        }
        const imageBlob = await imageResponse.blob();
        try {
          await base.obs.uploadMediaByE2EE({
            data: imageBlob, oType: "image", to: chat.mid, filename: `${type}.jpg`,
          });
        } catch (error) {
          if (error?.data?.code !== "E2EE_RETRY_PLAIN") throw error;
          await base.obs.uploadObjTalk(chat.mid, "image", imageBlob, undefined, `${type}.jpg`);
        }
        await api("/api/dmx/bot/nhom", { body: {
          hanhDong: "danh_dau_anh_da_gui", lineGroupId: schedule.line_group_id,
          nguoiDungId: schedule.nguoi_dung_id, sieuThiId: schedule.sieu_thi_id,
          loai: type, phienBanAnh: version,
        } });
      }
      const title = String(report.text || report.noiDung || "").trim();
      if (title) await sendText(chat, title.slice(0, 5000));
    }
    if (success) await mark(schedule.id);
    console.log(`SENT_SCHEDULE=${schedule.id}`);
  } catch (error) {
    console.error(`SCHEDULE_FAILED=${schedule.id}`, error);
  }
}

// Một số kết nối LINE giữ event loop mở sau khi đã gửi xong. Kết thúc tiến
// trình để systemd có thể chạy nhịp kế tiếp mà không bị kẹt ở trạng thái chạy.
process.exit(0);
