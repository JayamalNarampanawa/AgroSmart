import React, { useMemo, useRef } from 'react'
import { Color } from 'three'
import { useFrame } from '@react-three/fiber'
import { MeshDistortMaterial } from '@react-three/drei'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function Sun({ lightLevel = 40 }) {
    const coreRef = useRef()
    const pointRef = useRef()
    const dirRef = useRef()
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
        normRef.current += (targetNorm - normRef.current) * 0.08
        colorRef.current.lerpColors(dim, bright, normRef.current)

        if (pointRef.current) {
            const targetIntensity = normRef.current * 3.0
            pointRef.current.intensity += (targetIntensity - pointRef.current.intensity) * 0.12
            pointRef.current.color.copy(colorRef.current)
        }
        if (dirRef.current) {
            const targetDir = 0.4 + normRef.current * 2.5
            dirRef.current.intensity += (targetDir - dirRef.current.intensity) * 0.12
            dirRef.current.color.copy(colorRef.current)
        }
        if (matRef.current) {
            const targetEmissive = 0.3 + normRef.current * 4.0
            matRef.current.emissive.copy(colorRef.current)
            matRef.current.color.copy(colorRef.current)
            matRef.current.emissiveIntensity += (targetEmissive - matRef.current.emissiveIntensity) * 0.12
        }
    })

    return (
        <group position={[6, 7, -4]}>
            <directionalLight ref={dirRef} position={[6, 9, -6]} intensity={0.4 + normRef.current * 2.5} color={colorRef.current} castShadow />
            <pointLight ref={pointRef} intensity={normRef.current * 3.0} distance={26} decay={2} color={colorRef.current} />
            <mesh ref={coreRef}>
                <sphereGeometry args={[1.4, 64, 64]} />
                <MeshDistortMaterial
                    ref={matRef}
                    color={colorRef.current}
                    emissive={colorRef.current}
                    emissiveIntensity={0.3 + normRef.current * 4.0}
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
