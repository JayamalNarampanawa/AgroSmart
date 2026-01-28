import React, { useEffect, useState } from 'react'
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
import AIOverviewPanel from '../components/AIOverviewPanel'
import CropSuitabilityPanel from '../components/CropSuitabilityPanel'
import FeatureDiffPanel from '../components/FeatureDiffPanel'
import HistoricalComparisonChart from '../components/HistoricalComparisonChart'
import CropRecommendationPanel from '../components/CropRecommendationPanel'
import ChatWidget from '../components/ChatWidget'
import SoilProfileCard from '../components/SoilProfileCard'
import useCropRecommendation from '../hooks/useCropRecommendation'

export default function Dashboard(){
  const { current, history, error } = useSensorData()
  const { insight, suitability, recs, loading: aiLoading } = useAIData()
  const { aiResult, status: aiStatus, lastRunAt, error: aiEngineError } = useClientAIEngine(current, { requireAuth: false, writeBack: true, minInterval: 10000 })
  // analytics timeseries (historical + sensor)
  const { data: timeseries, loading: tsLoading } = useAnalyticsTimeseries({ limit: 3000 })
  // append live sensor records into analytics feed
  useAnalyticsAppender({ enabled: true, minInterval: 10000 })
  const [showLoading, setShowLoading] = useState(true)

  // start client-side crop recommendation engine (writes to /AgroSmart/ai/recommendation)
  useCropRecommendation()

  useEffect(()=>{
    const t = setTimeout(()=>setShowLoading(false), 3000)
    return ()=>clearTimeout(t)
  },[])

  return (
    <div className="min-h-screen p-4 md:p-8 bg-slate-50 dark:bg-slate-900 relative">
      {showLoading && <LoadingScreen message={'Connecting to sensors...'}/>}
      <Navbar />
      <main className="mt-6">
        {current?.timestamp && (Date.now() - current.timestamp > 10 * 60 * 1000) && (
          <div className="mb-4 p-3 rounded bg-amber-50 dark:bg-amber-900/30 border border-amber-200 dark:border-amber-700 text-amber-800 dark:text-amber-200">
            Sensor data appears stale (older than 10 minutes). Displaying last known values.
          </div>
        )}
        <section className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <SensorCard title="Temperature" value={current?.temperature ?? '--'} unit="°C" type="temperature" />
          <SensorCard title="Humidity" value={current?.humidity ?? '--'} unit="%" type="humidity" />
          <SensorCard title="Soil Moisture" value={current?.soilMoisture ?? '--'} unit="" type="soil" />
          <SensorCard title="Light Level" value={current?.lightLevel ?? '--'} unit="lux" type="light" />
        </section>

        <section className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 card p-4 rounded-lg shadow">
            <div className="mb-4">
              <SeedHistoricalData />
            </div>
            <ChartsPanel timeseries={timeseries} />
          </div>
          <div className="space-y-4">
            <div className="card p-4 rounded-lg shadow">
              <InsightsPanel current={current} history={history} />
            </div>
            <div className="card p-4 rounded-lg shadow">
              <AlertsPanel current={current} />
            </div>
          </div>
        </section>
        
        {/* AI Insights Section (Client-side Kaggle comparison) */}
        <section className="mt-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-1">
              <SoilProfileCard />
              <div className="mt-4">
                <AIOverviewPanel aiResult={aiResult} status={aiStatus} lastRunAt={lastRunAt} />
              </div>
              <div className="mt-4">
                <HistoricalComparisonChart />
              </div>
            </div>

            <div className="lg:col-span-2 space-y-6">
              <div className="card p-4 rounded-lg shadow">
                <CropSuitabilityPanel suitability={aiResult ? { totals: aiResult.scores, breakdown: Object.fromEntries(Object.keys(aiResult.scores||{}).map(k=>[k,{ why: Object.entries(aiResult.diffs?.[k]||{}).map(([f,v])=> v===null? `${f}: N/A` : `${f} Δ${v}`) }])) } : null} />
              </div>
              <div className="card p-4 rounded-lg shadow">
                <FeatureDiffPanel diffs={aiResult?.diffs?.[aiResult.topCrop]} crop={aiResult?.topCrop} />
              </div>
              <div className="card p-4 rounded-lg shadow">
                <CropRecommendationPanel />
              </div>
            </div>
          </div>
        </section>

        <section className="mt-6">
          <div className="card p-4 rounded-lg shadow">
            <h4 className="font-semibold mb-2">Debug — Raw Firebase Data</h4>
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
          </div>
        </section>
      </main>
      <ChatWidget />
    </div>
  )
}
