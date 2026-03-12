const ACTION_META = {
  'User Login':          { icon: '🔐', color: 'badge-info',   label: 'Auth' },
  'Document Uploaded':   { icon: '📄', color: 'badge-medium', label: 'Storage' },
  'AI Query':            { icon: '🤖', color: 'badge-high',   label: 'AI' },
  'Generated Summary':   { icon: '✨', color: 'badge-low',    label: 'AI Output' },
};

const DEFAULT_META = { icon: '⚡', color: 'badge-info', label: 'Event' };

function timeAgo(index) {
  const offsets = ['just now', '2 min ago', '5 min ago', '11 min ago', '18 min ago', '30 min ago'];
  return offsets[index % offsets.length];
}

export default function LogCard({ log, index }) {
  const meta = ACTION_META[log.action] ?? DEFAULT_META;

  return (
    <div
      className={`fade-up stagger-${Math.min(index + 1, 5)} flex items-center gap-4 px-5 py-4 border-b last:border-0 hover:bg-white/[0.015] transition-colors duration-150`}
      style={{ borderColor: 'var(--dark-500)' }}
    >
      {/* Icon bubble */}
      <div
        className="w-9 h-9 rounded-lg flex items-center justify-center text-base flex-shrink-0"
        style={{ background: 'var(--dark-600)' }}
      >
        {meta.icon}
      </div>

      {/* Text */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-200 truncate">{log.action}</p>
        <p className="text-xs text-gray-500 mt-0.5">{timeAgo(index)}</p>
      </div>

      {/* Badge */}
      <span className={meta.color}>{meta.label}</span>
    </div>
  );
}