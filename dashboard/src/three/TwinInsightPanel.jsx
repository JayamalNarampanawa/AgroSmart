import React, { useMemo } from 'react'
import { Billboard, RoundedBox, Text } from '@react-three/drei'

const clamp = (v, min, max) => Math.min(max, Math.max(min, v))

function formatScore(score) {
    if (typeof score !== 'number' || Number.isNaN(score)) return '--'
    return score.toFixed(2)
}

function formatConfidence(conf) {
    if (typeof conf !== 'number' || Number.isNaN(conf)) return null
    const pct = conf > 1 ? conf : conf * 100
    return clamp(pct, 0, 100)
}

function normalizeReasons(reasons) {
    if (!Array.isArray(reasons)) return []
    return reasons.map((r) => (typeof r === 'string' && r.trim().length > 0 ? r.trim() : null)).filter(Boolean)
}

export default function TwinInsightPanel({ recommendation, ml, position = [0, 2.6, 0] }) {
    const derived = useMemo(() => {
        const primaryCrop = recommendation?.recommendedCrop || recommendation?.bestCrop || recommendation?.crop || '—'
        const matchLevel = recommendation?.matchLevel || 'Unknown'
        const bestScore = formatScore(recommendation?.bestScore)

        const reasons = normalizeReasons(recommendation?.reasons)
        const reason1 = reasons[0] || 'No explanation yet'
        const reason2 = reasons[1] || (reasons[0] ? 'Collecting more data...' : 'Waiting for AI input...')

        const mlCrop = ml?.predictedCrop || ml?.crop || null
        const confPct = formatConfidence(ml?.confidence)
        const mlAvailable = Boolean(mlCrop && confPct !== null)
        const agrees = typeof ml?.agrees === 'boolean'
            ? ml.agrees
            : mlCrop && primaryCrop && primaryCrop !== '—'
                ? mlCrop.toLowerCase() === primaryCrop.toLowerCase()
                : null

        let agreementLabel = 'offline / not available'
        if (mlAvailable) {
            if (agrees === true) agreementLabel = 'agrees ✅'
            else if (agrees === false) agreementLabel = 'differs ⚠️'
            else agreementLabel = 'pending'
        }

        return {
            primaryCrop,
            matchLevel,
            bestScore,
            reason1,
            reason2,
            mlCrop: mlCrop || '—',
            confText: confPct === null ? null : `${Math.round(confPct)}%`,
            mlAvailable,
            agreementLabel,
        }
    }, [recommendation, ml])

    const panelWidth = 2.8
    const panelHeight = 1.7
    const margin = 0.14
    const startY = panelHeight / 2 - margin
    const lineGap = 0.26

    return (
        <Billboard position={position} follow lockZ>
            <group>
                <RoundedBox args={[panelWidth, panelHeight, 0.08]} radius={0.12} smoothness={4}>
                    <meshStandardMaterial color="#0b1628" transparent opacity={0.68} roughness={0.35} metalness={0.05} />
                </RoundedBox>

                <group position={[-panelWidth / 2 + margin, startY, 0.05]}>
                    <Text
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.12}
                        color="#67e8f9"
                        letterSpacing={0.02}
                        maxWidth={panelWidth - margin * 2}
                    >
                        AI Insight Hologram
                    </Text>

                    <Text
                        position={[0, -lineGap, 0]}
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.18}
                        color="#e2f3ff"
                        maxWidth={panelWidth - margin * 2}
                    >
                        {`Primary: ${derived.primaryCrop}`}
                    </Text>

                    <Text
                        position={[0, -lineGap * 2, 0]}
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.12}
                        color="#a5b4fc"
                        maxWidth={panelWidth - margin * 2}
                    >
                        {`Match: ${derived.matchLevel} · Score ${derived.bestScore}`}
                    </Text>

                    <Text
                        position={[0, -lineGap * 3.05, 0]}
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.115}
                        color="#cbd5e1"
                        maxWidth={panelWidth - margin * 2}
                    >
                        {`1) ${derived.reason1}`}
                    </Text>

                    <Text
                        position={[0, -lineGap * 4.05, 0]}
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.115}
                        color="#cbd5e1"
                        maxWidth={panelWidth - margin * 2}
                    >
                        {`2) ${derived.reason2}`}
                    </Text>

                    <Text
                        position={[0, -lineGap * 5.2, 0]}
                        anchorX="left"
                        anchorY="top"
                        fontSize={0.115}
                        color={derived.mlAvailable ? '#99f6e4' : '#f9a8d4'}
                        maxWidth={panelWidth - margin * 2}
                    >
                        {derived.mlAvailable
                            ? `ML: ${derived.mlCrop} · ${derived.confText || '--'} · ${derived.agreementLabel}`
                            : 'ML: offline / not available'}
                    </Text>
                </group>
            </group>
        </Billboard>
    )
}
