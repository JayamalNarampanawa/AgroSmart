import React, { useEffect, useMemo, useRef } from 'react'
import { Color, DoubleSide } from 'three'
import { useFrame } from '@react-three/fiber'
import { ContactShadows, Environment, Float, Html, Sparkles, Stars } from '@react-three/drei'
import { EffectComposer, Bloom, Vignette, Noise, Outline, Selection, Select } from '@react-three/postprocessing'
import Soil from './Soil'
import Sun from './Sun'
import Irrigation from './Irrigation'
import CinematicCamera from './CinematicCamera'
import HologramGrid from './HologramGrid'
import { calibration } from './calibration'
import TwinInsightPanel from './TwinInsightPanel'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function FarmScene({ data = {}, normalized = {}, irrigationOn = false, tick = 0, debugMode = false, labelsEnabled = false, recommendation = null, mlResult = null }) {
    const {
        temperature = 24,
        humidity = 60,
        soilMoisture = 50,
        lightLevel = 40,
        irrigationStatus = false
    } = data

    const computeWetness = (value) => clamp01((calibration.soil.dry - value) / Math.max(calibration.soil.dry - calibration.soil.wet, 1))
    const computeBrightness = (value) => clamp01((calibration.light.dark - value) / Math.max(calibration.light.dark - calibration.light.bright, 1))

    const wetness = normalized?.wetness ?? normalized?.soil ?? computeWetness(soilMoisture)
    const brightness = normalized?.brightness ?? normalized?.light ?? computeBrightness(lightLevel)

    const tempFactor = clamp01((temperature - 10) / 24)
    const humidityFactor = clamp01(humidity / 100)
    const lightFactor = Math.max(0.1, brightness)
    const irrigationActive = irrigationOn || irrigationStatus === 1 || irrigationStatus === true || String(irrigationStatus).toLowerCase() === 'on'
    const targetBackground = useMemo(() => new Color('#05070d').lerp(new Color('#0a1628'), humidityFactor * 0.35), [humidityFactor])
    const targetFog = useMemo(() => new Color('#060910').lerp(new Color('#0b1420'), 0.4 + humidityFactor * 0.25), [humidityFactor])
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
            const baseBloom = 0.4 + brightness * 0.9
            const targetBloom = baseBloom + pulseRef.current * 0.28
            bloomRef.current.intensity += (targetBloom - bloomRef.current.intensity) * 0.18
        }
    })

    return (
        <Selection>
            <CinematicCamera focus={[0, 0.6, 0]} radius={6.5} height={2.4} sway={0.18} speed={0.05} tick={tick} />

            <color attach="background" args={[targetBackground]} />
            {!debugMode && <fog attach="fog" args={[targetFog, 8, 20]} />}

            <hemisphereLight ref={hemiRef} args={[targetAmbient, new Color('#050505'), 0.35 + lightFactor * 0.15]} />
            <ambientLight ref={ambientRef} intensity={0.35 + lightFactor * 0.25} color={targetAmbient} />
            <directionalLight position={[5, 6, 5]} intensity={1.2} color="#ffd9a1" castShadow />
            <directionalLight position={[-6, 5, -6]} intensity={1.6} color="#67e8f9" />
            <directionalLight position={[0, 6, 4]} intensity={0.6} color="#bcd3ff" />
            <Sun lightLevel={brightness * 100} />

            <HologramGrid />
            <ContactShadows position={[0, 0.01, 0]} opacity={0.35} scale={12} blur={2.8} far={6} resolution={1024} />

            <Float speed={0.9} rotationIntensity={0.12} floatIntensity={0.24}>
                <group position={[0, 0.05, 0]}>
                    <Soil soilMoisture={wetness * 100} />
                    <GridOverlay />

                    <Select enabled>
                        <mesh position={[0, 0.8, 0]} scale={[3.6, 1.4, 3.6]}>
                            <boxGeometry args={[1, 1, 1]} />
                            <meshStandardMaterial
                                ref={cubeMatRef}
                                color="#00f5a0"
                                metalness={0.35}
                                roughness={0.22}
                                transparent
                                opacity={0.68}
                                emissive="#00ffc6"
                                emissiveIntensity={0.8 + tempFactor * 0.6}
                            />
                        </mesh>
                    </Select>

                    <mesh position={[0, 0.02, 0]}>
                        <ringGeometry args={[5, 5.1, 64]} />
                        <meshBasicMaterial color="#2dd4ff" opacity={0.32} transparent />
                    </mesh>

                    <Scanlines />
                    <Select enabled>
                        <Irrigation active={irrigationActive} />
                    </Select>

                    {labelsEnabled && <Labels />}
                </group>
            </Float>

            <LightBeams count={5} />
            <Sparkles count={140} speed={0.65} opacity={0.55} color="#67e8f9" size={2.8} scale={[16, 6, 16]} />
            <Stars radius={60} depth={20} count={1600} factor={3} fade />
            <Environment preset="city" />

            <Float speed={0.6} rotationIntensity={0.02} floatIntensity={0.14}>
                <TwinInsightPanel recommendation={recommendation} ml={mlResult} position={[0, 2.6, 0]} />
            </Float>

            <EffectComposer>
                <Outline
                    blur
                    visibleEdgeColor={0x3bf5ff}
                    hiddenEdgeColor={0x0}
                    edgeStrength={3}
                    width={0.0025}
                    pulseSpeed={0.7}
                />
                <Bloom ref={bloomRef} intensity={0.8} luminanceThreshold={0.2} luminanceSmoothing={0.4} radius={0.9} />
                <Noise premultiply opacity={0.06} />
                <Vignette eskil offset={0.18} darkness={0.92} />
            </EffectComposer>
        </Selection>
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

function Labels() {
    return (
        <>
            <Html position={[0, 1.9, 0]} center style={labelStyle}>Crop</Html>
            <Html position={[0, 0.15, 3.2]} center style={labelStyle}>Soil</Html>
            <Html position={[0, 0.7, -1]} center style={labelStyle}>Irrigation</Html>
            <Html position={[6, 7.2, -4]} center style={labelStyle}>Sun</Html>
        </>
    )
}

const labelStyle = {
    padding: '4px 8px',
    borderRadius: '9999px',
    background: 'rgba(16, 185, 129, 0.14)',
    border: '1px solid rgba(52, 211, 153, 0.6)',
    color: '#d1fae5',
    fontSize: '11px',
    fontWeight: 700,
    letterSpacing: '0.08em',
    textTransform: 'uppercase',
    backdropFilter: 'blur(6px)',
}

function GridOverlay() {
    return <gridHelper args={[12, 12, '#1e293b', '#1e293b']} position={[0, 0.02, 0]} />
}
