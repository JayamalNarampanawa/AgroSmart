import React, { useEffect, useMemo, useRef } from 'react'
import { Color, Vector3 } from 'three'
import { useFrame } from '@react-three/fiber'
import { Html } from '@react-three/drei'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function HoloBar({
    label,
    valueText,
    normalizedValue = 0,
    color = '#22d3ee',
    position = [0, 0, 0],
    unit = '',
    tick = 0,
    isKey = false,
    idealValue = null,
    rangeMin = 0,
    rangeMax = 1,
    status = null,
    severity = 'info',
    message = '',
    idealUnit = '',
}) {
    const barRef = useRef()
    const heightRef = useRef(clamp01(normalizedValue))
    const targetRef = useRef(clamp01(normalizedValue))
    const glowColor = useMemo(() => new Color(color), [color])
    const baseColor = useMemo(() => glowColor.clone().multiplyScalar(0.45), [glowColor])
    const idealNorm = useMemo(() => {
        if (idealValue == null || Number.isNaN(idealValue)) return null
        const denom = Math.max(rangeMax - rangeMin, 1e-6)
        return clamp01((idealValue - rangeMin) / denom)
    }, [idealValue, rangeMin, rangeMax])

    const badgeClass = useMemo(() => severityClasses[severity] || severityClasses.info, [severity])
    const showStatus = Boolean(status)

    useEffect(() => {
        targetRef.current = clamp01(normalizedValue)
    }, [normalizedValue, tick])

    useFrame((_, delta) => {
        const target = targetRef.current
        const lerpFactor = 1 - Math.pow(1 - 0.12, Math.min(delta * 60, 5))
        heightRef.current += (target - heightRef.current) * lerpFactor
        const h = 0.2 + heightRef.current * 3.0
        if (barRef.current) {
            barRef.current.scale.y = h
            barRef.current.position.y = h * 0.5 + 0.35
            barRef.current.material.emissiveIntensity = 0.6 + heightRef.current * 1.6
            barRef.current.material.opacity = 0.35 + heightRef.current * 0.4
        }
    })

    return (
        <group position={new Vector3(...position)}>
            <mesh position={[0, 0.1, 0]}>
                <cylinderGeometry args={[0.5, 0.6, 0.2, 32]} />
                <meshStandardMaterial color={'#0b1725'} metalness={0.35} roughness={0.8} emissive={isKey ? glowColor : new Color('#0b1725')} emissiveIntensity={isKey ? 0.4 : 0} />
            </mesh>

            <mesh ref={barRef} position={[0, 0.35, 0]}>
                <boxGeometry args={[0.6, 1, 0.6]} />
                <meshStandardMaterial
                    color={baseColor}
                    emissive={glowColor}
                    emissiveIntensity={0.9}
                    roughness={0.25}
                    metalness={0.25}
                    transparent
                    opacity={0.5}
                />
            </mesh>

            <mesh position={[0, 0.02, 0]}>
                <ringGeometry args={[0.8, 0.95, 48]} />
                <meshBasicMaterial color={color} opacity={isKey ? 0.5 : 0.22} transparent />
            </mesh>

            {idealNorm !== null && (
                <mesh position={[0, 0.35 + (0.2 + idealNorm * 3.0), 0]}>
                    <boxGeometry args={[0.9, 0.04, 0.9]} />
                    <meshBasicMaterial color="#fbbf24" transparent opacity={0.8} />
                </mesh>
            )}

            <Html key={`${label}-${tick}`} position={[0, 4.0, 0]} center distanceFactor={8} style={labelStyle}>
                <div className="text-center" style={{ fontSize: 'clamp(10px, 1.1vw, 14px)' }}>
                    <div className="font-semibold uppercase tracking-[0.2em] text-cyan-200/90" style={{ fontSize: 'clamp(9px, 0.95vw, 12px)' }}>{label}</div>
                    <div className="mt-1 font-bold text-white drop-shadow" aria-label={`${label} value`} style={{ fontSize: 'clamp(13px, 1.8vw, 18px)' }}>
                        {valueText}{unit && <span className="text-slate-300 ml-1" style={{ fontSize: 'clamp(10px, 1vw, 12px)' }}>{unit}</span>}
                    </div>
                    {isKey && <div className="mt-1 inline-block rounded-full border border-cyan-300/60 bg-cyan-300/15 px-2 py-0.5 uppercase tracking-wide text-cyan-100" style={{ fontSize: 'clamp(9px, 0.9vw, 11px)' }}>Key factor</div>}
                </div>
            </Html>

            {(showStatus || idealNorm !== null || message) && (
                <Html position={[0.95, 4.0, 0]} center distanceFactor={8} style={labelStyle}>
                    <div className="text-left space-y-1" style={{ maxWidth: 180, fontSize: 'clamp(6px, 0.6vw, 8px)', whiteSpace: 'normal' }}>
                        {showStatus && (
                            <div className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-semibold uppercase tracking-wide ${badgeClass}`} style={{ fontSize: 'clamp(6px, 0.6vw, 8px)' }}>
                                <span>{status}</span>
                            </div>
                        )}
                        {idealNorm !== null && (
                            <div className="text-amber-200" style={{ fontSize: 'clamp(6px, 0.6vw, 8px)' }}>
                                Ideal{idealValue !== null && idealValue !== undefined ? `: ${idealValue}${idealUnit ? ` ${idealUnit}` : ''}` : ''}
                            </div>
                        )}
                        {message && <div className="text-slate-200/90" style={{ fontSize: 'clamp(6px, 0.6vw, 8px)' }}>{message}</div>}
                    </div>
                </Html>
            )}
        </group>
    )
}

const labelStyle = {
    pointerEvents: 'none',
    color: '#e0f2fe',
    fontFamily: 'Inter, system-ui, sans-serif',
    textShadow: '0 0 12px rgba(56, 189, 248, 0.7)',
}

const severityClasses = {
    info: 'border-white/10 bg-black/60 text-slate-50',
    warn: 'border-yellow-400/30 bg-yellow-500/10 text-yellow-100',
    critical: 'border-red-400/30 bg-red-500/10 text-red-100',
}
