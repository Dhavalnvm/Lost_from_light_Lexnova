const TOKEN_KEY     = "auth_token";
const USER_ID_KEY   = "user_id";
const USER_NAME_KEY = "user_name";
const USER_EMAIL_KEY = "user_email";

export function saveAuth(auth) {
  const token  = auth?.token ?? auth?.access_token ?? "";
  const userId = auth?.userId ?? auth?.user_id ?? "";
  const name   = auth?.name ?? auth?.user?.name ?? "";
  const email  = auth?.email ?? auth?.user?.email ?? "";

  if (!token) throw new Error("Authentication response did not include a token.");

  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_ID_KEY, userId);
  localStorage.setItem(USER_NAME_KEY, name);
  localStorage.setItem(USER_EMAIL_KEY, email);
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY) ?? "";
}

export function getCurrentUser() {
  const token = getToken();
  if (!token) return null;
  return {
    userId: localStorage.getItem(USER_ID_KEY) ?? "",
    name:   localStorage.getItem(USER_NAME_KEY) ?? "",
    email:  localStorage.getItem(USER_EMAIL_KEY) ?? "",
  };
}

export function isLoggedIn() {
  return Boolean(getToken());
}

export function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_ID_KEY);
  localStorage.removeItem(USER_NAME_KEY);
  localStorage.removeItem(USER_EMAIL_KEY);
  localStorage.removeItem("token");
  localStorage.removeItem("adminLoggedIn");
}