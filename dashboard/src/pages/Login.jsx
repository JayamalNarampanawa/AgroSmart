import React, { useState } from 'react'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '../firebase'
import { useNavigate } from 'react-router-dom'

export default function Login(){
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const navigate = useNavigate()

  const submit = async (e)=>{
    e.preventDefault()
    setError(null)
    try{
      await signInWithEmailAndPassword(auth, email, password)
      navigate('/')
    }catch(err){
      setError(err.message)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900">
      <div className="w-full max-w-md p-8 card rounded-lg shadow">
        <h1 className="text-2xl font-semibold mb-4">AgroSmart Dashboard — Login</h1>
        <form onSubmit={submit} className="space-y-4">
          <div>
            <label className="block text-sm">Email</label>
            <input className="w-full border rounded px-3 py-2" value={email} onChange={e=>setEmail(e.target.value)} />
          </div>
          <div>
            <label className="block text-sm">Password</label>
            <input type="password" className="w-full border rounded px-3 py-2" value={password} onChange={e=>setPassword(e.target.value)} />
          </div>
          {error && <div className="text-red-600">{error}</div>}
          <button className="w-full py-2 bg-agBlue text-white rounded">Sign in</button>
        </form>
      </div>
    </div>
  )
}
