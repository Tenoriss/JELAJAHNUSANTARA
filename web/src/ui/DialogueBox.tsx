/**
 * Kotak dialog: nama pembicara, potret, teks yang muncul huruf demi huruf,
 * dan lanjut dengan SPACE / E / Enter / klik.
 */

import { useEffect, useRef, useState } from 'react';
import * as dialogue from '../core/dialogue';
import { useGame } from '../core/store';
import Portrait from './Portrait';

const TYPE_SPEED = 54; // huruf per detik (sama dengan DialogueBox.gd)

export default function DialogueBox() {
  const game = useGame();
  const view = game.dialogue;
  const [typed, setTyped] = useState(0);
  const autoRef = useRef<number | null>(null);

  const fullText = view?.text ?? '';

  useEffect(() => {
    setTyped(0);
  }, [view?.dialogueId, view?.index]);

  useEffect(() => {
    if (!view) return;
    if (typed >= fullText.length) return;
    const timer = window.setInterval(() => {
      setTyped((value) => Math.min(fullText.length, value + 1));
    }, 1000 / TYPE_SPEED);
    return () => window.clearInterval(timer);
  }, [view, typed, fullText.length]);

  // Baris narasi bisa lanjut sendiri setelah jeda (properti "pause" pada data).
  useEffect(() => {
    if (autoRef.current !== null) {
      window.clearTimeout(autoRef.current);
      autoRef.current = null;
    }
    if (!view) return;
    if (typed < fullText.length) return;
    const pause = view.pause;
    if (pause <= 0) return;
    autoRef.current = window.setTimeout(() => dialogue.advance(), pause * 1000);
    return () => {
      if (autoRef.current !== null) window.clearTimeout(autoRef.current);
      autoRef.current = null;
    };
  }, [view, typed, fullText.length]);

  const advance = () => {
    if (!view) return;
    if (typed < fullText.length) {
      setTyped(fullText.length);
      return;
    }
    dialogue.advance();
  };

  useEffect(() => {
    if (!view) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.code === 'Space' || event.code === 'Enter' || event.code === 'KeyE') {
        event.preventDefault();
        advance();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  if (!view) return null;
  const done = typed >= fullText.length;

  return (
    <div className="dialogue" onClick={advance} role="presentation">
      <div className="dialogue__box">
        {!view.narration && view.portrait && (
          <div className="dialogue__portrait">
            <Portrait id={view.portrait} size={84} />
          </div>
        )}
        <div className="dialogue__body">
          {!view.narration && (
            <div className="dialogue__name" style={{ color: view.color }}>
              {view.speaker}
            </div>
          )}
          <p className={`dialogue__text ${view.narration ? 'dialogue__text--narration' : ''}`}>
            {fullText.slice(0, typed)}
          </p>
          <div className={`dialogue__hint ${done ? 'dialogue__hint--on' : ''}`}>
            {view.hasMore ? 'SPACE lanjut ▸' : 'SPACE tutup ✕'}
          </div>
        </div>
      </div>
    </div>
  );
}
