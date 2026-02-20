import React, { useEffect, useMemo } from 'react'
import { Color } from 'three'
import { Canvas } from '@react-three/fiber'
import { ContactShadows, Environment, Float, Html, OrbitControls, Sparkles } from '@react-three/drei'
import { EffectComposer, Bloom, Noise, Vignette } from '@react-three/postprocessing'
import HoloBar from './HoloBar'
import HologramGrid from './HologramGrid'
import { cropIdeals } from '../data/cropIdeals'
import { extractKeyFeatures } from '../utils/reasonToFeature'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

function computeWetness(raw) {
    return 1 - clamp01((raw - 1369) / (2606 - 1369))
}

function computeBrightness(raw) {
    return 1 - clamp01((raw - 10) / (4095 - 10))
}

export default function SensorBarsScene({ data, raw, connected, tick, recommendation }) {
    const wetness = computeWetness(raw.soilMoisture)
    const brightness = computeBrightness(raw.lightLevel)
    const irrigationOn = !!raw.irrigationStatus

    const keyFeatures = useMemo(() => extractKeyFeatures(recommendation?.reasons || []), [recommendation?.reasons])
    const cropKey = (recommendation?.recommendedCrop || recommendation?.bestCrop || recommendation?.crop || '').toLowerCase()
    const ideal = cropIdeals[cropKey] || null

    const bars = useMemo(() => ([
        {
            key: 'temp',
            label: 'Temperature',
            valueText: `${Math.max(0, Math.min(50, raw.temperature ?? 0)).toFixed(1)} °C`,
            normalizedValue: clamp01((raw.temperature ?? 0) / 50),
            color: '#f97316',
            position: [-4, 0, 0],
            feature: 'temperature',
            idealValue: ideal?.temperature ?? null,
            rangeMin: 0,
            rangeMax: 50,
        },
        {
            key: 'humidity',
            label: 'Humidity',
            valueText: `${Math.max(0, Math.min(100, raw.humidity ?? 0)).toFixed(0)} %`,
            normalizedValue: clamp01((raw.humidity ?? 0) / 100),
            color: '#38bdf8',
            position: [-2, 0, 0],
            feature: 'humidity',
            idealValue: ideal?.humidity ?? null,
            rangeMin: 0,
            rangeMax: 100,
        },
        {
            key: 'soil',
            label: 'Soil Moisture',
            valueText: `${raw.soilMoisture ?? '--'} (${(wetness * 100).toFixed(0)}% wet)`,
            normalizedValue: wetness,
            color: '#22c55e',
            position: [0, 0, 0],
            feature: 'soilMoisture',
        },
        {
            key: 'light',
            label: 'Light Level',
            valueText: `${raw.lightLevel ?? '--'} (${(brightness * 100).toFixed(0)}% bright)`,
            normalizedValue: brightness,
            color: '#a5f3fc',
            position: [2, 0, 0],
            feature: 'lightLevel',
        },
        {
            key: 'irrigation',
            label: 'Irrigation',
            valueText: irrigationOn ? 'ON' : 'OFF',
            normalizedValue: irrigationOn ? 1 : 0.15,
            color: irrigationOn ? '#22d3ee' : '#ef4444',
            position: [4, 0, 0],
            feature: 'irrigation',
        },
    ]), [data.temperature, data.humidity, raw.soilMoisture, wetness, raw.lightLevel, brightness, irrigationOn, tick, ideal])

    useEffect(() => {
        // Trace incoming values to ensure the scene re-renders with new data each tick.
        console.log('[SensorBarsScene] tick', tick, {
            temp: raw?.temperature,
            humidity: raw?.humidity,
            soil: raw?.soilMoisture,
            light: raw?.lightLevel,
            irrigation: raw?.irrigationStatus,
            wetness,
            brightness,
        })
    }, [tick, raw?.temperature, raw?.humidity, raw?.soilMoisture, raw?.lightLevel, raw?.irrigationStatus, wetness, brightness])

    return (
        <Canvas
            shadows
            camera={{ position: [6, 4, 10], fov: 55 }}
            gl={{ antialias: true, powerPreference: 'high-performance' }}
        >
            <color attach="background" args={[new Color('#05070a')]} />
            <fog attach="fog" args={[new Color('#05070a'), 10, 28]} />

            <ambientLight intensity={0.4} color="#0ea5e9" />
            <directionalLight position={[6, 8, 6]} intensity={1.4} color="#e0f2fe" />
            <directionalLight position={[-6, 6, -4]} intensity={1.1} color="#22d3ee" />

            <HologramGrid />
            <ContactShadows position={[0, 0, 0]} opacity={0.35} scale={16} blur={2.6} far={8} resolution={1024} />

            <Float speed={0.6} rotationIntensity={0.08} floatIntensity={0.18}>
                {bars.map(({ key: barKey, feature, idealValue, rangeMin, rangeMax, ...rest }) => (
                    <HoloBar
                        key={`${barKey}-${tick}`}
                        tick={tick}
                        isKey={keyFeatures.includes(feature)}
                        idealValue={idealValue}
                        rangeMin={rangeMin}
                        rangeMax={rangeMax}
                        {...rest}
                    />
                ))}
            </Float>

            <Scanlines />
            <Sparkles count={120} speed={0.4} opacity={0.3} color="#67e8f9" size={2} scale={[14, 4, 14]} />
            <Environment preset="city" />
            <OrbitControls enablePan={false} enableZoom={false} autoRotate autoRotateSpeed={0.4} target={[0, 1.5, 0]} />

            <EffectComposer>
                <Bloom intensity={0.9} luminanceThreshold={0.2} luminanceSmoothing={0.4} radius={0.85} />
                <Noise premultiply opacity={0.06} />
                <Vignette eskil offset={0.2} darkness={0.92} />
            </EffectComposer>
        </Canvas>
    )
}

function Scanlines() {
    return (
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.04, 0]}>
            <planeGeometry args={[30, 30, 64, 64]} />
            <meshBasicMaterial color="#38bdf8" transparent opacity={0.08} wireframe />
        </mesh>
    )
}

export function SensorDebugOverlay({ connected, raw, wetness, brightness, tick, lastUpdated, normalized }) {
    return (
        <div className="absolute left-4 top-4 z-20 w-full max-w-sm rounded-2xl border border-white/10 bg-black/80 p-4 text-xs text-slate-100 shadow-lg backdrop-blur">
            <div className="flex items-center justify-between font-semibold">
                <span className="text-emerald-200">Sensor Test Debug</span>
                <span className={connected ? 'text-emerald-300' : 'text-amber-300'}>{connected ? 'Connected' : 'Disconnected'}</span>
            </div>
            <div className="mt-1 text-[11px] text-slate-400">tick: {tick} · lastUpdated: {lastUpdated || '—'}</div>
            <div className="mt-2 grid grid-cols-2 gap-2 text-[11px] text-slate-200">
                <div>Temp: <strong>{raw.temperature ?? '--'}</strong></div>
                <div>Humidity: <strong>{raw.humidity ?? '--'}</strong></div>
                <div>Soil raw: <strong>{raw.soilMoisture ?? '--'}</strong></div>
                <div>Light raw: <strong>{raw.lightLevel ?? '--'}</strong></div>
                <div>Irrigation: <strong>{raw.irrigationStatus ? 'ON' : 'OFF'}</strong></div>
                <div>Wetness: <strong>{wetness.toFixed(3)}</strong> (norm {normalized?.wetness?.toFixed?.(3) ?? '—'})</div>
                <div>Brightness: <strong>{brightness.toFixed(3)}</strong> (norm {normalized?.brightness?.toFixed?.(3) ?? '—'})</div>
            </div>
        </div>
    )
}
