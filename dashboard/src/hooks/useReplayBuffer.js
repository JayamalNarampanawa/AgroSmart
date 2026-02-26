import { useEffect, useMemo, useRef, useState } from 'react'

const clamp = (v, min, max) => Math.min(Math.max(v, min), max)
const nowTs = () => Date.now()

export default function useReplayBuffer({ source, enabled = true, throttleMs = 1000, maxPoints = 900 } = {}) {
  const [buffer, setBuffer] = useState([])
  const [isRecording, setIsRecording] = useState(Boolean(enabled))
  const lastTsRef = useRef(null)
  const sourceRef = useRef(source)

  useEffect(() => {
    sourceRef.current = source
  }, [source])

  useEffect(() => {
    if (!enabled || !isRecording) return undefined

    const recordOnce = () => {
      const value = sourceRef.current
      if (!value) return
      const stamp = value?.ts ?? value?.__ts ?? nowTs()
      if (lastTsRef.current && stamp === lastTsRef.current) return
      lastTsRef.current = stamp
      const snapshot = { ...value, ts: stamp }
      setBuffer((prev) => {
        const next = [...prev, snapshot]
        if (next.length > maxPoints) {
          return next.slice(next.length - clamp(maxPoints, 1, maxPoints))
        }
        return next
      })
    }

    recordOnce()
    const id = setInterval(recordOnce, throttleMs)
    return () => clearInterval(id)
  }, [enabled, isRecording, throttleMs, maxPoints])

  const clear = () => {
    setBuffer([])
    lastTsRef.current = null
  }

  const pause = () => setIsRecording(false)
  const resume = () => setIsRecording(true)
  const toggle = () => setIsRecording((v) => !v)

  const stats = useMemo(() => ({ size: buffer.length, latestTs: buffer[buffer.length - 1]?.ts }), [buffer])

  return {
    buffer,
    isRecording,
    clear,
    pause,
    resume,
    toggle,
    stats,
  }
}
