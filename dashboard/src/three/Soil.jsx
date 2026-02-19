import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function Soil({ soilMoisture = 50 }) {
    const planeRef = useRef()
    const moisture = clamp01(soilMoisture / 100)
    const dryness = 1 - moisture

    const soilColor = useMemo(() => {
        const wet = new Color('#2b1a12')
        const dry = new Color('#a27345')
        return wet.clone().lerp(dry, dryness)
    }, [dryness])

    const emissive = useMemo(() => {
        const dim = new Color('#130b08')
        const glow = new Color('#3a1e10')
        return dim.clone().lerp(glow, dryness * 0.6)
    }, [dryness])

    useFrame(({ clock }) => {
        const t = clock.getElapsedTime()
        if (planeRef.current) {
            planeRef.current.rotation.z = Math.sin(t * 0.08) * 0.01
        }
    })

    return (
        <mesh ref={planeRef} rotation={[-Math.PI / 2, 0, 0]} receiveShadow castShadow>
            <planeGeometry args={[24, 24, 64, 64]} />
            <meshStandardMaterial
                color={soilColor}
                roughness={0.9 - moisture * 0.35}
                metalness={0.1 + moisture * 0.05}
                emissive={emissive}
                emissiveIntensity={0.25 + moisture * 0.25}
            />
        </mesh>
    )
}
