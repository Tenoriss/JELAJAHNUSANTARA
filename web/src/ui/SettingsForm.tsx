/** Pengaturan suara & data simpanan (dipakai menu utama dan menu jeda). */

import { useState } from 'react';
import * as audio from '../core/audio';
import { applyBrightness, deleteSave, hasSave, type GameSettings } from '../core/save';
import { notify } from '../core/store';

export default function SettingsForm() {
  const [settings, setSettings] = useState<GameSettings>(audio.getSettings());
  const [saved, setSaved] = useState(false);

  const update = (key: keyof GameSettings, value: number) => {
    const next = { ...settings, [key]: value };
    setSettings(next);
    audio.setVolumes({ [key]: value });
    if (key === 'brightness') applyBrightness(value);
  };

  const rows: { key: keyof GameSettings; label: string; hint: string }[] = [
    { key: 'music', label: 'Musik', hint: 'Musik latar' },
    { key: 'sfx', label: 'Efek Suara', hint: 'Langkah kaki, interaksi, puzzle' },
    { key: 'ambient', label: 'Suasana Desa', hint: 'Suara lingkungan desa' },
    { key: 'brightness', label: 'Kecerahan', hint: 'Menerangkan gambar bila layar terasa gelap' },
  ];

  return (
    <div className="settings">
      {rows.map((row) => (
        <label key={row.key} className="settings__row">
          <span className="settings__label">{row.label}</span>
          <input
            type="range"
            min={row.key === 'brightness' ? 0.6 : 0}
            max={row.key === 'brightness' ? 1.8 : 1}
            step={0.05}
            value={settings[row.key]}
            title={row.hint}
            onChange={(event) => update(row.key, Number(event.target.value))}
          />
          <span className="settings__value">
            {row.key === 'brightness' ? `${Math.round(settings[row.key] * 100)}%` : `${Math.round(settings[row.key] * 100)}%`}
          </span>
        </label>
      ))}
      <div className="settings__row">
        <button
          type="button"
          className="btn btn--small"
          disabled={!hasSave()}
          onClick={() => {
            deleteSave();
            setSaved(true);
            notify();
          }}
        >
          Hapus simpanan
        </button>
        <span className="settings__note">{saved ? 'Simpanan dihapus.' : 'Menghapus riwayat LANJUTKAN.'}</span>
      </div>
      <p className="settings__note">
        Kecerahan hanya mengubah tampilan gambar; pengaturannya ikut tersimpan. Semua suara dibuat sendiri
        di dalam game (WebAudio) — tidak ada berkas audio yang diunduh.
      </p>
    </div>
  );
}
