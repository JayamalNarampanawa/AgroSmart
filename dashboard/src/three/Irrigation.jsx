import React, { useMemo, useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Color } from 'three'

const PARTICLES = 120

export default function Irrigation({ active = false }) {
    const pointsRef = useRef()
    const pumpMatRef = useRef()
    const pointsMatRef = useRef()
    const glowRef = useRef()
    const alphaRef = useRef(active ? 0.9 : 0)
    const speeds = useRef(new Float32Array(PARTICLES).map(() => 0.9 + Math.random() * 1.2))

    const positions = useMemo(() => {
        const arr = new Float32Array(PARTICLES * 3)
        for (let i = 0; i < PARTICLES; i++) {
            arr[i * 3] = (Math.random() - 0.5) * 2.2
            arr[i * 3 + 1] = Math.random() * 1.6 + 0.4
            arr[i * 3 + 2] = (Math.random() - 0.5) * 2.2
        }
        return arr
    }, [])

    const resetParticle = (arr, idx) => {
        arr[idx * 3] = (Math.random() - 0.5) * 2.2
        arr[idx * 3 + 1] = 1.6 + Math.random() * 0.8
        arr[idx * 3 + 2] = (Math.random() - 0.5) * 2.2
    }

    useFrame((state, delta) => {
        const targetAlpha = active ? 0.85 : 0
        alphaRef.current += (targetAlpha - alphaRef.current) * 0.1

        if (pointsMatRef.current) {
            pointsMatRef.current.opacity = alphaRef.current
            pointsMatRef.current.visible = alphaRef.current > 0.02
        }
        if (pumpMatRef.current) {
            const targetEmissive = active ? 0.8 : 0.15
            pumpMatRef.current.emissiveIntensity += (targetEmissive - pumpMatRef.current.emissiveIntensity) * 0.12
            pumpMatRef.current.color.lerpColors(new Color('#1f2937'), new Color('#59d6ff'), alphaRef.current)
            pumpMatRef.current.emissive.lerpColors(new Color('#111827'), new Color('#0ca7ff'), alphaRef.current)
        }

        if (glowRef.current) {
            const glowAlpha = active ? 0.35 : 0
            glowRef.current.material.opacity += (glowAlpha - glowRef.current.material.opacity) * 0.08
            glowRef.current.material.emissiveIntensity = 0.5 + alphaRef.current * 0.4
            glowRef.current.rotation.z += delta * 0.2
            glowRef.current.visible = glowRef.current.material.opacity > 0.02
        }

        if (!pointsRef.current || alphaRef.current < 0.02) return
        const arr = pointsRef.current.geometry.attributes.position.array
        for (let i = 0; i < PARTICLES; i++) {
            arr[i * 3 + 1] -= speeds.current[i] * delta * 2.4
            if (arr[i * 3 + 1] < 0) {
                resetParticle(arr, i)
            }
        }
        pointsRef.current.geometry.attributes.position.needsUpdate = true
        pointsRef.current.rotation.y += delta * 0.35
    })

    return (
        <group position={[0, 0.1, -1]}>
            <mesh position={[0, 0.1, 0]} scale={[1.4, 0.2, 1.4]}>
                <cylinderGeometry args={[0.1, 0.1, 0.2, 16]} />
                <meshStandardMaterial ref={pumpMatRef} color={active ? '#59d6ff' : '#1f2937'} emissive={active ? '#0ca7ff' : '#111827'} emissiveIntensity={active ? 0.8 : 0.15} roughness={0.4} metalness={0.2} />
            </mesh>
            <mesh ref={glowRef} rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.02, 0]} visible={false}>
                <ringGeometry args={[1.2, 2.8, 64]} />
                <meshStandardMaterial color="#67e8f9" emissive="#4fd1c5" transparent opacity={0} depthWrite={false} />
            </mesh>
            <points ref={pointsRef}>
                <bufferGeometry>
                    <bufferAttribute attach="attributes-position" count={positions.length / 3} array={positions} itemSize={3} />
                </bufferGeometry>
                <pointsMaterial ref={pointsMatRef} size={0.08} color={new Color('#8ddcff')} transparent opacity={alphaRef.current} depthWrite={false} />
            </points>
        </group>
    )
}
