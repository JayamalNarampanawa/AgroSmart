import React, { useEffect, useState } from 'react'
import Papa from 'papaparse'
import { ref, query, orderByChild, equalTo, get, update, push } from 'firebase/database'
import { database, auth } from '../firebase'
import { onAuthStateChanged } from 'firebase/auth'

const CROPS = ['kidneybeans','mungbean','chickpea']

function parseRowsForCrop(rows, crop){
  const lowerCrop = crop.toLowerCase()
  const matches = rows.filter(r=>{
    const keys = Object.keys(r)
    const labelKey = keys.find(k=>/crop|label|type|name/i.test(k))
    if(labelKey){
      return String(r[labelKey]).toLowerCase().includes(lowerCrop)
    }
    return Object.values(r).some(v=>String(v || '').toLowerCase().includes(lowerCrop))
  })
  if(matches.length === 0) return null
  const numeric = {temperature:[], humidity:[], ph:[], rainfall:[]}
  matches.forEach(m=>{
    const t = Number(m.temperature ?? m.Temperature ?? m.temp ?? m.Temp)
    const h = Number(m.humidity ?? m.Humidity ?? m.hum ?? m.Hum)
    const p = Number(m.ph ?? m.Ph ?? m.PH)
    const r = Number(m.rainfall ?? m.Rainfall ?? m.rain ?? m.Rain)
    if(!Number.isNaN(t)) numeric.temperature.push(t)
    if(!Number.isNaN(h)) numeric.humidity.push(h)
    if(!Number.isNaN(p)) numeric.ph.push(p)
    if(!Number.isNaN(r)) numeric.rainfall.push(r)
  })
  function mean(arr){ return arr.length ? arr.reduce((a,b)=>a+b,0)/arr.length : null }
  return {
    temperature: mean(numeric.temperature),
    humidity: mean(numeric.humidity),
    ph: mean(numeric.ph),
    rainfall: mean(numeric.rainfall)
  }
}

export default function SeedHistoricalData(){
  const [user, setUser] = useState(null)
  const [csvText, setCsvText] = useState(null)
  const [progress, setProgress] = useState(null)
  const [status, setStatus] = useState(null)
  const [force, setForce] = useState(false)
  const [selectedCrop, setSelectedCrop] = useState(CROPS[0])

  useEffect(()=>{
    const unsub = onAuthStateChanged(auth, u=>setUser(u))
    return ()=>unsub()
  },[])

  async function checkAlreadySeeded(){
    const q = query(ref(database, 'AgroSmart/analytics/timeseries'), orderByChild('source'), equalTo('historical'))
    const snap = await get(q)
    return snap.exists()
  }

  async function handleSeed(){
    setStatus(null)
    setProgress('Checking existing historical data...')
    const exists = await checkAlreadySeeded()
    if(exists && !force){
      setStatus('Already seeded')
      setProgress(null)
      return
    }

    let csv = csvText
    if(!csv){
      try{
        const res = await fetch('/src/assets/Crop_recommendation.csv')
        if(res.ok){
          csv = await res.text()
        }
      }catch(e){/* ignore */}
    }

    if(!csv){
      setStatus('No CSV available - please upload Crop_recommendation.csv')
      setProgress(null)
      return
    }

    setProgress('Parsing CSV...')
    const parsed = Papa.parse(csv, {header:true, skipEmptyLines:true})
    const rows = parsed.data || []
    const means = parseRowsForCrop(rows, selectedCrop)
    if(!means){
      setStatus('Could not find crop rows in CSV for '+selectedCrop)
      setProgress(null)
      return
    }

    setProgress('Preparing 90-day baseline...')
    const updates = {}
    const basePath = 'AgroSmart/analytics/timeseries'
    const today = new Date()
    for(let i=0;i<90;i++){
      const d = new Date(today)
      d.setDate(today.getDate() - i)
      d.setHours(9,0,0,0)
      const ts = d.getTime()
      const newRef = push(ref(database, basePath))
      const key = newRef.key
      updates[`/${basePath}/${key}`] = {
        source: 'historical',
        temperature: means.temperature ?? null,
        humidity: means.humidity ?? null,
        rainfall: means.rainfall ?? null,
        ph: means.ph ?? null,
        soilMoisture: null,
        pumpStatus: null,
        timestamp: ts,
        cropBaseline: selectedCrop
      }
    }

    setProgress('Seeding to Firebase...')
    try{
      await update(ref(database, '/'), updates)
      setStatus('Seeded 90 days historical baseline ✅')
      setProgress(null)
    }catch(e){
      console.error('seed error', e)
      setStatus('Seeding failed: '+String(e?.message || e))
      setProgress(null)
    }
  }

  function handleFileUpload(e){
    const f = e.target.files?.[0]
    if(!f) return
    const reader = new FileReader()
    reader.onload = ()=>{
      setCsvText(String(reader.result))
      setStatus('CSV loaded')
    }
    reader.readAsText(f)
  }

  if(!user) return null

  return (
    <div className="rounded-xl border border-dashed border-white/12 bg-white/2 p-4">
      <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Admin</div>
          <h4 className="font-semibold">Seed Historical Data</h4>
        </div>
        <div className="text-xs text-slate-400">Authenticated only</div>
      </div>
      <div className="text-sm text-slate-400 mb-4">Simulate past 90 days from Kaggle dataset means for selected crop.</div>
      <div className="flex flex-wrap gap-3 items-center mb-4">
        <label className="text-xs uppercase tracking-widest text-slate-400">Crop</label>
        <select value={selectedCrop} onChange={e=>setSelectedCrop(e.target.value)} className="px-3 py-2 rounded-xl bg-slate-900/60 border border-white/10 text-sm text-slate-100">
          {CROPS.map(c=>(<option key={c} value={c}>{c}</option>))}
        </select>
        <label className="text-xs uppercase tracking-widest text-slate-400">CSV upload</label>
        <input type="file" accept=".csv" onChange={handleFileUpload} className="text-xs text-slate-300" />
      </div>

      <div className="flex items-center gap-3">
        <button className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-semibold hover:bg-indigo-500 transition-colors" onClick={handleSeed}>Seed historical data</button>
        <label className="text-xs flex items-center gap-2 text-slate-300"><input type="checkbox" checked={force} onChange={e=>setForce(e.target.checked)} /> Force reseed</label>
      </div>
      {progress && <div className="mt-3 text-sm text-slate-300">{progress}</div>}
      {status && <div className="mt-3 text-sm font-medium">{status}</div>}
    </div>
  )
}
