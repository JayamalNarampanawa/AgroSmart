import React from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area, BarChart, Bar } from 'recharts'

function timeLabel(ts){
  if(!ts) return ''
  const d = new Date(ts)
  return d.toLocaleTimeString()
}

export default function ChartsPanel({ history }){
  const data = history.map(h=>({
    ...h,
    time: timeLabel(h.timestamp)
  }))

  return (
    <div className="space-y-6">
      <div className="mb-2 flex items-center justify-between">
        <div className="text-xl font-semibold">Analytics</div>
        <div className="text-sm text-slate-400">Last {data.length} samples</div>
      </div>
      <div>
        <h3 className="text-lg font-semibold mb-2">Temperature (°C)</h3>
        <div style={{height:220}}>
          <ResponsiveContainer>
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="temperature" stroke="#ef4444" dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-semibold mb-2">Soil Moisture</h3>
        <div style={{height:220}}>
          <ResponsiveContainer>
            <AreaChart data={data}>
              <defs>
                <linearGradient id="soilGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0.1}/>
                </linearGradient>
              </defs>
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Area type="monotone" dataKey="soilMoisture" stroke="#10b981" fillOpacity={1} fill="url(#soilGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-semibold mb-2">Irrigation Activity (Pump ON count)</h3>
        <div style={{height:180}}>
          <ResponsiveContainer>
            <BarChart data={data}>
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="pumpStatus" fill="#0ea5e9" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
