export const API_BASE_URL = (import.meta.env.VITE_API_URL || "http://localhost:8000").replace(/\/$/, "");
const API = API_BASE_URL;

export function getAuthHeaders() {
  const token = localStorage.getItem("auth_token") ?? localStorage.getItem("token");
  return {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "true",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

function clearStoredSession() {
  localStorage.removeItem("auth_token");
  localStorage.removeItem("user_id");
  localStorage.removeItem("user_name");
  localStorage.removeItem("user_email");
  localStorage.removeItem("token");
  localStorage.removeItem("adminLoggedIn");
}

async function parseApiError(response, fallbackMessage) {
  const err = await response.json().catch(() => ({}));
  if (response.status === 401) {
    clearStoredSession();
    window.location.href = "/admin-login";
    throw new Error(err.detail || "Unauthorized");
  }
  throw new Error(err.detail || fallbackMessage);
}

export const adminLogin = async (username, password) => {
  const res = await fetch(`${API}/api/v1/auth/login`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify({ email: username, password }),
  });
  if (!res.ok) await parseApiError(res, "Login failed");
  return res.json();
};

export const registerUser = async (name, email, password) => {
  const res = await fetch(`${API}/api/v1/auth/register`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify({ name, email, password }),
  });
  if (!res.ok) await parseApiError(res, "Registration failed");
  return res.json();
};

export const getDashboardData = async () => {
  const res = await fetch(`${API}/dashboard`, { headers: getAuthHeaders() });
  if (!res.ok) await parseApiError(res, "Failed to fetch dashboard");
  return res.json();
};

async function getJson(path) {
  const res = await fetch(`${API}${path}`, { headers: getAuthHeaders() });
  if (!res.ok) await parseApiError(res, `Request failed for ${path} (${res.status})`);
  return res.json();
}

export const getUserDashboard = async () => getJson("/api/user/dashboard");

export async function getCompanyDashboard() {
  const r = await fetch(`${API}/api/v1/enterprise/company/dashboard`, { headers: getAuthHeaders() });
  if (!r.ok) await parseApiError(r, `Dashboard failed (${r.status})`);
  return r.json();
}

export async function getCompanyTeam() {
  const r = await fetch(`${API}/api/v1/enterprise/company/team`, { headers: getAuthHeaders() });
  if (!r.ok) await parseApiError(r, `Team failed (${r.status})`);
  return r.json();
}

export async function getCompanyActivity() {
  const r = await fetch(`${API}/api/v1/enterprise/company/activity`, { headers: getAuthHeaders() });
  if (!r.ok) await parseApiError(r, `Activity failed (${r.status})`);
  return r.json();
}

export async function registerCompany({ companyName, industry, plan = "starter" }) {
  const r = await fetch(`${API}/api/v1/enterprise/company/register`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify({ company_name: companyName, industry, plan }),
  });
  if (!r.ok) await parseApiError(r, `Registration failed (${r.status})`);
  return r.json();
}

export async function addCompanyMember({ targetEmail, role = "analyst" }) {
  const r = await fetch(`${API}/api/v1/enterprise/company/add-member`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify({ target_email: targetEmail, role }),
  });
  if (!r.ok) await parseApiError(r, `Add member failed (${r.status})`);
  return r.json();
}