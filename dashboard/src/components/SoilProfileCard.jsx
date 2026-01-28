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
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">
      <div className="flex items-center justify-between mb-3">
        <div className="font-semibold">Soil Profile</div>
        <div className="text-xs px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-700">pH: {profile.phIsDefault ? 'Default' : 'Updated'}</div>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <div>
          <label className="text-xs">Nitrogen (N)</label>
          <input name="N" value={profile.N ?? ''} onChange={handleChange} className="w-full mt-1 p-2 rounded border" />
        </div>
        <div>
          <label className="text-xs">Phosphorus (P)</label>
          <input name="P" value={profile.P ?? ''} onChange={handleChange} className="w-full mt-1 p-2 rounded border" />
        </div>
        <div>
          <label className="text-xs">Potassium (K)</label>
          <input name="K" value={profile.K ?? ''} onChange={handleChange} className="w-full mt-1 p-2 rounded border" />
        </div>
        <div>
          <label className="text-xs">pH</label>
          <input name="ph" value={profile.ph ?? ''} onChange={handleChange} className="w-full mt-1 p-2 rounded border" />
        </div>
      </div>
      <div className="mt-3 flex items-center gap-2">
        <button onClick={save} disabled={!editing || saving} className="px-3 py-2 bg-indigo-600 text-white rounded disabled:opacity-60">Save</button>
        <button onClick={()=>setEditing(false)} disabled={saving} className="px-3 py-2 bg-slate-200 rounded">Cancel</button>
      </div>
    </div>
  )
}
