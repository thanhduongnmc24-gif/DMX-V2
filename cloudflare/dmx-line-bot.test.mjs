import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
const source = await readFile(new URL("./dmx-line-bot.js", import.meta.url), "utf8");
const { default: worker } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);

const userId = "11111111-1111-4111-8111-111111111111";
const storeId = "22222222-2222-4222-8222-222222222222";
const scheduleId = "33333333-3333-4333-8333-333333333333";
const imageKey = `bot-anh/${userId}/${storeId}/luyke_du_kien-1234.jpg`;
const imageUrl = `https://dmx-line-bot.example/r2/img/${imageKey}`;

async function runSchedule({ originalSize, previewSize = 0, missingData = false }) {
  const pushes = [];
  let scheduleUpdates = 0;
  const oldFetch = globalThis.fetch;
  const oldError = console.error;
  console.error = () => {};
  const groupId = `C${"1".repeat(32)}`;
  globalThis.fetch = async (input, options = {}) => {
    const url = new URL(input);
    if (url.hostname === "api.line.me") {
      pushes.push(JSON.parse(options.body));
      return Response.json({});
    }
    const table = url.pathname.split("/rest/v1/")[1];
    if (table === "dmx_line_lich_gui") {
      if (options.method === "PATCH") { scheduleUpdates++; return Response.json({}); }
      return Response.json(url.searchParams.has("id") ? {
        id: scheduleId, line_group_id: groupId, nguoi_dung_id: userId,
      } : [{
        id: scheduleId, line_group_id: groupId,
        nguoi_dung_id: userId, sieu_thi_id: storeId,
        gio: "00:00:00", cac_noi_dung: ["luyke_du_kien"], kieu_gui: "anh", lan_gui_cuoi: null,
      }]);
    }
    if (table === "dmx_line_anh_bao_cao") {
      if (url.searchParams.has("xoa_sau") || url.searchParams.has("order")) return Response.json([]);
      return Response.json({
        ngay: "2026-11-25", nha_cung_cap: "google_drive", url_ben_ngoai: imageUrl,
        ngay_cap_nhat: "2026-11-25T10:00:00Z",
      });
    }
    if (table === "dmx_du_lieu_ngay") return Response.json(missingData ? [] : [{
      ngay: "2026-11-25", du_lieu: { doanhThu: {}, doanhThuRealtime: {} },
    }]);
    if (table === "dmx_sieu_thi") return Response.json({ id: storeId, cai_dat: {} });
    if (table === "dmx_line_nhom") return Response.json({ line_group_id: groupId });
    if (table === "dmx_line_anh_da_gui") return new Response("tracking unavailable", { status: 500 });
    return Response.json([]);
  };
  const env = {
    LINE_CHANNEL_ACCESS_TOKEN: "test-token", SUPABASE_SERVICE_ROLE_KEY: "test-key",
    ENABLE_BOT_SCHEDULED_REPORTS: "true",
    R2_IMAGES: {
      head: async key => key === imageKey ? { size: originalSize }
        : key === imageKey.replace(/\.jpg$/, "-preview.jpg") && previewSize ? { size: previewSize } : null,
    },
  };
  try {
    const tasks = [];
    await worker.scheduled({}, env, { waitUntil: promise => tasks.push(promise) });
    await Promise.all(tasks);
    return { pushes, scheduleUpdates };
  } finally {
    globalThis.fetch = oldFetch;
    console.error = oldError;
  }
}

test("legacy R2 image above LINE preview limit sends a report link", async () => {
  const result = await runSchedule({ originalSize: 2_500_000 });
  assert.equal(result.pushes.length, 1);
  assert.equal(result.pushes[0].messages.length, 1);
  assert.equal(result.pushes[0].messages[0].type, "text");
  assert.match(result.pushes[0].messages[0].text, /Xem ảnh đầy đủ:/);
  assert.equal(result.scheduleUpdates, 1);
});

test("R2 preview sends the full image even when tracking table fails", async () => {
  const result = await runSchedule({ originalSize: 2_500_000, previewSize: 500_000 });
  assert.equal(result.pushes.length, 1);
  assert.equal(result.pushes[0].messages[0].type, "image");
  assert.equal(result.pushes[0].messages[0].originalContentUrl, imageUrl);
  assert.match(result.pushes[0].messages[0].previewImageUrl, /-preview\.jpg$/);
  assert.equal(result.scheduleUpdates, 1);
});

test("missing report data stays pending instead of marking the schedule sent", async () => {
  const result = await runSchedule({ originalSize: 500_000, missingData: true });
  assert.equal(result.pushes.length, 0);
  assert.equal(result.scheduleUpdates, 0);
});

test("upload splits original and LINE preview into separate R2 objects", async () => {
  const stored = new Map();
  const oldFetch = globalThis.fetch;
  globalThis.fetch = async (input, options = {}) => {
    const url = new URL(input);
    if (url.pathname === "/auth/v1/user") return Response.json({ id: userId });
    if (url.pathname.endsWith("/dmx_line_anh_bao_cao")) {
      return Response.json(options.method === "POST" ? {} : null);
    }
    throw new Error(`Unexpected request: ${url.pathname}`);
  };
  try {
    const original = new Uint8Array([0xff, 0xd8, 1, 2, 0xff, 0xd9]);
    const preview = new Uint8Array([0xff, 0xd8, 3, 0xff, 0xd9]);
    const body = new Uint8Array([...original, ...preview]);
    const request = new Request(
      `https://dmx-line-bot.example/r2/upload?loai=luyke_du_kien&ngay=2026-11-25&sid=${storeId}`,
      { method: "POST", body, headers: {
        Authorization: "Bearer token", "X-DMX-Original-Length": String(original.length),
      } },
    );
    const result = await worker.fetch(request, {
      SUPABASE_SERVICE_ROLE_KEY: "test-key",
      R2_IMAGES: {
        put: async (key, bytes) => stored.set(key, Uint8Array.from(bytes)),
        delete: async key => stored.delete(key),
      },
    }, {});
    assert.equal(result.status, 200);
    const response = await result.json();
    assert.deepEqual(stored.get(response.key), original);
    assert.deepEqual(stored.get(response.key.replace(/\.jpg$/, "-preview.jpg")), preview);
    assert.match(response.previewUrl, /-preview\.jpg$/);
  } finally {
    globalThis.fetch = oldFetch;
  }
});
