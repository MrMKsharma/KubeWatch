// Mock data for portfolio demo (no backend needed!)

const mockMetricsData = Array.from({ length: 12 }, (_, i) => {
  const minutesAgo = (11 - i) * 5
  const time = new Date(Date.now() - minutesAgo * 60 * 1000)
  return {
    time: time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    cpu: Math.floor(Math.random() * 40) + 20,
    mem: Math.floor(Math.random() * 30) + 40,
    net: Math.floor(Math.random() * 100) + 50
  }
})

export const demoApi = {
  getHealth: async () => Promise.resolve({ status: "ok", version: "1.0.0" }),
  getStatus: async () => Promise.resolve({
    status: "healthy",
    timestamp: new Date().toISOString(),
    services: ["prometheus", "loki", "tempo", "kubernetes"]
  }),
  getMetrics: async () => Promise.resolve({
    timestamp: new Date().toISOString(),
    data: mockMetricsData
  }),
  getNodes: async () => Promise.resolve({
    timestamp: new Date().toISOString(),
    nodes: [
      { name: "kind-control-plane", status: "Ready", cpu: `${Math.floor(Math.random() * 50) + 30}%`, mem: `${Math.floor(Math.random() * 40) + 40}%`, pods: 12 + Math.floor(Math.random() * 5) },
      { name: "kind-worker", status: "Ready", cpu: `${Math.floor(Math.random() * 40) + 20}%`, mem: `${Math.floor(Math.random() * 35) + 35}%`, pods: 8 + Math.floor(Math.random() * 4) }
    ]
  }),
  getAlerts: async () => Promise.resolve({
    timestamp: new Date().toISOString(),
    alerts: [
      { id: 1, severity: "warning", message: "High CPU usage on node kind-worker", time: "2 min ago" },
      { id: 2, severity: "info", message: "New pod deployed in default namespace", time: "5 min ago" },
      { id: 3, severity: "success", message: "All pods are healthy", time: "10 min ago" }
    ]
  })
}
