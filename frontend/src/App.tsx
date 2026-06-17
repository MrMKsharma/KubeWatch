import { useState, useEffect } from 'react'
import { 
  getHealth, 
  getStatus, 
  getMetrics, 
  getNodes, 
  getAlerts, 
  type HealthResponse, 
  type StatusResponse,
  type MetricsResponse,
  type NodesResponse,
  type AlertsResponse
} from './api'
import { demoApi } from './demo-api'

// Toggle this to use demo mode (NO backend needed!)
const USE_DEMO_MODE = true

// --- Color Palette (Modern & Professional) ---
const COLORS = {
  primary: '#6366f1',        // Indigo 500
  primaryLight: '#818cf8',   // Indigo 400
  secondary: '#06b6d4',      // Cyan 500
  accent: '#f472b6',         // Pink 400
  success: '#10b981',        // Green 500
  warning: '#f59e0b',        // Amber 500
  danger: '#ef4444',         // Red 500
  background: '#0f172a',     // Slate 900
  surface: '#1e293b',        // Slate 800
  surfaceHover: '#334155',   // Slate 700
  border: '#475569',         // Slate 600
  text: '#f8fafc',           // Slate 50
  textSecondary: '#94a3b8'   // Slate 400
}

function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null)
  const [status, setStatus] = useState<StatusResponse | null>(null)
  const [metrics, setMetrics] = useState<MetricsResponse | null>(null)
  const [nodes, setNodes] = useState<NodesResponse | null>(null)
  const [alerts, setAlerts] = useState<AlertsResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<string>("")

  // Fetch all data
  const fetchAllData = async () => {
    try {
      const api = USE_DEMO_MODE ? demoApi : { getHealth, getStatus, getMetrics, getNodes, getAlerts }
      const [healthData, statusData, metricsData, nodesData, alertsData] = await Promise.all([
        api.getHealth(),
        api.getStatus(),
        api.getMetrics(),
        api.getNodes(),
        api.getAlerts()
      ])
      setHealth(healthData)
      setStatus(statusData)
      setMetrics(metricsData)
      setNodes(nodesData)
      setAlerts(alertsData)
      setLastUpdated(new Date().toLocaleTimeString())
    } catch (err) {
      setError('Failed to load data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAllData()
  }, [])

  // Refresh data every 5 seconds for real-time demo
  useEffect(() => {
    const interval = setInterval(() => {
      fetchAllData()
    }, 5000)
    
    return () => clearInterval(interval)
  }, [])

  // --- SVG Segmented Donut Chart Component ---
  const DonutChart = ({ 
    value, 
    maxValue = 100, 
    color, 
    colors,
    size = 180
  }: { 
    value: number, 
    maxValue?: number, 
    color?: string, 
    colors?: string[],
    size?: number
  }) => {
    const percentage = Math.min(value / maxValue, 1)
    const totalSegments = 30
    const filledSegments = Math.round(percentage * totalSegments)
    
    const radius = (size - 60) / 2
    const strokeWidth = 24
    const gapAngle = 2 * Math.PI / totalSegments * 0.3
    const segmentAngle = 2 * Math.PI / totalSegments - gapAngle
    
    const startAngle = -Math.PI / 2 // Start at top
    
    const getGradientColor = (index: number, total: number) => {
      if (!colors || colors.length < 2) return color || '#6366f1'
      
      const t = index / (total - 1)
      const c1 = colors[0]
      const c2 = colors[1]
      
      // Parse colors from hex to RGB
      const parseColor = (hex: string) => {
        const h = hex.replace('#', '')
        return {
          r: parseInt(h.substring(0, 2), 16),
          g: parseInt(h.substring(2, 4), 16),
          b: parseInt(h.substring(4, 6), 16)
        }
      }
      
      const rgb1 = parseColor(c1)
      const rgb2 = parseColor(c2)
      
      const r = Math.round(rgb1.r + (rgb2.r - rgb1.r) * t)
      const g = Math.round(rgb1.g + (rgb2.g - rgb1.g) * t)
      const b = Math.round(rgb1.b + (rgb2.b - rgb1.b) * t)
      
      return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
    }
    
    const renderSegments = () => {
      const segments = []
      
      for (let i = 0; i < totalSegments; i++) {
        const isFilled = i < filledSegments
        const angle = startAngle + i * (segmentAngle + gapAngle)
        
        const x1 = size / 2 + radius * Math.cos(angle)
        const y1 = size / 2 + radius * Math.sin(angle)
        const x2 = size / 2 + radius * Math.cos(angle + segmentAngle)
        const y2 = size / 2 + radius * Math.sin(angle + segmentAngle)
        
        const largeArcFlag = segmentAngle > Math.PI ? 1 : 0
        
        const pathData = [
          `M ${x1} ${y1}`,
          `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2}`
        ].join(' ')
        
        const fillColor = isFilled ? 
          (colors ? getGradientColor(i, filledSegments) : (color || '#6366f1')) : 
          (colors ? `${colors[0]}25` : (color ? `${color}25` : '#6366f125'))
        
        segments.push(
          <path
            key={i}
            d={pathData}
            fill="none"
            stroke={fillColor}
            strokeWidth={strokeWidth}
            strokeLinecap="round"
          />
        )
      }
      
      return segments
    }
    
    return (
      <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          {renderSegments()}
        </svg>
      </div>
    )
  }

  // --- Styles ---
  const styles = {
    container: {
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column' as const,
      fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      background: `linear-gradient(180deg, ${COLORS.background} 0%, #020617 100%)`,
      color: COLORS.text
    },

    header: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: '24px 40px',
      background: `linear-gradient(180deg, ${COLORS.surface} 0%, transparent 100%)`,
      backdropFilter: 'blur(12px)',
      borderBottom: `1px solid ${COLORS.border}`,
      position: 'sticky' as const,
      top: 0,
      zIndex: 100
    },

    logo: {
      display: 'flex',
      alignItems: 'center',
      gap: '12px'
    },

    logoIcon: {
      width: '44px',
      height: '44px',
      background: `linear-gradient(135deg, ${COLORS.primary} 0%, ${COLORS.secondary} 100%)`,
      borderRadius: '12px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    },

    title: {
      fontSize: '24px',
      fontWeight: 700,
      margin: 0,
      letterSpacing: '-0.02em'
    },

    headerRight: {
      display: 'flex',
      alignItems: 'center',
      gap: '16px'
    },

    statusBadge: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      padding: '10px 20px',
      background: 'rgba(16, 185, 129, 0.1)',
      borderRadius: '9999px',
      border: '1px solid rgba(16, 185, 129, 0.3)'
    },

    statusDot: {
      width: '8px',
      height: '8px',
      background: COLORS.success,
      borderRadius: '50%',
      animation: 'pulse 2s infinite'
    },

    statusText: {
      fontSize: '14px',
      fontWeight: 600,
      color: COLORS.success
    },

    main: {
      flex: 1,
      padding: '32px 40px',
      maxWidth: '1600px',
      margin: '0 auto',
      width: '100%',
      boxSizing: 'border-box' as const
    },

    loadingContainer: {
      display: 'flex',
      flexDirection: 'column' as const,
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '50vh'
    },

    spinner: {
      width: '48px',
      height: '48px',
      border: '3px solid rgba(99, 102, 241, 0.2)',
      borderTopColor: COLORS.primary,
      borderRadius: '50%',
      animation: 'spin 1s linear infinite'
    },

    loadingText: {
      fontSize: '16px',
      color: COLORS.textSecondary,
      marginTop: '16px'
    },

    errorCard: {
      display: 'flex',
      flexDirection: 'column' as const,
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '50vh',
      textAlign: 'center' as const
    },

    errorTitle: {
      fontSize: '24px',
      margin: '0 0 8px 0',
      color: COLORS.text
    },

    errorText: {
      fontSize: '16px',
      color: COLORS.textSecondary,
      margin: 0
    },

    dashboard: {
      display: 'flex',
      flexDirection: 'column' as const,
      gap: '24px'
    },

    statsGrid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
      gap: '20px'
    },

    statCard: {
      display: 'flex',
      alignItems: 'flex-start',
      gap: '16px',
      padding: '24px',
      background: COLORS.surface,
      borderRadius: '16px',
      border: `1px solid ${COLORS.border}`,
      transition: 'all 0.3s ease',
      cursor: 'default',
      '&:hover': {
        transform: 'translateY(-2px)',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3)',
        borderColor: COLORS.primaryLight
      }
    },

    statIcon: {
      width: '52px',
      height: '52px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: '14px',
      flexShrink: 0
    },

    statContent: {
      flex: 1
    },

    statLabel: {
      fontSize: '13px',
      color: COLORS.textSecondary,
      margin: 0,
      textTransform: 'uppercase' as const,
      letterSpacing: '0.05em',
      fontWeight: 500
    },

    statValue: {
      fontSize: '28px',
      fontWeight: 700,
      margin: '4px 0 0 0',
      color: COLORS.text
    },

    chartsGrid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
      gap: '20px'
    },

    chartCard: {
      background: COLORS.surface,
      borderRadius: '16px',
      padding: '24px',
      border: `1px solid ${COLORS.border}`
    },

    chartHeader: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
      marginBottom: '8px'
    },

    chartTitle: {
      fontSize: '16px',
      fontWeight: 600,
      margin: 0,
      color: COLORS.text
    },

    chartValue: {
      fontSize: '32px',
      fontWeight: 700,
      margin: '8px 0 0 0'
    },

    section: {
      background: COLORS.surface,
      borderRadius: '16px',
      padding: '28px',
      border: `1px solid ${COLORS.border}`
    },

    sectionTitle: {
      fontSize: '18px',
      fontWeight: 600,
      margin: '0 0 20px 0',
      color: COLORS.text
    },

    nodesList: {
      display: 'flex',
      flexDirection: 'column' as const,
      gap: '12px'
    },

    nodeCard: {
      display: 'flex',
      alignItems: 'center',
      gap: '16px',
      padding: '16px 20px',
      background: `${COLORS.surfaceHover}30`,
      borderRadius: '12px',
      border: `1px solid ${COLORS.border}`,
      transition: 'all 0.2s ease'
    },

    nodeIcon: {
      width: '40px',
      height: '40px',
      background: 'rgba(99, 102, 241, 0.15)',
      borderRadius: '10px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    },

    nodeInfo: {
      flex: 1
    },

    nodeName: {
      fontSize: '15px',
      fontWeight: 600,
      margin: '0 0 2px 0',
      color: COLORS.text
    },

    nodeMeta: {
      fontSize: '13px',
      margin: 0,
      color: COLORS.textSecondary
    },

    nodeStats: {
      display: 'flex',
      flexDirection: 'column' as const,
      alignItems: 'flex-end',
      gap: '2px'
    },

    nodeStat: {
      fontSize: '13px',
      fontWeight: 600
    },

    alertsList: {
      display: 'flex',
      flexDirection: 'column' as const,
      gap: '12px'
    },

    alertCard: {
      display: 'flex',
      alignItems: 'flex-start',
      gap: '14px',
      padding: '16px 20px',
      background: `${COLORS.surfaceHover}30`,
      borderRadius: '12px',
      border: `1px solid ${COLORS.border}`,
      transition: 'all 0.2s ease'
    },

    alertDot: {
      width: '12px',
      height: '12px',
      borderRadius: '50%',
      flexShrink: 0,
      marginTop: '4px'
    },

    alertContent: {
      flex: 1
    },

    alertMessage: {
      fontSize: '14px',
      fontWeight: 500,
      margin: '0 0 4px 0',
      color: COLORS.text
    },

    alertTime: {
      fontSize: '12px',
      margin: 0,
      color: COLORS.textSecondary
    },

    servicesGrid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
      gap: '12px'
    },

    serviceCard: {
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      padding: '14px 18px',
      background: `${COLORS.surfaceHover}30`,
      borderRadius: '12px',
      border: `1px solid ${COLORS.border}`,
      transition: 'all 0.2s ease'
    },

    serviceIcon: {
      flexShrink: 0
    },

    serviceName: {
      fontSize: '14px',
      fontWeight: 500,
      color: COLORS.text
    },

    footer: {
      padding: '28px',
      textAlign: 'center' as const,
      color: COLORS.textSecondary,
      fontSize: '14px',
      borderTop: `1px solid ${COLORS.border}`,
      background: `${COLORS.surface}30`
    }
  }

  return (
    <div style={styles.container}>
      {/* Add CSS keyframes */}
      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.6; transform: scale(1.2); }
        }
      ` }} />

      {/* Header */}
      <header style={styles.header}>
        <div style={styles.logo}>
          <div style={styles.logoIcon}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path 
                d="M12 2L2 7L12 12L22 7L12 2Z" 
                fill="white" 
                fillOpacity="0.9"
              />
              <path 
                d="M2 17L12 22L22 17" 
                stroke="white" 
                strokeWidth="2" 
                strokeLinecap="round" 
                strokeLinejoin="round"
              />
              <path 
                d="M2 12L12 17L22 12" 
                stroke="white" 
                strokeWidth="2" 
                strokeLinecap="round" 
                strokeLinejoin="round"
              />
            </svg>
          </div>
          <h1 style={styles.title}>KubeWatch</h1>
        </div>
        <div style={styles.headerRight}>
          <div style={styles.statusBadge}>
            <span style={styles.statusDot}></span>
            <span style={styles.statusText}>Live</span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main style={styles.main}>
        {/* Loading State */}
        {loading && (
          <div style={styles.loadingContainer}>
            <div style={styles.spinner}></div>
            <p style={styles.loadingText}>Loading KubeWatch...</p>
          </div>
        )}

        {/* Error State */}
        {error && !loading && (
          <div style={styles.errorCard}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" style={{ marginBottom: '16px' }}>
              <circle cx="12" cy="12" r="10" stroke={COLORS.danger} strokeWidth="2" />
              <path d="M12 8V12" stroke={COLORS.danger} strokeWidth="2" strokeLinecap="round" />
              <path d="M12 16H12.01" stroke={COLORS.danger} strokeWidth="2" strokeLinecap="round" />
            </svg>
            <h2 style={styles.errorTitle}>Oops! Something went wrong</h2>
            <p style={styles.errorText}>{error}</p>
          </div>
        )}

        {/* Dashboard Content */}
        {!loading && !error && health && status && metrics && nodes && alerts && (
          <div style={styles.dashboard}>
            {/* Last Updated Indicator */}
            <div style={{ 
              textAlign: 'right', 
              color: COLORS.textSecondary, 
              fontSize: '13px', 
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'flex-end',
              gap: '8px'
            }}>
              <div style={{
                width: '6px',
                height: '6px',
                background: COLORS.success,
                borderRadius: '50%',
                animation: 'pulse 1.5s infinite'
              }}></div>
              Last Updated: {lastUpdated}
            </div>
            
            {/* Stats Grid - Top Row */}
            <div style={styles.statsGrid}>
              <div style={styles.statCard}>
                <div style={{ ...styles.statIcon, background: 'rgba(16, 185, 129, 0.15)' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M9 12L11 14L15 10M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z" stroke={COLORS.success} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <div style={styles.statContent}>
                  <p style={styles.statLabel}>Health Status</p>
                  <p style={{ ...styles.statValue, color: COLORS.success }}>{health.status === 'ok' ? 'Healthy' : 'Unhealthy'}</p>
                </div>
              </div>

              <div style={styles.statCard}>
                <div style={{ ...styles.statIcon, background: 'rgba(99, 102, 241, 0.15)' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" stroke={COLORS.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <div style={styles.statContent}>
                  <p style={styles.statLabel}>Version</p>
                  <p style={styles.statValue}>{health.version}</p>
                </div>
              </div>

              <div style={styles.statCard}>
                <div style={{ ...styles.statIcon, background: 'rgba(245, 158, 11, 0.15)' }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M19 11H5M19 11C20.1046 11 21 11.8954 21 13V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V13C3 11.8954 3.89543 11 5 11M19 11V9C19 7.89543 18.1046 7 17 7M5 11V9C5 7.89543 5.89543 7 7 7M7 7V5C7 3.89543 7.89543 3 9 3H15C16.1046 3 17 3.89543 17 5V7M7 7H17" stroke={COLORS.warning} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <div style={styles.statContent}>
                  <p style={styles.statLabel}>Services</p>
                  <p style={styles.statValue}>{status.services.length}</p>
                </div>
              </div>
            </div>

            {/* Charts */}
            <div style={styles.chartsGrid}>
              {/* CPU Chart */}
              <div style={styles.chartCard}>
                <div style={styles.chartHeader}>
                  <h3 style={styles.chartTitle}>CPU Usage</h3>
                </div>
                <p style={{ ...styles.chartValue, color: COLORS.accent }}>
                  {metrics.data[metrics.data.length - 1].cpu}%
                </p>
                <DonutChart 
                  value={metrics.data[metrics.data.length - 1].cpu} 
                  colors={['#4f46e5', '#f472b6']}
                />
              </div>

              {/* Memory Chart */}
              <div style={styles.chartCard}>
                <div style={styles.chartHeader}>
                  <h3 style={styles.chartTitle}>Memory Usage</h3>
                </div>
                <p style={{ ...styles.chartValue, color: COLORS.primary }}>
                  {metrics.data[metrics.data.length - 1].mem}%
                </p>
                <DonutChart 
                  value={metrics.data[metrics.data.length - 1].mem} 
                  color={COLORS.primary} 
                />
              </div>

              {/* Network Chart */}
              <div style={styles.chartCard}>
                <div style={styles.chartHeader}>
                  <h3 style={styles.chartTitle}>Network I/O</h3>
                </div>
                <p style={{ ...styles.chartValue, color: COLORS.secondary }}>
                  {metrics.data[metrics.data.length - 1].net} Mbps
                </p>
                <DonutChart 
                  value={metrics.data[metrics.data.length - 1].net} 
                  maxValue={150} 
                  color={COLORS.secondary} 
                />
              </div>
            </div>

            {/* Nodes and Alerts */}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
              {/* Nodes Section */}
              <div style={styles.section}>
                <h2 style={styles.sectionTitle}>Cluster Nodes</h2>
                <div style={styles.nodesList}>
                  {nodes.nodes.map((node, i) => (
                    <div key={i} style={styles.nodeCard}>
                      <div style={styles.nodeIcon}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                          <path d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" stroke={COLORS.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </div>
                      <div style={styles.nodeInfo}>
                        <p style={styles.nodeName}>{node.name}</p>
                        <p style={styles.nodeMeta}>Pods: {node.pods}</p>
                      </div>
                      <div style={styles.nodeStats}>
                        <span style={{ ...styles.nodeStat, color: COLORS.danger }}>CPU: {node.cpu}</span>
                        <span style={{ ...styles.nodeStat, color: COLORS.primary }}>Mem: {node.mem}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Alerts Section */}
              <div style={styles.section}>
                <h2 style={styles.sectionTitle}>Recent Alerts</h2>
                <div style={styles.alertsList}>
                  {alerts.alerts.map((alert) => {
                    let dotColor = COLORS.primary
                    if (alert.severity === 'warning') dotColor = COLORS.warning
                    if (alert.severity === 'success') dotColor = COLORS.success

                    return (
                      <div key={alert.id} style={styles.alertCard}>
                        <div style={{ ...styles.alertDot, background: dotColor }}></div>
                        <div style={styles.alertContent}>
                          <p style={styles.alertMessage}>{alert.message}</p>
                          <p style={styles.alertTime}>{alert.time}</p>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>

            {/* Services Section */}
            <div style={styles.section}>
              <h2 style={styles.sectionTitle}>System Services</h2>
              <div style={styles.servicesGrid}>
                {status.services.map((service, i) => (
                  <div key={i} style={styles.serviceCard}>
                    <div style={styles.serviceIcon}>
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                        <circle cx="10" cy="10" r="8" stroke={COLORS.success} strokeWidth="2" fill="rgba(16, 185, 129, 0.15)" />
                        <path d="M6 10L8.5 12.5L14 7" stroke={COLORS.success} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    </div>
                    <span style={styles.serviceName}>{service}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer style={styles.footer}>
        <p style={{ margin: 0, marginBottom: 8 }}>Built with ❤️ for Kubernetes monitoring</p>
        <p style={{ margin: 0 }}>
          Crafted by <a 
            href="https://www.linkedin.com/in/manishsharma31/" 
            target="_blank" 
            rel="noopener noreferrer"
            style={{ color: COLORS.primaryLight, textDecoration: 'none', fontWeight: 600 }}
          >
            Manish Sharma
          </a>
        </p>
      </footer>
    </div>
  )
}

export default App
