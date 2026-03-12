import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { isLoggedIn } from "../services/auth.js";

export default function ProtectedRoute({ children }) {
  const navigate = useNavigate();

  useEffect(() => {
    if (!isLoggedIn()) navigate("/admin-login", { replace: true });
  }, [navigate]);

  if (!isLoggedIn()) return null;
  return children;
}