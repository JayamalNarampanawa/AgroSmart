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
import WeatherPanel from '../components/WeatherPanel'
import FinalResultCard from '../components/FinalResultCard'
import NavSectionBar from '../components/NavSectionBar'
import useCropRecommendation from '../hooks/useCropRecommendation'
import useRecommendationData from '../hooks/useRecommendationData'
import useMlValidation from '../hooks/useMlValidation'
import useWeatherData from '../hooks/useWeatherData'
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
  const rec = useRecommendationData()
  const { mlResult, mlError } = useMlValidation(rec)
  const { weather, history: weatherHistory, forecast: weatherForecast } = useWeatherData()
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
    <>
      {/* Fixed ChatWidget - outside of scrollable content, hidden during loading */}
      {!showLoading && <ChatWidget />}
      
      <div className="app-shell app-shell-animate">
        <Background3D />
        <PerspectiveStage className="relative z-10 px-4 md:px-8 pt-6 pb-14">
        <AnimatePresence mode="wait">
          {showLoading && <LoadingScreen message={'Connecting to sensors...'}/>}
        </AnimatePresence>
        <Navbar />
        <Scroll3D>
          <main className="mt-4 space-y-8">
          <NavSectionBar
            sections={[
              { id: 'status', label: 'Status' },
              { id: 'final', label: 'Final Result' },
              { id: 'recommendations', label: 'Recommendations' },
              { id: 'weather', label: 'Weather' },
              { id: 'analytics', label: 'Analytics' }
            ]}
          />
          {current?.timestamp && (Date.now() - current.timestamp > 10 * 60 * 1000) && (
            <AnimatedSection>
              <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-400/20 text-amber-100">
                Sensor data appears stale (older than 10 minutes). Displaying last known values.
              </div>
            </AnimatedSection>
          )}

          {/* PRIORITY 1: Quick Farm Status */}
          <AnimatedSection>
            <section id="status">
              <SectionHeader
                eyebrow="Quick Farm Status"
                title="Current Sensor Readings"
                subtitle="Real-time environmental data from your farm"
                right={<StatusPill label="Live" tone="live" />}
              />
              <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4 md:gap-5">
                <SensorCard title="Temperature" value={current?.temperature ?? '--'} unit="°C" type="temperature" />
                <SensorCard title="Humidity" value={current?.humidity ?? '--'} unit="%" type="humidity" />
                <SensorCard title="Soil Moisture" value={current?.soilMoisture ?? '--'} unit="" type="soil" />
                <SensorCard title="Light Level" value={current?.lightLevel ?? '--'} unit="lux" type="light" />
              </div>
              <div className="mt-5 grid grid-cols-1 md:grid-cols-2 gap-4">
                <Card className="p-4">
                  <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Pump Status</div>
                  <div className="mt-2 text-lg font-semibold">
                    {current?.pumpStatus === 1 || current?.pumpStatus === true ? 'ON' : 'OFF'}
                  </div>
                </Card>
                <Card className="p-4">
                  <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Last Updated</div>
                  <div className="mt-2 text-sm text-slate-300">
                    {current?.timestamp ? new Date(current.timestamp).toLocaleString() : 'Unknown'}
                  </div>
                </Card>
              </div>
            </section>
          </AnimatedSection>

          {/* Alerts & Insights */}
          <AnimatedSection>
            <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card className="p-6" hoverable>
                <AlertsPanel current={current} />
              </Card>
              <Card className="p-6" hoverable>
                <InsightsPanel current={current} history={history} />
              </Card>
            </section>
          </AnimatedSection>

          {/* FINAL RESULT */}
          <AnimatedSection>
            <section id="final" className="space-y-6">
              <SectionHeader
                eyebrow="Decision"
                title="Final Result (Decision Summary)"
                subtitle="Farmer-friendly summary of the best crop choice"
                right={<StatusPill label="Ready" tone="live" />}
              />
              <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                <FinalResultCard
                  rec={rec}
                  mlResult={mlResult}
                  mlError={mlError}
                  current={current}
                  weather={weather}
                  weatherHistory={weatherHistory}
                />
              </Card>
            </section>
          </AnimatedSection>

          {/* Recommendation Details */}
          <AnimatedSection>
            <section id="recommendations" className="space-y-4">
              <SectionHeader
                eyebrow="Intelligence"
                title="Recommendation Details"
                subtitle="View the primary explainable recommendation and ML validation"
                right={<StatusPill label={aiLoading ? 'Processing' : 'Ready'} tone={aiLoading ? 'warn' : 'live'} />}
              />
              <div className="rounded-2xl border border-white/8 bg-slate-950/40 p-4">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <CropRecommendationPanel mlResult={mlResult} mlError={mlError} />
                  </Card>
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <CropSuitabilityPanel suitability={aiResult ? { totals: aiResult.scores, breakdown: Object.fromEntries(Object.keys(aiResult.scores||{}).map(k=>[k,{ why: Object.entries(aiResult.diffs?.[k]||{}).map(([f,v])=> v===null? `${f}: N/A` : `${f} delta ${v}`) }])) } : null} />
                  </Card>
                </div>
              </div>
            </section>
          </AnimatedSection>

          {/* Weather: Local conditions and rainfall trends */}
          <AnimatedSection>
            <section id="weather">
              <SectionHeader
                eyebrow="Weather Insights"
                title="Rainfall & Conditions"
                subtitle="OpenWeatherMap snapshot and recent rainfall trend"
                right={<StatusPill label="Live" tone="live" />}
              />
              <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                <WeatherPanel weather={weather} history={weatherHistory} forecast={weatherForecast} current={current} />
              </Card>
            </section>
          </AnimatedSection>

          {/* PRIORITY 4: Soil Management - Farm Configuration */}
          <AnimatedSection>
            <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card className="p-6 holo-panel" hoverable>
                <SoilProfileCard />
              </Card>
              <Card className="p-6 holo-panel">
                <CurrentVsIdealChart />
              </Card>
            </section>
          </AnimatedSection>

          {/* PRIORITY 5: Analytics & Historical Data - Detailed Analysis */}
          <AnimatedSection>
            <section id="analytics" className="space-y-6">
              <SectionHeader
                eyebrow="Analytics"
                title="Historical Analysis"
                subtitle="Trends, patterns, and detailed analytics"
                right={<StatusPill label={tsLoading ? 'Loading' : 'Updated'} tone={tsLoading ? 'warn' : 'info'} />}
              />
              <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] gap-6">
                <Card className="p-6 lg:p-7">
                  <div className="mb-6">
                    <SeedHistoricalData />
                  </div>
                  <ChartsPanel timeseries={timeseries} />
                </Card>
                <div className="space-y-6">
                  <Card className="p-6 holo-panel">
                    <HistoricalComparisonChart />
                  </Card>
                  <Card className="p-6 holo-panel">
                    <FeatureDiffPanel diffs={aiResult?.diffs?.[aiResult.topCrop]} crop={aiResult?.topCrop} />
                  </Card>
                </div>
              </div>
            </section>
          </AnimatedSection>

          {/* PRIORITY 6: Debug Information - Developer Tools (Collapsible) */}
          <AnimatedSection>
            <section className="pb-6">
              <Card className="p-6">
                <details className="group">
                  <summary className="cursor-pointer font-semibold mb-2 flex items-center gap-2 hover:text-emerald-400 transition-colors">
                    <span className="transform group-open:rotate-90 transition-transform">▶</span>
                    Debug - Raw Firebase Data
                    <span className="text-xs text-slate-500 ml-auto">(Click to expand)</span>
                  </summary>
                  <div className="mt-4 space-y-4">
                    {error && <div className="text-red-600 mb-2">Error: {String(error?.message ?? error)}</div>}
                    <div className="text-sm text-slate-600 dark:text-slate-300">
                      <div className="mb-2"><strong>currentData:</strong></div>
                      <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(current, null, 2)}</pre>
                      <div className="mt-4 mb-2"><strong>history (latest 20):</strong></div>
                      <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(history.slice(-20), null, 2)}</pre>
                      <div className="mt-4 mb-2"><strong>ai/currentInsight:</strong></div>
                      <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(insight, null, 2)}</pre>
                      <div className="mt-4 mb-2"><strong>ai/suitability:</strong></div>
                      <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(suitability, null, 2)}</pre>
                      <div className="mt-4 mb-2"><strong>ai/recommendations:</strong></div>
                      <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(recs, null, 2)}</pre>
                    </div>
                  </div>
                </details>
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
      </PerspectiveStage>
    </div>
    </>
  )
}
