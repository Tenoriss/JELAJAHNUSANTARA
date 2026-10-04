/**
 * Menu utama: judul, tagline, dan tombol MULAI / LANJUTKAN / PENGATURAN / KELUAR.
 * Latar senja digambar langsung di canvas supaya tidak perlu berkas gambar.
 */

import { useEffect, useRef, useState } from 'react';
import * as actions from '../core/actions';
import * as audio from '../core/audio';
import { hasSave, saveSummary } from '../core/save';
import { drawDuskScene } from '../game/scenery';
import SettingsForm from './SettingsForm';

export default function MainMenu() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [farewell, setFarewell] = useState(false);
  const summary = saveSummary();

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    let raf = 0;
    const start = performance.now();
    const draw = (now: number) => {
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const width = window.innerWidth;
      const height = window.innerHeight;
      canvas.width = Math.floor(width * dpr);
      canvas.height = Math.floor(height * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      drawDuskScene(ctx, width, height, (now - start) / 1000, false);
      raf = window.requestAnimationFrame(draw);
    };
    raf = window.requestAnimationFrame(draw);
    return () => window.cancelAnimationFrame(raf);
  }, []);

  const hover = () => audio.playSfx('hover', 1);

  return (
    <div className="screen screen--menu">
      <canvas ref={canvasRef} className="backdrop" />
      <div className="menu">
        <header className="menu__head">
          <h1 className="menu__title">TAPAK NUSA</h1>
          <p className="menu__tagline">Setiap langkah meninggalkan cerita.</p>
          <p className="menu__theme">Kearifan Lokal untuk Indonesia Emas</p>
        </header>

        <nav className="menu__buttons">
          <button
            type="button"
            className="btn btn--primary"
            onMouseEnter={hover}
            onClick={() => {
              audio.playUiClick();
              actions.newGame();
            }}
          >
            MULAI
          </button>
          <button
            type="button"
            className="btn"
            disabled={!hasSave()}
            onMouseEnter={hover}
            onClick={() => {
              audio.playUiClick();
              actions.continueGame();
            }}
          >
            LANJUTKAN
          </button>
          <button
            type="button"
            className="btn"
            onMouseEnter={hover}
            onClick={() => {
              audio.playUiClick();
              setShowSettings(true);
            }}
          >
            PENGATURAN
          </button>
          <button
            type="button"
            className="btn"
            onMouseEnter={hover}
            onClick={() => {
              audio.playUiClick();
              setFarewell(true);
            }}
          >
            KELUAR
          </button>
        </nav>

        <footer className="menu__foot">
          {summary ? (
            <p className="menu__save">
              Simpanan terakhir: <strong>{summary.quest || 'Desa Arunika'}</strong> ·{' '}
              {summary.notes} catatan budaya
              {summary.finished ? ' · tamat' : ''}
            </p>
          ) : (
            <p className="menu__save">Belum ada simpanan. Mulai perjalanan baru dari desa.</p>
          )}
          <p className="menu__hint">WASD / panah untuk berjalan · E untuk berbicara dan mengambil</p>
        </footer>
      </div>

      {showSettings && (
        <div className="modal">
          <div className="modal__panel">
            <h2 className="panel__title">Pengaturan</h2>
            <SettingsForm />
            <div className="modal__actions">
              <button type="button" className="btn" onClick={() => setShowSettings(false)}>
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {farewell && (
        <div className="modal">
          <div className="modal__panel">
            <h2 className="panel__title">Terima kasih sudah bermain</h2>
            <p className="panel__text">
              Karena TAPAK NUSA berjalan di peramban, tab ini tidak bisa menutup sendiri. Tutup tab
              atau tekan tombol di bawah untuk kembali ke desa.
            </p>
            <div className="modal__actions">
              <button type="button" className="btn btn--primary" onClick={() => setFarewell(false)}>
                Kembali
              </button>
            </div>
          </div>
        </div>
      )}

      <span className="version">versi 1.0.0 · dibuat dengan React</span>
    </div>
  );
}
