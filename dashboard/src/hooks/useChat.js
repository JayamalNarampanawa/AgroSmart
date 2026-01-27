import { useEffect, useState, useCallback } from 'react'
import { ref, onValue, push } from 'firebase/database'
import { database } from '../firebase'

export default function useChat({ path = 'AgroSmart/chat/messages', limit = 500 } = {}){
  const [messages, setMessages] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(()=>{
    setLoading(true)
    const listRef = ref(database, path)
    const unsub = onValue(listRef, snap=>{
      const val = snap.val() || {}
      const arr = Object.entries(val).map(([k,v])=>({ id:k, ...v }))
      arr.sort((a,b)=> (a.timestamp||0) - (b.timestamp||0))
      const limited = limit ? arr.slice(-limit) : arr
      setMessages(limited)
      setLoading(false)
    }, err=>{
      console.error('[useChat] onValue error', err)
      setLoading(false)
    })

    return ()=>{ try{ unsub() }catch(e){} }
  },[path, limit])

  const sendMessage = useCallback(async (msg)=>{
    try{
      const listRef = ref(database, path)
      await push(listRef, msg)
    }catch(e){
      console.error('[useChat] sendMessage error', e)
    }
  },[path])

  return { messages, loading, sendMessage }
}
