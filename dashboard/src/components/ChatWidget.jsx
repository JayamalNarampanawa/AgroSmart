import React, { useState, useEffect, useRef } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
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
    <div 
      className="fixed bottom-6 right-4 z-[9999]"
      style={{ 
        position: 'fixed',
        bottom: '24px',
        right: '16px', // Closer to edge but not cut off
        zIndex: 9999
      }}
    >
      <div className="w-80 max-w-xs"> {/* Back to smaller container */}
        <div className="flex justify-end">
          <button
            onClick={()=>setOpen(o=>!o)}
            className="chat-toggle group relative"
            aria-label={open ? 'Close chat' : 'Open AgriBot'}
          >
            <span className="chat-avatar relative">
              <img src={chatbotUrl} alt="AgriBot" className="chat-avatar-img" />
              {/* Online indicator */}
              <span className="absolute -top-1 -right-1 w-4 h-4 bg-green-500 border-2 border-white rounded-full animate-pulse"></span>
            </span>
            <span className="text-sm font-semibold tracking-wide">
              {open ? 'Close' : 'AgriBot'}
            </span>
          </button>
        </div>
        <AnimatePresence>
          {open && (
          <motion.div
            className="chat-panel mt-3 shadow-2xl"
            style={{
              height: 450, 
              width: 350,
              position: 'absolute',
              right: 0, // Align to right edge of container
              bottom: '70px' // Position above the button
            }}
            initial={{ opacity: 0, y: 20, scale: 0.95, filter: 'blur(10px)' }}
            animate={{ opacity: 1, y: 0, scale: 1, filter: 'blur(0px)' }}
            exit={{ opacity: 0, y: 15, scale: 0.95, filter: 'blur(5px)' }}
            transition={{ duration: 0.4, ease: [0.23, 1, 0.32, 1] }}
          >
            {/* Header */}
            <div className="px-4 py-3 border-b border-white/10 bg-gradient-to-r from-emerald-600/20 to-cyan-600/20 backdrop-blur-sm">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full overflow-hidden border-2 border-emerald-400/50">
                    <img src={chatbotUrl} alt="AgriBot" className="w-full h-full object-cover" />
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-white">AgriBot</div>
                    <div className="text-xs text-emerald-300 flex items-center gap-1">
                      <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
                      Online
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => setOpen(false)}
                  className="text-white/70 hover:text-white transition-colors p-1 rounded-full hover:bg-white/10"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>

            {/* Messages */}
            <div ref={listRef} className="flex-1 p-4 overflow-auto space-y-3 bg-gradient-to-b from-slate-900/50 to-slate-800/50">
              {loading && (
                <div className="flex items-center gap-2 text-sm text-slate-400">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-emerald-400 rounded-full animate-bounce"></div>
                    <div className="w-2 h-2 bg-emerald-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                    <div className="w-2 h-2 bg-emerald-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                  </div>
                  AgriBot is thinking...
                </div>
              )}
              
              {messages.length === 0 && !loading && (
                <div className="text-center py-8">
                  <div className="text-slate-400 text-sm mb-2">👋 Welcome to AgriBot!</div>
                  <div className="text-slate-500 text-xs">Ask me about your sensors, crops, or analytics</div>
                </div>
              )}

              {messages.map((m, index) => (
                <motion.div 
                  key={m.id} 
                  className={`flex ${m.role === 'assistant' ? 'justify-start' : 'justify-end'}`}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <div className={`${
                    m.role === 'assistant' 
                      ? 'bg-gradient-to-r from-slate-700 to-slate-600 text-white border border-slate-600/50' 
                      : 'bg-gradient-to-r from-emerald-600 to-emerald-500 text-white'
                  } px-4 py-3 rounded-2xl max-w-[85%] shadow-lg backdrop-blur-sm`}> 
                    <div className="text-xs font-medium mb-1 opacity-80">
                      {m.role === 'assistant' ? '🤖 AgriBot' : '👤 You'}
                    </div>
                    <div className="text-sm leading-relaxed">{m.text}</div>
                    <div className="text-[10px] opacity-60 mt-2 text-right">
                      {m.timestamp ? new Date(m.timestamp).toLocaleTimeString() : ''}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>

            {/* Input */}
            <div className="p-4 border-t border-white/10 bg-gradient-to-r from-slate-800/80 to-slate-700/80 backdrop-blur-sm">
              <div className="flex gap-3">
                <input 
                  value={text} 
                  onChange={e=>setText(e.target.value)} 
                  onKeyDown={e=>{ if(e.key==='Enter' && !e.shiftKey) { e.preventDefault(); handleSend() } }} 
                  placeholder="Ask about sensors, crops, weather..." 
                  className="flex-1 px-4 py-3 rounded-xl border border-white/20 bg-white/10 text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all backdrop-blur-sm" 
                />
                <motion.button 
                  onClick={handleSend} 
                  disabled={!text.trim()}
                  className="px-4 py-3 bg-gradient-to-r from-emerald-600 to-emerald-500 text-white rounded-xl font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:from-emerald-500 hover:to-emerald-400 transition-all shadow-lg"
                  whileHover={{ scale: text.trim() ? 1.05 : 1 }}
                  whileTap={{ scale: text.trim() ? 0.95 : 1 }}
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                  </svg>
                </motion.button>
              </div>
              <div className="text-xs text-slate-400 mt-2 text-center">
                Press Enter to send • Shift+Enter for new line
              </div>
            </div>
          </motion.div>
        )}
        </AnimatePresence>
      </div>
    </div>
  )
}
