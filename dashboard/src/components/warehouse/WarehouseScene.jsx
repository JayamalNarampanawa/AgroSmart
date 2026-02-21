import React, { useMemo, useRef, useState } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'
import { PROTOTYPE, CUT, POLE, COMPONENTS } from '../../twin/warehouseLayout'
import HoloBar from '../../three/HoloBar'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

function lerpColor(a, b, t) {
    const c = a.clone()
    c.lerp(b, t)
    return c
}

export default function WarehouseScene({ live }) {
    const {
        soilMoisture = 0,
        lightLevel = 0,
        humidity = 0,
        irrigationStatus = false
    } = live || {}

    const [showPoleData, setShowPoleData] = useState(false)
    const [showSoil, setShowSoil] = useState(false)
    const [showPump, setShowPump] = useState(false)

    const soilT = useMemo(() => clamp01((soilMoisture - 1500) / (3500 - 1500)), [soilMoisture])
    const lightT = useMemo(() => clamp01(lightLevel / 4095), [lightLevel])
    const humidityT = useMemo(() => clamp01(humidity / 100), [humidity])

    const soilColor = useMemo(() => {
        const wet = new THREE.Color('#2d5f3a')
        const dry = new THREE.Color('#4b2f1b')
        return lerpColor(wet, dry, soilT)
    }, [soilT])

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

    const ambientIntensity = useMemo(() => 0.2 + lightT * 0.9, [lightT])
    const dirIntensity = useMemo(() => 0.5 + lightT * 1.5, [lightT])
    const mistOpacity = useMemo(() => 0.03 + humidityT * 0.22, [humidityT])

    const { camera } = useThree()
    const sprayRef = useRef()
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

    return (
        <group scale={[sceneScale, sceneScale, sceneScale]}>
            <color attach="background" args={[bgColor]} />
            <ambientLight intensity={ambientIntensity} color={ambientColor} />
            <directionalLight position={[1.2, 1.6, 1.1]} intensity={dirIntensity} color={dirColor} castShadow />

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
                <meshStandardMaterial color={soilColor} roughness={0.95} />
            </mesh>

            {/* Clickable soil area overlay */}
            <mesh
                position={[cutCenterX, topY + 0.001, cutCenterZ]}
                rotation={[-Math.PI / 2, 0, 0]}
                onPointerDown={(e) => {
                    e.stopPropagation()
                    setShowSoil((v) => !v)
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
                    setShowPump((v) => !v)
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
                    setShowPoleData((v) => !v)
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
                        onPointerDown={(e) => e.stopPropagation()}
                    >
                        <HoloBar
                            label="LDR"
                            valueText={ldrValueText}
                            normalizedValue={lightT}
                            color="#22d3ee"
                            tick={ldrValueText}
                            rangeMin={0}
                            rangeMax={4095}
                        />
                    </group>
                    <group
                        position={[backHumX, barY, backBarZ]}
                        ref={humBarRef}
                        onPointerDown={(e) => e.stopPropagation()}
                    >
                        <HoloBar
                            label="Humidity"
                            valueText={humidityValueText}
                            normalizedValue={humidityT}
                            color="#60a5fa"
                            tick={humidityValueText}
                            rangeMin={0}
                            rangeMax={100}
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
                    setShowSoil((v) => !v)
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
                    />
                </group>
            )}

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
                <meshStandardMaterial color="#7dd3fc" transparent opacity={mistOpacity} roughness={1} metalness={0} />
            </mesh>

            {/* Irrigation spray removed (cone hidden) */}
        </group>
    )
}
