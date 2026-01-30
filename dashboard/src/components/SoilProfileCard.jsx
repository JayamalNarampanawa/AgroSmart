import React, { useEffect, useState } from 'react'
import { ref, onValue, update, serverTimestamp } from 'firebase/database'
import { database } from '../firebase'

export default function SoilProfileCard(){
  const [profile, setProfile] = useState({ N:0,P:0,K:0,ph:6.5,phIsDefault:true })
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)

  useEffect(()=>{
    const r = ref(database, 'AgroSmart/farmProfile')
    const unsub = onValue(r, snap=>{
      const v = snap.val() || { N:0,P:0,K:0,ph:6.5,phIsDefault:true }
      setProfile(v)
    })
    return ()=>{ try{ unsub() }catch(e){} }
  },[])

  function handleChange(e){
    const { name, value } = e.target
    setProfile(prev => ({ ...prev, [name]: value }))
    setEditing(true)
  }

  async function save(){
    setSaving(true)
    try{
      const N = Number(profile.N)
      const P = Number(profile.P)
      const K = Number(profile.K)
      const ph = (profile.ph === '' || profile.ph == null) ? 6.5 : Number(profile.ph)

      if(Number.isNaN(N) || Number.isNaN(P) || Number.isNaN(K) || Number.isNaN(ph)){
        alert('Please enter valid numeric values for N, P, K and pH.')
        setSaving(false)
        return
      }
      if(ph < 0 || ph > 14){
        alert('pH must be between 0 and 14.')
        setSaving(false)
        return
      }

      const phIsDefault = ph === 6.5
      await update(ref(database, 'AgroSmart/farmProfile'), { N, P, K, ph, phIsDefault, updatedAt: serverTimestamp() })
      setEditing(false)
    }catch(e){
      console.error('save farm profile', e)
    }finally{ setSaving(false) }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Soil Profile</div>
          <div className="font-semibold">NPK and pH</div>
        </div>
        <div className="text-xs px-2.5 py-1 rounded-full bg-white/6 border border-white/10">
          pH: {profile.phIsDefault ? 'Default' : 'Updated'}
        </div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="text-xs text-slate-400">Nitrogen (N)</label>
          <input name="N" value={profile.N ?? ''} onChange={handleChange} className="w-full mt-1 px-3 py-2 rounded-xl bg-slate-900/60 border border-white/10 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/40 focus:border-sky-400/40" />
        </div>
        <div>
          <label className="text-xs text-slate-400">Phosphorus (P)</label>
          <input name="P" value={profile.P ?? ''} onChange={handleChange} className="w-full mt-1 px-3 py-2 rounded-xl bg-slate-900/60 border border-white/10 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/40 focus:border-sky-400/40" />
        </div>
        <div>
          <label className="text-xs text-slate-400">Potassium (K)</label>
          <input name="K" value={profile.K ?? ''} onChange={handleChange} className="w-full mt-1 px-3 py-2 rounded-xl bg-slate-900/60 border border-white/10 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/40 focus:border-sky-400/40" />
        </div>
        <div>
          <label className="text-xs text-slate-400">pH</label>
          <input name="ph" value={profile.ph ?? ''} onChange={handleChange} className="w-full mt-1 px-3 py-2 rounded-xl bg-slate-900/60 border border-white/10 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/40 focus:border-sky-400/40" />
        </div>
      </div>
      <div className="mt-4 flex items-center gap-3">
        <button onClick={save} disabled={!editing || saving} className="px-4 py-2 rounded-xl bg-sky-500 text-white font-semibold disabled:opacity-60 transition-colors hover:bg-sky-400">Save</button>
        <button onClick={()=>setEditing(false)} disabled={saving} className="px-4 py-2 rounded-xl bg-white/8 text-slate-200 border border-white/10 transition-colors hover:bg-white/12">Cancel</button>
      </div>
    </div>
  )
}
