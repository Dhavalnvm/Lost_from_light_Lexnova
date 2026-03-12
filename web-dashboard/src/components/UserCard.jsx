export default function UserCard({ label, value, icon }) {
  return (
    <div className="bg-white shadow-md rounded-xl p-5 flex items-center justify-between border hover:shadow-lg transition">

      <div>
        <p className="text-sm text-gray-500">{label}</p>

        <h2 className="text-2xl font-bold text-gray-800">
          {value}
        </h2>
      </div>

      <div className="text-3xl">
        {icon}
      </div>

    </div>
  );
}