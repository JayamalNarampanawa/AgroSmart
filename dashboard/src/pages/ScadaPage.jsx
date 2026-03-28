import { Link } from "react-router-dom"
import useSensorData from "../hooks/useSensorData"

export default function ScadaPage() {
    const { current } = useSensorData()

    const toNum = (v) => {
        const n = Number(v)
        return Number.isFinite(n) ? n : null
    }

    // Prefer raw (unsmoothed) from live hook; fall back to smoothed
    const temperature = current?.temperature ?? '--'
    const humidity = current?.humidity ?? '--'
    const soilMoisture = current?.soilMoisture ?? '--'
    const lightLevel = current?.lightLevel ?? '--'
    const irrigation = current?.pumpStatus === true ? 'ON' : current?.pumpStatus === false ? 'OFF' : '--'
    const lastTs = current?.timestamp
    const lastUpdate = lastTs ? new Date(lastTs).toLocaleTimeString([], { hour12: false }) : '--:--:--'

    const alarms = []
    const t = toNum(temperature)
    const h = toNum(humidity)
    const s = toNum(soilMoisture)
    const l = toNum(lightLevel)
    const now = Date.now()

    if (t !== null && t > 35) alarms.push({ id: 'temp-high', title: 'High Temperature', message: 'Temperature above 35°C', value: `${t} °C`, severity: 'warning' })
    if (h !== null && h < 40) alarms.push({ id: 'humidity-low', title: 'Low Humidity', message: 'Humidity below 40%', value: `${h} %`, severity: 'warning' })
    if (s !== null && s > 2800) alarms.push({ id: 'soil-dry', title: 'Dry Soil', message: 'Soil moisture above 2800 (drier)', value: `${s}`, severity: 'critical' })
    if (l !== null && l < 800) alarms.push({ id: 'light-low', title: 'Low Light', message: 'Light level below 800', value: `${l}`, severity: 'warning' })
    if (irrigation === 'ON') alarms.push({ id: 'pump-on', title: 'Pump Active', message: 'Irrigation pump is ON', value: irrigation, severity: 'info' })
    if (lastTs && now - lastTs > 20000) alarms.push({ id: 'data-offline', title: 'Data Offline', message: 'No updates in the last 20s', value: lastUpdate, severity: 'critical' })

    const badgeFor = (severity) => {
        switch (severity) {
            case 'critical': return 'border-red-400/50 bg-red-500/10 text-red-200'
            case 'warning': return 'border-amber-400/50 bg-amber-500/10 text-amber-100'
            case 'info': return 'border-cyan-400/50 bg-cyan-500/10 text-cyan-100'
            case 'active': return 'border-cyan-400/60 bg-cyan-500/15 text-cyan-100'
            case 'standby': return 'border-slate-500/60 bg-slate-800 text-slate-200'
            default: return 'border-emerald-400/40 bg-emerald-500/10 text-emerald-100'
        }
    }

    const statusForSensor = {
        temperature: () => {
            const n = toNum(temperature)
            if (n !== null && n > 35) return { label: 'Warning', severity: 'warning' }
            return { label: 'Normal', severity: 'normal' }
        },
        humidity: () => {
            const n = toNum(humidity)
            if (n !== null && n < 40) return { label: 'Warning', severity: 'warning' }
            return { label: 'Normal', severity: 'normal' }
        },
        soil: () => {
            const n = toNum(soilMoisture)
            if (n !== null && n > 2800) return { label: 'Critical', severity: 'critical' }
            return { label: 'Normal', severity: 'normal' }
        },
        light: () => {
            const n = toNum(lightLevel)
            if (n !== null && n < 800) return { label: 'Warning', severity: 'warning' }
            return { label: 'Normal', severity: 'normal' }
        },
        irrigation: () => {
            if (irrigation === 'ON') return { label: 'Active', severity: 'active' }
            if (irrigation === 'OFF') return { label: 'Standby', severity: 'standby' }
            return { label: 'Standby', severity: 'standby' }
        },
    }

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
                                {["Water Source", "Pump Unit", "Irrigation Line", "Field Zone", "Sensor Node"].map((item) => (
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
                                    { key: 'temperature', title: "Temperature", value: `${temperature ?? '--'} °C`, getStatus: statusForSensor.temperature },
                                    { key: 'humidity', title: "Humidity", value: `${humidity ?? '--'} %`, getStatus: statusForSensor.humidity },
                                    { key: 'soil', title: "Soil Moisture", value: soilMoisture ?? '--', getStatus: statusForSensor.soil },
                                    { key: 'light', title: "Light Level", value: lightLevel ?? '--', getStatus: statusForSensor.light },
                                    { key: 'irrigation', title: "Irrigation", value: irrigation ?? '--', getStatus: statusForSensor.irrigation },
                                ].map((card) => {
                                    const status = card.getStatus ? card.getStatus() : { label: card.status, severity: 'normal' }
                                    const badgeTone = badgeFor(status.severity)
                                    const cardTone = status.severity === 'critical'
                                        ? 'border-red-400/30 shadow-red-500/10'
                                        : status.severity === 'warning'
                                            ? 'border-amber-400/30 shadow-amber-500/10'
                                            : status.severity === 'active'
                                                ? 'border-cyan-400/30 shadow-cyan-500/10'
                                                : status.severity === 'standby'
                                                    ? 'border-slate-600 shadow-slate-800/40'
                                                    : 'border-slate-700'
                                    return (
                                        <div
                                            key={card.key}
                                            className={`rounded-xl border bg-slate-950 p-4 ${cardTone}`}
                                        >
                                            <p className="text-xs uppercase tracking-widest text-slate-400">
                                                {card.title}
                                            </p>
                                            <p className="mt-3 text-2xl font-bold text-slate-100">
                                                {card.value}
                                            </p>
                                            <div className={`mt-3 inline-flex rounded-full border px-3 py-1 text-xs font-semibold ${badgeTone}`}>
                                                {status.label}
                                            </div>
                                        </div>
                                    )
                                })}
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
                                {alarms.length === 0 ? (
                                    <div className="rounded-xl border border-slate-700 bg-slate-950 p-3 text-sm text-slate-400">
                                        No active alarms
                                    </div>
                                ) : (
                                    alarms.map((alarm) => {
                                        const tone = alarm.severity === 'critical'
                                            ? 'border-red-400/50 bg-red-500/10 text-red-200'
                                            : alarm.severity === 'warning'
                                                ? 'border-amber-400/50 bg-amber-500/10 text-amber-100'
                                                : 'border-cyan-400/50 bg-cyan-500/10 text-cyan-100'
                                        return (
                                            <div key={alarm.id} className={`rounded-xl border p-3 text-sm ${tone}`}>
                                                <div className="flex items-center justify-between">
                                                    <div>
                                                        <div className="text-xs uppercase tracking-wide opacity-80">{alarm.title}</div>
                                                        <div className="font-semibold text-slate-50">{alarm.message}</div>
                                                    </div>
                                                    <div className="rounded-full border border-white/20 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide">
                                                        {alarm.severity}
                                                    </div>
                                                </div>
                                                {alarm.value && (
                                                    <div className="mt-1 text-xs text-slate-200/80">Value: {alarm.value}</div>
                                                )}
                                            </div>
                                        )
                                    })
                                )}
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
    )
}
