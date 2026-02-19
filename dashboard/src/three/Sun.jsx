import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'
import { MeshDistortMaterial } from '@react-three/drei'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function Sun({ lightLevel = 40 }) {
    const coreRef = useRef()
    const lightRef = useRef()
    const matRef = useRef()
    const dim = useMemo(() => new Color('#1e90ff'), [])
    const bright = useMemo(() => new Color('#ffd27f'), [])
    const colorRef = useRef(dim.clone())
    const normRef = useRef(clamp01(lightLevel / 100))

    useFrame(({ clock }, delta) => {
        const t = clock.getElapsedTime()
        if (coreRef.current) {
            coreRef.current.rotation.y = t * 0.3
            coreRef.current.rotation.x = Math.sin(t * 0.5) * 0.2
        }

        const targetNorm = clamp01(lightLevel / 100)
        normRef.current += (targetNorm - normRef.current) * 0.06
        colorRef.current.lerpColors(dim, bright, normRef.current)

        if (lightRef.current) {
            const targetIntensity = 0.35 + normRef.current * 2.4
            lightRef.current.intensity += (targetIntensity - lightRef.current.intensity) * 0.08
            lightRef.current.color.copy(colorRef.current)
        }
        if (matRef.current) {
            const targetEmissive = 1.6 + normRef.current
            matRef.current.emissive.copy(colorRef.current)
            matRef.current.color.copy(colorRef.current)
            matRef.current.emissiveIntensity += (targetEmissive - matRef.current.emissiveIntensity) * 0.08
        }
    })

    return (
        <group position={[6, 7, -4]}>
            <pointLight ref={lightRef} intensity={0.35 + normRef.current * 2.4} distance={40} decay={2} color={colorRef.current} castShadow />
            <mesh ref={coreRef}>
                <sphereGeometry args={[1.4, 64, 64]} />
                <MeshDistortMaterial
                    ref={matRef}
                    color={colorRef.current}
                    emissive={colorRef.current}
                    emissiveIntensity={1.6 + normRef.current}
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
