import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'
import { MeshDistortMaterial } from '@react-three/drei'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function Sun({ lightLevel = 40 }) {
    const coreRef = useRef()
    const normalized = clamp01(lightLevel / 100)

    const color = useMemo(() => {
        const dim = new Color('#1e90ff')
        const bright = new Color('#ffd27f')
        return dim.clone().lerp(bright, normalized)
    }, [normalized])

    const intensity = 0.35 + normalized * 2.4

    useFrame(({ clock }) => {
        const t = clock.getElapsedTime()
        if (coreRef.current) {
            coreRef.current.rotation.y = t * 0.3
            coreRef.current.rotation.x = Math.sin(t * 0.5) * 0.2
        }
    })

    return (
        <group position={[6, 7, -4]}>
            <pointLight intensity={intensity} distance={40} decay={2} color={color} castShadow />
            <mesh ref={coreRef}>
                <sphereGeometry args={[1.4, 64, 64]} />
                <MeshDistortMaterial
                    color={color}
                    emissive={color}
                    emissiveIntensity={1.6 + normalized}
                    roughness={0.2}
                    metalness={0.1}
                    speed={2.2}
                    distort={0.4}
                    transparent
                    opacity={0.85}
                />
            </mesh>
        </group>
    )
}
