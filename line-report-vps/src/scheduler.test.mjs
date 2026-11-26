import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

test("scheduled custom text is sent unchanged without loading report data", async () => {
  const folder = await mkdtemp(join(tmpdir(), "dmx-text-schedule-"));
  try {
    const source = await readFile(join(dirname(fileURLToPath(import.meta.url)), "scheduler.mjs"), "utf8");
    await writeFile(join(folder, "scheduler.mjs"), source);
    await writeFile(join(folder, "api.mjs"), `
      import { appendFileSync } from "node:fs";
      let marked = 0;
      process.on("exit", () => appendFileSync(process.env.DMX_TEST_OUT, JSON.stringify({ marked }) + "\\n"));
      export async function sbRest(path, options = {}) {
        if (path === "dmx_line_lich_gui" && options.method === "PATCH") { marked++; return null; }
        if (path === "dmx_line_lich_gui" && options.single) return { id: "schedule-1" };
        if (path === "dmx_line_lich_gui") return [{
          id: "schedule-1", line_group_id: "c-test", nguoi_dung_id: "user-1", sieu_thi_id: "store-1",
          gio: "00:00", lan_gui_cuoi: null, kieu_gui: "text",
          cac_noi_dung: ["dmx_text_v1:" + process.env.DMX_TEST_TEXT],
          dmx_line_nhom: { ten_nhom: "Test" }
        }];
        throw new Error("Unexpected report data request: " + path);
      }
      export async function sbStorageSign() { throw new Error("Storage should not be used"); }
    `);
    await writeFile(join(folder, "client.mjs"), `
      import { appendFileSync } from "node:fs";
      const sent = [];
      process.on("exit", () => appendFileSync(process.env.DMX_TEST_OUT, JSON.stringify({ sent }) + "\\n"));
      export async function createLineClient() {
        const chat = { mid: "c-test", name: "Test", fetchMessages: async () => [] };
        return {
          base: { talk: {
            getAllChatMids: async () => ({ invitedChatMids: [] }),
            sendMessage: async input => { sent.push(input); return {}; }
          } },
          client: { fetchJoinedChats: async () => [chat] }
        };
      }
    `);
    const output = join(folder, "result.jsonl");
    const message = "Báo cáo sáng ~ 275QT\nHẹn gặp lúc 09:30 🟢";
    const run = spawnSync(process.execPath, [join(folder, "scheduler.mjs")], {
      encoding: "utf8",
      env: { ...process.env, DMX_TEST_TEXT: message, DMX_TEST_OUT: output },
      timeout: 10_000,
    });
    assert.equal(run.status, 0, run.stderr);
    assert.match(run.stdout, /SENT_SCHEDULE=schedule-1/);
    const events = (await readFile(output, "utf8")).trim().split("\n").map(JSON.parse);
    assert.deepEqual(events.find(event => event.sent)?.sent, [{ to: "c-test", text: message, e2ee: true }]);
    assert.equal(events.find(event => "marked" in event)?.marked, 1);
  } finally {
    if (dirname(folder) === tmpdir()) await rm(folder, { recursive: true, force: true });
  }
});
