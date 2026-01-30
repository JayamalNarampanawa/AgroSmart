import React, { useState, useEffect, useRef } from 'react'
import useChat from '../hooks/useChat'
import useClientChatbotEngine from '../hooks/useClientChatbotEngine'
import { auth } from '../firebase'
import { onAuthStateChanged } from 'firebase/auth'
import chatbotUrl from '../assets/chatbot.jpg'

export default function ChatWidget({ position = 'bottom-right' }){
  const { messages, loading, sendMessage } = useChat()
  useClientChatbotEngine({ enabled: true })
  const [open, setOpen] = useState(false)
  const [text, setText] = useState('')
  const [user, setUser] = useState(null)
  const listRef = useRef(null)

  useEffect(()=>{
    const unsub = onAuthStateChanged(auth, u=>setUser(u))
    return ()=>unsub()
  },[])

  useEffect(()=>{
    if(open && listRef.current) listRef.current.scrollTop = listRef.current.scrollHeight
  },[open, messages])

  async function handleSend(){
    if(!text.trim()) return
    const payload = {
      role: 'user',
      uid: user?.uid ?? null,
      name: user?.email ? user.email.split('@')[0] : 'Guest',
      text: text.trim(),
      timestamp: Date.now()
    }
    setText('')
    await sendMessage(payload)
  }

  return (
    <div className={`fixed z-40 ${position === 'bottom-right' ? 'bottom-6 right-6' : 'bottom-6 left-6'}`}>
      <div className="w-80 max-w-xs">
        <div className="flex justify-end">
          <button
            onClick={()=>setOpen(o=>!o)}
            className="group flex items-center gap-2 rounded-full bg-emerald-600 text-white px-3 py-2 shadow transition-all hover:bg-emerald-500"
            aria-label={open ? 'Close chat' : 'Open AgriBot'}
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-full overflow-hidden ring-2 ring-white/20">
              <img src={chatbotUrl} alt="AgriBot" className="h-full w-full object-cover" />
            </span>
            <span className="text-sm font-semibold tracking-wide">{open ? 'Close' : 'AgriBot'}</span>
          </button>
        </div>
        {open && (
          <div className="mt-2 bg-white dark:bg-slate-800 rounded-lg shadow-lg overflow-hidden flex flex-col" style={{height:360}}>
            <div className="px-3 py-2 border-b dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-sm">AgriBot — Ask about sensors or analytics</div>
            <div ref={listRef} className="flex-1 p-3 overflow-auto space-y-2">
              {loading && <div className="text-sm text-slate-400">Loading messages...</div>}
              {messages.map(m=> (
                <div key={m.id} className={`flex ${m.role === 'assistant' ? 'justify-start' : 'justify-end'}`}>
                  <div className={`${m.role === 'assistant' ? 'bg-slate-100 dark:bg-slate-700 text-slate-900' : 'bg-emerald-600 text-white'} px-3 py-2 rounded-lg max-w-[75%]`}> 
                    <div className="text-xs font-medium mb-1">{m.role === 'assistant' ? (m.name || 'AgriBot') : (m.name || 'You')}</div>
                    <div className="text-sm">{m.text}</div>
                    <div className="text-[10px] text-slate-400 mt-1 text-right">{m.timestamp ? new Date(m.timestamp).toLocaleString() : ''}</div>
                  </div>
                </div>
              ))}
            </div>
            <div className="p-2 border-t dark:border-slate-700 bg-white dark:bg-slate-800">
              <div className="flex gap-2">
                <input value={text} onChange={e=>setText(e.target.value)} onKeyDown={e=>{ if(e.key==='Enter') handleSend() }} placeholder="Type a message" className="flex-1 px-3 py-2 rounded border dark:border-slate-700 bg-white/0" />
                <button onClick={handleSend} className="px-3 py-2 bg-emerald-600 text-white rounded">Send</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
