import { useFrame, useThree } from '@react-three/fiber'
import React from 'react'

export default function CinematicCamera({ focus = [0, 1, 0], radius = 7, height = 3, sway = 0.4, speed = 0.16 }){
  const { camera } = useThree()
  useFrame(({ clock })=>{
    const t = clock.getElapsedTime()
    const r = radius + Math.sin(t * 0.08) * 0.3
    camera.position.x = Math.sin(t * speed) * r
    camera.position.z = Math.cos(t * speed) * r
    camera.position.y = height + Math.sin(t * 0.35) * sway
    camera.lookAt(...focus)
  })
  return null
}
