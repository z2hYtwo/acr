import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { HealthPage } from './pages/dashboard/HealthPage'
export default function App() { return <BrowserRouter><Routes><Route path="*" element={<HealthPage />} /></Routes></BrowserRouter> }
