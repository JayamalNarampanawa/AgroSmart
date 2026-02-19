import React from 'react'
import { Grid } from '@react-three/drei'

export default function HologramGrid() {
    return (
        <Grid
            position={[0, 0.01, 0]}
            rotation={[-Math.PI / 2, 0, 0]}
            args={[40, 40]}
            cellSize={1.6}
            cellThickness={0.7}
            cellColor="#0ea5e9"
            sectionSize={4}
            sectionThickness={1.2}
            sectionColor="#22d3ee"
            fadeDistance={18}
            fadeStrength={2.5}
            infiniteGrid
        />
    )
}
