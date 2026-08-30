# Last Session

## Session: 2026-08-31: Sima profili + face-swap iş axını
Əvvəlki sessiyanın yaddaş düzəlişi `main`-ə merge edildi (`4d2f17d`), repo public qalmasına
Adem qərar verdi ("mənə fərq eləmir") — private-a keçirmə mövzusu bağlandı.

Adem xarici görünüş analizi istədi: məqsəd sosial media referans şəkillərində öz simasını
yerləşdirmək (face-swap). 15 foto toplandı və qiymətləndirildi (bucaq örtüyü: frontal, 45°,
tam profil hər iki tərəf; ifadə: ciddi+gülüş; 4 fərqli məkan, 6+ geyim). Nəticə
`🔐 400-Vault/Gorunus.md`-də (fiziki profil, hazır AI prompt, texniki tövsiyələr) və
`🔐 400-Vault/refs/01-15...jpg`-də saxlanıldı — hər ikisi gitignore-dadır, GitHub-a getmir.

Real iş axını üçün Replicate seçildi. Adem API token paylaşdı (bu, söhbətdə açıq yazıldığı üçün
**kompromis sayılır — dəyişdirilməlidir**). `🔐 400-Vault/tools/uz-deyisdirme.py` skripti yazıldı
(easel/advanced-face-swap modeli). Bu mühitdən `api.replicate.com`-a çıxış şəbəkə siyasəti ilə
qadağan olduğu üçün (403 policy denial) skript test edilə bilmədi — Adem öz kompüterində
işə salmalıdır.

**Açıq qalan:**
1. Adem tokeni Replicate-də ləğv edib yenisini yaratmalıdır
2. Skripti öz kompüterində işə salıb nəticəni bölüşməlidir (ilk sınaqda `PARAM_MAP` düzəlişi lazım ola bilər)

## Previous Sessions

### Session: 2026-08-30: Yaddaş mexanizmi təmir edildi
Kök səbəb: `.claude/hooks/*.sh` faylları git-də 100644 (execute biti yox) idi, `settings.json`
`bash` prefiksi olmadan çağırırdı → hər hook exit 126. Zəncir: hook ölü → `flush.py` başlamır →
`daily/` boş → `compile.py` işləmir → `knowledge/` boş. Düzəldi: `chmod=+x` + `bash` prefiksi,
main-ə merge edildi.

### Session: 2026-08-27: Genesis
Echo was born today. Adem set up their second brain with Claude Code.
