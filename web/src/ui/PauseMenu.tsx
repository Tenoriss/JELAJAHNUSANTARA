/**
 * Menu jeda (ESC): Lanjut, Quest, Inventaris, Catatan Budaya, Simpan,
 * Pengaturan, dan Kembali ke Menu.
 */

import * as actions from '../core/actions';
import * as audio from '../core/audio';
import * as quests from '../core/quests';
import { saveGame } from '../core/save';
import { notify, state, useGame } from '../core/store';
import { InventoryPanel, NoteReader, NotesPanel, QuestPanel } from './panels';
import SettingsForm from './SettingsForm';

const TITLES: Record<Exclude<typeof state.menuPanel, null>, string> = {
  pause: 'Jeda',
  quests: 'Quest',
  inventory: 'Inventaris',
  notes: 'Catatan Budaya',
  settings: 'Pengaturan',
};

export default function PauseMenu() {
  const game = useGame();
  const panel = game.menuPanel;
  if (!panel) return null;

  const open = (next: Exclude<typeof state.menuPanel, null>) => {
    audio.playUiClick();
    state.menuPanel = next;
    notify();
  };

  const close = () => {
    audio.playUiClick();
    state.menuPanel = null;
    actions.setPaused(false);
    notify();
  };

  return (
    <div className="modal">
      <div className="modal__panel">
        <h2 className="panel__title">{TITLES[panel]}</h2>

        {panel === 'pause' && (
          <div className="pause__buttons">
            <button type="button" className="btn btn--primary" onClick={close}>
              Lanjut
            </button>
            <button type="button" className="btn" onClick={() => open('quests')}>
              Quest
            </button>
            <button type="button" className="btn" onClick={() => open('inventory')}>
              Inventaris
            </button>
            <button type="button" className="btn" onClick={() => open('notes')}>
              Catatan Budaya
            </button>
            <button
              type="button"
              className="btn"
              onClick={() => {
                saveGame(null, false);
                notify();
              }}
            >
              Simpan
            </button>
            <button type="button" className="btn" onClick={() => open('settings')}>
              Pengaturan
            </button>
            <button
              type="button"
              className="btn btn--danger"
              onClick={() => {
                audio.playSfx('cancel');
                actions.returnToMainMenu();
              }}
            >
              Kembali ke Menu
            </button>
            <p className="pause__progress">
              Quest selesai: {quests.completedQuests().length} · Catatan: {game.notes.length}
            </p>
          </div>
        )}

        {panel === 'quests' && <QuestPanel />}
        {panel === 'inventory' && <InventoryPanel />}
        {panel === 'notes' && <NotesPanel />}
        {panel === 'settings' && <SettingsForm />}

        {panel !== 'pause' && (
          <div className="modal__actions">
            <button type="button" className="btn" onClick={() => open('pause')}>
              Kembali
            </button>
            <button type="button" className="btn btn--primary" onClick={close}>
              Lanjut Bermain
            </button>
          </div>
        )}
      </div>
      <NoteReader />
    </div>
  );
}
