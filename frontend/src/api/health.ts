import { request } from './request'
import type { ApiResponse, HealthData } from '../types/api'
export async function getHealth(): Promise<HealthData> {
  const response = await request.get<ApiResponse<HealthData>>('/health')
  if (response.data.code !== 'OK' || !response.data.data) throw new Error('Invalid health response')
  return response.data.data
}
