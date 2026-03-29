import { useEffect, useRef, useState } from "react"
import { Link } from "react-router-dom"
import {
    Area,
    AreaChart,
    CartesianGrid,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from "recharts"
import useSensorData from "../hooks/useSensorData"

export default function ScadaPage() {
    const { current } = useSensorData()

    const [events, setEvents] = useState([])
    const [trendSamples, setTrendSamples] = useState([])
    const [controlMode, setControlMode] = useState('AUTO')
    const [lastCommand, setLastCommand] = useState(null)
    const [alarmAckTs, setAlarmAckTs] = useState(null)
    const prevStateRef = useRef({
        pumpOn: null,
        soilDry: null,
        tempHigh: null,
        humidityLow: null,
        online: null,
        lastSampleTs: null,
    })

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

    const parseTs = (value) => {
        if (!value) return null
        const numTs = Number(value)
        if (Number.isFinite(numTs)) return numTs
        const parsed = new Date(value).getTime()
        return Number.isFinite(parsed) ? parsed : null
    }

    const eventTimestamp = () => {
        const rawTs = current?.raw?.__ts ?? current?.timestamp ?? Date.now()
        const ts = parseTs(rawTs)
        return ts ?? Date.now()
    }

    const pushTrendSample = () => {
        const ts = eventTimestamp()
        const prevTs = prevStateRef.current.lastSampleTs
        if (prevTs && ts === prevTs) return

        const sample = {
            ts,
            temperature: t,
            humidity: h,
            soilMoisture: s,
            lightLevel: l,
            irrigation: irrigation === 'ON' ? 1 : irrigation === 'OFF' ? 0 : null,
        }

        setTrendSamples((prev) => {
            const next = [...prev, sample].slice(-40)
            return next
        })

        prevStateRef.current.lastSampleTs = ts
    }

    const pushEvent = (title, message, severity) => {
        const ts = eventTimestamp()
        setEvents((prev) => {
            const next = [
                {
                    id: `${ts}-${title}-${Math.random().toString(36).slice(2, 6)}`,
                    title,
                    message,
                    severity,
                    timestamp: ts,
                },
                ...prev,
            ]
            return next.slice(0, 15)
        })
    }

    const alarms = []
    const t = toNum(temperature)
    const h = toNum(humidity)
    const s = toNum(soilMoisture)
    const l = toNum(lightLevel)
    const now = Date.now()

    const isOnline = (() => {
        const ts = parseTs(lastTs)
        return ts !== null ? now - ts <= 20000 : false
    })()

    if (t !== null && t > 35) alarms.push({ id: 'temp-high', title: 'High Temperature', message: 'Temperature above 35°C', value: `${t} °C`, severity: 'warning' })
    if (h !== null && h < 40) alarms.push({ id: 'humidity-low', title: 'Low Humidity', message: 'Humidity below 40%', value: `${h} %`, severity: 'warning' })
    if (s !== null && s > 2800) alarms.push({ id: 'soil-dry', title: 'Dry Soil', message: 'Soil moisture above 2800 (drier)', value: `${s}`, severity: 'critical' })
    if (l !== null && l < 800) alarms.push({ id: 'light-low', title: 'Low Light', message: 'Light level below 800', value: `${l}`, severity: 'warning' })
    if (irrigation === 'ON') alarms.push({ id: 'pump-on', title: 'Pump Active', message: 'Irrigation pump is ON', value: irrigation, severity: 'info' })
    if (!isOnline) alarms.push({ id: 'data-offline', title: 'Data Offline', message: 'No updates in the last 20s', value: lastUpdate, severity: 'critical' })

    useEffect(() => {
        const ts = eventTimestamp()
        const pumpOn = current?.pumpStatus === true
        const soilDry = s !== null ? s > 2800 : null
        const tempHigh = t !== null ? t > 35 : null
        const humidityLow = h !== null ? h < 40 : null
        const prev = prevStateRef.current

        pushTrendSample()

        if (prev.online !== null && prev.online !== isOnline) {
            pushEvent(
                isOnline ? 'Live data restored' : 'Data connection lost',
                isOnline ? 'Telemetry is updating again' : 'No updates received recently',
                isOnline ? 'success' : 'critical'
            )
        }

        if (prev.pumpOn !== null && prev.pumpOn !== pumpOn && pumpOn !== null) {
            pushEvent(
                pumpOn ? 'Pump turned ON' : 'Pump turned OFF',
                pumpOn ? 'Irrigation pump activated' : 'Irrigation pump deactivated',
                'info'
            )
        }

        if (prev.soilDry !== null && prev.soilDry !== soilDry && soilDry !== null) {
            pushEvent(
                soilDry ? 'Dry soil detected' : 'Soil moisture back to normal',
                soilDry ? 'Soil moisture is above safe range' : 'Soil moisture returned within range',
                soilDry ? 'critical' : 'success'
            )
        }

        if (prev.tempHigh !== null && prev.tempHigh !== tempHigh && tempHigh !== null) {
            pushEvent(
                tempHigh ? 'High temperature detected' : 'Temperature back to normal',
                tempHigh ? 'Temperature crossed safe limit' : 'Temperature returned within range',
                tempHigh ? 'warning' : 'success'
            )
        }

        if (prev.humidityLow !== null && prev.humidityLow !== humidityLow && humidityLow !== null) {
            pushEvent(
                humidityLow ? 'Low humidity detected' : 'Humidity back to normal',
                humidityLow ? 'Humidity dropped below safe range' : 'Humidity recovered to safe range',
                humidityLow ? 'warning' : 'success'
            )
        }

        prevStateRef.current = {
            pumpOn,
            soilDry,
            tempHigh,
            humidityLow,
            online: isOnline,
            ts,
            lastSampleTs: prevStateRef.current.lastSampleTs,
        }
    }, [current, h, isOnline, s, t])

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

    const eventTone = (severity) => {
        switch (severity) {
            case 'critical': return 'border-red-500/40 bg-red-500/10 text-red-100'
            case 'warning': return 'border-amber-500/40 bg-amber-500/10 text-amber-100'
            case 'info': return 'border-cyan-500/40 bg-cyan-500/10 text-cyan-100'
            case 'success': return 'border-emerald-500/40 bg-emerald-500/10 text-emerald-100'
            default: return 'border-slate-700 bg-slate-950 text-slate-200'
        }
    }

    const formatEventTime = (ts) => {
        const n = Number(ts)
        if (!Number.isFinite(n)) return '--:--:--'
        return new Date(n).toLocaleTimeString([], { hour12: false })
    }

    const formatTrendTime = (ts) => {
        const n = Number(ts)
        if (!Number.isFinite(n)) return ''
        return new Date(n).toLocaleTimeString([], { hour12: false, minute: '2-digit', second: '2-digit' })
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

    const processTone = (severity) => {
        switch (severity) {
            case 'critical': return 'border-red-500/50 bg-red-500/5 shadow-red-500/10'
            case 'warning': return 'border-amber-500/50 bg-amber-500/5 shadow-amber-500/10'
            case 'active': return 'border-cyan-500/60 bg-cyan-500/5 shadow-cyan-500/15'
            case 'normal': return 'border-emerald-500/40 bg-emerald-500/5 shadow-emerald-500/10'
            case 'standby': return 'border-slate-600 bg-slate-950 shadow-slate-900/40'
            default: return 'border-slate-700 bg-slate-950'
        }
    }

    const processNodes = () => {
        const pumpOn = current?.pumpStatus === true
        const soilDry = s !== null ? s > 2800 : null
        const warningConditions = (
            (t !== null && t > 35) ||
            (h !== null && h < 40) ||
            (s !== null && s > 2800)
        )

        return [
            {
                key: 'water',
                title: 'Water Source',
                status: isOnline ? 'Online' : 'Offline',
                severity: isOnline ? 'normal' : 'critical',
                note: isOnline ? 'Data link good' : 'No recent telemetry',
                pulse: isOnline,
            },
            {
                key: 'pump',
                title: 'Pump Unit',
                status: pumpOn ? 'Active' : pumpOn === false ? 'Idle' : 'Idle',
                severity: pumpOn ? 'active' : 'standby',
                note: pumpOn ? 'Irrigation ON' : 'Standing by',
                pulse: pumpOn,
            },
            {
                key: 'line',
                title: 'Irrigation Line',
                status: pumpOn ? 'Flowing' : 'Standby',
                severity: pumpOn ? 'active' : 'standby',
                note: pumpOn ? 'Flow in progress' : 'Awaiting demand',
                pulse: pumpOn,
            },
            {
                key: 'field',
                title: 'Field Zone',
                status: soilDry === true ? 'Dry' : 'Normal',
                severity: soilDry === true ? 'critical' : 'normal',
                note: soilDry === true ? 'Soil moisture high (dry)' : 'Within range',
                pulse: soilDry === true,
            },
            {
                key: 'sensor',
                title: 'Sensor Node',
                status: !isOnline ? 'Offline' : warningConditions ? 'Warning' : 'Healthy',
                severity: !isOnline ? 'critical' : warningConditions ? 'warning' : 'normal',
                note: !isOnline ? 'Awaiting data' : warningConditions ? 'Check thresholds' : 'Operating normally',
                pulse: isOnline && !warningConditions,
            },
        ]
    }

    const modeTone = controlMode === 'AUTO'
        ? 'border-cyan-500/50 bg-cyan-500/10 text-cyan-100'
        : 'border-amber-500/50 bg-amber-500/10 text-amber-100'

    const handleModeToggle = () => {
        const next = controlMode === 'AUTO' ? 'MANUAL' : 'AUTO'
        setControlMode(next)
        pushEvent(
            `Control mode switched to ${next}`,
            'Supervisory control updated',
            'info'
        )
    }

    const handlePumpOn = () => {
        if (controlMode !== 'MANUAL') return
        setLastCommand('Pump ON')
        pushEvent('Manual pump ON command issued', 'Operator command (local UI)', 'info')
    }

    const handlePumpOff = () => {
        if (controlMode !== 'MANUAL') return
        setLastCommand('Pump OFF')
        pushEvent('Manual pump OFF command issued', 'Operator command (local UI)', 'info')
    }

    const handleResetAlarms = () => {
        const ts = Date.now()
        setAlarmAckTs(ts)
        pushEvent('Alarms acknowledged/reset', 'Pending alarms will reappear if conditions persist', 'info')
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
                            <div className="relative">
                                <div className="pointer-events-none absolute inset-x-4 top-7 hidden h-px bg-gradient-to-r from-cyan-500/10 via-slate-700/60 to-cyan-500/10 md:block" />
                                <div className="grid grid-cols-1 gap-4 md:grid-cols-5">
                                    {processNodes().map((node) => {
                                        const tone = processTone(node.severity)
                                        const dotTone = node.severity === 'critical'
                                            ? 'bg-red-400'
                                            : node.severity === 'warning'
                                                ? 'bg-amber-400'
                                                : node.severity === 'active'
                                                    ? 'bg-cyan-400'
                                                    : node.severity === 'normal'
                                                        ? 'bg-emerald-400'
                                                        : 'bg-slate-400'
                                        return (
                                            <div
                                                key={node.key}
                                                className={`relative overflow-hidden rounded-xl border p-4 text-center ${tone}`}
                                            >
                                                {node.pulse && (
                                                    <div className="pointer-events-none absolute inset-0 animate-pulse bg-cyan-400/5" />
                                                )}
                                                <div className="relative space-y-2">
                                                    <div className={`mx-auto h-3 w-3 rounded-full ${dotTone}`} />
                                                    <p className="text-sm font-semibold text-slate-100">{node.title}</p>
                                                    <div className="inline-flex items-center justify-center rounded-full border border-white/10 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-slate-100">
                                                        {node.status}
                                                    </div>
                                                    <p className="text-xs text-slate-400">{node.note}</p>
                                                </div>
                                            </div>
                                        )
                                    })}
                                </div>
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
                            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                                {[
                                    { key: 'temperature', title: 'Temperature (°C)', dataKey: 'temperature', stroke: '#22d3ee', fill: '#22d3ee22' },
                                    { key: 'humidity', title: 'Humidity (%)', dataKey: 'humidity', stroke: '#a3e635', fill: '#a3e63522' },
                                    { key: 'soil', title: 'Soil Moisture', dataKey: 'soilMoisture', stroke: '#f43f5e', fill: '#f43f5e22' },
                                    { key: 'light', title: 'Light Level', dataKey: 'lightLevel', stroke: '#fb923c', fill: '#fb923c22' },
                                    { key: 'irrigation', title: 'Irrigation Activity', dataKey: 'irrigation', stroke: '#38bdf8', fill: '#38bdf822', yDomain: [0, 1], step: true },
                                ].map((chart) => (
                                    <div key={chart.key} className="rounded-xl border border-slate-700 bg-slate-950 p-3 shadow-inner shadow-cyan-500/5">
                                        <div className="mb-2 text-sm font-semibold text-slate-100 flex items-center justify-between">
                                            <span>{chart.title}</span>
                                            <span className="text-[11px] text-slate-500">Last {Math.min(trendSamples.length, 40)} samples</span>
                                        </div>
                                        <div className="h-40">
                                            <ResponsiveContainer width="100%" height="100%">
                                                <AreaChart data={trendSamples} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                                                    <defs>
                                                        <linearGradient id={`grad-${chart.key}`} x1="0" y1="0" x2="0" y2="1">
                                                            <stop offset="5%" stopColor={chart.stroke} stopOpacity={0.35} />
                                                            <stop offset="95%" stopColor={chart.stroke} stopOpacity={0} />
                                                        </linearGradient>
                                                    </defs>
                                                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.6} />
                                                    <XAxis dataKey="ts" tickFormatter={formatTrendTime} stroke="#64748b" tickLine={false} axisLine={false} minTickGap={20} style={{ fontSize: '11px' }} />
                                                    <YAxis stroke="#64748b" tickLine={false} axisLine={false} width={chart.yDomain ? 28 : 36} domain={chart.yDomain || ['auto', 'auto']} style={{ fontSize: '11px' }} />
                                                    <Tooltip
                                                        contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', color: '#e2e8f0', fontSize: '12px' }}
                                                        labelFormatter={(v) => formatTrendTime(v)}
                                                        formatter={(value) => [value ?? '--', chart.title]}
                                                    />
                                                    <Area
                                                        type={chart.step ? 'stepAfter' : 'monotone'}
                                                        dataKey={chart.dataKey}
                                                        stroke={chart.stroke}
                                                        fill={`url(#grad-${chart.key})`}
                                                        strokeWidth={2}
                                                        connectNulls
                                                        isAnimationActive={false}
                                                    />
                                                </AreaChart>
                                            </ResponsiveContainer>
                                        </div>
                                    </div>
                                ))}
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
                                {events.length === 0 ? (
                                    <div className="rounded-xl border border-slate-700 bg-slate-950 p-3 text-slate-400">
                                        Waiting for live events...
                                    </div>
                                ) : (
                                    events.map((event) => {
                                        const tone = eventTone(event.severity)
                                        return (
                                            <div key={event.id} className={`rounded-xl border p-3 ${tone}`}>
                                                <div className="flex items-start justify-between gap-3">
                                                    <div>
                                                        <div className="text-xs uppercase tracking-wide opacity-80">{event.title}</div>
                                                        <div className="text-slate-100">{event.message}</div>
                                                    </div>
                                                    <div className="text-[11px] font-mono text-slate-300">
                                                        {formatEventTime(event.timestamp)}
                                                    </div>
                                                </div>
                                                <div className="mt-2 inline-flex rounded-full border border-white/10 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wide">
                                                    {event.severity}
                                                </div>
                                            </div>
                                        )
                                    })
                                )}
                            </div>
                        </div>

                        {/* Supervisory controls */}
                        <div className="rounded-2xl border border-amber-500/20 bg-slate-900 p-5">
                            <h2 className="mb-4 text-lg font-semibold text-amber-300">
                                Supervisory Controls
                            </h2>

                            <div className="mb-3 flex flex-wrap items-center gap-3 text-xs text-slate-400">
                                <div className={`rounded-full border px-3 py-1 font-semibold uppercase tracking-wide ${modeTone}`}>
                                    Mode: {controlMode}
                                </div>
                                <div className="rounded-full border border-slate-700 px-3 py-1 text-[11px] text-slate-300">
                                    Last command: {lastCommand ?? 'None'}
                                </div>
                                {alarmAckTs && (
                                    <div className="rounded-full border border-slate-700 px-3 py-1 text-[11px] text-slate-300">
                                        Alarms acknowledged at {formatEventTime(alarmAckTs)}
                                    </div>
                                )}
                            </div>

                            <div className="grid grid-cols-2 gap-3">
                                <button
                                    onClick={handlePumpOn}
                                    disabled={controlMode !== 'MANUAL'}
                                    className={`rounded-xl border px-4 py-3 text-sm font-medium transition ${controlMode === 'MANUAL' ? 'border-green-500/40 bg-green-500/10 text-green-200 hover:border-green-400/70' : 'border-slate-700 bg-slate-800 text-slate-500 cursor-not-allowed opacity-50'}`}
                                >
                                    Pump ON
                                </button>
                                <button
                                    onClick={handlePumpOff}
                                    disabled={controlMode !== 'MANUAL'}
                                    className={`rounded-xl border px-4 py-3 text-sm font-medium transition ${controlMode === 'MANUAL' ? 'border-red-500/40 bg-red-500/10 text-red-200 hover:border-red-400/70' : 'border-slate-700 bg-slate-800 text-slate-500 cursor-not-allowed opacity-50'}`}
                                >
                                    Pump OFF
                                </button>
                                <button
                                    onClick={handleModeToggle}
                                    className={`rounded-xl border px-4 py-3 text-sm font-medium transition ${controlMode === 'AUTO' ? 'border-cyan-500/50 bg-cyan-500/10 text-cyan-200 hover:border-cyan-400/70' : 'border-amber-500/50 bg-amber-500/10 text-amber-200 hover:border-amber-400/70'}`}
                                >
                                    {controlMode === 'AUTO' ? 'Switch to MANUAL' : 'Switch to AUTO'}
                                </button>
                                <button
                                    onClick={handleResetAlarms}
                                    className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm font-medium text-amber-300 hover:border-amber-400/60"
                                >
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
