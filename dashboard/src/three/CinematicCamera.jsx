import { useFrame, useThree } from '@react-three/fiber'
import React, { useEffect, useRef } from 'react'

export default function CinematicCamera({ focus = [0, 1, 0], radius = 7, height = 3, sway = 0.4, speed = 0.16, pulse = 0, tick = 0 }){
    const { camera } = useThree()
    const pulseRef = useRef(0)

    useEffect(()=>{ pulseRef.current = 1 }, [tick])

    useFrame(({ clock }, delta)=>{
        const t = clock.getElapsedTime()
        pulseRef.current = Math.max(0, pulseRef.current - delta * 1.1)
        const livePulse = Math.max(pulse, pulseRef.current)
        const r = radius + Math.sin(t * 0.08) * 0.3 - livePulse * 0.35
        camera.position.x = Math.sin(t * speed) * r
        camera.position.z = Math.cos(t * speed) * r
        camera.position.y = height + Math.sin(t * 0.35) * sway + livePulse * 0.12
        camera.lookAt(...focus)
    })
    return null
}
