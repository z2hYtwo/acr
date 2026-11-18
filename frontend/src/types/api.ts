export interface ApiResponse<T> { code: string; message: string; data: T | null }
export interface HealthData { service: string; status: 'UP' }
export interface Page<T> { items: T[]; total: number; page: number; size: number }
