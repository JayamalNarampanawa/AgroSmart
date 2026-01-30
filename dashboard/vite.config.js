import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  // GitHub Pages subpath for this repo
  base: '/agrosmart-dashboard/',
  plugins: [react()],
})
