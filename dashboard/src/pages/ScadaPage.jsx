import { Link } from "react-router-dom";
import useAgroSmartLiveData from "../three/useAgroSmartLiveData";

export default function ScadaPage() {
  const { data, raw } = useAgroSmartLiveData()

  const temperature = data?.temperature ?? data?.Temperature ?? raw?.Temperature ?? '--'
  const humidity = data?.humidity ?? data?.Humidity ?? raw?.Humidity ?? '--'
  const soilMoisture = data?.soilMoisture ?? data?.SoilMoisture ?? raw?.SoilMoisture ?? '--'
  const lightLevel = data?.lightLevel ?? data?.LightLevel ?? raw?.LightLevel ?? '--'
  const irrigationRaw = data?.irrigationStatus ?? data?.Irrigation ?? raw?.Irrigation
  const irrigation = irrigationRaw == null
    ? '--'
    : (irrigationRaw === true || irrigationRaw === 1 || irrigationRaw === '1' || irrigationRaw === 'on' || irrigationRaw === 'ON' ? 'ON' : 'OFF')
  const lastUpdate = raw?.__ts ? new Date(raw.__ts).toLocaleTimeString([], { hour12: false }) : '--:--:--'

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* Top bar */}
      <div className="border-b border-cyan-500/20 bg-slate-900/80 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div>
            <h1 className="text-2xl font-bold tracking-wide text-cyan-400">
              AgroSmart SCADA
            </h1>
            <p className="text-sm text-slate-400">
              Supervisory Control and Data Acquisition Interface
            </p>
          </div>

          <div className="flex items-center gap-3">
            <Link
              to="/dashboard"
              className="rounded-lg border border-slate-700 px-4 py-2 text-sm text-slate-300 transition hover:border-cyan-400 hover:text-cyan-300"
            >
              Dashboard
            </Link>
            <Link
              to="/twin"
              className="rounded-lg border border-slate-700 px-4 py-2 text-sm text-slate-300 transition hover:border-cyan-400 hover:text-cyan-300"
            >
              Digital Twin
            </Link>
          </div>
        </div>
      </div>

      {/* Main SCADA layout */}
      <div className="mx-auto max-w-7xl px-6 py-6">
        {/* System status row */}
        <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-4">
          <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-4 shadow-lg shadow-cyan-500/5">
            <p className="text-xs uppercase tracking-widest text-slate-400">System</p>
            <div className="mt-2 flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-green-400 animate-pulse" />
              <span className="text-lg font-semibold text-green-400">Online</span>
            </div>
          </div>

          <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-4 shadow-lg shadow-cyan-500/5">
            <p className="text-xs uppercase tracking-widest text-slate-400">Data Source</p>
            <p className="mt-2 text-lg font-semibold text-cyan-300">Firebase RTDB</p>
          </div>

          <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-4 shadow-lg shadow-cyan-500/5">
            <p className="text-xs uppercase tracking-widest text-slate-400">Mode</p>
            <p className="mt-2 text-lg font-semibold text-emerald-300">Live Monitoring</p>
          </div>

          <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-4 shadow-lg shadow-cyan-500/5">
            <p className="text-xs uppercase tracking-widest text-slate-400">Last Update</p>
            <p className="mt-2 text-lg font-semibold text-slate-200">{lastUpdate}</p>
          </div>
        </div>

        {/* Main grid */}
        <div className="grid grid-cols-1 gap-6 xl:grid-cols-12">
          {/* Left side */}
          <div className="space-y-6 xl:col-span-8">
            {/* Process overview */}
            <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-cyan-300">
                Process Overview
              </h2>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-5">
                {[
                  "Water Source",
                  "Pump Unit",
                  "Irrigation Line",
                  "Field Zone",
                  "Sensor Node",
                ].map((item) => (
                  <div
                    key={item}
                    className="rounded-xl border border-slate-700 bg-slate-950 p-4 text-center"
                  >
                    <div className="mb-2 mx-auto h-3 w-3 rounded-full bg-green-400" />
                    <p className="text-sm font-medium text-slate-200">{item}</p>
                    <p className="mt-1 text-xs text-slate-500">Active</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Sensor cards */}
            <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-cyan-300">
                Live Sensor Panels
              </h2>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                {[ 
                  { title: "Temperature", value: `${temperature ?? '--'} °C`, status: "Normal" },
                  { title: "Humidity", value: `${humidity ?? '--'} %`, status: "Normal" },
                  { title: "Soil Moisture", value: soilMoisture ?? '--', status: "Normal" },
                  { title: "Light Level", value: lightLevel ?? '--', status: "Normal" },
                  { title: "Irrigation", value: irrigation ?? '--', status: "Standby" },
                ].map((card) => (
                  <div
                    key={card.title}
                    className="rounded-xl border border-slate-700 bg-slate-950 p-4"
                  >
                    <p className="text-xs uppercase tracking-widest text-slate-400">
                      {card.title}
                    </p>
                    <p className="mt-3 text-2xl font-bold text-slate-100">
                      {card.value}
                    </p>
                    <div className="mt-3 inline-flex rounded-full border border-emerald-500/30 bg-emerald-500/10 px-3 py-1 text-xs text-emerald-300">
                      {card.status}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Trend charts placeholder */}
            <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-cyan-300">
                Trend Monitoring
              </h2>
              <div className="flex h-64 items-center justify-center rounded-xl border border-dashed border-slate-700 bg-slate-950 text-slate-500">
                Trend charts will be added here
              </div>
            </div>
          </div>

          {/* Right side */}
          <div className="space-y-6 xl:col-span-4">
            {/* Alarm panel */}
            <div className="rounded-2xl border border-red-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-red-300">
                Alarm Panel
              </h2>

              <div className="space-y-3">
                <div className="rounded-xl border border-slate-700 bg-slate-950 p-3 text-sm text-slate-400">
                  No active alarms
                </div>
              </div>
            </div>

            {/* Event log */}
            <div className="rounded-2xl border border-cyan-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-cyan-300">
                Event Log
              </h2>

              <div className="space-y-3 text-sm">
                <div className="rounded-xl border border-slate-700 bg-slate-950 p-3 text-slate-400">
                  Waiting for live events...
                </div>
              </div>
            </div>

            {/* Supervisory controls */}
            <div className="rounded-2xl border border-amber-500/20 bg-slate-900 p-5">
              <h2 className="mb-4 text-lg font-semibold text-amber-300">
                Supervisory Controls
              </h2>

              <div className="grid grid-cols-2 gap-3">
                <button className="rounded-xl border border-green-500/30 bg-green-500/10 px-4 py-3 text-sm font-medium text-green-300">
                  Pump ON
                </button>
                <button className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm font-medium text-red-300">
                  Pump OFF
                </button>
                <button className="rounded-xl border border-cyan-500/30 bg-cyan-500/10 px-4 py-3 text-sm font-medium text-cyan-300">
                  Auto Mode
                </button>
                <button className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm font-medium text-amber-300">
                  Reset Alarms
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}