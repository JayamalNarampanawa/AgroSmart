import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function Soil({ soilMoisture = 50 }) {
    const planeRef = useRef()
    const matRef = useRef()
    const moistureRef = useRef(clamp01(soilMoisture / 100))
    const wetColor = useMemo(() => new Color('#2b1a12'), [])
    const dryColor = useMemo(() => new Color('#a27345'), [])
    const dimColor = useMemo(() => new Color('#130b08'), [])
    const glowColor = useMemo(() => new Color('#3a1e10'), [])
    const colorRef = useRef(wetColor.clone())
    const emissiveRef = useRef(dimColor.clone())

    useFrame(({ clock }, delta) => {
        const t = clock.getElapsedTime()
        if (planeRef.current) {
            planeRef.current.rotation.z = Math.sin(t * 0.08) * 0.01
        }

        const targetMoisture = clamp01(soilMoisture / 100)
        moistureRef.current += (targetMoisture - moistureRef.current) * 0.05
        const dryness = 1 - moistureRef.current

        colorRef.current.lerpColors(wetColor, dryColor, dryness)
        emissiveRef.current.lerpColors(dimColor, glowColor, dryness * 0.6)

        if (matRef.current) {
            matRef.current.color.copy(colorRef.current)
            const targetRough = 0.9 - moistureRef.current * 0.35
            const targetMetal = 0.1 + moistureRef.current * 0.05
            const targetEmissive = 0.25 + moistureRef.current * 0.25
            matRef.current.roughness += (targetRough - matRef.current.roughness) * 0.08
            matRef.current.metalness += (targetMetal - matRef.current.metalness) * 0.08
            matRef.current.emissive.copy(emissiveRef.current)
            matRef.current.emissiveIntensity += (targetEmissive - matRef.current.emissiveIntensity) * 0.08
        }
    })

    return (
        <mesh ref={planeRef} rotation={[-Math.PI / 2, 0, 0]} receiveShadow castShadow>
            <planeGeometry args={[24, 24, 64, 64]} />
            <meshStandardMaterial
                ref={matRef}
                color={colorRef.current}
                roughness={0.9 - moistureRef.current * 0.35}
                metalness={0.1 + moistureRef.current * 0.05}
                emissive={emissiveRef.current}
                emissiveIntensity={0.25 + moistureRef.current * 0.25}
            />
        </mesh>
    )
}
