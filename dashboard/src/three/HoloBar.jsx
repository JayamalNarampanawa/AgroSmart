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
}) {
    const barRef = useRef()
    const heightRef = useRef(clamp01(normalizedValue))
    const targetRef = useRef(clamp01(normalizedValue))
    const glowColor = useMemo(() => new Color(color), [color])
    const baseColor = useMemo(() => glowColor.clone().multiplyScalar(0.45), [glowColor])

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
                <meshStandardMaterial color={'#0b1725'} metalness={0.35} roughness={0.8} />
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
                <meshBasicMaterial color={color} opacity={0.22} transparent />
            </mesh>

            <Html key={`${label}-${tick}`} position={[0, 4.0, 0]} center distanceFactor={8} style={labelStyle}>
                <div className="text-center">
                    <div className="text-[11px] font-semibold uppercase tracking-[0.2em] text-cyan-200/90">{label}</div>
                    <div className="mt-1 text-lg font-bold text-white drop-shadow" aria-label={`${label} value`}>
                        {valueText}{unit && <span className="text-slate-300 text-xs ml-1">{unit}</span>}
                    </div>
                </div>
            </Html>
        </group>
    )
}

const labelStyle = {
    pointerEvents: 'none',
    color: '#e0f2fe',
    fontFamily: 'Inter, system-ui, sans-serif',
    textShadow: '0 0 12px rgba(56, 189, 248, 0.7)',
}
