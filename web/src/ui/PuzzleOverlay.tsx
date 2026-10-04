/**
 * Dua puzzle TAPAK NUSA (padanan PatternPuzzle.gd & PrepPuzzle.gd).
 *
 * Cara mainnya sama: pilih satu potongan, lalu klik tempat tujuan. Salah susun
 * tidak menghukum — pemain diberi umpan balik dan tempat yang benar ditandai.
 */

import { useCallback, useEffect, useState } from 'react';
import * as actions from '../core/actions';
import * as audio from '../core/audio';
import { itemColor, itemName } from '../core/data';
import { MOTIF_COLORS } from '../game/palette';
import { useGame } from '../core/store';
import type { PuzzleId } from '../core/types';

interface Piece {
  id: string;
  label: string;
  hint: string;
}

interface Slot {
  id: string;
  label: string;
  correct: string;
}

interface PuzzleSpec {
  id: PuzzleId;
  title: string;
  hint: string;
  pieces: Piece[];
  slots: Slot[];
  renderPiece: (pieceId: string) => React.ReactNode;
  reference?: React.ReactNode;
}

// --- Motif kain (digambar sebagai SVG; tidak butuh berkas gambar) ----------

function Kawung() {
  return (
    <svg viewBox="0 0 100 100" className="motif">
      <rect width="100" height="100" fill={MOTIF_COLORS.kawung} />
      {[
        [30, 30],
        [70, 30],
        [30, 70],
        [70, 70],
      ].map(([cx, cy]) => (
        <circle key={`${cx}-${cy}`} cx={cx} cy={cy} r={16} fill="none" stroke="#f2b134" strokeWidth={4} />
      ))}
      <circle cx={50} cy={50} r={7} fill="#f2b134" />
    </svg>
  );
}

function Ceplok() {
  return (
    <svg viewBox="0 0 100 100" className="motif">
      <rect width="100" height="100" fill={MOTIF_COLORS.ceplok} />
      {Array.from({ length: 8 }, (_, index) => {
        const angle = (index / 8) * Math.PI * 2;
        return (
          <circle
            key={index}
            cx={50 + Math.cos(angle) * 26}
            cy={50 + Math.sin(angle) * 26}
            r={11}
            fill="#f7d68a"
          />
        );
      })}
      <circle cx={50} cy={50} r={14} fill="#f2b134" />
    </svg>
  );
}

function Tumpal() {
  return (
    <svg viewBox="0 0 100 100" className="motif">
      <rect width="100" height="100" fill={MOTIF_COLORS.parang} />
      {Array.from({ length: 5 }, (_, index) => (
        <polygon
          key={index}
          points={`${8 + index * 18},78 ${26 + index * 18},78 ${17 + index * 18},22`}
          fill="#f7d68a"
        />
      ))}
      <rect x={6} y={80} width={88} height={7} fill="#8c3d4d" />
    </svg>
  );
}

function Parang() {
  return (
    <svg viewBox="0 0 100 100" className="motif">
      <rect width="100" height="100" fill={MOTIF_COLORS.tumpal} />
      {Array.from({ length: 7 }, (_, index) => (
        <polygon
          key={index}
          points={`${index * 16},100 ${index * 16 + 16},100 ${index * 16 + 44},0 ${index * 16 + 28},0`}
          fill={index % 2 === 0 ? '#f2b134' : '#dfcdae'}
        />
      ))}
    </svg>
  );
}

const MOTIFS: Record<string, () => JSX.Element> = {
  kawung: Kawung,
  ceplok: Ceplok,
  tumpal: Tumpal,
  parang: Parang,
};

function MotifPiece({ id }: { id: string }) {
  const Component = MOTIFS[id] ?? Kawung;
  return <Component />;
}

function ItemPiece({ id }: { id: string }) {
  return (
    <div className="itemPiece" style={{ background: itemColor(id) }}>
      <span>{itemName(id)}</span>
    </div>
  );
}

const PATTERN: PuzzleSpec = {
  id: 'pattern',
  title: 'Menyusun Pola Kain',
  hint:
    'Pak Jaya: "Susun potongan supaya sama dengan contoh kain di kanan. Kawung, ceplok, tumpal, parang — masing-masing punya tempatnya."',
  pieces: [
    { id: 'kawung', label: 'Kawung', hint: 'Empat bulatan mengelilingi titik tengah' },
    { id: 'ceplok', label: 'Ceplok', hint: 'Roset bintang delapan arah' },
    { id: 'tumpal', label: 'Tumpal', hint: 'Deretan segitiga' },
    { id: 'parang', label: 'Parang', hint: 'Garis miring berulang' },
  ],
  slots: [
    { id: 'p1', label: 'Pola kiri atas', correct: 'kawung' },
    { id: 'p2', label: 'Pola kanan atas', correct: 'ceplok' },
    { id: 'p3', label: 'Pola kiri bawah', correct: 'tumpal' },
    { id: 'p4', label: 'Pola kanan bawah', correct: 'parang' },
  ],
  renderPiece: (pieceId) => <MotifPiece id={pieceId} />,
  reference: (
    <div className="reference">
      <span className="reference__label">Contoh kain</span>
      <div className="reference__grid">
        <MotifPiece id="kawung" />
        <MotifPiece id="ceplok" />
        <MotifPiece id="tumpal" />
        <MotifPiece id="parang" />
      </div>
    </div>
  ),
};

const PREP: PuzzleSpec = {
  id: 'prep',
  title: 'Menyiapkan Lapangan',
  hint: 'Sari: "Letakkan setiap bahan di tempat yang sesuai. Pilih bahannya dulu, lalu klik tempatnya."',
  pieces: [
    { id: 'bambu', label: 'Bambu', hint: 'Berdiri tegak sebagai penopang gapura' },
    { id: 'tali', label: 'Tali Ijuk', hint: 'Mengikat supaya sambungan tidak lepas' },
    { id: 'papan_kayu', label: 'Papan Kayu', hint: 'Permukaan rata untuk meja panjang' },
    { id: 'kain_pola', label: 'Kain Pola', hint: 'Dipasang sebagai hiasan bercorak' },
  ],
  slots: [
    { id: 's_tiang', label: 'Penopang gapura', correct: 'bambu' },
    { id: 's_ikat', label: 'Ikatan sambungan', correct: 'tali' },
    { id: 's_meja', label: 'Meja panjang', correct: 'papan_kayu' },
    { id: 's_hias', label: 'Hiasan panggung', correct: 'kain_pola' },
  ],
  renderPiece: (pieceId) => <ItemPiece id={pieceId} />,
};

export default function PuzzleOverlay() {
  const game = useGame();
  if (game.puzzle === 'pattern') return <Puzzle spec={PATTERN} />;
  if (game.puzzle === 'prep') return <Puzzle spec={PREP} />;
  return null;
}

function Puzzle({ spec }: { spec: PuzzleSpec }) {
  const [placements, setPlacements] = useState<Record<string, string>>({});
  const [selected, setSelected] = useState('');
  const [wrong, setWrong] = useState<string[]>([]);
  const [checked, setChecked] = useState(false);
  const [attempts, setAttempts] = useState(0);
  const [message, setMessage] = useState('Pilih potongan di baki bawah, lalu klik tempat yang diinginkan.');
  const [busy, setBusy] = useState(false);

  const close = useCallback(
    (success: boolean) => {
      actions.finishPuzzle(spec.id, success);
    },
    [spec.id],
  );

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.code === 'Escape') {
        event.preventDefault();
        if (!busy) close(false);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [busy, close]);

  const unplaced = spec.pieces.filter((piece) => !Object.values(placements).includes(piece.id));

  const clickSlot = (slotId: string) => {
    if (busy) return;
    if (placements[slotId]) {
      const next = { ...placements };
      delete next[slotId];
      setPlacements(next);
      setWrong((list) => list.filter((id) => id !== slotId));
      setChecked(false);
      setSelected('');
      setMessage('Potongan dikembalikan ke baki.');
      audio.playSfx('click', -10);
      return;
    }
    if (!selected) {
      setMessage('Pilih dulu satu potongan di baki bawah.');
      return;
    }
    setPlacements({ ...placements, [slotId]: selected });
    setWrong((list) => list.filter((id) => id !== slotId));
    setChecked(false);
    setSelected('');
    setMessage('Potongan terpasang. Periksa bila sudah lengkap.');
    audio.playSfx('place', -6);
  };

  const check = () => {
    if (busy) return;
    if (Object.keys(placements).length < spec.slots.length) {
      setMessage('Masih ada tempat yang belum terisi.');
      audio.playSfx('fail', -6);
      return;
    }
    const wrongSlots = spec.slots.filter((slot) => placements[slot.id] !== slot.correct).map((slot) => slot.id);
    setChecked(true);
    setWrong(wrongSlots);
    if (wrongSlots.length === 0) {
      setBusy(true);
      setMessage('Susunan tepat!');
      audio.playSfx('success');
      window.setTimeout(() => close(true), 1100);
      return;
    }
    const next = attempts + 1;
    setAttempts(next);
    audio.playSfx('fail');
    setMessage(
      next <= 1
        ? 'Belum tepat. Bandingkan lagi bentuk tiap potongan.'
        : next === 2
          ? 'Masih ada yang salah. Tempat yang benar akan menyala hijau.'
          : 'Tidak apa-apa, ulangi perlahan. Setiap bentuk punya tempatnya.',
    );
  };

  return (
    <div className="puzzle">
      <div className="puzzle__panel">
        <header className="puzzle__head">
          <div>
            <h2 className="puzzle__title">{spec.title}</h2>
            <p className="puzzle__hint">{spec.hint}</p>
          </div>
          {spec.reference}
        </header>

        <div className="puzzle__stage" data-slots={spec.slots.length}>
          {spec.slots.map((slot) => {
            const placed = placements[slot.id];
            const isWrong = wrong.includes(slot.id);
            const isRight = checked && placed === slot.correct;
            return (
              <button
                type="button"
                key={slot.id}
                className={`slot ${isWrong ? 'slot--wrong' : ''} ${isRight ? 'slot--right' : ''}`}
                onClick={() => clickSlot(slot.id)}
              >
                {placed ? (
                  <div className="slot__piece">{spec.renderPiece(placed)}</div>
                ) : (
                  <span className="slot__label">{slot.label}</span>
                )}
              </button>
            );
          })}
        </div>

        <div className="puzzle__tray">
          <span className="tray__label">Potongan tersedia</span>
          <div className="tray__row">
            {unplaced.map((piece) => (
              <button
                type="button"
                key={piece.id}
                className={`tray__piece ${selected === piece.id ? 'is-selected' : ''}`}
                onClick={() => {
                  setSelected(selected === piece.id ? '' : piece.id);
                  audio.playSfx('click', -12);
                  setMessage(
                    selected === piece.id
                      ? 'Pilihan dibatalkan.'
                      : `Sekarang klik tempat untuk ${piece.label}.`,
                  );
                }}
                title={piece.hint}
              >
                <div className="tray__art">{spec.renderPiece(piece.id)}</div>
                <span className="tray__name">{piece.label}</span>
              </button>
            ))}
            {unplaced.length === 0 && <span className="tray__empty">Semua potongan sudah dipasang.</span>}
          </div>
        </div>

        <footer className="puzzle__foot">
          <p className="puzzle__message">{message}</p>
          <div className="puzzle__actions">
            <button type="button" className="btn" onClick={() => close(false)} disabled={busy}>
              Batal
            </button>
            <button type="button" className="btn btn--primary" onClick={check} disabled={busy}>
              Periksa
            </button>
          </div>
        </footer>
      </div>
    </div>
  );
}
