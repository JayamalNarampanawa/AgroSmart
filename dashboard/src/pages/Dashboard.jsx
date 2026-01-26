import React, { useEffect, useState } from 'react'
import Navbar from '../components/Navbar'
import SensorCard from '../components/SensorCard'
import ChartsPanel from '../components/ChartsPanel'
import InsightsPanel from '../components/InsightsPanel'
import AlertsPanel from '../components/AlertsPanel'
import useSensorData from '../hooks/useSensorData'
import LoadingScreen from '../components/LoadingScreen'

export default function Dashboard(){
  const { current, history, error, isReady } = useSensorData()
  const [showLoading, setShowLoading] = useState(true)

  useEffect(()=>{
    const t = setTimeout(()=>setShowLoading(false), 3000)
    return ()=>clearTimeout(t)
  },[])

  return (
    <div className="min-h-screen p-4 md:p-8 bg-slate-50 dark:bg-slate-900 relative">
      {showLoading && <LoadingScreen message={'Connecting to sensors...'}/>}
      <Navbar />
      <main className="mt-6">
        <section className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <SensorCard title="Temperature" value={current?.temperature ?? '--'} unit="°C" type="temperature" />
          <SensorCard title="Humidity" value={current?.humidity ?? '--'} unit="%" type="humidity" />
          <SensorCard title="Soil Moisture" value={current?.soilMoisture ?? '--'} unit="" type="soil" />
          <SensorCard title="Light Level" value={current?.lightLevel ?? '--'} unit="lux" type="light" />
        </section>

        <section className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 card p-4 rounded-lg shadow">
            <ChartsPanel history={history} />
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
        
        <section className="mt-6">
          <div className="card p-4 rounded-lg shadow">
            <h4 className="font-semibold mb-2">Debug — Raw Firebase Data</h4>
            {error && <div className="text-red-600 mb-2">Error: {String(error?.message ?? error)}</div>}
            <div className="text-sm text-slate-600 dark:text-slate-300">
              <div className="mb-2"><strong>currentData:</strong></div>
              <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(current, null, 2)}</pre>
              <div className="mt-2 mb-2"><strong>history (latest 20):</strong></div>
              <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto">{JSON.stringify(history.slice(-20), null, 2)}</pre>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
