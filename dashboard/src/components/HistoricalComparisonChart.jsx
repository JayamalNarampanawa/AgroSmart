import React from 'react'
import { HISTORICAL_MEANS_3 } from '../ai/historicalPatterns'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Legend } from 'recharts'

function buildData(){
  const crops = Object.keys(HISTORICAL_MEANS_3)
  const metrics = ['temperature','humidity','rainfall','ph']
  return crops.map(c=>({ crop: c, ...HISTORICAL_MEANS_3[c] }))
}

export default function HistoricalComparisonChart(){
  const data = buildData()

  return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">
      <div className="font-semibold mb-2">Historical Means (Kaggle)</div>
      <div style={{ width: '100%', height: 220 }}>
        <ResponsiveContainer>
          <BarChart data={data} margin={{top:8,right:16,left:0,bottom:8}}>
            <XAxis dataKey="crop" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="temperature" fill="#60a5fa" />
            <Bar dataKey="humidity" fill="#34d399" />
            <Bar dataKey="rainfall" fill="#f59e0b" />
            <Bar dataKey="ph" fill="#f97316" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
