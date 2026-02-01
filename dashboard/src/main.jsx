import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import { MotionPreferencesProvider } from './hooks/useMotionPreferences.jsx'
import './styles/index.css'

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <MotionPreferencesProvider>
        <App />
      </MotionPreferencesProvider>
    </BrowserRouter>
  </React.StrictMode>
)

// persistent theme: respect localStorage 'theme' or default to dark
try{
  const stored = localStorage.getItem('theme')
  if(stored === 'light') document.documentElement.classList.remove('dark')
  else document.documentElement.classList.add('dark')
}catch(e){
  try{ document.documentElement.classList.add('dark') }catch(e){}
}
