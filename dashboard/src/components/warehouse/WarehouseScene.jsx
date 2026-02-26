import React, { useMemo, useRef, useState } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { Html, Text } from '@react-three/drei'
import * as THREE from 'three'
import { PROTOTYPE, CUT, POLE, COMPONENTS } from '../../twin/warehouseLayout'
import HoloBar from '../../three/HoloBar'

const clamp01 = (v) => Math.max(0, Math.min(1, v))
const normalize = (v, min, max) => (v - min) / (max - min)

const RANGES = {
    soilMoisture: { min: 1500, max: 3500 },
    lightLevel: { min: 0, max: 4095 },
    humidity: { min: 0, max: 100 },
    temperature: { min: 0, max: 50 },
}

function lerpColor(a, b, t) {
    const c = a.clone()
    c.lerp(b, t)
    return c
}

export default function WarehouseScene({ live, envState, alerts = [] }) {
    const {
        soilMoisture = 0,
        lightLevel = 0,
        humidity = 0,
        irrigationStatus = false
    } = live || {}

    const featureState = envState?.features || {}
    const extraState = envState?.extraFeatures || {}

    const humidityState = featureState.humidity || null
    const lightState = extraState.lightLevel || null
    const soilState = extraState.soilMoisture || null

    const [showPoleData, setShowPoleData] = useState(false)
    const [showSoil, setShowSoil] = useState(false)
    const [showPump, setShowPump] = useState(false)
    const [activeSensor, setActiveSensor] = useState(null)

    const hasSoilAlert = useMemo(() => alerts?.some((a) => a.type === 'soil'), [alerts])
    const hasTempAlert = useMemo(() => alerts?.some((a) => a.type === 'temperature'), [alerts])

    const soilT = useMemo(() => clamp01(normalize(soilMoisture, RANGES.soilMoisture.min, RANGES.soilMoisture.max)), [soilMoisture])
    const lightT = useMemo(() => clamp01(normalize(lightLevel, RANGES.lightLevel.min, RANGES.lightLevel.max)), [lightLevel])
    const humidityT = useMemo(() => clamp01(normalize(humidity, RANGES.humidity.min, RANGES.humidity.max)), [humidity])

    const wetMix = useMemo(() => 1 - soilT, [soilT])
    const soilColor = useMemo(() => {
        const dry = new THREE.Color('#5c3b27')
        const wet = new THREE.Color('#2f5f42')
        return lerpColor(dry, wet, wetMix)
    }, [wetMix])

    const bgColor = useMemo(() => {
        const dark = new THREE.Color('#050913')
        const bright = new THREE.Color('#e6ecf6')
        return lerpColor(dark, bright, lightT)
    }, [lightT])

    const ambientColor = useMemo(() => {
        const dark = new THREE.Color('#111827')
        const bright = new THREE.Color('#ffffff')
        return lerpColor(dark, bright, lightT)
    }, [lightT])

    const dirColor = useMemo(() => {
        const dark = new THREE.Color('#1f2a44')
        const bright = new THREE.Color('#ffffff')
        return lerpColor(dark, bright, lightT)
    }, [lightT])

    const ambientIntensity = useMemo(() => 0.25 + lightT * 0.25, [lightT])
    const dirIntensity = useMemo(() => 0.6 + lightT * 1.8, [lightT])
    const humidityAlert = humidityState && (humidityState.severity === 'warn' || humidityState.severity === 'critical')
    const humidityBoost = humidityAlert ? (humidityState.severity === 'critical' ? 0.08 : 0.04) : 0
    const mistOpacity = useMemo(() => 0.03 + humidityT * 0.22 + humidityBoost, [humidityT, humidityBoost])

    const { camera } = useThree()
    const sprayRef = useRef()
    const soilMatRef = useRef()
    const mistMatRef = useRef()
    const sunLightRef = useRef()
    const sunOrbMatRef = useRef()
    const ambientRef = useRef()
    const shimmerMatRef = useRef()
    const shimmerRef = useRef()
    const soilHighlightRef = useRef()
    const sunOrbRef = useRef()
    const ldrBarRef = useRef()
    const humBarRef = useRef()
    const soilTextRef = useRef()
    const soilBarRef = useRef()
    const pumpButtonRef = useRef()
    const pumpPanelRef = useRef()
    const ldrVis = useRef(0)
    const humVis = useRef(0)
    const soilVis = useRef(0)
    const pumpVis = useRef(0)

    useFrame(({ clock }) => {
        // Animate irrigation spray opacity when active
        if (sprayRef.current && irrigationStatus) {
            const s = 1 + Math.sin(clock.elapsedTime * 3) * 0.08
            const o = 0.35 + Math.sin(clock.elapsedTime * 4) * 0.25
            sprayRef.current.scale.set(0.6 * s, 1.05 * s, 0.6 * s)
            sprayRef.current.material.opacity = clamp01(o)
        }

        const soilAlert = soilState && (soilState.severity === 'warn' || soilState.severity === 'critical')
        if (soilHighlightRef.current) {
            const base = soilAlert ? 0.08 : 0
            const pulse = soilAlert ? 0.05 * Math.sin(clock.elapsedTime * 2.4) : 0
            soilHighlightRef.current.material.opacity = clamp01(base + pulse)
        }

        const lightAlert = lightState && (lightState.severity === 'warn' || lightState.severity === 'critical')
        if (sunOrbMatRef.current) {
            const pulse = lightAlert ? 0.05 * Math.sin(clock.elapsedTime * 3.2) : 0
            const baseIntensity = Math.min(2.4, 0.3 + lightT * 2.2)
            const alertBoost = lightState?.severity === 'critical' ? 0.6 : lightAlert ? 0.3 : 0
            sunOrbMatRef.current.emissiveIntensity = baseIntensity + alertBoost + pulse
            if (lightState?.status === 'LOW') sunOrbMatRef.current.color.set('#60a5fa')
            else if (lightState?.status === 'HIGH') sunOrbMatRef.current.color.set('#fbbf24')
            else sunOrbMatRef.current.color.set('#fde68a')
        }

        if (sunLightRef.current) {
            const target = Math.min(2.4, dirIntensity)
            sunLightRef.current.intensity += (target - sunLightRef.current.intensity) * 0.08
        }

        if (ambientRef.current) {
            const target = ambientIntensity
            ambientRef.current.intensity += (target - ambientRef.current.intensity) * 0.08
        }

        if (soilMatRef.current) {
            const { r, g, b } = soilColor
            soilMatRef.current.color.setRGB(r, g, b)
            soilMatRef.current.roughness = 0.65 + (1 - wetMix) * 0.25
            soilMatRef.current.metalness = 0.03 + wetMix * 0.05
        }

        if (mistMatRef.current) {
            const targetOpacity = clamp01(0.04 + humidityT * 0.28)
            mistMatRef.current.opacity = targetOpacity
            mistMatRef.current.transparent = true
            mistMatRef.current.depthWrite = false
            mistMatRef.current.emissiveIntensity = humidityT > 0.8 ? 0.05 * humidityT : 0
            mistMatRef.current.color.set('#9ad8ff')
        }

        if (shimmerMatRef.current && shimmerRef.current) {
            if (irrigationStatus) {
                const shimmerOpacity = 0.06 + 0.04 * Math.sin(clock.elapsedTime * 3)
                const shimmerScale = 1 + 0.008 * Math.sin(clock.elapsedTime * 2)
                shimmerMatRef.current.opacity = clamp01(shimmerOpacity)
                shimmerRef.current.scale.set(shimmerScale, shimmerScale, shimmerScale)
                shimmerRef.current.visible = true
            } else {
                shimmerMatRef.current.opacity = 0
                shimmerRef.current.visible = false
            }
        }

        // Visibility easing for holograms
        const lerpVis = (ref, target) => {
            ref.current = ref.current + (target - ref.current) * 0.15
        }

        lerpVis(ldrVis, showPoleData ? 1 : 0)
        lerpVis(humVis, showPoleData ? 1 : 0)
        lerpVis(soilVis, showSoil ? 1 : 0)
        lerpVis(pumpVis, showPump ? 1 : 0)

        // Responsive UI scaling based on camera distance
        const dist = camera.position.length()
        const factor = Math.min(1.2, Math.max(0.4, dist * 0.6))

        const applyScale = (ref, base, visRef) => {
            if (!ref.current) return
            const v = visRef ? visRef.current : 1
            const s = Math.max(0.001, v)
            ref.current.scale.set(base[0] * factor * s, base[1] * factor * s, base[2] * factor * s)
            ref.current.visible = v > 0.02
        }

        applyScale(ldrBarRef, [uiScale * 0.18, uiScale * 0.36, uiScale * 0.18], ldrVis)
        applyScale(humBarRef, [uiScale * 0.18, uiScale * 0.36, uiScale * 0.18], humVis)
        applyScale(soilBarRef, [uiScale * 0.2, uiScale * 0.4, uiScale * 0.2], soilVis)
        applyScale(soilTextRef, [uiScale, uiScale, uiScale])
        applyScale(pumpButtonRef, [uiScale, uiScale, uiScale])
        applyScale(pumpPanelRef, [uiScale * 0.28, uiScale * 0.5, uiScale * 0.28], pumpVis)
    })

    const halfW = PROTOTYPE.width / 2
    const halfD = PROTOTYPE.depth / 2
    const topY = PROTOTYPE.height
    const layer2Y = topY - PROTOTYPE.layer2Drop
    const layer3Y = topY - PROTOTYPE.layer2Drop - PROTOTYPE.layer3Drop
    const soilY = topY - PROTOTYPE.layer2Drop - PROTOTYPE.layer3Drop - PROTOTYPE.soilDrop

    const cutWidth = CUT.xMax - CUT.xMin
    const cutDepth = CUT.zMax - CUT.zMin
    const cutCenterX = (CUT.xMin + CUT.xMax) / 2
    const cutCenterZ = (CUT.zMin + CUT.zMax) / 2

    const poleBaseY = layer3Y
    const poleCenterY = poleBaseY + POLE.height / 2
    const poleTopY = poleBaseY + POLE.height
    const sceneScale = 2.2
    const uiScale = 0.14
    const ldrValueText = Math.round(lightLevel || 0)
    const humidityValueText = Math.round(humidity || 0)
    const soilValueText = Math.round(soilMoisture || 0)

    const barY = topY + 0.035
    const frontZ = halfD + 0.015
    const ldrX = -halfW + 0.08
    const humX = halfW - 0.08
    const pumpButtonZ = -halfD - 0.035
    const pumpButtonY = topY + 0.008
    const pumpPanelY = pumpButtonY + 0.04
    const backBarZ = pumpButtonZ - 0.01
    const backLdrX = -halfW + 0.08
    const backHumX = halfW - 0.08
    const pumpOn = Boolean(irrigationStatus)
    const lightAlert = lightState && (lightState.severity === 'warn' || lightState.severity === 'critical')
    const soilAlert = soilState && (soilState.severity === 'warn' || soilState.severity === 'critical')

    const popupPositions = {
        ldr: [backLdrX, barY + 0.08, backBarZ + 0.04],
        humidity: [backHumX, barY + 0.05, backBarZ + 0.04],
        soil: [cutCenterX, soilY + 0.05, cutCenterZ + 0.04],
        pump: [0, pumpPanelY + 0.02, pumpButtonZ - 0.02],
    }

    const popupData = {
        ldr: {
            title: 'Light Level',
            value: `${ldrValueText}`,
            status: lightState?.status || null,
            ideal: null,
            message: lightState?.message,
        },
        humidity: {
            title: 'Humidity',
            value: `${humidityValueText} %`,
            status: humidityState?.status || null,
            ideal: humidityState?.ideal ? `${humidityState.ideal} %` : null,
            message: humidityState?.message,
        },
        soil: {
            title: 'Soil Moisture',
            value: `${soilValueText}`,
            status: soilState?.status || null,
            ideal: null,
            message: soilState?.message,
        },
        pump: {
            title: 'Pump',
            value: pumpOn ? 'ON' : 'OFF',
            status: pumpOn ? 'Active' : 'Idle',
            ideal: null,
            message: null,
        },
    }

    const renderActivePopup = () => {
        if (!activeSensor || !popupPositions[activeSensor]) return null
        const data = popupData[activeSensor]
        return (
            <Html position={popupPositions[activeSensor]} transform center distanceFactor={8} occlude>
                <div className="w-44 rounded-xl border border-white/10 bg-black/75 px-3 py-2 text-xs text-slate-100 backdrop-blur">
                    <div className="text-[10px] uppercase tracking-wide text-slate-300">{data.title}</div>
                    <div className="mt-1 text-sm font-semibold leading-tight text-white">{data.value}</div>
                    {data.status && <div className="mt-1 inline-flex rounded-full bg-white/10 px-2 py-0.5 text-[10px] uppercase text-amber-200">{data.status}</div>}
                    {data.ideal && <div className="mt-1 text-[10px] text-slate-300">Ideal: {data.ideal}</div>}
                    {data.message && <div className="mt-1 text-[10px] text-slate-200 leading-snug">{data.message}</div>}
                </div>
            </Html>
        )
    }

    return (
        <group scale={[sceneScale, sceneScale, sceneScale]} onPointerMissed={() => setActiveSensor(null)}>
            <color attach="background" args={[bgColor]} />
            <ambientLight ref={ambientRef} intensity={ambientIntensity} color={ambientColor} />
            <directionalLight ref={sunLightRef} position={[1.2, 1.6, 1.1]} intensity={dirIntensity} color={dirColor} castShadow />

            <mesh ref={sunOrbRef} position={[backLdrX, barY + 0.36, frontZ * 0.85]}>
                <sphereGeometry args={[0.05, 18, 18]} />
                <meshStandardMaterial
                    ref={sunOrbMatRef}
                    color="#fde68a"
                    emissive="#fde68a"
                    emissiveIntensity={0.8}
                    roughness={0.2}
                    metalness={0.1}
                />
            </mesh>

            {hasTempAlert && (
                <mesh position={[0, barY + 0.28, frontZ - 0.06]}>
                    <sphereGeometry args={[0.011, 14, 14]} />
                    <meshStandardMaterial
                        color="#facc15"
                        emissive="#facc15"
                        emissiveIntensity={1}
                        transparent
                        opacity={0.9}
                    />
                </mesh>
            )}

            {/* Outer cube */}
            <mesh position={[0, PROTOTYPE.height / 2, 0]} castShadow receiveShadow>
                <boxGeometry args={[PROTOTYPE.width, PROTOTYPE.height, PROTOTYPE.depth]} />
                <meshStandardMaterial color="#0f172a" roughness={0.65} metalness={0.1} />
            </mesh>

            {/* Grass tint on top surface outside cut area */}
            <mesh position={[0, topY + 0.0005, (CUT.zMax + halfD) / 2]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[PROTOTYPE.width, halfD - CUT.zMax]} />
                <meshBasicMaterial color="#14532d" transparent opacity={0.65} />
            </mesh>
            {/* Soil cut area top tint */}
            <mesh position={[cutCenterX, topY + 0.0006, cutCenterZ]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[cutWidth, cutDepth]} />
                <meshBasicMaterial color={soilColor} transparent opacity={0.7} />
            </mesh>
            <mesh ref={soilHighlightRef} position={[cutCenterX, topY + 0.0007, cutCenterZ]} rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[cutWidth, cutDepth]} />
                <meshBasicMaterial color="#f97316" transparent opacity={0} depthWrite={false} />
            </mesh>

            {/* Carved interior volumes (stacked boxes to show depth) */}
            {/* layer2 */}
            <mesh position={[cutCenterX, layer2Y / 2, cutCenterZ]} castShadow receiveShadow>
                <boxGeometry args={[cutWidth, layer2Y, cutDepth]} />
                <meshStandardMaterial color={soilColor} roughness={0.9} />
            </mesh>
            {/* layer3 */}
            <mesh position={[cutCenterX, layer3Y / 2, cutCenterZ]} castShadow receiveShadow>
                <boxGeometry args={[cutWidth * 0.92, layer3Y, cutDepth * 0.92]} />
                <meshStandardMaterial color={soilColor} roughness={0.92} />
            </mesh>
            {/* soil fill */}
            <mesh position={[cutCenterX, soilY / 2, cutCenterZ]} castShadow receiveShadow>
                <boxGeometry args={[cutWidth * 0.84, soilY, cutDepth * 0.84]} />
                <meshStandardMaterial ref={soilMatRef} color={soilColor} roughness={0.95} />
            </mesh>

            {/* irrigation shimmer overlay */}
            <mesh ref={shimmerRef} position={[cutCenterX, soilY + 0.002, cutCenterZ]} rotation={[-Math.PI / 2, 0, 0]} visible={false}>
                <planeGeometry args={[cutWidth * 0.7, cutDepth * 0.7]} />
                <meshBasicMaterial ref={shimmerMatRef} color="#7dd3fc" transparent opacity={0} depthWrite={false} />
            </mesh>

            {/* Clickable soil area overlay */}
            <mesh
                position={[cutCenterX, topY + 0.001, cutCenterZ]}
                rotation={[-Math.PI / 2, 0, 0]}
                onPointerDown={(e) => {
                    e.stopPropagation()
                    setShowSoil((v) => {
                        const next = !v
                        setActiveSensor(next ? 'soil' : null)
                        return next
                    })
                }}
            >
                <planeGeometry args={[cutWidth, cutDepth]} />
                <meshBasicMaterial transparent opacity={0} />
            </mesh>

            {/* Pump status button on back side */}
            <group
                position={[0, pumpButtonY, pumpButtonZ]}
                ref={pumpButtonRef}
                onPointerDown={(e) => {
                    e.stopPropagation()
                    setShowPump((v) => {
                        const next = !v
                        setActiveSensor(next ? 'pump' : null)
                        return next
                    })
                }}
            >
                <Text
                    fontSize={0.22}
                    color="#f8fafc"
                    outlineColor={pumpOn ? '#22c55e' : '#f97316'}
                    outlineWidth={showPump ? 0.024 : 0.012}
                    anchorX="center"
                    anchorY="middle"
                >
                    PUMP
                </Text>
            </group>

            {showPump && (
                <group
                    position={[0, pumpPanelY, pumpButtonZ - 0.01]}
                    ref={pumpPanelRef}
                    onPointerDown={(e) => e.stopPropagation()}
                >
                    <mesh position={[0, 0.02, 0]}>
                        <cylinderGeometry args={[0.09, 0.11, 0.06, 32]} />
                        <meshStandardMaterial
                            color="#0f172a"
                            emissive={pumpOn ? '#22c55e' : '#f97316'}
                            emissiveIntensity={pumpOn ? 1.2 : 0.9}
                            roughness={0.35}
                            metalness={0.25}
                        />
                    </mesh>
                    <mesh position={[0, 0.055, 0]}>
                        <ringGeometry args={[0.11, 0.14, 36]} />
                        <meshBasicMaterial color={pumpOn ? '#22c55e' : '#f97316'} transparent opacity={0.6} />
                    </mesh>
                    <Text
                        position={[0, 0.11, 0]}
                        fontSize={0.28}
                        color={pumpOn ? '#bbf7d0' : '#fed7aa'}
                        outlineColor={pumpOn ? '#22c55e' : '#f97316'}
                        outlineWidth={0.02}
                        anchorX="center"
                        anchorY="middle"
                    >
                        {pumpOn ? 'ON' : 'OFF'}
                    </Text>
                </group>
            )}

            {/* Pole on layer3 surface; click to show pole data */}
            <mesh
                position={[POLE.x, poleCenterY, POLE.z]}
                castShadow
                receiveShadow
                onPointerDown={(e) => {
                    e.stopPropagation()
                    setShowPoleData((v) => {
                        const next = !v
                        if (!next) setActiveSensor(null)
                        return next
                    })
                }}
            >
                <cylinderGeometry args={[POLE.radius, POLE.radius, POLE.height, 18]} />
                <meshStandardMaterial color="#cbd5e1" metalness={0.25} roughness={0.35} />
            </mesh>

            {showPoleData && (
                <>
                    <group
                        position={[backLdrX, barY, backBarZ]}
                        ref={ldrBarRef}
                        onPointerDown={(e) => {
                            e.stopPropagation()
                            setActiveSensor((cur) => (cur === 'ldr' ? null : 'ldr'))
                        }}
                    >
                        <HoloBar
                            label="LDR"
                            valueText={ldrValueText}
                            normalizedValue={lightT}
                            color="#22d3ee"
                            tick={ldrValueText}
                            rangeMin={0}
                            rangeMax={4095}
                            status={lightState?.status}
                            severity={lightState?.severity}
                            message={lightState?.message}
                        />
                    </group>
                    <group
                        position={[backHumX, barY, backBarZ]}
                        ref={humBarRef}
                        onPointerDown={(e) => {
                            e.stopPropagation()
                            setActiveSensor((cur) => (cur === 'humidity' ? null : 'humidity'))
                        }}
                    >
                        <HoloBar
                            label="Humidity"
                            valueText={humidityValueText}
                            normalizedValue={humidityT}
                            color="#60a5fa"
                            tick={humidityValueText}
                            rangeMin={0}
                            rangeMax={100}
                            status={humidityState?.status}
                            severity={humidityState?.severity}
                            message={humidityState?.message}
                            idealValue={humidityState?.ideal ?? null}
                            idealUnit="%"
                        />
                    </group>
                </>
            )}

            {/* Soil moisture text button in soil area */}
            <group
                position={[cutCenterX, soilY + 0.01, cutCenterZ]}
                ref={soilTextRef}
                onPointerDown={(e) => {
                    e.stopPropagation()
                    setShowSoil((v) => {
                        const next = !v
                        setActiveSensor(next ? 'soil' : null)
                        return next
                    })
                }}
            >
                <Text
                    fontSize={0.22}
                    color="#34d399"
                    outlineColor="#16a34a"
                    outlineWidth={showSoil ? 0.02 : 0.01}
                    anchorX="center"
                    anchorY="middle"
                >
                    SOIL
                </Text>
            </group>

            {showSoil && (
                <group
                    position={[cutCenterX, soilY + 0.06, cutCenterZ + 0.02]}
                    ref={soilBarRef}
                    onPointerDown={(e) => {
                        e.stopPropagation()
                        setActiveSensor((cur) => (cur === 'soil' ? null : 'soil'))
                    }}
                >
                    <HoloBar
                        label="Soil"
                        valueText={soilValueText}
                        normalizedValue={soilT}
                        color="#34d399"
                        tick={soilValueText}
                        rangeMin={1500}
                        rangeMax={3500}
                        status={soilState?.status}
                        severity={soilState?.severity}
                        message={soilState?.message}
                    />
                </group>
            )}

            {hasSoilAlert && (
                <mesh position={[cutCenterX + cutWidth * 0.32, soilY + 0.08, cutCenterZ + 0.08]}>
                    <sphereGeometry args={[0.012, 16, 16]} />
                    <meshStandardMaterial
                        color="#ef4444"
                        emissive="#ef4444"
                        emissiveIntensity={1.1}
                        transparent
                        opacity={0.9}
                    />
                </mesh>
            )}

            {renderActivePopup()}

            {/* Component markers */}
            {COMPONENTS.map((c) => (
                <mesh key={c.id} position={[c.position.x, c.position.y, c.position.z]}>
                    <sphereGeometry args={[0.012, 18, 18]} />
                    <meshStandardMaterial color="#38bdf8" emissive="#0ea5e9" emissiveIntensity={0.4} />
                </mesh>
            ))}

            {/* Mist volume over soil area */}
            <mesh position={[cutCenterX, layer3Y / 2, cutCenterZ]}>
                <boxGeometry args={[cutWidth * 0.9, layer3Y, cutDepth * 0.9]} />
                <meshStandardMaterial
                    ref={mistMatRef}
                    color="#9ad8ff"
                    transparent
                    opacity={mistOpacity}
                    roughness={1}
                    metalness={0}
                    emissive="#9ad8ff"
                    emissiveIntensity={0}
                    depthWrite={false}
                />
            </mesh>

            {/* Irrigation spray removed (cone hidden) */}
        </group>
    )
}
