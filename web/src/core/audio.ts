/**
 * Sistem audio versi web (pengganti ProceduralAudio.gd + AudioSystem.gd).
 *
 * Semua suara dibuat sendiri dengan WebAudio: tidak ada berkas audio yang
 * diunduh, jadi tidak ada aset berhak cipta. Efek suara pendek dibangkitkan
 * saat dipanggil; musik adalah rangkaian nada pentatonik yang lembut.
 */

import { loadSettings, saveSettings, type GameSettings } from './save';

type Osc = OscillatorType;

const MUSIC_PATTERNS: Record<string, number[]> = {
  // Nada pentatonik (skala slendro sederhana) — tenang, tidak mengganggu.
  village: [392, 440, 523, 587, 523, 440, 392, 330],
  menu: [330, 392, 440, 523, 440, 392, 349, 294],
  ending: [294, 349, 392, 440, 392, 349, 330, 262],
};

const MUSIC_STEP = 0.62; // detik per nada
const AMBIENT_LEVEL = 0.045;

let ctx: AudioContext | null = null;
let musicGain: GainNode | null = null;
let sfxGain: GainNode | null = null;
let ambientGain: GainNode | null = null;
let musicTimer: number | null = null;
let musicStep = 0;
let currentMusic = '';
let ambientSource: AudioBufferSourceNode | null = null;
let currentAmbient = '';
let settings: GameSettings = loadSettings();

/** Dipanggil pada gestur pertama pemain (browser memblokir audio sebelum itu). */
export function unlock(): void {
  const context = ensureContext();
  if (context && context.state === 'suspended') void context.resume();
}

function ensureContext(): AudioContext | null {
  if (ctx) return ctx;
  const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!Ctor) return null;
  ctx = new Ctor();
  musicGain = ctx.createGain();
  sfxGain = ctx.createGain();
  ambientGain = ctx.createGain();
  musicGain.connect(ctx.destination);
  sfxGain.connect(ctx.destination);
  ambientGain.connect(ctx.destination);
  applyVolumes();
  return ctx;
}

function applyVolumes(): void {
  if (musicGain) musicGain.gain.value = settings.music * 0.5;
  if (sfxGain) sfxGain.gain.value = settings.sfx * 0.6;
  if (ambientGain) ambientGain.gain.value = settings.ambient * 0.5;
}

export function getSettings(): GameSettings {
  return { ...settings };
}

export function setVolumes(next: Partial<GameSettings>): void {
  settings = { ...settings, ...next };
  applyVolumes();
  saveSettings(settings);
}

// --- Dasar pembangkit suara -------------------------------------------------

function tone(
  freq: number,
  duration: number,
  options: { type?: Osc; gain?: number; delay?: number; sweepTo?: number; target?: GainNode | null } = {},
): void {
  const context = ensureContext();
  if (!context) return;
  const { type = 'sine', gain = 0.3, delay = 0, sweepTo } = options;
  const start = context.currentTime + delay;
  const osc = context.createOscillator();
  const envelope = context.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, start);
  if (sweepTo) osc.frequency.exponentialRampToValueAtTime(Math.max(30, sweepTo), start + duration);
  envelope.gain.setValueAtTime(0.0001, start);
  envelope.gain.exponentialRampToValueAtTime(Math.max(0.0002, gain), start + Math.min(0.02, duration * 0.2));
  envelope.gain.exponentialRampToValueAtTime(0.0001, start + duration);
  osc.connect(envelope);
  envelope.connect(options.target ?? sfxGain ?? context.destination);
  osc.start(start);
  osc.stop(start + duration + 0.05);
}

function noise(duration: number, filterFreq: number, gain = 0.25, delay = 0): void {
  const context = ensureContext();
  if (!context) return;
  const frames = Math.floor(context.sampleRate * duration);
  const buffer = context.createBuffer(1, frames, context.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < frames; i += 1) {
    data[i] = (Math.random() * 2 - 1) * (1 - i / frames);
  }
  const source = context.createBufferSource();
  source.buffer = buffer;
  const filter = context.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = filterFreq;
  const envelope = context.createGain();
  envelope.gain.value = gain;
  source.connect(filter);
  filter.connect(envelope);
  envelope.connect(sfxGain ?? context.destination);
  source.start(context.currentTime + delay);
}

/** Efek suara yang tersedia (sama dengan sfx_names() versi Godot). */
export const SFX_NAMES = [
  'click',
  'hover',
  'confirm',
  'cancel',
  'pickup',
  'quest',
  'note',
  'place',
  'success',
  'fail',
  'talk',
  'sparkle',
  'step1',
  'step2',
  'gong',
] as const;

export type SfxName = (typeof SFX_NAMES)[number];

export function playSfx(name: string, pitch = 1): void {
  switch (name) {
    case 'click':
      tone(880 * pitch, 0.07, { type: 'square', gain: 0.18 });
      break;
    case 'hover':
      tone(1180 * pitch, 0.05, { type: 'sine', gain: 0.09 });
      break;
    case 'confirm':
      tone(660 * pitch, 0.09, { type: 'triangle', gain: 0.2 });
      tone(990 * pitch, 0.12, { type: 'triangle', gain: 0.18, delay: 0.07 });
      break;
    case 'cancel':
      tone(440 * pitch, 0.1, { type: 'triangle', gain: 0.18 });
      tone(330 * pitch, 0.16, { type: 'triangle', gain: 0.16, delay: 0.07 });
      break;
    case 'pickup':
      [660, 880, 1174].forEach((freq, index) => {
        tone(freq * pitch, 0.12, { type: 'sine', gain: 0.2, delay: index * 0.05 });
      });
      break;
    case 'quest':
      tone(523 * pitch, 0.22, { type: 'triangle', gain: 0.22 });
      tone(784 * pitch, 0.34, { type: 'triangle', gain: 0.2, delay: 0.12 });
      break;
    case 'note':
      [784, 988, 1319].forEach((freq, index) => {
        tone(freq * pitch, 0.28, { type: 'triangle', gain: 0.16, delay: index * 0.08 });
      });
      break;
    case 'place':
      noise(0.09, 520, 0.2);
      tone(180 * pitch, 0.09, { type: 'sine', gain: 0.16 });
      break;
    case 'success':
      [523, 659, 784, 1047].forEach((freq, index) => {
        tone(freq * pitch, 0.32, { type: 'triangle', gain: 0.2, delay: index * 0.09 });
      });
      break;
    case 'fail':
      tone(320 * pitch, 0.16, { type: 'sawtooth', gain: 0.12 });
      tone(228 * pitch, 0.24, { type: 'sawtooth', gain: 0.1, delay: 0.1 });
      break;
    case 'talk':
      tone(520 * pitch, 0.06, { type: 'sine', gain: 0.13 });
      break;
    case 'sparkle':
      [1319, 1568, 2093].forEach((freq, index) => {
        tone(freq * pitch, 0.16, { type: 'sine', gain: 0.1, delay: index * 0.04 });
      });
      break;
    case 'step1':
    case 'step2':
      noise(0.06, name === 'step1' ? 260 : 220, 0.12);
      break;
    case 'gong':
      [110, 165, 220, 330].forEach((freq, index) => {
        tone(freq, 2.6 - index * 0.4, { type: 'sine', gain: 0.22 - index * 0.04 });
      });
      noise(0.6, 900, 0.08);
      break;
    default:
      tone(700, 0.08, { type: 'sine', gain: 0.15 });
      break;
  }
}

export function playUiClick(): void {
  playSfx('click');
}

// --- Musik & ambience ------------------------------------------------------

export function playMusic(track: string): void {
  if (track === currentMusic) return;
  ensureContext();
  stopMusic();
  currentMusic = track;
  const pattern = MUSIC_PATTERNS[track] ?? MUSIC_PATTERNS.village;
  musicStep = 0;
  const step = () => {
    if (!currentMusic) return;
    const base = pattern[musicStep % pattern.length];
    const octave = musicStep % 16 >= 8 ? 0.5 : 1;
    tone(base * octave, MUSIC_STEP * 1.6, {
      type: 'triangle',
      gain: 0.12,
      target: musicGain,
    });
    tone(base * octave * 2, MUSIC_STEP * 1.1, {
      type: 'sine',
      gain: 0.05,
      target: musicGain,
    });
    if (musicStep % 4 === 0) {
      tone(base * 0.5 * octave, MUSIC_STEP * 2.6, {
        type: 'sine',
        gain: 0.09,
        target: musicGain,
      });
    }
    musicStep += 1;
  };
  step();
  musicTimer = window.setInterval(step, MUSIC_STEP * 1000);
}

export function stopMusic(): void {
  currentMusic = '';
  if (musicTimer !== null) {
    window.clearInterval(musicTimer);
    musicTimer = null;
  }
}

export function currentMusicTrack(): string {
  return currentMusic;
}

export function playAmbient(track: string): void {
  if (track === currentAmbient) return;
  const context = ensureContext();
  if (!context || !ambientGain) return;
  stopAmbient();
  currentAmbient = track;
  const seconds = 4;
  const frames = Math.floor(context.sampleRate * seconds);
  const buffer = context.createBuffer(1, frames, context.sampleRate);
  const data = buffer.getChannelData(0);
  let last = 0;
  for (let i = 0; i < frames; i += 1) {
    // Derau merah lembut + gelombang lambat = angin/alam desa.
    last = last * 0.98 + (Math.random() * 2 - 1) * 0.02;
    data[i] = last + Math.sin((i / context.sampleRate) * 0.6) * 0.02;
  }
  const source = context.createBufferSource();
  source.buffer = buffer;
  source.loop = true;
  source.connect(ambientGain);
  ambientGain.gain.value = settings.ambient * AMBIENT_LEVEL * 10;
  source.start();
  ambientSource = source;
}

export function stopAmbient(): void {
  currentAmbient = '';
  if (ambientSource) {
    try {
      ambientSource.stop();
    } catch {
      /* sudah berhenti */
    }
    ambientSource = null;
  }
}

export function currentAmbientTrack(): string {
  return currentAmbient;
}
