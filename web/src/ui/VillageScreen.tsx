/**
 * Layar desa: kanvas tempat WorldEngine menggambar Desa Arunika.
 *
 * Di sini juga quest pertama dimulai (seperti Village.gd versi Godot) dan
 * permainan disimpan setiap kali ada quest yang selesai.
 */

import { useEffect, useRef } from 'react';
import * as quests from '../core/quests';
import { saveGame } from '../core/save';
import { showBanner, state, useGame } from '../core/store';
import { WorldEngine } from '../game/engine';

export default function VillageScreen() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const game = useGame();
  const completedRef = useRef(-1);

  // Mulai mesin dunia.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const engine = new WorldEngine(canvas);
    engine.start();
    return () => engine.stop();
  }, []);

  // Quest pembuka.
  useEffect(() => {
    if (!quests.hasStarted('q_pulang') && !quests.isCompleted('q_tapak')) {
      quests.startQuest('q_pulang');
      showBanner('Desa Arunika', 'Setiap langkah meninggalkan cerita');
    }
  }, []);

  // Simpan otomatis tiap kali sebuah quest selesai.
  useEffect(() => {
    const completed = quests.completedQuests().length;
    if (completedRef.current === -1) {
      completedRef.current = completed;
      return;
    }
    if (completed !== completedRef.current) {
      completedRef.current = completed;
      saveGame(null, true);
    }
  }, [game.quests]);

  useEffect(() => {
    const onBeforeUnload = () => saveGame(null, true);
    window.addEventListener('beforeunload', onBeforeUnload);
    return () => window.removeEventListener('beforeunload', onBeforeUnload);
  }, []);

  return (
    <div className="screen screen--village">
      <canvas ref={canvasRef} className="world" />
      {state.paused && <div className="dim" aria-hidden="true" />}
    </div>
  );
}
