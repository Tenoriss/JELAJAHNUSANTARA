/**
 * Panel-panel menu: daftar quest, inventaris, catatan budaya, dan pembaca
 * catatan. Semua membaca data yang sama dengan versi Godot.
 */

import { itemColor, itemName, items, noteText, noteTitle, notes, questOrder, quests, totalNotes } from '../core/data';
import * as questsApi from '../core/quests';
import { notify, state, useGame } from '../core/store';
import { QuestStatus } from '../core/types';

function statusLabel(questId: string): { text: string; className: string } {
  const quest = state.quests[questId];
  if (!quest) return { text: 'Belum dimulai', className: 'tag tag--idle' };
  if (quest.status === QuestStatus.Completed) return { text: 'Selesai', className: 'tag tag--done' };
  if (quest.status === QuestStatus.Active) return { text: 'Berjalan', className: 'tag tag--active' };
  return { text: 'Belum dimulai', className: 'tag tag--idle' };
}

export function QuestPanel() {
  useGame();
  return (
    <div className="panel__body">
      {questOrder.map((questId) => {
        const definition = quests[questId];
        const status = statusLabel(questId);
        const questState = state.quests[questId];
        return (
          <article key={questId} className="card">
            <header className="card__head">
              <h3>{definition.title}</h3>
              <span className={status.className}>{status.text}</span>
            </header>
            <p className="card__text">{definition.description}</p>
            <ul className="hud__objectives">
              {definition.objectives.map((objective, index) => {
                const progress = questState?.objectives[index]?.progress ?? 0;
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
          </article>
        );
      })}
    </div>
  );
}

export function InventoryPanel() {
  const game = useGame();
  const owned = Object.keys(game.items).filter((itemId) => (game.items[itemId] ?? 0) > 0);
  if (owned.length === 0) {
    return (
      <div className="panel__body">
        <p className="panel__text">
          Belum ada barang. Perlengkapan acara Guyub Desa diambil dari warga dan dari sekitar desa.
        </p>
      </div>
    );
  }
  return (
    <div className="panel__body">
      {owned.map((itemId) => (
        <article key={itemId} className="card card--item">
          <span className="swatch" style={{ background: itemColor(itemId) }} />
          <div>
            <h3>
              {itemName(itemId)} <small>×{game.items[itemId]}</small>
            </h3>
            <p className="card__text">{items[itemId]?.description ?? ''}</p>
          </div>
        </article>
      ))}
    </div>
  );
}

export function NotesPanel() {
  const game = useGame();
  const all = Object.keys(notes);
  return (
    <div className="panel__body">
      <p className="panel__text">
        Catatan budaya ditemukan dengan membaca papan, memeriksa sumur, dan berbicara dengan warga.
        Terkumpul {game.notes.length} dari {totalNotes()}.
      </p>
      {all.map((noteId) => {
        const found = game.notes.includes(noteId);
        return (
          <article key={noteId} className={`card card--note ${found ? '' : 'card--locked'}`}>
            <header className="card__head">
              <h3>{found ? noteTitle(noteId) : '？？？'}</h3>
              {found && (
                <button
                  type="button"
                  className="btn btn--tiny"
                  onClick={() => {
                    state.noteReader = noteId;
                    notify();
                  }}
                >
                  Baca
                </button>
              )}
            </header>
            <p className="card__text">
              {found ? `${noteText(noteId).slice(0, 90)}…` : 'Belum ditemukan di desa.'}
            </p>
          </article>
        );
      })}
    </div>
  );
}

export function NoteReader() {
  useGame();
  const noteId = state.noteReader;
  if (!noteId) return null;
  return (
    <div className="modal">
      <div className="modal__panel modal__panel--note">
        <h2 className="panel__title">{noteTitle(noteId)}</h2>
        <p className="note__text">{noteText(noteId)}</p>
        <div className="modal__actions">
          <button
            type="button"
            className="btn"
            onClick={() => {
              state.noteReader = null;
              notify();
            }}
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}

export { questsApi };
