import React, { useMemo, useRef } from 'react'
import { Color, DoubleSide } from 'three'
import { useFrame } from '@react-three/fiber'
import { Environment, Float, Sparkles, Stars, Grid } from '@react-three/drei'
import { EffectComposer, Bloom, Vignette, Noise } from '@react-three/postprocessing'
import Soil from './Soil'
import Sun from './Sun'
import Irrigation from './Irrigation'
import CinematicCamera from './CinematicCamera'
import HologramGrid from './HologramGrid'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

export default function FarmScene({ data = {} }){
  const {
    temperature = 24,
    humidity = 60,
    soilMoisture = 50,
    lightLevel = 40,
    irrigationStatus = false
  } = data

  const tempFactor = clamp01((temperature - 10) / 24)
  const humidityFactor = clamp01(humidity / 100)
  const lightFactor = clamp01(lightLevel / 100)
  const irrigationActive = irrigationStatus === 1 || irrigationStatus === true || String(irrigationStatus).toLowerCase() === 'on'

  const backgroundColor = useMemo(()=> new Color('#03060d').lerp(new Color('#0e1728'), humidityFactor * 0.5), [humidityFactor])
  const fogColor = useMemo(()=> new Color('#05070c').lerp(new Color('#0b1422'), 0.5 + humidityFactor * 0.3), [humidityFactor])
  const ambientColor = useMemo(()=> new Color('#0f3450').lerp(new Color('#543322'), tempFactor), [tempFactor])

  return (
    <>
      <CinematicCamera focus={[0, 1.1, 0]} radius={7.2} height={3.1} sway={0.55} speed={0.18} />

      <color attach="background" args={[backgroundColor]} />
      <fog attach="fog" args={[fogColor, 6, 18]} />

      <hemisphereLight args={[ambientColor, new Color('#050505'), 0.35 + lightFactor * 0.15]} />
      <ambientLight intensity={0.45 + lightFactor * 0.35} color={ambientColor} />
      <Sun lightLevel={lightLevel} />

      <HologramGrid />

      <Float speed={1.1} rotationIntensity={0.16} floatIntensity={0.32}>
        <group position={[0, 0.05, 0]}>
          <Soil soilMoisture={soilMoisture} />

          <mesh position={[0, 0.8, 0]} scale={[3.6, 1.4, 3.6]}>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial
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
        <Bloom intensity={0.95} luminanceThreshold={0.2} luminanceSmoothing={0.4} radius={0.9} />
        <Noise premultiply opacity={0.06} />
        <Vignette eskil offset={0.18} darkness={0.92} />
      </EffectComposer>
    </>
  )
}

function Scanlines(){
  const planeRef = useRef()
  useFrame(({ clock })=>{
    if(!planeRef.current) return
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

function LightBeams({ count = 4 }){
  const beams = useMemo(()=> Array.from({ length: count }).map((_, i)=>({
    x: (Math.random() - 0.5) * 6,
    z: (Math.random() - 0.5) * 6,
    height: 2.4 + Math.random() * 1.2,
    delay: Math.random() * 2 + i * 0.15
  })), [count])

  return beams.map((beam, idx)=>(
    <AnimatedBeam key={idx} {...beam} />
  ))
}

function AnimatedBeam({ x, z, height, delay }){
  const ref = useRef()
  useFrame(({ clock })=>{
    const t = clock.getElapsedTime() + delay
    if(ref.current){
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
