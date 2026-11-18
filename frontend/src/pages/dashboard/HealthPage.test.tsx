import { render, screen } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { HealthPage } from './HealthPage'
import { getHealth } from '../../api/health'
vi.mock('../../api/health', () => ({ getHealth: vi.fn() }))
function page() {
  return render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}><HealthPage /></QueryClientProvider>)
}
beforeEach(() => vi.clearAllMocks())
describe('P0 service status', () => {
  it('shows loading', () => { vi.mocked(getHealth).mockReturnValue(new Promise(() => {})); page(); expect(screen.getByText('正在检查后端…')).toBeInTheDocument() })
  it('shows real health result', async () => { vi.mocked(getHealth).mockResolvedValue({service:'backend',status:'UP'}); page(); expect(await screen.findByText('后端服务正常')).toBeInTheDocument() })
  it('shows failure without inventing success', async () => { vi.mocked(getHealth).mockRejectedValue(new Error('offline')); page(); expect(await screen.findByText('后端连接失败')).toBeInTheDocument() })
})
