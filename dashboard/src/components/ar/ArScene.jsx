import React, { useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

function lerpColor(a, b, t) {
  return a.clone().lerp(b, t)
}

export default function ArScene({ live }) {
  const {
    temperature = 0,
    humidity = 0,
    soilMoisture = 0,
    lightLevel = 0,
    irrigationStatus = false
  } = live || {}

  // Normalize sensor values
  const soilT = useMemo(() => {
    const wet = 1500
    const dry = 3500
    return clamp01((soilMoisture - wet) / (dry - wet)) // 0 wet -> 1 dry
  }, [soilMoisture])

  const lightT = useMemo(() => clamp01(lightLevel / 4095), [lightLevel])
  const humidityT = useMemo(() => clamp01(humidity / 100), [humidity])

  const groundColor = useMemo(() => {
    const dryColor = new THREE.Color('#4b2f1b')
    const wetColor = new THREE.Color('#2d5f3a')
    return lerpColor(wetColor, dryColor, soilT)
  }, [soilT])

  const mistOpacity = useMemo(() => 0.05 + humidityT * 0.18, [humidityT])
  const sunIntensity = useMemo(() => 0.2 + lightT * 2.0, [lightT])

  const sprayRef = React.useRef()

  useFrame(({ clock }) => {
    if (!sprayRef.current || !irrigationStatus) return
    const s = 1 + Math.sin(clock.elapsedTime * 3) * 0.08
    const o = 0.45 + Math.sin(clock.elapsedTime * 4) * 0.2
    sprayRef.current.scale.set(0.4 * s, 1.2 * s, 0.4 * s)
    sprayRef.current.material.opacity = clamp01(o)
  })

  return (
    <>
      <color attach="background" args={["#03070f"]} />
      <ambientLight intensity={0.4} />
      <directionalLight position={[4, 6, 4]} intensity={1.2} castShadow />

      {/* Ground */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} receiveShadow position={[0, -0.01, 0]}>
        <planeGeometry args={[20, 20]} />
        <meshStandardMaterial color={groundColor} roughness={0.9} metalness={0.05} />
      </mesh>

      {/* Sun orb */}
      <mesh position={[0, 3.5, -2]} castShadow>
        <sphereGeometry args={[0.4, 32, 32]} />
        <meshStandardMaterial emissive={new THREE.Color('#f8d24b')} emissiveIntensity={sunIntensity} color="#fef3c7" />
      </mesh>

      {/* Mist volume */}
      <mesh position={[0, 0.75, 0]}>
        <boxGeometry args={[6, 1.5, 6]} />
        <meshStandardMaterial color="#7dd3fc" transparent opacity={mistOpacity} roughness={1} metalness={0} />
      </mesh>

      {/* Sensor pillars */}
      <mesh position={[-2, 1, 0]}>
        <boxGeometry args={[0.3, 2, 0.3]} />
        <meshStandardMaterial color="#38bdf8" roughness={0.4} metalness={0.2} />
      </mesh>
      <mesh position={[2, 1, 0]}>
        <boxGeometry args={[0.3, 2, 0.3]} />
        <meshStandardMaterial color="#22c55e" roughness={0.4} metalness={0.2} />
      </mesh>

      {/* Irrigation spray */}
      {irrigationStatus && (
        <mesh ref={sprayRef} position={[0, 1.2, 0]}>
          <coneGeometry args={[0.7, 1.4, 16]} />
          <meshStandardMaterial color="#67e8f9" transparent opacity={0.5} emissive="#22d3ee" emissiveIntensity={0.6} />
        </mesh>
      )}
    </>
  )
}
