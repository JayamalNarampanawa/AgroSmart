import React, { useEffect, useMemo, useRef } from 'react'
import { Color, DoubleSide } from 'three'
import { useFrame } from '@react-three/fiber'
import { Environment, Float, Sparkles, Stars } from '@react-three/drei'
import { EffectComposer, Bloom, Vignette, Noise } from '@react-three/postprocessing'
import Soil from './Soil'
import Sun from './Sun'
import Irrigation from './Irrigation'
import CinematicCamera from './CinematicCamera'
import HologramGrid from './HologramGrid'
import { calibration } from './calibration'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function FarmScene({ data = {}, normalized = {}, irrigationOn = false, tick = 0 }) {
    const {
        temperature = 24,
        humidity = 60,
        soilMoisture = 50,
        lightLevel = 40,
        irrigationStatus = false
    } = data

    const soilNorm = normalized?.soil ?? clamp01((soilMoisture - calibration.soil.min) / (calibration.soil.max - calibration.soil.min))
    const lightNorm = normalized?.light ?? clamp01((lightLevel - calibration.light.min) / (calibration.light.max - calibration.light.min))

    const tempFactor = clamp01((temperature - 10) / 24)
    const humidityFactor = clamp01(humidity / 100)
    const lightFactor = Math.max(0.1, lightNorm)
    const irrigationActive = irrigationOn || irrigationStatus === 1 || irrigationStatus === true || String(irrigationStatus).toLowerCase() === 'on'

    const targetBackground = useMemo(() => new Color('#03060d').lerp(new Color('#0e1728'), humidityFactor * 0.5), [humidityFactor])
    const targetFog = useMemo(() => new Color('#05070c').lerp(new Color('#0b1422'), 0.5 + humidityFactor * 0.3), [humidityFactor])
    const targetAmbient = useMemo(() => new Color('#0f3450').lerp(new Color('#543322'), tempFactor), [tempFactor])

    const ambientRef = useRef()
    const hemiRef = useRef()
    const cubeMatRef = useRef()
    const bloomRef = useRef()
    const pulseRef = useRef(0)
    const bgRef = useRef(targetBackground.clone())
    const fogRef = useRef(targetFog.clone())
    const ambientColorRef = useRef(targetAmbient.clone())

    useEffect(() => { pulseRef.current = 1 }, [tick])

    useFrame((state, delta) => {
        const lerpColor = (from, to, alpha) => from.lerp(to, alpha)

        // smooth background & fog tint
        lerpColor(bgRef.current, targetBackground, 0.05)
        lerpColor(fogRef.current, targetFog, 0.05)
        if (state.scene.background) state.scene.background.copy(bgRef.current)
        if (state.scene.fog) state.scene.fog.color.copy(fogRef.current)

        // smooth ambient tint/intensity
        ambientColorRef.current.lerp(targetAmbient, 0.08)
        const targetHemiIntensity = 0.35 + lightFactor * 0.15
        const targetAmbientIntensity = 0.45 + lightFactor * 0.35
        if (hemiRef.current) {
            hemiRef.current.color.copy(ambientColorRef.current)
            hemiRef.current.intensity += (targetHemiIntensity - hemiRef.current.intensity) * 0.08
        }
        if (ambientRef.current) {
            ambientRef.current.color.copy(ambientColorRef.current)
            ambientRef.current.intensity += (targetAmbientIntensity - ambientRef.current.intensity) * 0.08
        }

        // decay pulse and apply to emissive and bloom
        pulseRef.current = Math.max(0, pulseRef.current - delta * 1.2)
        if (cubeMatRef.current) {
            const base = 0.35 + tempFactor * 0.5
            const targetEmissive = base + pulseRef.current * 0.5
            cubeMatRef.current.emissiveIntensity += (targetEmissive - cubeMatRef.current.emissiveIntensity) * 0.12
        }
        if (bloomRef.current) {
            const baseBloom = 0.95
            const targetBloom = baseBloom + pulseRef.current * 0.3
            bloomRef.current.intensity += (targetBloom - bloomRef.current.intensity) * 0.18
        }
    })

    return (
        <>
            <CinematicCamera focus={[0, 1.1, 0]} radius={7.2} height={3.1} sway={0.55} speed={0.18} tick={tick} />

            <color attach="background" args={[targetBackground]} />
            <fog attach="fog" args={[targetFog, 6, 18]} />

            <hemisphereLight ref={hemiRef} args={[targetAmbient, new Color('#050505'), 0.35 + lightFactor * 0.15]} />
            <ambientLight ref={ambientRef} intensity={0.45 + lightFactor * 0.35} color={targetAmbient} />
            <Sun lightLevel={lightNorm * 100} />

            <HologramGrid />

            <Float speed={1.1} rotationIntensity={0.16} floatIntensity={0.32}>
                <group position={[0, 0.05, 0]}>
                    <Soil soilMoisture={soilNorm * 100} />


                    <mesh position={[0, 0.8, 0]} scale={[3.6, 1.4, 3.6]}>
                        <boxGeometry args={[1, 1, 1]} />
                        <meshStandardMaterial
                            ref={cubeMatRef}
                            color="#1b2433"
                            metalness={0.45}
                            roughness={0.18}
                            transparent
                            opacity={0.52}
                            emissive="#3ab8ff"
                            emissiveIntensity={0.35 + tempFactor * 0.5}
                        />
                    </mesh>

                    <mesh position={[0, 0.02, 0]}>
                        <ringGeometry args={[5, 5.1, 64]} />
                        <meshBasicMaterial color="#2dd4ff" opacity={0.32} transparent />
                    </mesh>

                    <Scanlines />
                    <Irrigation active={irrigationActive} />
                </group>
            </Float>

            <LightBeams count={5} />
            <Sparkles count={140} speed={0.65} opacity={0.55} color="#67e8f9" size={2.8} scale={[16, 6, 16]} />
            <Stars radius={60} depth={20} count={1600} factor={3} fade />
            <Environment preset="city" />

            <EffectComposer>
                <Bloom ref={bloomRef} intensity={0.95} luminanceThreshold={0.2} luminanceSmoothing={0.4} radius={0.9} />
                <Noise premultiply opacity={0.06} />
                <Vignette eskil offset={0.18} darkness={0.92} />
            </EffectComposer>
        </>
    )
}

function Scanlines() {
    const planeRef = useRef()
    useFrame(({ clock }) => {
        if (!planeRef.current) return
        const t = clock.getElapsedTime()
        planeRef.current.position.y = 0.06 + Math.sin(t * 0.7) * 0.01
        planeRef.current.material.opacity = 0.08 + (Math.sin(t * 1.1) + 1) * 0.05
    })
    return (
        <mesh ref={planeRef} rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.06, 0]}>
            <planeGeometry args={[20, 20, 64, 64]} />
            <meshBasicMaterial color="#38bdf8" transparent opacity={0.12} wireframe />
        </mesh>
    )
}

function LightBeams({ count = 4 }) {
    const beams = useMemo(() => Array.from({ length: count }).map((_, i) => ({
        x: (Math.random() - 0.5) * 6,
        z: (Math.random() - 0.5) * 6,
        height: 2.4 + Math.random() * 1.2,
        delay: Math.random() * 2 + i * 0.15
    })), [count])

    return beams.map((beam, idx) => (
        <AnimatedBeam key={idx} {...beam} />
    ))
}

function AnimatedBeam({ x, z, height, delay }) {
    const ref = useRef()
    useFrame(({ clock }) => {
        const t = clock.getElapsedTime() + delay
        if (ref.current) {
            ref.current.material.opacity = 0.05 + (Math.sin(t * 1.6) + 1) * 0.12
            ref.current.scale.y = 0.7 + Math.sin(t * 1.2) * 0.2
        }
    })
    return (
        <mesh position={[x, height / 2, z]} rotation={[-Math.PI / 2, 0, 0]}>
            <planeGeometry args={[0.35, height]} />
            <meshBasicMaterial color="#38bdf8" transparent opacity={0.12} side={DoubleSide} />
        </mesh>
    )
}
