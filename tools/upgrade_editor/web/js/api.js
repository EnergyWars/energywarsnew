const HEADERS = { "Content-Type": "application/json", "X-Upgrade-Editor": "1" };

async function request(path, options = {}) {
  const response = await fetch(path, { ...options, credentials: "omit", cache: "no-store" });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw Object.assign(new Error(body.error || "ERROR"), { errors: body.errors || [], status: response.status });
  return body;
}

const post = (path, body) => request(path, { method: "POST", headers: HEADERS, body: JSON.stringify(body) });

export const api = {
  document: () => request("/api/document"),
  save: (document) => request("/api/document", { method: "PUT", headers: HEADERS, body: JSON.stringify({ document }) }),
  validate: (document) => post("/api/validate", { document }),
  reset: () => post("/api/reset", {}),
};
