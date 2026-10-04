/**
 * App — akar permainan versi web (padanan Main.tscn + Main.gd).
 *
 * Mengatur layar mana yang tampil, tombol global (ESC, Q), pemutaran musik
 * sesuai layar, dan efek memudar saat berpindah layar.
 */

import { useEffect } from 'react';
import * as actions from './core/actions';
import * as audio from './core/audio';
import * as dialogue from './core/dialogue';
import { applyBrightness, loadSettings } from './core/save';
import { notify, state, useGame } from './core/store';
import type { ScreenId } from './core/types';
import CreditsScreen from './ui/CreditsScreen';
import DialogueBox from './ui/DialogueBox';
import EndingScreen from './ui/EndingScreen';
import Hud from './ui/Hud';
import MainMenu from './ui/MainMenu';
import OpeningScreen from './ui/OpeningScreen';
import PauseMenu from './ui/PauseMenu';
import PuzzleOverlay from './ui/PuzzleOverlay';
import VillageScreen from './ui/VillageScreen';

function musicFor(screen: ScreenId): string {
  if (screen === 'village') return 'village';
  if (screen === 'ending' || screen === 'credits') return 'ending';
  return 'menu';
}

export default function App() {
  const game = useGame();

  // Kecerahan dari pengaturan terakhir dipasang begitu permainan dibuka.
  useEffect(() => {
    applyBrightness(loadSettings().brightness);
  }, []);

  // Audio baru boleh berbunyi setelah pemain menyentuh layar/tombol.
  useEffect(() => {
    const unlock = () => {
      audio.unlock();
      audio.playMusic(musicFor(state.screen));
      if (state.screen === 'village') audio.playAmbient('day');
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
    window.addEventListener('pointerdown', unlock);
    window.addEventListener('keydown', unlock);
    return () => {
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
  }, []);

  // Musik mengikuti layar.
  useEffect(() => {
    audio.playMusic(musicFor(game.screen));
    if (game.screen === 'village') audio.playAmbient('day');
    else audio.stopAmbient();
  }, [game.screen]);

  // Tombol global: ESC (menu jeda) dan Q/J (jurnal quest).
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.code === 'Escape') {
        if (state.puzzle !== null) return; // puzzle menangani ESC sendiri
        if (dialogue.isActive()) return; // dialog diselesaikan dulu
        if (state.menuPanel !== null) {
          state.menuPanel = null;
          actions.setPaused(false);
          notify();
          return;
        }
        if (state.screen === 'village' && state.gameStarted) {
          state.menuPanel = 'pause';
          actions.setPaused(true);
          notify();
        }
        return;
      }
      if (event.code === 'KeyQ' || event.code === 'KeyJ') {
        if (!state.gameStarted || state.screen !== 'village') return;
        if (dialogue.isActive() || state.puzzle !== null) return;
        if (state.menuPanel === 'quests') {
          state.menuPanel = null;
          actions.setPaused(false);
        } else {
          state.menuPanel = 'quests';
          actions.setPaused(true);
        }
        notify();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <div className="app">
      {game.screen === 'main_menu' && <MainMenu />}
      {game.screen === 'opening' && <OpeningScreen />}
      {game.screen === 'village' && (
        <>
          <VillageScreen />
          <Hud />
        </>
      )}
      {game.screen === 'ending' && <EndingScreen />}
      {game.screen === 'credits' && <CreditsScreen />}

      <DialogueBox />
      <PuzzleOverlay />
      {game.screen === 'village' && <PauseMenu />}
      <div className={`fade ${game.transitioning ? 'fade--on' : ''}`} aria-hidden="true" />
    </div>
  );
}
