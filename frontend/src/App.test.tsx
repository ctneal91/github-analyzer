import { render, screen, act } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders the main heading', () => {
    render(<App />)

    expect(
      screen.getByRole('heading', { name: /GitHub Event Analyzer/i })
    ).toBeInTheDocument()
  })

  it('renders the dashboard description', () => {
    render(<App />)

    expect(
      screen.getByText(/Dashboard for monitoring GitHub push events/i)
    ).toBeInTheDocument()
  })

  it('renders the health status section', () => {
    render(<App />)

    expect(
      screen.getByRole('heading', { name: /System Health/i })
    ).toBeInTheDocument()
    expect(screen.getByTestId('health-status')).toBeInTheDocument()
  })

  it('starts with loading status', () => {
    render(<App />)

    expect(screen.getByTestId('health-label')).toHaveTextContent('Loading...')
  })

  it('renders check health button', () => {
    render(<App />)

    expect(
      screen.getByRole('button', { name: /Check Health/i })
    ).toBeInTheDocument()
  })

  it('sets status to loading when check health is clicked and returns to healthy', async () => {
    render(<App />)

    // Advance past initial timeout to get to healthy state
    await act(async () => {
      await vi.advanceTimersByTimeAsync(1100)
    })
    expect(screen.getByTestId('health-label')).toHaveTextContent('Healthy')

    // Click the button using fireEvent (simpler than userEvent with fake timers)
    await act(async () => {
      screen.getByRole('button', { name: /Check Health/i }).click()
    })

    // Should be loading immediately after click
    expect(screen.getByTestId('health-label')).toHaveTextContent('Loading...')

    // Advance timers to complete the checkHealth timeout
    await act(async () => {
      await vi.advanceTimersByTimeAsync(1100)
    })

    // Should be healthy again after timeout completes
    expect(screen.getByTestId('health-label')).toHaveTextContent('Healthy')
  })

  it('changes to healthy status after timeout', async () => {
    render(<App />)

    // Initially loading
    expect(screen.getByTestId('health-label')).toHaveTextContent('Loading...')

    // Fast-forward timers
    await act(async () => {
      await vi.advanceTimersByTimeAsync(1100)
    })

    // Should now be healthy
    expect(screen.getByTestId('health-label')).toHaveTextContent('Healthy')
  })
})
