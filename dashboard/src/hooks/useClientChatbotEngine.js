import { useEffect, useRef } from 'react'
import { ref, onChildAdded, push } from 'firebase/database'
import { database } from '../firebase'
import useSensorData from './useSensorData'

// Simple client-side chatbot engine that listens for new user messages and replies with rule-based answers.
// Writes assistant messages into the same chat path. Avoids replying to its own messages.

export default function useClientChatbotEngine({ chatPath = 'AgroSmart/chat/messages', enabled = true } = {}){
  const processedRef = useRef(new Set())
  const { current } = useSensorData()

  useEffect(()=>{
    if(!enabled) return
    const listRef = ref(database, chatPath)
    const unsub = onChildAdded(listRef, snap=>{
      const id = snap.key
      const msg = snap.val()
      if(!msg) return
      if(processedRef.current.has(id)) return
      // do not respond to assistant messages
      if(msg.role && msg.role === 'assistant') return
      processedRef.current.add(id)

      // basic keyword responses
      const text = (msg.text || '').toLowerCase()
      let reply = null

      if(/hello|hi|hey|hiya/.test(text)){
        reply = `Hello! I'm AgroBot — I can show current sensor values or explain analytics. Try: "what's the temperature" or "show pump status"` 
      }else if(/temp|temperature/.test(text)){
        const t = current?.temperature ?? null
        reply = t == null ? `I don't have a temperature reading right now.` : `Current temperature is ${t}°C (last updated ${new Date(current.timestamp||Date.now()).toLocaleString()}).`
      }else if(/humid|humidity/.test(text)){
        const h = current?.humidity ?? null
        reply = h == null ? `No humidity available at the moment.` : `Current humidity is ${h}% (timestamp ${new Date(current.timestamp||Date.now()).toLocaleString()}).`
      }else if(/pump|irrigat|water/.test(text)){
        const p = current?.pumpStatus
        if(p == null) reply = `Pump status unavailable.`
        else reply = p ? `Pump is currently ON.` : `Pump is currently OFF.`
      }else if(/help|what can you do/.test(text)){
        reply = `I can answer simple sensor questions and confirm analytics. Ask about temperature, humidity, pump status, or seed historical data.`
      }else{
        // fallback small-talk / unknown
        reply = `Sorry, I didn't understand that. Try asking about temperature, humidity, or pump status.`
      }

      // write reply as assistant (simulate typing delay)
      setTimeout(async ()=>{
        try{
          await push(ref(database, chatPath), {
            role: 'assistant',
            name: 'AgroBot',
            text: reply,
            timestamp: Date.now()
          })
        }catch(e){
          console.error('[useClientChatbotEngine] reply error', e)
        }
      }, 600)
    })

    return ()=>{ try{ unsub() }catch(e){} }
  },[chatPath, enabled, current])
}
