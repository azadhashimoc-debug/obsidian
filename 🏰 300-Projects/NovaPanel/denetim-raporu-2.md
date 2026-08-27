# NovaPanel / Panel'im — İkinci Denetim Raporu

**Tarih:** 5 Avqust 2026
**Kapsam:** öncelikli denetim — kimlik doğrulama & yetki, mali/iş mantığı, temel kullanıcı akışları + destekleyici kod analizi
**Yöntem:** çalışan dev sunucusuna karşı canlı tarayıcı ve HTTP testleri (`localhost:8000`), tam test paketi çalıştırma, kaynak kod okuma
**Önceki rapor:** `denetim-raporu.md` (3 Avqust 2026)

---

## Özet

Önceki denetimdeki kritik maddelerin büyük bölümü kapatılmış. Doğruladıklarım:
`/xidmetler/<slug>/` sayfaları artık çalışıyor (K-01), `STATIC_ROOT` tanımlı (K-02),
dekont doğrulaması Pillow ile yapılıyor (K-03), `submit_order` şartlı UPDATE ile
kilitleniyor (K-04), kısmi iade var (K-05), takılan sipariş toplayıcısı var (K-06),
ödeme oturumu sınırı veritabanı kısıtıyla korunuyor (K-07), `check --deploy` temiz (K-08).
Test sayısı 93'ten **361**'e çıkmış.

Ancak **yayına hazır değil.** Bu turda 3 kritik, 3 yüksek, 6 orta öncelikli yeni bulgu var.
En ciddisi: **sistemdeki en yetkili hesabın giriş sayfasında hiçbir brute-force koruması yok.**

| Önem | Adet |
|---|---:|
| 🔴 Kritik | 3 |
| 🟠 Yüksek | 3 |
| 🟡 Orta | 6 |

---

# 🔴 KRİTİK

## D-01 · Admin giriş sayfasında hız sınırı ve CAPTCHA yok

**Kategori:** Güvenlik / Kimlik doğrulama
**Kritiklik:** 🔴 Critical
**Dosya:** `config/urls.py:47` — `path("admin/", admin.site.urls)`

**Problem:**
`/accounts/login/` iki ayrı hız sınırıyla korunuyor (`login-ip` ve `login-user`, 10/15dk)
ve Turnstile CAPTCHA'sından geçiyor. Ancak `admin.site.urls` hiçbir sarmalayıcıdan
geçmiyor — `/admin/login/` tamamen korumasız. Bu, ödemeleri onaylayabilen, bakiyeleri
elle değiştirebilen ve tüm dekontları okuyabilen hesabın giriş kapısı.

**Tekrarlama adımları:**
1. `/accounts/login/` adresine 14 kez yanlış şifreyle POST gönder.
2. `/admin/login/` adresine 25 kez yanlış şifreyle POST gönder.

**Beklenen:** Her iki uçta da belirli bir denemeden sonra 429 dönmeli.
**Fiili:** Kullanıcı girişi 11. denemede 429'a geçti; admin girişi 25 denemenin
**hepsinde 200** döndü.

**Kanıt:**
```
/accounts/login/ : 200 200 200 200 200 200 200 200 200 200 429 429 429 429
/admin/login/    : 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200
                   200 200 200 200 200 200 200 200 200 200
```

**Muhtemel sebep:** Hız sınırı `LoginView` için elle eklenmiş; `admin.site.urls`
Django'nun kendi giriş görünümünü kullandığı için kapsam dışında kalmış.

**Öneri:**
1. `AdminSite.login` görünümünü `rate_limit` ile sar (aynı iki anahtar: `ip` ve
   `post:username`) veya özel bir `AdminSite` alt sınıfı tanımla.
2. Admin URL'ini `/admin/` dışında tahmin edilemez bir yola taşı
   (`DJANGO_ADMIN_URL` ortam değişkeni).
3. Yönetici hesapları için zorunlu iki faktörlü doğrulama ekle.
4. Ters vekil (nginx/Caddy) katmanında `/admin/` yolunu IP allow-list'e al.

**Zorluk:** Asan (1–2 saat)

---

## D-02 · Google OAuth ile hesap ele geçirme (pre-hijacking)

**Kategori:** Güvenlik / Kimlik doğrulama
**Kritiklik:** 🔴 Critical (gizli — OAuth anahtarları tanımlanınca aktifleşir)
**Dosya:** `core/views.py:326`, `core/views.py:247` (`signup`)

**Problem:**
Kayıt sırasında e-posta doğrulaması **yok** — `RegistrationForm` yalnızca adresin
benzersizliğine bakıyor. Google callback'i ise kullanıcıyı **yalnızca e-posta
eşleşmesiyle** buluyor ve oturum açıyor:

```python
user = User.objects.filter(email__iexact=email).first()
...
login(request, user, backend="django.contrib.auth.backends.ModelBackend")
```

Saldırı: saldırgan kurbanın e-posta adresiyle (`kurban@gmail.com`) normal kayıt olur ve
kendi bildiği bir şifreyi belirler. Kurban daha sonra "Google ilə daxil ol" ile giriş
yapar, sistem e-posta eşleşmesiyle **saldırganın oluşturduğu hesaba** bağlar. Saldırgan
şifreyi bildiği için kurbanın bakiyesine, sipariş geçmişine ve dekontlarına erişmeye
devam eder.

**Mevcut durum:** `DJANGO_GOOGLE_OAUTH_CLIENT_ID`/`SECRET` tanımlı olmadığı için akış
şu anda kapalı. Anahtarlar production'da tanımlandığı **an** açık aktifleşir.

**Beklenen:** Doğrulanmamış e-postayla açılmış yerel hesap, Google kimliğine sessizce
bağlanmamalı.
**Fiili:** Sessizce bağlanıyor ve oturum açılıyor.

**Öneri:**
1. Kayıtta e-posta doğrulamasını zorunlu kıl **veya** `EmailVerification.is_verified`
   olmayan bir hesaba OAuth ile bağlanmayı reddet.
2. Bağlantı öncesi kullanıcıdan mevcut şifresini iste (hesap birleştirme onayı).
3. `google_sub` (OpenID `sub` alanı) için ayrı bir sütun tut ve eşleştirmeyi e-posta
   yerine bu değişmez kimlik üzerinden yap.

**Zorluk:** Orta (yarım gün)

---

## D-03 · Redis kesintisinde önbellek katmanı çöküyor — geri düşüş yok

**Kategori:** Dayanıklılık / Altyapı
**Kritiklik:** 🔴 Critical
**Dosya:** `core/models.py:23` (`get_default_markup_percent`), `core/signals.py:18`

**Problem:**
`core/ratelimit.py` Redis erişilemezse bilinçli olarak SQL'e düşüyor ve bunu belgeliyor
("Fail-open EDİLMİR"). Ancak **önbellek katmanında aynı özen yok**: `REDIS_URL` tanımlıysa
`CACHES` doğrudan `RedisCache` oluyor ve `cache.get`/`cache.set` çağrıları Redis kapalıyken
`ConnectionError` fırlatıyor — hiçbir yerde yakalanmıyor.

**Etki alanı (ölçüldü, abartmıyorum):** Genel sayfalar etkilenmiyor — ana sayfa, katalog
ve panel Redis kapalıyken sorunsuz açıldı. Kırılan yollar: `Service.save()` (katalog
senkronizasyonu, admin'den servis düzenleme), `SiteSetting` kaydetme ve bunları çağıran
tüm Celery görevleri.

**Tekrarlama adımları:**
1. Redis'i kapat, `.env` içinde `REDIS_URL=redis://127.0.0.1:6379/0` bırak.
2. `manage.py test` çalıştır.

**Beklenen:** Önbellek erişilemezse sessizce atlanmalı (önbellek kritik veri değil).
**Fiili:** 361 testin **273'ü** `redis.exceptions.ConnectionError` ile hata verdi.
Aynı paket `REDIS_URL=""` ile çalıştırıldığında 361 testten yalnızca 1'i hata verdi.

**Kanıt:**
```
REDIS_URL tanımlı, Redis kapalı : Ran 361 tests in 567.171s — FAILED (errors=273)
REDIS_URL boş                   : Ran 361 tests in  19.582s — FAILED (errors=1, skipped=6)

core/signals.py:18, in refresh_default_service_prices
    cache.set(DEFAULT_MARKUP_CACHE_KEY, markup, DEFAULT_MARKUP_CACHE_TIMEOUT)
redis.exceptions.ConnectionError: Error 10061 connecting to 127.0.0.1:6379
```

**Muhtemel sebep:** Aşama 4'te Redis eklenirken hız sınırı için geri düşüş yazılmış,
önbellek yolu için aynı şey düşünülmemiş.

**Öneri:**
1. `get_default_markup_percent` ve `refresh_default_service_prices` içindeki önbellek
   çağrılarını `try/except Exception` ile sar; hata durumunda veritabanından oku ve
   `logger.warning` bas. Önbellek performans katmanıdır, doğruluk kaynağı değil.
2. Alternatif: `django-redis` kullanıp `IGNORE_EXCEPTIONS: True` ayarla.
3. Ek yan fayda: geliştirici makinesinde Redis kurmadan test çalıştırılabilir hale gelir.

**Zorluk:** Asan (1–2 saat)

---

# 🟠 YÜKSEK

## D-04 · `maintenance_mode` ölü bir anahtar — hiçbir yerde okunmuyor

**Kategori:** İş mantığı / Operasyon
**Kritiklik:** 🟠 High
**Dosya:** `core/models.py:45`, `core/admin.py:45`

**Problem:** `SiteSetting.maintenance_mode` alanı tanımlı ve admin panelinde
"Biznes qaydaları" bölümünde düzenlenebilir durumda. Ancak alan **hiçbir görünümde,
middleware'de veya şablonda okunmuyor.** Yönetici bakım moduna aldığını sanarken site
normal çalışmaya, sipariş almaya ve bakiyeden para düşmeye devam eder.

**Kanıt:**
```
$ grep -rn "maintenance_mode" --include=*.py --include=*.html .
./core/admin.py:45:  ("Biznes qaydaları", {"fields": (..., "maintenance_mode")}),
./core/models.py:45: maintenance_mode = models.BooleanField("Baxım rejimi", default=False)
```
Tanım ve admin girişi dışında tek bir okuma yok.

**Öneri:** Ya bir middleware yaz (bayrak açıkken `is_staff` olmayan herkese 503 +
bakım şablonu göster, `/admin/` hariç), ya da alanı ve admin girişini tamamen kaldır.
**Yanıltıcı bir kontrol, olmayan kontrolden daha tehlikelidir.**

**Zorluk:** Asan (2–3 saat)

---

## D-05 · Müşteriye Django admin arayüzü gösteriliyor

**Kategori:** UX / Bilgi ifşası
**Kritiklik:** 🟠 High
**Dosya:** `config/urls.py:50` — `path("accounts/", include("django.contrib.auth.urls"))`

**Problem:** `django.contrib.auth.urls` tüm hesap görünümlerini yayına açıyor, ancak
proje yalnızca `login` ve `password_reset` şablonlarını özelleştirmiş.
`/accounts/password_change/` için proje şablonu yok; Django `django.contrib.admin`
paketinden gelen şablonu kullanıyor.

**Tekrarlama adımları:**
1. Normal (staff olmayan) bir kullanıcıyla giriş yap.
2. `/accounts/password_change/` adresine git.

**Beklenen:** Sitenin kendi tasarımında bir şifre değiştirme sayfası.
**Fiili:** "Django administrasiya" başlıklı, koyu admin temalı, sayfa başlığı
**"Şifrəni dəyiş | Django sayt administratoru"** olan bir sayfa. Breadcrumb "Ana səhifə"
admin index'ine bağlanıyor.

**Kanıt:** Ekran görüntüsü alındı — admin mavi başlık çubuğu, admin breadcrumb'ı ve
admin form stilleri müşteriye görünüyor.

**Etki:** (a) Para yatırılan bir panelde güven kaybı — sayfa bozuk/sahte görünüyor.
(b) Admin arayüzünün varlığı ve yol yapısı sıradan müşteriye ifşa oluyor.

**Öneri:**
1. `templates/registration/password_change_form.html` ve `password_change_done.html`
   dosyalarını site tasarımıyla oluştur.
2. `django.contrib.auth.urls` yerine yalnızca gerçekten kullanılan yolları tek tek
   dahil et — kullanılmayan uçlar yayına açılmasın.
3. Panel menüsündeki "Ayarlar" bağlantısını (şu an `href="#"`) bu sayfaya bağla.

**Zorluk:** Asan (2–3 saat)

---

## D-06 · Content-Security-Policy başlığı yok

**Kategori:** Güvenlik
**Kritiklik:** 🟠 High
**Dosya:** `config/settings.py:340`

**Problem:** Güvenlik başlıkları kısmen doğru kurulmuş (`X-Frame-Options: DENY`,
`X-Content-Type-Options: nosniff`, `Referrer-Policy: same-origin`,
`Cross-Origin-Opener-Policy: same-origin`) ancak **CSP tanımlı değil.**

Bu, sitenin bağlamında önemli: servis adları ve açıklamaları **sağlayıcı API'sinden**
geliyor (bizim kontrolümüzde değil), `Guide.body` serbest metin ve dekont görselleri
`disposition=inline` ile tarayıcıda açılabiliyor. Django'nun otomatik şablon kaçışı
ilk savunma hattı, ama tek hat olmamalı.

**Kanıt:**
```
$ curl -sI http://localhost:8000/
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin
Cross-Origin-Opener-Policy: same-origin
```
`Content-Security-Policy` başlığı yok.

**Öneri:** Django 5'in yerleşik `SECURE_CSP` ayarını veya `django-csp` paketini kullan.
Sıkı bir başlangıç: `default-src 'self'; img-src 'self' data:; script-src 'self';
style-src 'self'; frame-ancestors 'none'; form-action 'self'`. Turnstile kullanılıyorsa
`https://challenges.cloudflare.com` alan adını script/frame kaynaklarına ekle. Önce
`Content-Security-Policy-Report-Only` ile yayına al, ihlalleri izle, sonra zorunlu kıl.

**Zorluk:** Orta (yarım gün — satır içi script/stil temizliği gerekebilir)

---

# 🟡 ORTA

## D-07 · `transaction_history_export` ekrandaki filtreyi yok sayıyor

**Kategori:** Fonksiyonel hata
**Kritiklik:** 🟡 Medium
**Dosya:** `core/views.py:465`

**Problem:** Sipariş dışa aktarımında bu sorun bilinçli olarak çözülmüş —
`filtered_orders` hem sayfa hem CSV tarafından paylaşılıyor ve kodda şu yorum var:
*"əks halda istifadəçi filtrlənmiş siyahıya baxıb 'CSV yüklə' düyməsinə basanda bütün
tarixçəni alır və bunu heç bir yerdə görmür."* Aynı hata işlem geçmişinde duruyor:

```python
# transaction_history (satır 452) — filtre uygulanıyor
if selected_type:
    transactions = transactions.filter(transaction_type=selected_type)

# transaction_history_export (satır 465) — filtre yok
transactions = wallet.transactions.order_by("-created_at")
```

**Beklenen:** "Yalnızca iadeler" filtresi seçiliyken CSV yalnızca iadeleri içermeli.
**Fiili:** CSV tüm işlem geçmişini içeriyor; kullanıcı farkı fark etmiyor.

**Öneri:** Sipariş tarafındaki desene uy — ortak bir `filtered_transactions(request)`
yardımcı fonksiyonu çıkar, hem görünüm hem dışa aktarım onu çağırsın.

**Zorluk:** Asan (30 dakika)

---

## D-08 · Yönetim komutları UTF-8 olmayan locale'de çöküyor

**Kategori:** Operasyon / Dayanıklılık
**Kritiklik:** 🟡 Medium
**Dosya:** `core/management/commands/reconcile_wallets.py:25`

**Problem:** Komut çıktıları Azerbaycan alfabesi içeriyor (`ə`, `ğ`, `ş`). Çalışma
ortamının kodlaması UTF-8 değilse `self.stdout.write` `UnicodeEncodeError` ile çöküyor.
Windows'ta (cp1254) doğrudan gözlemlendi; Linux'ta systemd birimleri sıklıkla
`LANG=C`/POSIX locale ile çalışır ve aynı hatayı üretir.

**Kanıt:**
```
File "core/management/commands/reconcile_wallets.py", line 25, in handle
    self.stdout.write(report.summary_text())
UnicodeEncodeError: 'charmap' codec can't encode character 'ə' in position 36
```
Bu, `REDIS_URL` boşken kalan tek gerçek test hatasının da sebebi
(`WalletReconciliationTests.test_command_exits_nonzero_when_dirty`).

**Not:** Celery yolu güvende — `reconcile_wallets_task` komutu değil
`run_reconciliation_and_log()` fonksiyonunu doğrudan çağırıyor. Risk, komutun cron'dan
veya elle çalıştırıldığı durumlarda.

**Öneri:**
1. systemd birim dosyalarına `Environment=PYTHONIOENCODING=utf-8` ve `LANG=C.UTF-8` ekle.
2. Ek güvence olarak `manage.py` içinde `sys.stdout.reconfigure(encoding="utf-8")`.
3. Test bunu yakalamalı — CI'da bir işi kasıtlı olarak ASCII locale ile çalıştır.

**Zorluk:** Asan (1 saat)

---

## D-09 · `RedisOutageTests` yapılandırma yokken atlanmıyor

**Kategori:** Test kalitesi
**Kritiklik:** 🟡 Medium
**Dosya:** `core/tests.py` — `RedisOutageTests.test_falls_back_to_the_database`

**Problem:** Paketteki 6 test, bağımlılık yoksa düzgün şekilde `skip` ediyor. Bu test
etmiyor: `REDIS_URL` tanımsızsa `FAIL` veriyor. Sonuç: **test paketi hiçbir
yapılandırmada temiz geçmiyor** — Redis varsa D-03 yüzünden 273 hata, yoksa bu test
başarısız. "Testler geçiyor" ifadesi doğrulanabilir olmaktan çıkıyor.

**Öneri:** `@skipUnless(settings.REDIS_URL, "Redis yapılandırılmamış")` ekle. D-03
düzeltildikten sonra tam paket her iki modda da temiz geçmeli — bunu CI'da iki ayrı
iş olarak çalıştır.

**Zorluk:** Asan (15 dakika)

---

## D-10 · Drip-feed siparişlerde `remains` semantiği doğrulanmamış (mali risk)

**Kategori:** İş mantığı / Mali
**Kritiklik:** 🟡 Medium — **doğrulanması gereken bulgu, kanıtlanmış hata değil**
**Dosya:** `core/services/orders.py:104` (`undelivered_charge`), `core/models.py:359`

**Problem:** Kod, drip-feed'de sağlayıcıya `quantity_per_run` (= `quantity // runs`)
gönderiyor ve bunu doğru şekilde belgeliyor. Ancak `Order.remains` **toplam** miktarla
başlatılıyor (`remains=quantity`), `sync_order_status` ise sağlayıcının döndürdüğü
`remains` değerini doğrudan yazıyor. İade hesabı buna dayanıyor:

```python
remains = min(order.remains, order.quantity)
return (order.charge * Decimal(remains) / Decimal(order.quantity))
```

Sağlayıcı `remains` değerini **aşama başına** mı yoksa **toplam** üzerinden mi
raporluyor — kodda bu varsayım hiçbir yerde belgelenmemiş. Aşama başına raporluyorsa
kısmi iadeler `runs` katı eksik hesaplanır (müşteri zararına) ya da fazla (işletme
zararına). Tek aşamalı siparişlerde (`runs=1`) sorun yok; sorun yalnızca drip-feed'de.

**Öneri:**
1. Sağlayıcıda gerçek bir drip-feed siparişi ver (küçük tutarla), `status` yanıtındaki
   `remains` değerini toplamla karşılaştır ve **kodda yorum olarak belgele.**
2. Doğrulanan semantiğe göre `undelivered_charge` için bir birim testi yaz.
3. Doğrulanana kadar drip-feed'i devre dışı bırakmayı değerlendir — kısmi iade
   matematiğinin doğruluğu ispatlanmamış bir para yolu.

**Zorluk:** Orta (sağlayıcı testi gerektirir)

---

## D-11 · Erişilebilirlik: sipariş formunda isimsiz butonlar

**Kategori:** Accessibility
**Kritiklik:** 🟡 Medium
**Dosya:** `templates/core/new_order.html`

**Problem:** `/panel/order/new/` erişilebilirlik ağacında 14 butonun **hiçbirinde
erişilebilir isim yok** — platform seçicileri yalnızca ikon içeriyor. Ekran okuyucu
kullanıcısı için hepsi ayırt edilemez "button" olarak duyuruluyor; klavye ile gezen
kullanıcı hangi platformda olduğunu bilemiyor.

**Kanıt:** Erişilebilirlik ağacı çıktısı — `button [ref_15]` … `button [ref_26]`,
`button [ref_28]` (yalnızca `ref_27` "Sonrakı platformalar" ismine sahip).

**Öneri:** Her ikon butonuna `aria-label="Instagram"` gibi bir isim ver, veya ikonun
yanına `<span class="visually-hidden">` ile metin ekle. Aynı denetimi katalog
sayfasındaki filtre butonlarına da uygula.

**Zorluk:** Asan (1 saat)

---

## D-12 · Eksik özellikler — kontrol listesindeki karşılığı olmayan maddeler

**Kategori:** Kapsam
**Kritiklik:** 🟡 Medium

Denetim kapsamında istenen ancak sistemde **hiç bulunmayan** işlevler:

| İstenen | Durum |
|---|---|
| Profil bilgilerini değiştirme | Yok — menüdeki "Ayarlar" `href="#"`, "TEZLİKLƏ" etiketli |
| Şifre değiştirme (site içi) | Yalnızca admin temalı sayfa — bkz. D-05 |
| Destek biletleri | Yok — "Dəstək" bağlantısı `mailto:support@panelim.az` |
| Kupon ve kampanyalar | Yok — model, görünüm veya alan yok |
| Site içi bildirimler | Yok — yalnızca e-posta (`core/services/notifications.py`) |
| Telefon numarası doğrulama | Yok |
| Rol ve izin yönetimi (site içi) | Yok — yalnızca Django'nun `is_staff` ayrımı |

Bunlar hata değil, **kapsam boşluğu.** Ancak "destek biletleri" ve "profil sayfası"
para yatırılan bir panelde beklenen asgari işlevler.

---

# ✅ Doğrulanan olumlu bulgular

Denetimin dengeli olması için, canlı olarak test edip **doğru çalıştığını gördüğüm**
noktalar:

- **Kullanıcı girişinde brute-force koruması gerçekten çalışıyor** — 11. denemede 429,
  `Retry-After` başlığıyla birlikte.
- **`check --deploy` temiz** — production ayar yolunda (`DEBUG=False`, Postgres, SMTP)
  tek uyarı bile yok.
- **Önceki denetimin 8 kritik maddesinin tamamı kapatılmış** ve doğrulandı.
- **Sır yönetimi doğru:** `PANELBAKU_API_KEY` git'te izlenen hiçbir dosyada yok
  (`git grep` boş döndü); `.env`, `backups/`, `private-media/`, `media/`, `db.sqlite3`
  hepsi `.gitignore` içinde.
- **Para yolu hâlâ sağlam kurulmuş:** `select_for_update` + `transaction.atomic`,
  veritabanı seviyesinde `CheckConstraint`'ler, `refunded_amount` üzerinden idempotent
  iade, ödeme oturumu için kısmi `UniqueConstraint`.
- **Sağlayıcı hataları üç anlamlı sınıfa ayrılmış** ve belirsiz iletimde iade
  **yapılmıyor** — bu, çoğu projede yanlış yapılan bir ayrım.
- **Dekont güvenliği tam:** Pillow ile içerik doğrulama, `MEDIA_ROOT` dışında saklama,
  yetki kontrollü tek çıkış noktası, `nosniff`, yalnızca doğrulanmış görsellerde `inline`.
- **E-posta doğrulama kodu hash'lenerek saklanıyor** ve deneme sayacının işlem geri
  alımıyla sıfırlanması hatası düzeltilmiş (kod yorumunda açıkça anlatılmış).
- **Test sayısı 93 → 361.**

---

# Yayın öncesi düzeltme sırası

## 1. Yayına çıkmaya engel olanlar
1. **D-01** Admin girişine hız sınırı + admin URL'ini değiştir *(1–2 saat)*
2. **D-03** Önbellek çağrılarına geri düşüş ekle *(1–2 saat)*
3. **D-02** OAuth hesap bağlama açığını kapat — *anahtarlar tanımlanmadan önce* *(yarım gün)*

## 2. Güvenlik ve mali riskler
4. **D-06** CSP başlığı (önce Report-Only) *(yarım gün)*
5. **D-10** Drip-feed `remains` semantiğini sağlayıcıda doğrula ve belgele *(değişken)*
6. **D-04** `maintenance_mode` — ya uygula ya kaldır *(2–3 saat)*

## 3. Fonksiyonel hatalar
7. **D-07** İşlem dışa aktarım filtresi *(30 dakika)*
8. **D-08** Locale/kodlama sağlamlaştırması *(1 saat)*
9. **D-09** Test atlama koşulu *(15 dakika)*

## 4. UX ve erişilebilirlik
10. **D-05** Şifre değiştirme sayfasını markala *(2–3 saat)*
11. **D-11** İkon butonlarına erişilebilir isim *(1 saat)*

## 5. Kapsam genişletmesi
12. **D-12** Profil sayfası → destek biletleri → kuponlar *(ayrı planlama)*

**1–3. gruplar toplamı: yaklaşık 3 gün.**

---

# Bu denetimin kapsamadıkları

Öncelikli kapsam gereği aşağıdakiler **test edilmedi** — "sorun yok" anlamına gelmez:

- Performans ve Core Web Vitals ölçümü, N+1 sorgu analizi
- Tam SEO denetimi (sitemap içeriği, yapısal veri doğrulaması, canonical'lar)
- Chromium dışındaki tarayıcılar (Firefox, WebKit) ve mobil/tablet görünümleri
- Kapsamlı form validation matrisi (XSS/SQLi payload'ları, uzun metin, özel karakterler)
- Gerçek ödeme akışının uçtan uca testi (bakiye yükleme → onay → sipariş → sağlayıcı)
- Yük ve eşzamanlılık testleri (paralel sipariş, çift tıklama davranışı)
