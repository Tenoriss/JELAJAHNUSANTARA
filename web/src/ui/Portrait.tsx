/** Potret karakter digambar di canvas kecil (tanpa berkas gambar). */

import { useEffect, useRef } from 'react';
import { drawPortrait } from '../game/character';

interface Props {
  id: string;
  size?: number;
}

export default function Portrait({ id, size = 84 }: Props) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.floor(size * dpr);
    canvas.height = Math.floor(size * dpr);
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    drawPortrait(ctx, id, size);
  }, [id, size]);

  return (
    <canvas
      ref={ref}
      className="portrait"
      style={{ width: size, height: size }}
      aria-label={`Potret ${id}`}
    />
  );
}
