import { useQuery } from '@tanstack/react-query'
import { Alert, Card, Typography } from 'antd'
import { Activity } from 'lucide-react'
import { getHealth } from '../../api/health'
export function HealthPage() {
  const health = useQuery({ queryKey: ['health'], queryFn: getHealth, refetchInterval: 15000, retry: false })
  return <main style={{ maxWidth: 900, margin: '64px auto', padding: 24 }}>
    <Typography.Title><Activity size={30} /> AI Comic Studio</Typography.Title>
    <Typography.Paragraph>P0 工程基线 · 尚未启用漫剧生产功能</Typography.Paragraph>
    <Card title="服务状态">
      {health.isPending && <p>正在检查后端…</p>}
      {health.isError && <Alert type="error" message="后端连接失败" description="请检查 Java 服务和 PostgreSQL 是否就绪。" showIcon />}
      {health.data && <Alert type="success" message="后端服务正常" description={`${health.data.service} / ${health.data.status}`} showIcon />}
    </Card>
    <Typography.Paragraph style={{marginTop:24}}>浏览器仅通过 Java 访问业务服务；内部认证 Token 不传入前端。</Typography.Paragraph>
  </main>
}
