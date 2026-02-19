import React, { useMemo, useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Color } from 'three'

const PARTICLES = 120

export default function Irrigation({ active = false }){
  const pointsRef = useRef()
  const speeds = useRef(new Float32Array(PARTICLES).map(()=> 0.9 + Math.random() * 1.2))

  const positions = useMemo(()=>{
    const arr = new Float32Array(PARTICLES * 3)
    for(let i = 0; i < PARTICLES; i++){
      arr[i * 3] = (Math.random() - 0.5) * 2.2
      arr[i * 3 + 1] = Math.random() * 1.6 + 0.4
      arr[i * 3 + 2] = (Math.random() - 0.5) * 2.2
    }
    return arr
  }, [])

  const resetParticle = (arr, idx)=>{
    arr[idx * 3] = (Math.random() - 0.5) * 2.2
    arr[idx * 3 + 1] = 1.6 + Math.random() * 0.8
    arr[idx * 3 + 2] = (Math.random() - 0.5) * 2.2
  }

  useFrame((state, delta)=>{
    if(!active || !pointsRef.current) return
    const arr = pointsRef.current.geometry.attributes.position.array
    for(let i = 0; i < PARTICLES; i++){
      arr[i * 3 + 1] -= speeds.current[i] * delta * 2.4
      if(arr[i * 3 + 1] < 0){
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
        <meshStandardMaterial color={active ? '#59d6ff' : '#1f2937'} emissive={active ? '#0ca7ff' : '#111827'} emissiveIntensity={active ? 0.8 : 0.15} roughness={0.4} metalness={0.2} />
      </mesh>
      {active && (
        <points ref={pointsRef}>
          <bufferGeometry>
            <bufferAttribute attach="attributes-position" count={positions.length / 3} array={positions} itemSize={3} />
          </bufferGeometry>
          <pointsMaterial size={0.08} color={new Color('#8ddcff')} transparent opacity={0.9} depthWrite={false} />
        </points>
      )}
    </group>
  )
}
