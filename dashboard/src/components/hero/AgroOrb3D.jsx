import React, { Suspense, useEffect, useMemo, useRef, useState } from 'react'
import { Canvas, useFrame } from '@react-three/fiber'
import { Float } from '@react-three/drei'
import useMotionPreferences from '../../hooks/useMotionPreferences.jsx'

function isWebGLAvailable(){
  try{
    const canvas = document.createElement('canvas')
    return !!(window.WebGLRenderingContext && (canvas.getContext('webgl') || canvas.getContext('experimental-webgl')))
  }catch(e){
    return false
  }
}

function OrbCore(){
  const ringRef = useRef(null)
  const orbitRef = useRef(null)

  useFrame((state, delta) => {
    if(ringRef.current){
      ringRef.current.rotation.z += delta * 0.35
    }
    if(orbitRef.current){
      orbitRef.current.rotation.y += delta * 0.55
      orbitRef.current.rotation.x += delta * 0.15
    }
  })

  return (
    <Float speed={1.2} rotationIntensity={0.2} floatIntensity={0.35}>
      <group>
        <mesh>
          <sphereGeometry args={[1, 24, 24]} />
          <meshStandardMaterial color="#7dd3fc" transparent opacity={0.35} roughness={0.25} metalness={0.2} />
        </mesh>
        <mesh>
          <sphereGeometry args={[1.01, 16, 16]} />
          <meshBasicMaterial color="#34d399" wireframe transparent opacity={0.4} />
        </mesh>
        <mesh ref={ringRef} rotation={[Math.PI / 2.6, 0, 0]}>
          <torusGeometry args={[1.25, 0.02, 12, 90]} />
          <meshStandardMaterial color="#38bdf8" transparent opacity={0.7} />
        </mesh>
        <group ref={orbitRef}>
          <mesh position={[1.6, 0.2, 0.4]}>
            <sphereGeometry args={[0.05, 10, 10]} />
            <meshStandardMaterial color="#22d3ee" emissive="#22d3ee" emissiveIntensity={0.6} />
          </mesh>
          <mesh position={[-1.3, -0.4, -0.6]}>
            <sphereGeometry args={[0.04, 10, 10]} />
            <meshStandardMaterial color="#34d399" emissive="#34d399" emissiveIntensity={0.6} />
          </mesh>
          <mesh position={[0.2, 1.4, -0.2]}>
            <sphereGeometry args={[0.03, 10, 10]} />
            <meshStandardMaterial color="#60a5fa" emissive="#60a5fa" emissiveIntensity={0.6} />
          </mesh>
        </group>
      </group>
    </Float>
  )
}

export default function AgroOrb3D({ size = 'lg', className = '' }){
  const { enabled, reducedMotion } = useMotionPreferences()
  const [webgl, setWebgl] = useState(false)

  useEffect(() => {
    setWebgl(isWebGLAvailable())
  }, [])

  const allowMotion = enabled && !reducedMotion
  const allow3d = allowMotion && webgl
  const dpr = useMemo(() => (typeof window !== 'undefined' && window.innerWidth < 768 ? 1 : 1.5), [])

  return (
    <div className={`agro-orb ${size} ${allowMotion ? '' : 'agro-orb-static'} ${className}`}>
      {allow3d ? (
        <Canvas
          dpr={dpr}
          camera={{ position: [0, 0, 3.2], fov: 40 }}
          gl={{ antialias: false, alpha: true, powerPreference: 'low-power' }}
        >
          <ambientLight intensity={0.7} />
          <pointLight position={[5, 5, 5]} intensity={1.2} color="#7dd3fc" />
          <pointLight position={[-5, -3, -2]} intensity={0.6} color="#22d3ee" />
          <Suspense fallback={null}>
            <OrbCore />
          </Suspense>
        </Canvas>
      ) : (
        <div className="agro-orb-fallback">
          <div className="agro-orb-core" />
          <div className="agro-orb-ring" />
          <div className="agro-orb-satellites" />
        </div>
      )}
    </div>
  )
}
