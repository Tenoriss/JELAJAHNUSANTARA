import { Component, StrictMode, type ErrorInfo, type ReactNode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';

/**
 * Penjaga galat: kalau ada yang gagal (skrip, gambar, atau React), pesan aslinya
 * ditampilkan di layar — bukan layar gelap tanpa penjelasan.
 */

function showFatal(message: string): void {
  const host = document.getElementById('tapak-error');
  if (!host) return;
  host.classList.add('is-on');
  const body = host.querySelector('.fatal__message');
  if (body) body.textContent = message;
}

function fatalOverlay(): HTMLElement {
  const host = document.createElement('div');
  host.id = 'tapak-error';
  host.className = 'fatal';
  host.innerHTML = `
    <div class="fatal__panel">
      <h2>TAPAK NUSA tidak bisa dijalankan</h2>
      <p class="fatal__message"></p>
      <p class="fatal__hint">
        Coba muat ulang halaman. Bila pesan ini muncul terus, salin pesannya
        supaya bisa diperiksa.
      </p>
      <button type="button">Muat ulang</button>
    </div>`;
  host.querySelector('button')?.addEventListener('click', () => window.location.reload());
  document.body.appendChild(host);
  return host;
}

window.addEventListener('error', (event) => {
  const detail = event.error instanceof Error ? `${event.error.name}: ${event.error.message}` : String(event.message);
  showFatal(detail);
});
window.addEventListener('unhandledrejection', (event) => {
  const reason = event.reason;
  const detail = reason instanceof Error ? `${reason.name}: ${reason.message}` : String(reason);
  showFatal(`Janji gagal — ${detail}`);
});

class ErrorBoundary extends Component<{ children: ReactNode }, { message: string | null }> {
  state: { message: string | null } = { message: null };

  static getDerivedStateFromError(error: unknown): { message: string } {
    const detail = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    return { message: detail };
  }

  componentDidCatch(error: unknown, info: ErrorInfo): void {
    console.error('Galat antarmuka:', error, info.componentStack);
  }

  render(): ReactNode {
    if (this.state.message !== null) {
      return (
        <div className="fatal__panel">
          <h2>TAPAK NUSA tidak bisa dijalankan</h2>
          <p className="fatal__message">{this.state.message}</p>
          <p className="fatal__hint">Coba muat ulang halaman.</p>
          <button type="button" onClick={() => window.location.reload()}>
            Muat ulang
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

fatalOverlay();

const container = document.getElementById('root');
if (!container) {
  showFatal('Elemen #root tidak ditemukan di index.html');
} else {
  container.replaceChildren();
  try {
    createRoot(container).render(
      <StrictMode>
        <ErrorBoundary>
          <App />
        </ErrorBoundary>
      </StrictMode>,
    );
  } catch (error) {
    const detail = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    showFatal(detail);
  }
}
