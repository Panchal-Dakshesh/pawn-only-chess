async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    ...options,
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(body.error || `Request failed (${response.status})`);
    error.status = response.status;
    throw error;
  }
  return body;
}

export const createGame = (userColor) =>
  request("/api/games", { method: "POST", body: JSON.stringify({ user_color: userColor }) });

export const fetchGame = (id) => request(`/api/games/${id}`);

export const postMove = (id, from, to) =>
  request(`/api/games/${id}/moves`, { method: "POST", body: JSON.stringify({ from, to }) });

export const restartGame = (id) => request(`/api/games/${id}/restart`, { method: "POST" });
