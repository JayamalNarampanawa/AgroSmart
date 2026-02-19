import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

const lerp = (a, b, t) => a + (b - a) * t

export default function Soil({ soilMoisture = 50 }) {
    const planeRef = useRef()
    const matRef = useRef()
    const moistureRef = useRef(clamp01(soilMoisture / 100))
    const wetColor = useMemo(() => new Color('#1E140B'), [])
    const dryColor = useMemo(() => new Color('#6B4F2A'), [])
    const dimColor = useMemo(() => new Color('#120a06'), [])
    const glowColor = useMemo(() => new Color('#3a1e10'), [])
    const colorRef = useRef(wetColor.clone())
    const emissiveRef = useRef(dimColor.clone())
    const highlightRef = useRef()

    useFrame(({ clock }, delta) => {
        const t = clock.getElapsedTime()
        if (planeRef.current) {
            planeRef.current.rotation.z = Math.sin(t * 0.08) * 0.01
        }

        const targetMoisture = clamp01(soilMoisture / 100)
        moistureRef.current += (targetMoisture - moistureRef.current) * 0.06
        const wetness = moistureRef.current
        const dryness = 1 - wetness

        const curve = Math.pow(wetness, 1.6)
        colorRef.current.lerpColors(dryColor, wetColor, curve)
        emissiveRef.current.lerpColors(dimColor, glowColor, dryness * 0.6)

        if (matRef.current) {
            matRef.current.color.copy(colorRef.current)
            const targetRough = lerp(0.95, 0.25, wetness)
            const targetMetal = lerp(0.0, 0.15, wetness)
            const targetEmissive = 0.18 + wetness * 0.35
            matRef.current.roughness += (targetRough - matRef.current.roughness) * 0.1
            matRef.current.metalness += (targetMetal - matRef.current.metalness) * 0.1
            matRef.current.emissive.copy(emissiveRef.current)
            matRef.current.emissiveIntensity += (targetEmissive - matRef.current.emissiveIntensity) * 0.1
        }

        if (highlightRef.current) {
            const targetOpacity = clamp01((wetness - 0.55) / 0.45)
            highlightRef.current.material.opacity += (targetOpacity - highlightRef.current.material.opacity) * 0.08
            highlightRef.current.visible = highlightRef.current.material.opacity > 0.02
        }
    })

    return (
        <mesh ref={planeRef} rotation={[-Math.PI / 2, 0, 0]} receiveShadow castShadow>
            <planeGeometry args={[24, 24, 64, 64]} />
            <meshStandardMaterial
                ref={matRef}
                color={colorRef.current}
                roughness={lerp(0.95, 0.25, moistureRef.current)}
                metalness={lerp(0.0, 0.15, moistureRef.current)}
                emissive={emissiveRef.current}
                emissiveIntensity={0.18 + moistureRef.current * 0.35}
            />
            <mesh ref={highlightRef} rotation={[0, 0, 0]} position={[0, 0.01, 0]} visible={false}>
                <circleGeometry args={[6.5, 64]} />
                <meshBasicMaterial color="#73eaff" transparent opacity={0} depthWrite={false} />
            </mesh>
        </mesh>
    )
}
