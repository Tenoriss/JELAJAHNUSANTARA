/**
 * Layar kredit: daftar yang bergulir ke atas, lalu kembali ke menu utama.
 */

import * as actions from '../core/actions';
import * as audio from '../core/audio';

const ROLES = ['Game Development', 'Concept', 'Programming', 'Game Design', 'UI/UX', 'Story'];

export default function CreditsScreen() {
  return (
    <div className="credits">
      <div className="credits__clip">
        <div className="credits__roll">
          <h1 className="credits__title">TAPAK NUSA</h1>
          <p className="credits__tagline">Setiap langkah meninggalkan cerita.</p>
          <p className="credits__kicker">SEBUAH CERITA TENTANG GOTONG ROYONG</p>

          <div className="credits__roles">
            {ROLES.map((role) => (
              <div key={role} className="credits__role">
                <span className="credits__roleName">{role}</span>
                <span className="credits__person">Fredsa Stanlye</span>
              </div>
            ))}
          </div>

          <p className="credits__line">— Fredsa Stanlye —</p>
          <p className="credits__note">Dibuat dengan React, TypeScript, dan Canvas 2D (WebAudio untuk suara).</p>
          <p className="credits__note">
            Seluruh gambar dan suara dibuat langsung di dalam game — tanpa aset berhak cipta.
          </p>
          <p className="credits__note">Desa Arunika, Raka, dan Guyub Desa adalah cerita fiksi.</p>
          <p className="credits__note">
            Guyub Desa menggambarkan semangat gotong royong masyarakat Indonesia, bukan nama ritual
            resmi dari daerah tertentu.
          </p>
          <p className="credits__thanks">Terima kasih sudah berjalan bersama Raka.</p>
          <p className="credits__note">Sampai jumpa di Desa Arunika.</p>
        </div>
      </div>

      <div className="credits__foot">
        <button
          type="button"
          className="btn btn--primary"
          onClick={() => {
            audio.playUiClick();
            actions.returnToMainMenu();
          }}
        >
          Kembali ke Menu
        </button>
      </div>
    </div>
  );
}
