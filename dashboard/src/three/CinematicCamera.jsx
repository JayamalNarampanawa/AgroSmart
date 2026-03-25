import { useFrame, useThree } from '@react-three/fiber'
import { Vector3 } from 'three'
import React, { useEffect, useRef } from 'react'

export default function CinematicCamera({ focus = [0, 1, 0], radius = 7, height = 3, sway = 0.4, speed = 0.16, pulse = 0, tick = 0, target = null }) {
    const { camera } = useThree()
    const pulseRef = useRef(0)
    const desiredPos = useRef(new Vector3())
    const desiredLook = useRef(new Vector3(...focus))
    const smoothLook = useRef(new Vector3(...focus))

    useEffect(() => { pulseRef.current = 1 }, [tick])

    useFrame(({ clock }, delta) => {
        const t = clock.getElapsedTime()
        pulseRef.current = Math.max(0, pulseRef.current - delta * 1.1)
        const livePulse = Math.max(pulse, pulseRef.current)

        if (target?.position && target?.lookAt) {
            desiredPos.current.set(...target.position)
            desiredLook.current.set(...target.lookAt)
        } else {
            const r = radius + Math.sin(t * 0.08) * 0.3 - livePulse * 0.35
            desiredPos.current.set(
                Math.sin(t * speed) * r,
                height + Math.sin(t * 0.35) * sway + livePulse * 0.12,
                Math.cos(t * speed) * r,
            )
            desiredLook.current.set(...focus)
        }

        // Smoothly interpolate camera position and look target
        const lerpAmt = target ? 0.08 : 0.12
        camera.position.lerp(desiredPos.current, lerpAmt)
        smoothLook.current.lerp(desiredLook.current, lerpAmt)
        camera.lookAt(smoothLook.current)
    })
    return null
}
