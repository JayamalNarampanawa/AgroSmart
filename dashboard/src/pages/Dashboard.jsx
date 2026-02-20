import React, { useEffect, useState } from 'react'
import { AnimatePresence } from 'framer-motion'
import Navbar from '../components/Navbar'
import SensorCard from '../components/SensorCard'
import ChartsPanel from '../components/ChartsPanel'
import InsightsPanel from '../components/InsightsPanel'
import AlertsPanel from '../components/AlertsPanel'
import useSensorData from '../hooks/useSensorData'
import useAnalyticsTimeseries from '../hooks/useAnalyticsTimeseries'
import useAnalyticsAppender from '../hooks/useAnalyticsAppender'
import SeedHistoricalData from '../components/SeedHistoricalData'
import LoadingScreen from '../components/LoadingScreen'
import useAIData from '../hooks/useAIData'
import useClientAIEngine from '../hooks/useClientAIEngine'
import CropSuitabilityPanel from '../components/CropSuitabilityPanel'
import FeatureDiffPanel from '../components/FeatureDiffPanel'
import HistoricalComparisonChart from '../components/HistoricalComparisonChart'
import CropRecommendationPanel from '../components/CropRecommendationPanel'
import CurrentVsIdealChart from '../components/CurrentVsIdealChart'
import ChatWidget from '../components/ChatWidget'
import SoilProfileCard from '../components/SoilProfileCard'
import WeatherPanel from '../components/WeatherPanel'
import FinalResultCard from '../components/FinalResultCard'
import NavSectionBar from '../components/NavSectionBar'
import useCropRecommendation from '../hooks/useCropRecommendation'
import useRecommendationData from '../hooks/useRecommendationData'
import useMlValidation from '../hooks/useMlValidation'
import useWeatherData from '../hooks/useWeatherData'
import Card from '../components/ui/Card'
import SectionHeader from '../components/ui/SectionHeader'
import StatusPill from '../components/ui/StatusPill'
import Background3D from '../components/background/Background3D'
import PerspectiveStage from '../components/layout/PerspectiveStage'
import AnimatedSection from '../components/layout/AnimatedSection'
import Scroll3D from '../components/layout/Scroll3D'

export default function Dashboard() {
  const { current, history, error } = useSensorData()
  const { insight, suitability, recs, loading: aiLoading } = useAIData()
  const { aiResult } = useClientAIEngine(current, { requireAuth: false, writeBack: true, minInterval: 10000 })
  const rec = useRecommendationData()
  const { mlResult, mlError } = useMlValidation(rec)
  const { weather, history: weatherHistory, forecast: weatherForecast } = useWeatherData()
  // analytics timeseries (historical + sensor)
  const { data: timeseries, loading: tsLoading } = useAnalyticsTimeseries({ limit: 3000 })
  // append live sensor records into analytics feed
  useAnalyticsAppender({ enabled: true, minInterval: 10000 })
  const [showLoading, setShowLoading] = useState(true)

  // start client-side crop recommendation engine (writes to /AgroSmart/ai/recommendation)
  useCropRecommendation()

  useEffect(() => {
    const t = setTimeout(() => setShowLoading(false), 5000)
    return () => clearTimeout(t)
  }, [])

  return (
    <>
      {/* Fixed ChatWidget - outside of scrollable content, hidden during loading */}
      {!showLoading && <ChatWidget />}

      <div className="app-shell app-shell-animate">
        <Background3D />
        <PerspectiveStage className="relative z-10 px-4 md:px-8 pt-6 pb-14">
          <AnimatePresence mode="wait">
            {showLoading && <LoadingScreen message={'Connecting to sensors...'} />}
          </AnimatePresence>
          <Navbar />
          <Scroll3D>
            <main className="mt-4 space-y-8">
              <NavSectionBar
                sections={[
                  { id: 'status', label: 'Status' },
                  { id: 'final', label: 'Final Result' },
                  { id: 'recommendations', label: 'Recommendations' },
                  { id: 'weather', label: 'Weather' },
                  { id: 'analytics', label: 'Analytics' }
                ]}
              />
              {current?.timestamp && (Date.now() - current.timestamp > 10 * 60 * 1000) && (
                <AnimatedSection>
                  <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-400/20 text-amber-100">
                    Sensor data appears stale (older than 10 minutes). Displaying last known values.
                  </div>
                </AnimatedSection>
              )}

              {/* PRIORITY 1: Quick Farm Status */}
              <AnimatedSection>
                <section id="status">
                  <SectionHeader
                    eyebrow="Quick Farm Status"
                    title="Current Sensor Readings"
                    subtitle="Real-time environmental data from your farm"
                    right={<StatusPill label="Live" tone="live" />}
                  />
                  <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4 md:gap-5">
                    <SensorCard title="Temperature" value={current?.temperature ?? '--'} unit="°C" type="temperature" />
                    <SensorCard title="Humidity" value={current?.humidity ?? '--'} unit="%" type="humidity" />
                    <SensorCard title="Soil Moisture" value={current?.soilMoisture ?? '--'} unit="" type="soil" />
                    <SensorCard title="Light Level" value={current?.lightLevel ?? '--'} unit="lux" type="light" />
                  </div>
                  <div className="mt-5 grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Card className="p-4">
                      <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Pump Status</div>
                      <div className="mt-2 text-lg font-semibold">
                        {current?.pumpStatus === 1 || current?.pumpStatus === true ? 'ON' : 'OFF'}
                      </div>
                    </Card>
                    <Card className="p-4">
                      <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Last Updated</div>
                      <div className="mt-2 text-sm text-slate-300">
                        {current?.timestamp ? new Date(current.timestamp).toLocaleString() : 'Unknown'}
                      </div>
                    </Card>
                  </div>
                </section>
              </AnimatedSection>

              {/* Alerts & Insights */}
              <AnimatedSection>
                <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <Card className="p-6" hoverable>
                    <AlertsPanel current={current} />
                  </Card>
                  <Card className="p-6" hoverable>
                    <InsightsPanel current={current} history={history} />
                  </Card>
                </section>
              </AnimatedSection>

              {/* FINAL RESULT */}
              <AnimatedSection>
                <section id="final" className="space-y-6">
                  <SectionHeader
                    eyebrow="Decision"
                    title="Final Result (Decision Summary)"
                    subtitle="Farmer-friendly summary of the best crop choice"
                    right={<StatusPill label="Ready" tone="live" />}
                  />
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <FinalResultCard
                      rec={rec}
                      mlResult={mlResult}
                      mlError={mlError}
                      current={current}
                      weather={weather}
                      weatherHistory={weatherHistory}
                    />
                  </Card>
                </section>
              </AnimatedSection>

              {/* Recommendation Details */}
              <AnimatedSection>
                <section id="recommendations" className="space-y-4">
                  <SectionHeader
                    eyebrow="Intelligence"
                    title="Recommendation Details"
                    subtitle="View the primary explainable recommendation and ML validation"
                    right={<StatusPill label={aiLoading ? 'Processing' : 'Ready'} tone={aiLoading ? 'warn' : 'live'} />}
                  />
                  <div className="rounded-2xl border border-white/8 bg-slate-950/40 p-4">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                      <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                        <CropRecommendationPanel mlResult={mlResult} mlError={mlError} />
                      </Card>
                      <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                        <CropSuitabilityPanel suitability={aiResult ? { totals: aiResult.scores, breakdown: Object.fromEntries(Object.keys(aiResult.scores || {}).map(k => [k, { why: Object.entries(aiResult.diffs?.[k] || {}).map(([f, v]) => v === null ? `${f}: N/A` : `${f} delta ${v}`) }])) } : null} />
                      </Card>
                    </div>
                  </div>
                </section>
              </AnimatedSection>

              {/* Weather: Local conditions and rainfall trends */}
              <AnimatedSection>
                <section id="weather">
                  <SectionHeader
                    eyebrow="Weather Insights"
                    title="Rainfall & Conditions"
                    subtitle="OpenWeatherMap snapshot and recent rainfall trend"
                    right={<StatusPill label="Live" tone="live" />}
                  />
                  <Card className="p-0 bg-transparent border-0 shadow-none" hoverable>
                    <WeatherPanel weather={weather} history={weatherHistory} forecast={weatherForecast} current={current} />
                  </Card>
                </section>
              </AnimatedSection>

              {/* PRIORITY 4: Soil Management - Farm Configuration */}
              <AnimatedSection>
                <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <Card className="p-6 holo-panel" hoverable>
                    <SoilProfileCard />
                  </Card>
                  <Card className="p-6 holo-panel">
                    <CurrentVsIdealChart />
                  </Card>
                </section>
              </AnimatedSection>

              {/* PRIORITY 5: Analytics & Historical Data - Detailed Analysis */}
              <AnimatedSection>
                <section id="analytics" className="space-y-6">
                  <SectionHeader
                    eyebrow="Analytics"
                    title="Historical Analysis"
                    subtitle="Trends, patterns, and detailed analytics"
                    right={<StatusPill label={tsLoading ? 'Loading' : 'Updated'} tone={tsLoading ? 'warn' : 'info'} />}
                  />
                  <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] gap-6">
                    <Card className="p-6 lg:p-7">
                      <div className="mb-6">
                        <SeedHistoricalData />
                      </div>
                      <ChartsPanel timeseries={timeseries} />
                    </Card>
                    <div className="space-y-6">
                      <Card className="p-6 holo-panel">
                        <HistoricalComparisonChart />
                      </Card>
                      <Card className="p-6 holo-panel">
                        <FeatureDiffPanel diffs={aiResult?.diffs?.[aiResult.topCrop]} crop={aiResult?.topCrop} />
                      </Card>
                    </div>
                  </div>
                </section>
              </AnimatedSection>

              {/* PRIORITY 6: Debug Information - Developer Tools (Collapsible) */}
              <AnimatedSection>
                <section className="pb-6">
                  <Card className="p-6">
                    <details className="group">
                      <summary className="cursor-pointer font-semibold mb-2 flex items-center gap-2 hover:text-emerald-400 transition-colors">
                        <span className="transform group-open:rotate-90 transition-transform">▶</span>
                        Debug - Raw Firebase Data
                        <span className="text-xs text-slate-500 ml-auto">(Click to expand)</span>
                      </summary>
                      <div className="mt-4 space-y-4">
                        {error && <div className="text-red-600 mb-2">Error: {String(error?.message ?? error)}</div>}
                        <div className="text-sm text-slate-600 dark:text-slate-300">
                          <div className="mb-2"><strong>currentData:</strong></div>
                          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(current, null, 2)}</pre>
                          <div className="mt-4 mb-2"><strong>history (latest 20):</strong></div>
                          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(history.slice(-20), null, 2)}</pre>
                          <div className="mt-4 mb-2"><strong>ai/currentInsight:</strong></div>
                          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(insight, null, 2)}</pre>
                          <div className="mt-4 mb-2"><strong>ai/suitability:</strong></div>
                          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(suitability, null, 2)}</pre>
                          <div className="mt-4 mb-2"><strong>ai/recommendations:</strong></div>
                          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded overflow-auto max-h-40">{JSON.stringify(recs, null, 2)}</pre>
                        </div>
                      </div>
                    </details>
                  </Card>
                </section>
              </AnimatedSection>

              <AnimatedSection>
                <section className="mt-12 flex justify-center">
                  <div className="glass-panel w-full max-w-4xl rounded-2xl border border-cyan-400/20 bg-black/40 px-6 py-8 text-center shadow-[0_0_20px_rgba(34,211,238,0.25)]">
                    <h2 className="text-2xl md:text-3xl font-semibold text-white">Explore AgroSmart 2.0</h2>
                    <p className="mt-3 text-sm md:text-base text-slate-300">
                      Experience the next-generation AR-enhanced Digital Twin with advanced visualization and hybrid AI validation.
                    </p>
                    <div className="mt-6">
                      <a
                        href="https://agrosmart-dashboard.onrender.com/ar"
                        className="inline-flex items-center justify-center px-6 py-3 rounded-xl bg-cyan-500/20 border border-cyan-400/40 text-cyan-100 font-semibold shadow-[0_0_20px_rgba(34,211,238,0.25)] transition-all duration-300 hover:scale-[1.02] hover:border-cyan-400/70 hover:bg-cyan-500/30 focus:outline-none focus:ring-2 focus:ring-cyan-400/60 focus:ring-offset-0"
                      >
                        Launch AgroSmart 2.0 AR
                      </a>
                    </div>
                  </div>
                </section>
              </AnimatedSection>
            </main>
          </Scroll3D>
          <AnimatedSection>
            <footer className="mt-10">
              <div className="glass-panel rounded-2xl px-6 py-6 md:px-8 md:py-8">
                {/* Main Footer Content */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-6">
                  {/* Company Info */}
                  <div className="space-y-3">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full overflow-hidden border-2 border-emerald-400/50 shadow-lg shadow-emerald-500/30">
                        <img src="/icon-round.png" alt="AgroSmart" className="w-full h-full object-cover" />
                      </div>
                      <h3 className="text-lg font-semibold text-white">AgroSmart</h3>
                    </div>
                    <p className="text-sm text-slate-400 leading-relaxed">
                      Smart IoT solutions for modern agriculture. Real-time monitoring and AI-powered insights for your farm.
                    </p>
                    <div className="flex items-center gap-2 text-xs text-emerald-400">
                      <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></span>
                      <span>System Online</span>
                    </div>
                  </div>

                  {/* Quick Links with Icons */}
                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold text-white uppercase tracking-wider flex items-center gap-2">
                      <svg className="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                      </svg>
                      Quick Actions
                    </h4>
                    <ul className="space-y-2">
                      <li>
                        <a href="#dashboard" onClick={(e) => { e.preventDefault(); window.scrollTo({ top: 0, behavior: 'smooth' }); }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-emerald-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-emerald-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-emerald-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                            </svg>
                          </span>
                          <span className="font-medium">Dashboard Home</span>
                        </a>
                      </li>
                      <li>
                        <a href="#analytics" onClick={(e) => { e.preventDefault(); const sections = document.querySelectorAll('section'); const analyticsSection = Array.from(sections).find(s => s.textContent.includes('Historical Analysis') || s.textContent.includes('Analytics')); if (analyticsSection) { analyticsSection.scrollIntoView({ behavior: 'smooth', block: 'start' }); } }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-emerald-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-cyan-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-cyan-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                            </svg>
                          </span>
                          <span className="font-medium">Live Analytics</span>
                        </a>
                      </li>
                      <li>
                        <a href="#ai-insights" onClick={(e) => { e.preventDefault(); const sections = document.querySelectorAll('section'); const aiSection = Array.from(sections).find(s => s.textContent.includes('AI-Powered Recommendations') || s.textContent.includes('Intelligence')); if (aiSection) { aiSection.scrollIntoView({ behavior: 'smooth', block: 'start' }); } }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-emerald-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-purple-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-purple-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                            </svg>
                          </span>
                          <span className="font-medium">AI Insights</span>
                        </a>
                      </li>
                    </ul>
                  </div>

                  {/* Support with Icons */}
                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold text-white uppercase tracking-wider flex items-center gap-2">
                      <svg className="w-4 h-4 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                      Support & Help
                    </h4>
                    <ul className="space-y-2">
                      <li>
                        <a href="#" onClick={(e) => { e.preventDefault(); alert('💬 Help Center\n\n24/7 Support Available!\n\nEmail: jayamalnarampanawa@gmail.com\nPhone: +94 78 466 4490\n\nWe\'re here to help you! 💖'); }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-cyan-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-cyan-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-cyan-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                          </span>
                          <span className="font-medium">Help Center</span>
                          <span className="ml-auto px-2 py-0.5 text-xs bg-cyan-500/20 text-cyan-400 rounded-full">24/7</span>
                        </a>
                      </li>
                      <li>
                        <a href="mailto:jayamalnarampanawa@gmail.com" className="group flex items-center gap-3 text-sm text-slate-400 hover:text-cyan-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-emerald-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-emerald-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                            </svg>
                          </span>
                          <span className="font-medium">Contact Us</span>
                          <span className="ml-auto px-2 py-0.5 text-xs bg-emerald-500/20 text-emerald-400 rounded-full">Fast</span>
                        </a>
                      </li>
                      <li>
                        <a href="#" onClick={(e) => { e.preventDefault(); alert('🔒 Privacy Policy\n\nYour privacy is important to us!\n\nWe protect your data with:\n✓ End-to-end encryption\n✓ Secure cloud storage\n✓ GDPR compliance\n✓ No data sharing\n\nFull policy coming soon! 💖'); }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-cyan-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-blue-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-blue-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                            </svg>
                          </span>
                          <span className="font-medium">Privacy Policy</span>
                        </a>
                      </li>
                      <li>
                        <a href="#" onClick={(e) => { e.preventDefault(); alert('📄 Terms of Service\n\nBy using AgroSmart, you agree to:\n✓ Responsible use of our platform\n✓ Accurate data reporting\n✓ Respect for other users\n✓ Compliance with local laws\n\nFull terms coming soon! ✨'); }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-cyan-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-purple-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-purple-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                          </span>
                          <span className="font-medium">Terms of Service</span>
                        </a>
                      </li>
                      <li>
                        <a href="#" onClick={(e) => { e.preventDefault(); const chatBtn = document.querySelector('.chat-toggle'); if (chatBtn) { chatBtn.click(); alert('💬 Live Chat opened! Ask AgriBot anything! 🤖💚'); } else { alert('💬 Live Chat\n\nChat with our AI assistant AgriBot!\n\nClick the AgriBot button in the bottom-right corner! 🤖✨'); } }} className="group flex items-center gap-3 text-sm text-slate-400 hover:text-cyan-400 transition-all duration-300 hover:translate-x-1">
                          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-800/50 group-hover:bg-pink-500/20 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-pink-500/30">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                            </svg>
                          </span>
                          <span className="font-medium">Live Chat</span>
                          <span className="ml-auto px-2 py-0.5 text-xs bg-pink-500/20 text-pink-400 rounded-full animate-pulse">New</span>
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>

                {/* Divider */}
                <div className="border-t border-white/10 my-6"></div>

                {/* Bottom Footer */}
                <div className="flex flex-col md:flex-row justify-between items-center gap-4">
                  <div className="text-sm text-slate-400 text-center md:text-left">
                    © {new Date().getFullYear()} <span className="text-emerald-400 font-semibold">AgroSmart</span>. All rights reserved to AgroSmart owners.
                  </div>

                  {/* Social Links */}
                  <div className="flex items-center gap-4">
                    <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors" aria-label="Facebook">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                      </svg>
                    </a>
                    <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors" aria-label="Twitter">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" />
                      </svg>
                    </a>
                    <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors" aria-label="LinkedIn">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
                      </svg>
                    </a>
                    <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors" aria-label="GitHub">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
                      </svg>
                    </a>
                  </div>
                </div>

                {/* Additional Info */}
                <div className="mt-6 pt-4 border-t border-white/10">
                  <p className="text-xs text-slate-500 text-center">
                    Powered by IoT Technology • Built with ❤️ for Modern Agriculture
                  </p>
                </div>
              </div>
            </footer>
          </AnimatedSection>
        </PerspectiveStage>
      </div>
    </>
  )
}
