import { readFile } from "node:fs/promises";
import { sign } from "node:crypto";

const baseUrl = process.env.DMX_API_BASE_URL ?? "https://www.duongnt.io.vn";
const keyPath = process.env.DMX_SIGNING_KEY ?? "/var/lib/dmx-line-report/keys/request-signing.pem";
let privateKey;

async function signedHeaders(url, method, extra = {}) {
  privateKey ??= await readFile(keyPath);
  const timestamp = String(Date.now());
  const parsed = new URL(url);
  const payload = `${timestamp}\n${method.toUpperCase()}\n${parsed.pathname}${parsed.search}`;
  const signature = sign(null, Buffer.from(payload), privateKey).toString("base64");
  return {
    Accept: "application/json",
    "Content-Type": "application/json",
    "X-DMX-VPS-Timestamp": timestamp,
    "X-DMX-VPS-Signature": signature,
    ...extra,
  };
}

export async function api(path, { method = "POST", body, headers = {} } = {}) {
  const url = new URL(path, baseUrl).toString();
  const response = await fetch(url, {
    method,
    headers: await signedHeaders(url, method, headers),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.loi || `DMX API HTTP ${response.status}`);
  return data;
}
