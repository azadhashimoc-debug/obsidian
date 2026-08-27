# Panel'im — Sayfa ve Reklam Metinleri (AZ)

**Dil:** Azərbaycan dili · **Ton:** Aydın, sübutlu, güvən verən · **Tarix:** 2026-08-14

---

## 0. Mövqeləndirmə (bütün mətnlərin əsası)

SMM panel bazarında əsas etiraz **qiymət deyil, etibardır**:

1. "Pulu alıb xidməti verməyəcəklər."
2. "Hesabımın şifrəsini istəyəcəklər / hesabım bloklanacaq."
3. "Sifariş yarımçıq qalacaq, pulum yanacaq."

Panel'imin koddan təsdiqlənən üç cavabı var — bütün mətnlər bunun üstündə qurulub:

| Etiraz | Sübut (real, uydurma deyil) |
|---|---|
| Pulum yanacaq | Provayder rədd edərsə **tam məbləğ**, yarımçıq icrada **icra olunmayan hissə** avtomatik balansa qayıdır |
| Şifrəmi istəyəcəklər | Sistem yalnız profil/paylaşım linki ilə işləyir — sosial şəbəkə şifrəsi heç vaxt istənmir |
| Nə baş verdiyini bilmirəm | Sifariş statusu, balans və əməliyyat tarixçəsi paneldə açıq |

> **Xəbərdarlıq — düzəldilməli iddia:** Ana səhifədəki `AZƏRBAYCANIN #1 SMM PLATFORMASI` rozeti sübut edilə bilməyən iddiadır və reklam yoxlamasında da risklidir. Aşağıda hər yerdə **sayıla bilən** əvəzi verilib: `{{ total_services }}+ XİDMƏT · MANATLA ÖDƏNİŞ`.

---

## 1. Ana səhifə (`templates/core/home.html`)

### 1.1 Hero

**Rozet (badge)**
```
{{ total_services }}+ XİDMƏT · MANATLA ÖDƏNİŞ · ŞİFRƏSİZ
```

**H1 — variantlar**

- **A (tövsiyə olunur):** `Hesabını böyüt — şifrəni vermədən`
  *Səbəb: ən böyük etirazı birinci sətirdə öldürür. Fırlanan söz animasiyası (izləyici/bəyənmə/baxış) saxlanılır, sonra gəlir.*
- **B:** `İzləyici, bəyənmə, baxış — dəqiqələr içində, şifrəsiz`
  *Səbəb: nə satıldığını birbaşa deyir; SEO üçün açar sözlər başlıqda.*
- **C:** `Sifariş yarımçıq qalsa, pulun avtomatik geri qayıdır`
  *Səbəb: ən güclü fərqləndirici. Rəqiblərin çoxu bunu vermir. Reklam trafiki üçün ideal.*

**Mövcud fırlanan H1-i saxlamaq istəyirsənsə (minimal dəyişiklik):**
```
Hesabına [izləyici / bəyənmə / baxış / abunəçi / kəşfet]
qazandır — şifrəsiz, manatla
```
*"dəqiqələr içində" → "şifrəsiz, manatla" ilə əvəzləndi: ikisi də yoxlanıla bilən fakt, "dəqiqələr" isə provayderdən asılıdır.*

**Alt başlıq (subheadline)**
```
Instagram, TikTok, YouTube və Telegram göstəricilərini bir paneldən idarə et.
Sosial şəbəkə şifrəni istəmirik, manatla ödəyirsən, sifarişin gedişatını canlı izləyirsən.
```

**Axtarış düyməsi:** `Axtar` *(mövcud "Axtar ⚡" — emoji CTA-nı zəiflədir, çıxarıldı)*

**Hero etibar sətri (4 element — mövcud struktur saxlanılır)**
```
{{ min_price }} ₼-dan başlayan qiymətlər
Yarımçıq sifarişdə avtomatik geri qaytarma
Sosial şifrə tələb olunmur
Yerli kartla, manatla ödəniş
```
*Dəyişiklik səbəbi: "1-3 dəqiqəyə sürətli icra" zəmanət kimi oxunur, amma icra müddəti provayderdən asılıdır — gecikəndə etibar itirir. Yerinə yoxlanıla bilən vəd qoyuldu.*

### 1.2 Bölmə başlıqları

| Bölmə | Etiket | Başlıq |
|---|---|---|
| Platformalar | `PLATFORMALAR` | `Bütün əsas platformalar bir yerdə` ✓ *(dəyişiklik lazım deyil)* |
| Canlı aktivlik | `CANLI AKTİVLİK` | `Bu yaxınlarda tamamlananlar` |
| Populyar | `ƏN ÇOX SEÇİLƏN` | `Başqaları nədən başlayır?` |
| Necə işləyir | `NECƏ İŞLƏYİR` | `Üç addım, hesab şifrəsi yoxdur` |
| Üstünlüklər | `NİYƏ PANEL'İM` | `Riski bizim üzərimizə götürürük` |
| FAQ | `SUALLAR` | `Ən çox soruşulanlar` |

### 1.3 "Necə işləyir" addımları

```
01 · Xidməti seç
   Platformanı aç, qiyməti, minimum və maksimum limiti gör. Gizli haqq yoxdur.

02 · Linki yapışdır
   Profil və ya paylaşım linkini yaz, miqdarı seç. Şifrə heç bir addımda istənmir.

03 · Gedişatı izlə
   Sifariş verildiyi andan statusu paneldə yenilənir. Yarımçıq qalarsa fərq balansına qayıdır.
```

### 1.4 Üstünlüklər (4 kart)

```
🔒 Şifrəni istəmirik
   Xidmət yalnız açıq profil və ya paylaşım linki ilə işləyir. Giriş məlumatın bizdə heç vaxt olmur.

↩️ Yarımçıq qalsa, pulun qayıdır
   Provayder sifarişi rədd edərsə tam məbləğ, natamam icrada isə qalan hissə balansına avtomatik köçürülür.

💳 Manatla, yerli kartla
   Valyuta çevirməsi, xarici ödəniş sistemi və əlavə komissiya yoxdur.

📊 Qiymət də, limit də açıq
   Hər xidmətin dəyəri, minimum və maksimum miqdarı sifarişdən əvvəl yazılıb.
```

### 1.5 Yekun CTA

```
Etiket:   BAŞLA
Başlıq:   İlk sifarişini bu gün ver
Mətn:     Hesab açmaq pulsuzdur, kart tələb olunmur. Kataloqa bax, qiymətləri müqayisə et,
          hazır olanda balansını artır.
Düymə 1:  Xidmətlərə bax          (primary)
Düymə 2:  Pulsuz hesab aç         (ghost — qonaq istifadəçi üçün)
```

---

## 2. Qeydiyyat / giriş axını

### 2.1 `start.html` (reklam eniş səhifəsi)

**H1 — variantlar**

- **A (tövsiyə olunur):** `Sosial şəbəkə şifrəni vermədən hesabını böyüt`
  *Səbəb: reklamdan gələn soyuq trafikin birinci sualı təhlükəsizlikdir.*
- **B:** `Instagram, TikTok və YouTube üçün 900+ xidmət — hamısı bir paneldə`
- **C:** `Boost sifariş et, yarımçıq qalsa pulun geri qayıtsın`

**Kicker:** `ŞİFRƏSİZ · MANATLA · AVTOMATİK GERİ QAYTARMA`

**Lead:**
```
Instagram, TikTok, YouTube və Telegram göstəricilərini bir paneldən sifariş et.
Hesab açmaq pulsuzdur, kart tələb olunmur.
```

**CTA:** `Pulsuz hesab aç` → *(mövcud "Pulsuz qeydiyyatdan keç" uzun və rəsmidir; "hesab aç" nə əldə edildiyini deyir)*

**CTA altı qeydlər:**
```
Kart məlumatı istənmir
Hesab bir neçə saniyəyə hazır olur
```

**4 fayda maddəsi:**
```
01 Sosial şifrə yoxdur     — Instagram, TikTok və digər hesablarının giriş məlumatını istəmirik.
02 Yarımçıq qalsa, qayıdır  — İcra olunmayan hissənin məbləği balansına avtomatik qaytarılır.
03 Kartsız qeydiyyat        — Kataloqa baxmaq və hesab açmaq üçün kart lazım deyil.
04 Hər şey paneldə          — Sifariş, balans və əməliyyat tarixçən bir ekranda.
```

**Final bölmə:**
```
2 DƏQİQƏDƏ BAŞLA
Kataloqa baxmaq pulsuzdur
Hesabını aç, qiymətləri gör — ödəniş yalnız sifariş verəndə.
```

### 2.2 `signup.html`

```
Eyebrow:  YENİ HESAB
H1:       Hesabını aç, kataloqa bax
Intro:    Instagram, TikTok və digər hesablarının şifrəsini istəmirik.
          Aşağıdakı şifrə yalnız Panel'im hesabını qoruyur.        ← ✓ mövcud mətn yaxşıdır, saxla
Düymə:    Hesabımı aç
Trust:    ✓ Kart tələb olunmur   ✓ Sosial şifrə istənmir   ✓ Kataloqa baxmaq pulsuzdur
```
*"Hesabını aç və başla" → "Hesabını aç, kataloqa bax": "başla" boşdur, "kataloqa bax" növbəti addımı və sıfır riski göstərir.*

### 2.3 `login.html`

```
Eyebrow:  XOŞ GƏLDİN
H1:       Panelinə qayıt
Alt mətn: Sifarişlərin, balansın və tarixçən səni gözləyir.
Düymə:    Panelə keç
```

---

## 3. Balans artırma (`add_balance.html`)

Bu səhifədəki əsas problem **copy deyil, gözlənti idarəsidir**: ödəniş avtomatik deyil — köçürmə administrator tərəfindən yoxlanır. Bu, mətndə gizlədilməməli, əvvəlcədən deyilməlidir. Gizlədilsə, gözləmə müddəti şikayətə çevrilir.

### 3.1 Hero

```
Eyebrow:  BALANS ARTIR
H1:       Nə qədər əlavə edirsən?
Alt mətn: Hazırkı balansın: <strong>{{ wallet.balance }} ₼</strong>.
          Növbəti səhifədə sənə məxsus kart rekviziti və dəqiq məbləğ göstəriləcək —
          məbləği <strong>olduğu kimi</strong> köçür, təsdiqdən sonra balansına düşür.
```
*"olduğu kimi köçür" xəbərdarlığı aşağıdan yuxarı çıxarıldı: səhv məbləğ köçürmək dəstək müraciətlərinin ən böyük mənbəyidir.*

### 3.2 Bonus zolaqları

```
🎁  20 ₼ – 49 ₼ artır      →  +5% bonus balans, avtomatik
🚀  50 ₼ və yuxarı artır   →  +10% bonus balans, avtomatik
```

### 3.3 Düymə

```
Ödəniş rekvizitini göstər
```
*"Ödəniş səhifəsinə keç" növbəti addımın nə olduğunu demir. "Rekvizit" sözü istifadəçinin nə görəcəyini dəqiqləşdirir və gözlənilməzliyi aradan qaldırır.*

### 3.4 Yan panel — "Bonus qaydaları" → "Bilməli olduqların"

```
Bonus necə işləyir?
20 ₼ və yuxarı artımda +5%, 50 ₼ və yuxarıda +10% bonus balansına avtomatik əlavə olunur.
Kod yazmağa, müraciət etməyə ehtiyac yoxdur.

Məbləğ dəqiq olmalıdır
Növbəti səhifədə göstərilən rəqəmi qəpiyinə qədər eyni köçür. Fərqli məbləğ təsdiqi gecikdirir.

Minimum 1 ₼
Sınamaq üçün kiçik məbləğdən başlaya bilərsən.

Balans nağdlaşdırılmır
Artırdığın balans yalnız paneldəki xidmətlər üçün istifadə olunur.
```
*Sonuncu maddə narahat edici görünə bilər, amma **əvvəldən** deyilməsi sonradan yaranan mübahisəni tamamilə aradan qaldırır — və dürüstlük özü satır.*

### 3.5 Promo bloku

```
🎁 Promo kodun var?
Placeholder: Məs: PANEL2026
Düymə: Kodu tətbiq et
```

---

## 4. Meta / Instagram reklam mətnləri

Hər dəst: **Primary text · Headline (40 simvol) · Description · CTA**. Bütün rəqəmlər şablon dəyişəni ilə əvəzlənməli, uydurulmamalıdır.

### Dəst 1 — Etibar bucağı *(soyuq trafik üçün tövsiyə olunur)*

```
Primary text:
SMM panellərində ən çox qorxulan şey nədir? Pulu ödəyib nəticə görməmək.

Panel'im-də sifariş provayder tərəfindən rədd edilərsə tam məbləğ,
yarımçıq icra olunarsa qalan hissə balansına avtomatik qayıdır.

Sosial şəbəkə şifrəni isə heç bir addımda istəmirik — yalnız profil linki.

Kataloqa baxmaq pulsuzdur. panelim.az

Headline:     Yarımçıq qalsa, pulun qayıdır
Description:  Şifrəsiz · Manatla ödəniş · 900+ xidmət
CTA:          Sign Up
```

### Dəst 2 — Təhlükəsizlik bucağı

```
Primary text:
"Şifrəni ver, hesabını böyüdək" deyənlərdən uzaq dur.

Panel'im yalnız açıq profil və ya paylaşım linki ilə işləyir.
Instagram, TikTok, YouTube və Telegram üçün 900+ xidmət —
heç birində hesabının şifrəsi istənmir.

Manatla ödə, sifarişini paneldən izlə.

Headline:     Şifrəni vermədən hesabını böyüt
Description:  Yerli kartla, manatla · Kartsız qeydiyyat
CTA:          Learn More
```

### Dəst 3 — Yerli ödəniş bucağı

```
Primary text:
Xarici SMM saytlarında dollarla ödəyib komissiya verməkdən yorulmusan?

Panel'im manatla işləyir. Yerli kartla köçür, balansını artır,
Instagram və TikTok xidmətlərini birbaşa sifariş et.

20 ₼ artırana +5%, 50 ₼ artırana +10% bonus balans.

Headline:     Manatla ödə, bonusla başla
Description:  20 ₼-a +5%, 50 ₼-a +10% bonus
CTA:          Sign Up
```

### Dəst 4 — Qısa / Story-Reels üçün

```
Primary text:
Profil linkini yapışdır. Miqdarı seç. Vəssalam.
Şifrə yoxdur, dollar yoxdur, gizli haqq yoxdur.

Headline:     3 addımda sifariş, şifrəsiz
Description:  panelim.az — manatla ödəniş
CTA:          Sign Up
```

### Story / vizual üstü mətnlər (qısa)

```
Şifrəni istəmirik.
Yarımçıq qalsa, pulun qayıdır.
Manatla. Yerli kartla.
900+ xidmət. Bir panel.
Kataloqa baxmaq pulsuzdur.
```

---

## 5. Meta məzmun (SEO)

**Ana səhifə**
```
Title (60):  SMM Panel Azərbaycan — İzləyici, Bəyənmə, Baxış | Panel'im
Description: Instagram, TikTok, YouTube və Telegram üçün 900+ SMM xidməti.
             Şifrə tələb olunmur, manatla ödəyirsən, yarımçıq sifarişdə məbləğ
             avtomatik geri qaytarılır.
```

**Xidmətlər**
```
Title:       Bütün SMM xidmətləri və qiymətləri | Panel'im
Description: Instagram, TikTok, YouTube, Telegram xidmətlərinin qiymətini,
             minimum və maksimum limitini sifarişdən əvvəl gör. Manatla ödəniş.
```

**Balans artır**
```
Title:       Balans artır — manatla, bonuslu | Panel'im
Description: Yerli kartla balansını artır. 20 ₼-dan +5%, 50 ₼-dan +10% avtomatik
             bonus balans.
```

---

## 6. İstifadə edilməyən sözlər (siyahı)

Aşağıdakılar bütün mətnlərdən çıxarıldı və çıxarılmış qalmalıdır:

- **`#1`, `ən yaxşı`, `lider`** — sübut edilə bilməz, reklam rədd səbəbidir
- **`1-3 dəqiqəyə`** — provayderdən asılıdır, zəmanət kimi oxunur
- **`real auditoriya`** — mənbə provayderdir, təsdiq edə bilmirik
- **`100%`** — hər hansı kontekstdə şişirtmə siqnalıdır
- **`nida işarəsi (!)`** — CTA-nı zəiflədir
- **`sadəcə`, `çox`, `həqiqətən`** — doldurucu sözlər

---

## 7. Tətbiq sırası (təsirə görə)

1. **`start.html` H1 + CTA** — reklam pulu birbaşa bura axır, ən sürətli qazanc
2. **Reklam dəst 1 və 2** — A/B testi üçün eyni anda yayımla
3. **Ana səhifə hero + etibar sətri** — `#1` iddiasını çıxar
4. **`add_balance.html` hero + düymə** — dəstək müraciətlərini azaldır
5. **Meta title/description** — orqanik trafik, effekti gec görünür
