import React, { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { Link } from 'react-router-dom'
import WarehouseScene from '../components/warehouse/WarehouseScene'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'

export default function ArView() {
    const { data: liveData = {}, raw = {}, connected, tick, lastUpdated } = useAgroSmartLiveData({ fastMode: true })

    return (
        <div className="min-h-screen bg-slate-950 text-slate-100">
            <header className="flex items-center justify-between border-b border-white/10 bg-slate-900/70 px-6 py-4 backdrop-blur">
                <div>
                    <div className="text-[11px] uppercase tracking-[0.28em] text-cyan-200">AgroSmart 2.0</div>
                    <div className="text-lg font-semibold text-white">AR Mode (3D)</div>
                </div>
                <div className="flex items-center gap-3">
                    <Link
                        to="/dashboard"
                        className="inline-flex items-center gap-2 rounded-lg border border-slate-300/40 bg-slate-700/30 px-3 py-2 text-sm font-semibold text-slate-100 transition-all duration-200 hover:border-slate-200/70 hover:bg-slate-600/40"
                    >
                        Dashboard
                    </Link>
                    <Link
                        to="/twin"
                        className="inline-flex items-center gap-2 rounded-lg border border-cyan-400/40 bg-cyan-500/10 px-3 py-2 text-sm font-semibold text-cyan-100 transition-all duration-200 hover:border-cyan-400/70 hover:bg-cyan-500/20"
                    >
                        Back to Twin
                    </Link>
                </div>
            </header>

            <div className="relative h-[calc(100vh-72px)]">
                <Canvas shadows camera={{ position: [0.8, 0.55, 1.2], fov: 55 }} gl={{ antialias: true, powerPreference: 'high-performance' }}>
                    <Suspense fallback={null}>
                        <OrbitControls enableDamping dampingFactor={0.08} maxDistance={2.5} minDistance={0.6} />
                        <WarehouseScene live={liveData} />
                    </Suspense>
                </Canvas>
            </div>
        </div>
    )
}
