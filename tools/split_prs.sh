#!/usr/bin/env bash
# Memecah riwayat cabang TAPAK NUSA menjadi dua pull request terpisah:
#   1) versi Godot  -> cabang pr/godot  (commit pertama di cabang sesi)
#   2) versi web    -> cabang pr/web    (commit kedua, bertumpu pada pr/godot)
#
# Jalankan sekali dari akar repositori (butuh git dan GitHub CLI `gh` yang
# sudah login: `gh auth login`):
#
#   bash tools/split_prs.sh
#
# Urutan menggabungkan: PR Godot dulu, lalu PR web.

set -euo pipefail

SESSION_BRANCH="${SESSION_BRANCH:-arena/01a10790-jelajahnusantara}"
GODOT_BRANCH="${GODOT_BRANCH:-pr/godot}"
WEB_BRANCH="${WEB_BRANCH:-pr/web}"
COMBINED_PR="${COMBINED_PR:-1}"

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }

command -v git >/dev/null 2>&1 || { echo "git tidak ditemukan."; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "GitHub CLI (gh) tidak ditemukan: https://cli.github.com"; exit 1; }

say "1/5  Mengambil riwayat terbaru"
git fetch origin
TIP="$(git rev-parse "origin/$SESSION_BRANCH")"
GODOT_COMMIT="$(git log --format=%H --reverse origin/main.."origin/$SESSION_BRANCH" | head -1)"
COUNT="$(git rev-list --count origin/main.."origin/$SESSION_BRANCH")"

echo "  cabang sesi : $SESSION_BRANCH"
echo "  commit Godot: ${GODOT_COMMIT:0:8}"
echo "  commit web  : ${TIP:0:8}"
if [ "$COUNT" != "2" ]; then
  echo "  peringatan: cabang berisi $COUNT commit (diharapkan 2)."
  echo "  Skrip ini mengambil commit pertama sebagai 'Godot' dan sisanya sebagai 'web'."
fi

say "2/5  Membuat cabang lokal $GODOT_BRANCH dan $WEB_BRANCH"
git branch -f "$GODOT_BRANCH" "$GODOT_COMMIT"
git branch -f "$WEB_BRANCH" "$TIP"

say "3/5  Mendorong kedua cabang ke origin"
git push origin "$GODOT_BRANCH" "$WEB_BRANCH"

say "4/5  Membuka dua pull request"
gh pr create \
  --base main \
  --head "$GODOT_BRANCH" \
  --title "TAPAK NUSA — versi Godot (proyek lengkap)" \
  --body-file tools/pr_bodies/godot.md

gh pr create \
  --base "$GODOT_BRANCH" \
  --head "$WEB_BRANCH" \
  --title "TAPAK NUSA — versi web (React + Canvas 2D)" \
  --body-file tools/pr_bodies/web.md

say "5/5  Menutup PR gabungan lama (kalau masih ada)"
if gh pr view "$COMBINED_PR" >/dev/null 2>&1; then
  gh pr close "$COMBINED_PR" --comment "PR gabungan ini dipecah menjadi dua supaya lebih mudah ditinjau: **versi Godot** (cabang \`$GODOT_BRANCH\`) dan **versi web** (cabang \`$WEB_BRANCH\`, bertumpu pada cabang Godot). Silakan tutup PR ini setelah kedua PR baru diperiksa."
else
  echo "  PR #$COMBINED_PR tidak ditemukan atau sudah ditutup."
fi

say "Selesai. Daftar PR yang terbuka:"
gh pr list --state open
echo
echo "Catatan: gabungkan PR Godot lebih dulu, lalu PR web — supaya beda PR web"
echo "tetap hanya berisi folder web/ dan tidak membawa perubahan Godot."
