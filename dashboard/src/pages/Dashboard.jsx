import React, { useEffect, useState } from 'react'
import { AnimatePresence } from 'framer-motion'
import Navbar from '../components/Navbar'
import SensorCard from '../components/SensorCard'
import ChartsPanel from '../components/ChartsPanel'
import InsightsPanel from '../components/InsightsPanel'
import AlertsPanel from '../components/AlertsPanel'
import useSensorData from '../hooks/useSensorData'
import useAnalyticsTimeseries from '../hooks/useAnalyticsTimeseries'
import useAnalyticsAppender from '../hooks/useAnalyticsAppender'
import SeedHistoricalData from '../components/SeedHistoricalData'
import LoadingScreen from '../components/LoadingScreen'
import useAIData from '../hooks/useAIData'
import useClientAIEngine from '../hooks/useClientAIEngine'
import CropSuitabilityPanel from '../components/CropSuitabilityPanel'
import FeatureDiffPanel from '../components/FeatureDiffPanel'
import HistoricalComparisonChart from '../components/HistoricalComparisonChart'
import CropRecommendationPanel from '../components/CropRecommendationPanel'
import CurrentVsIdealChart from '../components/CurrentVsIdealChart'
import ChatWidget from '../components/ChatWidget'
import SoilProfileCard from '../components/SoilProfileCard'
import useCropRecommendation from '../hooks/useCropRecommendation'
import Card from '../components/ui/Card'
import SectionHeader from '../components/ui/SectionHeader'
import StatusPill from '../components/ui/StatusPill'
import Background3D from '../components/background/Background3D'
import PerspectiveStage from '../components/layout/PerspectiveStage'
import AnimatedSection from '../components/layout/AnimatedSection'
import Scroll3D from '../components/layout/Scroll3D'

export default function Dashboard(){
  const { current, history, error } = useSensorData()
  const { insight, suitability, recs, loading: aiLoading } = useAIData()
  const { aiResult } = useClientAIEngine(current, { requireAuth: false, writeBack: true, minInterval: 10000 })
  // analytics timeseries (historical + sensor)
  const { data: timeseries, loading: tsLoading } = useAnalyticsTimeseries({ limit: 3000 })
  // append live sensor records into analytics feed
  useAnalyticsAppender({ enabled: true, minInterval: 10000 })
  const [showLoading, setShowLoading] = useState(true)

  // start client-side crop recommendation engine (writes to /AgroSmart/ai/recommendation)
  useCropRecommendation()

  useEffect(()=>{
    const t = setTimeout(()=>setShowLoading(false), 5000)
    return ()=>clearTimeout(t)
  },[])

  return (
    <div className="app-shell app-shell-animate">
      <Background3D />
      <PerspectiveStage className="relative z-10 px-4 md:px-8 pt-6 pb-14">
        <AnimatePresence mode="wait">
          {showLoading && <LoadingScreen message={'Connecting to sensors...'}/>}
        </AnimatePresence>
        <Navbar />
        <Scroll3D>
          <main className="mt-6 space-y-8">
          {current?.timestamp && (Date.now() - current.timestamp > 10 * 60 * 1000) && (
            <AnimatedSection>
              <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-400/20 text-amber-100">
                Sensor data appears stale (older than 10 minutes). Displaying last known values.
              </div>
            </AnimatedSection>
          )}
          <AnimatedSection>
            <section className="grid grid-cols-1 md:grid-cols-4 gap-4 md:gap-5">
              <SensorCard title="Temperature" value={current?.temperature ?? '--'} unit="°C" type="temperature" />
              <SensorCard title="Humidity" value={current?.humidity ?? '--'} unit="%" type="humidity" />
              <SensorCard title="Soil Moisture" value={current?.soilMoisture ?? '--'} unit="" type="soil" />
              <SensorCard title="Light Level" value={current?.lightLevel ?? '--'} unit="lux" type="light" />
            </section>
          </AnimatedSection>

          <AnimatedSection>
            <section className="grid grid-cols-1 lg:grid-cols-[minmax(0,2.1fr)_minmax(0,1fr)] gap-6">
              <Card className="p-6 lg:p-7">
                <SectionHeader
                  eyebrow="Operations"
                  title="Analytics Overview"
                  subtitle="Live + historical context from Kaggle baselines"
                  right={<StatusPill label={tsLoading ? 'Loading' : 'Updated'} tone={tsLoading ? 'warn' : 'info'} />}
                />
                <div className="mt-5">
                  <SeedHistoricalData />
                </div>
                <div className="mt-6">
                  <ChartsPanel timeseries={timeseries} />
                </div>
              </Card>
              <div className="space-y-6">
                <Card className="p-6" hoverable>
                  <InsightsPanel current={current} history={history} />
                </Card>
                <Card className="p-6" hoverable>
                  <AlertsPanel current={current} />
                </Card>
              </div>
            </section>
          </AnimatedSection>

          {/* AI Insights Section (Client-side Kaggle comparison) */}
          <AnimatedSection>
            <section className="space-y-6">
              <SectionHeader
                eyebrow="Intelligence"
                title="AI Insights"
                subtitle="Rule-based suitability, ML validation, and crop recommendations"
                right={<StatusPill label={aiLoading ? 'Processing' : 'Live'} tone={aiLoading ? 'warn' : 'live'} />}
              />
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-1 space-y-6">
                  <Card className="p-6 holo-panel" hoverable>
                    <SoilProfileCard />
                  </Card>
                  <Card className="p-6 holo-panel">
                    <HistoricalComparisonChart />
                  </Card>
                </div>

                <div className="lg:col-span-2 space-y-6">
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <CropSuitabilityPanel suitability={aiResult ? { totals: aiResult.scores, breakdown: Object.fromEntries(Object.keys(aiResult.scores||{}).map(k=>[k,{ why: Object.entries(aiResult.diffs?.[k]||{}).map(([f,v])=> v===null? `${f}: N/A` : `${f} delta ${v}`) }])) } : null} />
                  </Card>
                  <Card className="p-6 holo-panel">
                    <FeatureDiffPanel diffs={aiResult?.diffs?.[aiResult.topCrop]} crop={aiResult?.topCrop} />
                  </Card>
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <CropRecommendationPanel />
                  </Card>
                  <Card className="p-6 holo-panel">
                    <CurrentVsIdealChart />
                  </Card>
                </div>
              </div>
            </section>
          </AnimatedSection>

          <AnimatedSection>
            <section className="pb-6">
              <Card className="p-6">
                <h4 className="font-semibold mb-2">Debug - Raw Firebase Data</h4>
                {error && <div className="text-red-600 mb-2">Error: {String(error?.message ?? error)}</div>}
                <div className="text-sm text-slate-600 dark:text-slate-300">
                  <div className="mb-2"><strong>currentData:</strong></div>
                  <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(current, null, 2)}</pre>
                  <div className="mt-2 mb-2"><strong>history (latest 20):</strong></div>
                  <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(history.slice(-20), null, 2)}</pre>
                  <div className="mt-2 mb-2"><strong>ai/currentInsight:</strong></div>
                  <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(insight, null, 2)}</pre>
                  <div className="mt-2 mb-2"><strong>ai/suitability:</strong></div>
                  <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(suitability, null, 2)}</pre>
                  <div className="mt-2 mb-2"><strong>ai/recommendations:</strong></div>
                  <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(recs, null, 2)}</pre>
                </div>
              </Card>
            </section>
          </AnimatedSection>
          </main>
        </Scroll3D>
        <AnimatedSection>
          <footer className="mt-10">
            <div className="glass-panel rounded-2xl px-6 py-4 text-center">
              <div className="text-sm text-slate-300">AgroSmart2026 pvt ltd.</div>
            </div>
          </footer>
        </AnimatedSection>
        <ChatWidget />
      </PerspectiveStage>
    </div>
  )
}
