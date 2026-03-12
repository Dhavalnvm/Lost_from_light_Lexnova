import { useNavigate } from 'react-router-dom';
import { clearAuth } from "../services/auth";

export default function Navbar({ username }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    clearAuth();
    navigate('/');
  };

  return (
    <header
      className="h-16 flex items-center justify-between px-6 border-b"
      style={{ background: 'var(--dark-800)', borderColor: 'var(--dark-500)' }}
    >
      {/* Brand */}
      <div className="flex items-center gap-3">
        <div
          className="w-7 h-7 rounded-md flex items-center justify-center text-xs font-bold"
          style={{ background: 'linear-gradient(135deg, #c9a96e, #e2c47a)', color: '#0d0d0f' }}
        >
          L
        </div>
        <span className="font-display text-lg font-semibold text-gradient">LexNova</span>
        <span
          className="text-xs px-2 py-0.5 rounded-full ml-1"
          style={{ background: 'rgba(201,169,110,0.1)', color: 'var(--gold-400)', border: '1px solid rgba(201,169,110,0.2)' }}
        >
          Admin
        </span>
      </div>

      {/* Right */}
      <div className="flex items-center gap-4">
        {username && (
          <div className="flex items-center gap-2">
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-semibold"
              style={{ background: 'rgba(201,169,110,0.15)', color: 'var(--gold-400)', border: '1px solid rgba(201,169,110,0.2)' }}
            >
              {username[0]?.toUpperCase()}
            </div>
            <span className="text-sm text-gray-400 hidden sm:block">{username}</span>
          </div>
        )}
        <button onClick={handleLogout} className="btn-outline text-xs px-3 py-1.5">
          Sign out
        </button>
      </div>
    </header>
  );
}
