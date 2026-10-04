/**
 * Adegan penutup: warga berkumpul di Lapangan Guyub saat malam.
 * Setelah narasi penutup selesai, judul dan tagline muncul, lalu layar kredit.
 */

import { useEffect, useRef, useState } from 'react';
import * as actions from '../core/actions';
import * as dialogue from '../core/dialogue';
import { drawNightScene, type NightVillager } from '../game/scenery';

const TITLE_HOLD = 6500;

const VILLAGERS: NightVillager[] = [
  { palette: 'mbah_seno', x: 0.5, y: 0.585, facing: [0, 1] },
  { palette: 'sari', x: 0.41, y: 0.63, facing: [1, 0] },
  { palette: 'dimas', x: 0.59, y: 0.635, facing: [-1, 0] },
  { palette: 'bu_rini', x: 0.365, y: 0.7, facing: [1, 0] },
  { palette: 'pak_jaya', x: 0.63, y: 0.705, facing: [-1, 0] },
  { palette: 'warga_petani', x: 0.46, y: 0.74, facing: [0, -1] },
  { palette: 'warga_penjual', x: 0.56, y: 0.745, facing: [0, -1] },
  { palette: 'warga_anak', x: 0.54, y: 0.545, facing: [0, 1] },
];

export default function EndingScreen() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [titleShown, setTitleShown] = useState(false);
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
      drawNightScene(ctx, width, height, (now - start) / 1000, VILLAGERS);
      raf = window.requestAnimationFrame(draw);
    };
    raf = window.requestAnimationFrame(draw);
    return () => window.cancelAnimationFrame(raf);
  }, []);

  // Narasi penutup jalan sekali; pendengarnya dipasang terpisah.
  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;
    dialogue.start('ending_narasi');
  }, []);

  useEffect(
    () =>
      dialogue.onFinished((id) => {
        if (id === 'ending_narasi') setTitleShown(true);
      }),
    [],
  );

  useEffect(() => {
    if (!titleShown) return;
    const timer = window.setTimeout(() => actions.goto('credits'), TITLE_HOLD);
    return () => window.clearTimeout(timer);
  }, [titleShown]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (dialogue.isActive()) return;
      if (event.code === 'Space' || event.code === 'Enter') {
        if (titleShown) actions.goto('credits');
        else setTitleShown(true);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [titleShown]);

  return (
    <div className="screen screen--ending">
      <canvas ref={canvasRef} className="backdrop" />
      {titleShown && (
        <div className="titleCard">
          <h1>TAPAK NUSA</h1>
          <p>Setiap langkah meninggalkan cerita.</p>
          <button type="button" className="btn btn--primary" onClick={() => actions.goto('credits')}>
            Lihat Kredit ▸
          </button>
        </div>
      )}
    </div>
  );
}
