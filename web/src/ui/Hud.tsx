/**
 * HUD dalam permainan: penunjuk quest, penghitung catatan, waktu bermain,
 * petunjuk tombol interaksi, toast barang, spanduk tujuan, dan label wilayah.
 */

import { useEffect } from 'react';
import { quests } from '../core/data';
import { formatPlayTime } from '../core/save';
import { currentQuestId, objectiveProgress } from '../core/quests';
import { notify, useGame } from '../core/store';

export default function Hud() {
  const game = useGame();

  // Waktu bermain bertambah di mesin dunia tanpa memicu gambar ulang; detik ini
  // yang menyegarkan HUD supaya jamnya tetap berjalan.
  useEffect(() => {
    const timer = window.setInterval(() => notify(), 1000);
    return () => window.clearInterval(timer);
  }, []);

  const questId = currentQuestId();
  const definition = questId ? quests[questId] : null;
  const totalNotes = Object.keys(game.notes).length;
  const knownNotes = game.notes.length;

  return (
    <div className="hud">
      {definition && (
        <section className="hud__quest">
          <h2 className="hud__questTitle">{definition.title}</h2>
          <p className="hud__questDesc">{definition.description}</p>
          <ul className="hud__objectives">
            {definition.objectives.map((objective, index) => {
              const progress = objectiveProgress(questId as string, index);
              const done = progress >= objective.required;
              return (
                <li key={objective.id} className={done ? 'is-done' : ''}>
                  <span className="hud__mark">{done ? '✓' : '•'}</span>
                  <span>{objective.text}</span>
                  {objective.required > 1 && (
                    <span className="hud__count">
                      {progress}/{objective.required}
                    </span>
                  )}
                </li>
              );
            })}
          </ul>
        </section>
      )}

      <aside className="hud__stats">
        <span title="Catatan budaya yang ditemukan">📖 {knownNotes}/{totalNotes}</span>
        <span title="Waktu bermain">⏱ {formatPlayTime(game.playTime)}</span>
      </aside>

      {game.area && (
        <div className="hud__area" key={game.area.id}>
          <strong>{game.area.title}</strong>
          <small>{game.area.subtitle}</small>
        </div>
      )}

      {game.banner && (
        <div className="hud__banner" key={game.banner.id}>
          <strong>{game.banner.title}</strong>
          {game.banner.subtitle && <small>{game.banner.subtitle}</small>}
        </div>
      )}

      <div className="hud__toasts">
        {game.toasts.map((toast) => (
          <div className="toast" key={toast.id} style={{ borderColor: toast.color }}>
            {toast.text}
          </div>
        ))}
      </div>

      {game.prompt && !game.dialogue && (
        <div className="hud__prompt">
          <span className="hud__key">E</span>
          <span>{game.prompt}</span>
        </div>
      )}

      <div className="hud__controls">
        WASD jalan · E interaksi · SPACE lanjut · Q jurnal · ESC menu
      </div>
    </div>
  );
}
