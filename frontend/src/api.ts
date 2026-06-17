const API_BASE_URL = import.meta.env.VITE_API_URL || "/api";

export interface HealthResponse {
  status: string
  version: string
}

export interface StatusResponse {
  status: string
  timestamp: string
  services: string[]
}

export interface MetricDataPoint {
  time: string
  cpu: number
  mem: number
  net: number
}

export interface MetricsResponse {
  timestamp: string
  data: MetricDataPoint[]
}

export interface NodeStats {
  name: string
  status: string
  cpu: string
  mem: string
  pods: number
}

export interface NodesResponse {
  timestamp: string
  nodes: NodeStats[]
}

export interface Alert {
  id: number
  severity: string
  message: string
  time: string
}

export interface AlertsResponse {
  timestamp: string
  alerts: Alert[]
}

export async function getHealth(): Promise<HealthResponse> {
  const res = await fetch(`${API_BASE_URL}/v1/health`)
  if (!res.ok) throw new Error('Failed to get health')
  return res.json()
}

export async function getStatus(): Promise<StatusResponse> {
  const res = await fetch(`${API_BASE_URL}/v1/status`)
  if (!res.ok) throw new Error('Failed to get status')
  return res.json()
}

export async function getMetrics(): Promise<MetricsResponse> {
  const res = await fetch(`${API_BASE_URL}/v1/metrics`)
  if (!res.ok) throw new Error('Failed to get metrics')
  return res.json()
}

export async function getNodes(): Promise<NodesResponse> {
  const res = await fetch(`${API_BASE_URL}/v1/nodes`)
  if (!res.ok) throw new Error('Failed to get nodes')
  return res.json()
}

export async function getAlerts(): Promise<AlertsResponse> {
  const res = await fetch(`${API_BASE_URL}/v1/alerts`)
  if (!res.ok) throw new Error('Failed to get alerts')
  return res.json()
}
