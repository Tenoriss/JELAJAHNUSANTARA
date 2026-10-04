/**
 * Layar pembuka: Raka turun dari bus di ujung jalan desa.
 * Narasi berjalan sendiri (properti "pause" di data); pemain bisa melewatinya.
 */

import { useEffect, useRef } from 'react';
import * as actions from '../core/actions';
import * as dialogue from '../core/dialogue';
import { drawDuskScene } from '../game/scenery';

export default function OpeningScreen() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const startedRef = useRef(false);

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
      drawDuskScene(ctx, width, height, (now - start) / 1000, true);
      raf = window.requestAnimationFrame(draw);
    };
    raf = window.requestAnimationFrame(draw);
    return () => window.cancelAnimationFrame(raf);
  }, []);

  // Narasi dijalankan sekali; pendengarnya dipasang di efek terpisah supaya
  // tidak ikut dilepas saat komponen menggambar ulang.
  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;
    dialogue.start('opening_narasi');
  }, []);

  useEffect(
    () =>
      dialogue.onFinished((id) => {
        if (id === 'opening_narasi') actions.goto('village');
      }),
    [],
  );

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (dialogue.isActive()) return;
      if (event.code === 'Space' || event.code === 'Enter' || event.code === 'Escape') {
        actions.goto('village');
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <div className="screen screen--opening">
      <canvas ref={canvasRef} className="backdrop" />
      <div className="opening__label">
        <span>TAPAK NUSA</span>
        <small>Desa Arunika · lima tahun kemudian</small>
      </div>
      <button
        type="button"
        className="skip"
        onClick={() => actions.goto('village')}
        disabled={dialogue.isActive()}
      >
        ESC untuk melewati ▸
      </button>
    </div>
  );
}
