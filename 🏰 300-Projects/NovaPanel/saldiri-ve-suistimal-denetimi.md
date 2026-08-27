# Panel'im — Saldırı ve Kötüye Kullanım Denetimi

**Tarih:** 5 Avqust 2026
**Kapsam:** kötüye kullanım (abuse) vektörleri, hizmet reddi (DoS), teşvik istismarı, bilgi sızıntısı
**Yöntem:** çalışan sunucuya karşı ölçüm (yanıt boyutu, CPU süresi, SQL sorgu sayımı), kaynak kod analizi
**Önceki raporlar:** `denetim-raporu-2.md`, `seo-denetimi.md`

---

## Özet

Önceki raporun kritik maddeleri kapatılmış — doğruladım: admin girişi artık çift anahtarlı
hız sınırıyla korunuyor (`config/urls.py:43`), OAuth pre-hijacking açığı doğru şekilde
kapatılmış (`core/views.py:357`, şifresi olan doğrulanmamış hesaba otomatik bağlanmıyor).
Test paketi 372 testle temiz geçiyor.

Bu denetim farklı bir soruya bakıyor: **sistem kötü niyetli ama "kurallara uyan" bir
kullanıcıya karşı ne kadar dayanıklı?** Yani exploit değil, ölçek ve teşvik istismarı.

Ana bulgu: **kimlik doğrulaması gerektirmeyen `/services/` sayfası tek istekte 652 KB
üretiyor ve 200 ms CPU harcıyor — hiçbir hız sınırı, sayfalama veya önbellek yok.**

| Önem | Adet |
|---|---:|
| 🟠 Yüksek | 2 |
| 🟡 Orta | 4 |
| 🔵 Düşük | 3 |

---

# 🟠 YÜKSEK

## A-01 · `/services/` — kimlik doğrulamasız CPU ve bant genişliği amplifikasyonu

**Kategori:** DoS · **Kritiklik:** 🟠 High · **Dosya:** `core/views.py:116`

Katalog sayfası 955 aktif servisin tamamını tek yanıtta render ediyor. Ölçüm:

| Uç | Sorgu | Toplam | SQL | Yanıt boyutu |
|---|---:|---:|---:|---:|
| `/services/` | 4 | **200.8 ms** | 2.0 ms | **652 667 bayt** |
| `/xidmetler/instagram-beyenme/` | 3 | 41.8 ms | 1.0 ms | 56 845 bayt |
| `/sitemap.xml` | 5 | 28.3 ms | 1.0 ms | 7 329 bayt |
| `/` | 7 | 7.3 ms | 0.0 ms | 28 307 bayt |

**Kritik ayrım:** Sorun N+1 değil — `select_related` doğru kullanılmış, yalnızca 4 sorgu
var ve SQL toplam 2 ms. Maliyetin tamamı **Python tarafındaki gruplama ve şablon
render'ı**: istek başına ~200 ms saf CPU.

**Saldırı matematiği:** Tek çekirdek saniyede ~5 istek karşılayabilir. 4 çekirdekli bir
VPS'te saniyede ~20 istek tüm CPU'yu doyurur — bu, tek bir URL'ye kimlik doğrulaması
olmadan atılan mütevazı bir yükle ulaşılabilir. Ayrıca her istek 652 KB egress üretiyor:
saniyede 20 istek = **13 MB/s giden trafik**.

**Önbellek kaçırma:** `?q=<rastgele>` parametresi her seferinde farklı bir yanıt
ürettiği için önüne konacak bir CDN/proxy önbelleği de atlatılır. Arama `icontains` ile
3 alanda çalışıyor ve bu alanlarda indeks yok.

**Tutarsızlık:** Ucuz olan AJAX ucu (`services_more`) 60/600 sn hız sınırıyla korunmuş
(`core/views.py:147`) — pahalı olan ana katalog sayfası korunmamış.

**Öneri:**
1. `/services/` için sunucu tarafı sayfalama (`Paginator`) — tam kataloğu tek yanıtta
   göndermeyi bırak. Tek başına en büyük kazanım.
2. `@rate_limit(scope="services", limit=60, seconds=600, key="ip", methods=None)` ekle —
   `services_more` ile aynı desen.
3. Filtresiz katalog için `cache_page` (5–10 dk) ve kabul edilen sorgu parametrelerini
   beyaz listeye al; listede olmayan parametre varsa kanonik sürüme yönlendir
   (bu aynı zamanda `seo-denetimi.md`'deki S-01 duplicate content sorununu da çözer).
4. `q` araması için minimum uzunluk (örn. 3 karakter) ve `Service.name` üzerinde indeks.

**Zorluk:** Orta (yarım gün)

---

## A-02 · Kayıt bonusu istismarı — koruma katmanlarının hiçbiri fiilen aktif değil

**Kategori:** Teşvik istismarı / Mali · **Kritiklik:** 🟠 High
**Dosya:** `core/views.py:264` (`grant_signup_bonus`), `core/forms.py:93` (`clean_email`)

Bonus kayıt anında koşulsuz veriliyor (`SIGNUP_BONUS_AMOUNT = 1.00`). Koruma katmanlarının
fiilî durumu ölçüldü:

```
Turnstile (CAPTCHA) aktif  : HAYIR — DJANGO_TURNSTILE_SITE_KEY/SECRET_KEY boş
User.email DB unique       : HAYIR — yalnızca form katmanında kontrol (yarış koşuluna açık)
E-posta normalizasyonu     : HAYIR — yalnızca .strip().lower()
E-posta doğrulaması        : yalnızca para yatırırken; kayıtta yok
Signup hız sınırı          : 5/saat, yalnızca IP başına
```

**Saldırı:** `ali+1@gmail.com`, `ali+2@gmail.com` … Gmail'de hepsi **aynı posta
kutusuna** düşer ama sistem bunları farklı kullanıcı sayar. Nokta varyantları
(`a.li@` = `ali@`) da aynı şekilde. CAPTCHA olmadığı için tamamen script'lenebilir.
IP limiti 5/saat → tek IP'den **120 AZN/gün**; VPN/mobil ağ rotasyonuyla katlanır.

**Bonusun gerçekten harcanabilir olduğu doğrulandı:** 955 aktif servisin **856'sı**
1 AZN bonusla sipariş verilebiliyor. Yani bonus "ölü bakiye" değil, doğrudan sağlayıcı
maliyetine dönüşüyor.

**Hasarı sınırlayan yapısal unsur:** Sistemde **para çekme (withdrawal) özelliği yok** —
bonus nakde çevrilemiyor, yalnızca hizmete harcanabiliyor. Bu, zararı "bedava hizmet"
ile sınırlıyor; yine de her sahte hesap size sağlayıcı maliyeti kadar gerçek para
kaybettiriyor.

**Öneri (etki sırasına göre):**
1. **Bonusu kayıttan değil, e-posta doğrulamasından sonra ver.** `EmailVerification`
   altyapısı (hash'li kod, 5 deneme sınırı, yeniden gönderme soğuması) zaten hazır —
   `check_code` başarılı olduğunda tetikle. Her hesap için gerçek, erişilebilir bir
   posta kutusu şart olur. Duyuru metni buna göre güncellenmeli.
2. **E-postayı normalize edip veritabanı seviyesinde benzersiz kıl:** `+alias` kısmını
   ve Gmail için noktaları temizleyip `normalized_email` sütununda `UniqueConstraint`.
   Mevcut form kontrolü hem bu varyantları kaçırıyor hem de eşzamanlı iki kayıtta yarışa açık.
3. **Turnstile'ı aç** — kod hazır, yalnızca iki ortam değişkeni eksik. En ucuz kazanım.
4. Tek kullanımlık e-posta alan adları için kara liste.
5. Günlük toplam bonus bütçesi (`SIGNUP_BONUS_DAILY_BUDGET`) — en kötü senaryoyu sınırla
   ve eşiğe yaklaşınca uyarı üret.

**Zorluk:** Orta (1 gün, 1–3 arası maddeler yarım gün)

---

# 🟡 ORTA

## A-03 · Sıfır maliyetli sipariş — bakiyesi 0 olan hesap bedava sipariş verebiliyor

**Kategori:** İş mantığı / Mali · **Kritiklik:** 🟡 Medium
**Dosya:** `core/services/orders.py:29` (`calculate_rate_amount`)

Ücret `sale_rate × miqdar / 1000` olarak hesaplanıp `0.0001`e yuvarlanıyor. Çok ucuz
servislerde minimum miktarda bu **tam olarak sıfıra** düşüyor:

```
id=97  min=10  provider_rate=0.0020  sale_rate=0.0026  -> bizden=0.0000  sağlayıcıya=0.0000
id=96  min=10  provider_rate=0.0010  sale_rate=0.0013  -> bizden=0.0000  sağlayıcıya=0.0000
```

`create_order` bakiye kontrolü `wallet.balance < charge` şeklinde; `0 < 0` yanlış
olduğu için **bakiyesi sıfır olan hesap bu siparişleri sınırsız verebiliyor**
(yalnızca 30/saat hız sınırına tabi). `Order.charge >= 0` kısıtı da sıfıra izin veriyor.

Doğrudan para kaybı küçük (sağlayıcı maliyeti de ~0), ancak: her sipariş gerçek bir
sağlayıcı API çağrısı ve gerçek bir sağlayıcı siparişi tüketiyor; sağlayıcının kendi
minimum ücreti varsa zarar bize kalıyor; ayrıca sağlayıcı nezdinde itibar riski.

**Öneri:** `create_order` içinde minimum sipariş tutarı kontrolü
(`MIN_ORDER_CHARGE = Decimal("0.01")`) ve `charge > 0` şartı. Alternatif olarak
yuvarlamayı `ROUND_UP` yap — müşteri lehine olmayan ama sıfırı imkânsız kılan yaklaşım.
Şu anki `ROUND_HALF_UP` sıfıra yuvarlamayı mümkün bırakıyor.

**Zorluk:** Asan (1–2 saat)

---

## A-04 · Kayıt formunda e-posta enumerasyonu

**Kategori:** Bilgi sızıntısı · **Kritiklik:** 🟡 Medium · **Dosya:** `core/forms.py:96`

```python
raise forms.ValidationError("Bu e-poçt ünvanı artıq istifadə olunur.")
```

Giriş formu ve şifre sıfırlama, Django'nun varsayılan davranışıyla kullanıcı varlığını
**doğru şekilde sızdırmıyor**. Kayıt formu ise sızdırıyor: saldırgan bir e-posta listesini
deneyerek hangi adreslerin sitede hesabı olduğunu öğrenebilir. Hız sınırı (5/saat/IP)
bunu yavaşlatır ama engellemez.

Bu, hedefli oltalama için değerli bir listedir ("Panel'im hesabınızda sorun var...").

**Öneri:** Kayıt formunda adresin kullanımda olduğunu doğrudan söyleme. Standart çözüm:
formu her durumda "başarılı" göster ve mevcut adrese *"hesabınız zaten var, giriş yapın
veya şifrenizi sıfırlayın"* içerikli bir e-posta gönder. Bu, bilgiyi yalnızca posta
kutusunun sahibine verir.

**Zorluk:** Orta (yarım gün — kayıt akışını değiştirir)

---

## A-05 · CSV dışa aktarım uçlarında hız sınırı ve satır tavanı yok

**Kategori:** DoS · **Kritiklik:** 🟡 Medium
**Dosya:** `core/views.py:471`, `core/views.py:505`

`order_history_export` ve `transaction_history_export` giriş gerektiriyor ama:
- hız sınırı yok (panel uçları arasında `new_order`, `add_balance`, `verify_email`
  sınırlı; dışa aktarımlar değil),
- satır tavanı yok — tüm geçmiş belleğe alınıp tek yanıtta yazılıyor (önceki denetimin
  **O-15** maddesi hâlâ açık),
- yanıt streaming değil (`HttpResponse`, `StreamingHttpResponse` değil).

Çok siparişi olan bir hesap (veya sipariş üretmiş bir saldırgan) bu ucu arka arkaya
çağırarak bellek ve CPU tüketebilir.

**Öneri:** `@rate_limit(scope="export", limit=10, seconds=3600, key="user")`,
`StreamingHttpResponse` + `.iterator()` kullanımı ve makul bir satır tavanı
(örn. 50 000, aşılırsa tarih aralığı seçmeye yönlendir).

**Zorluk:** Asan (2–3 saat)

---

## A-06 · 51 iniş sayfası da korumasız ve her istekte tüm kataloğu işliyor

**Kategori:** DoS · **Kritiklik:** 🟡 Medium · **Dosya:** `core/views.py:190`

`platform_landing` her istekte tüm aktif servisleri belleğe alıp gruplandırıyor ve
doğru slug'ı bulana kadar doğrusal arama yapıyor (önceki denetimin **O-06** maddesi).
Ölçüm: istek başına 41.8 ms CPU, 56 KB yanıt — kimlik doğrulaması ve hız sınırı yok.
Bu URL'lerin 51'i de sitemap'te ilan edildiği için hem botlar hem saldırganlar için
hazır bir liste mevcut.

**Öneri:** Slug → (platform, tür) eşlemesini önbelleğe al veya veritabanı seviyesinde
çözerek tam katalog taramasını kaldır; A-01'deki hız sınırını bu görünüme de uygula.

**Zorluk:** Orta (yarım gün)

---

# 🔵 DÜŞÜK

## A-07 · Oturum ömrü 14 gün ve tarayıcı kapanınca sonlanmıyor

**Dosya:** `config/settings.py` (Django varsayılanları kullanılıyor)

```
SESSION_COOKIE_AGE             : 1209600 sn = 14 gün
SESSION_EXPIRE_AT_BROWSER_CLOSE: False
PASSWORD_RESET_TIMEOUT         : 259200 sn = 3 gün
```

Bakiye tutan ve sipariş verebilen bir panel için 14 gün uzun; internet kafe veya paylaşılan
cihazda oturum açık kalır. Çerez bayrakları doğru (`HttpOnly=True`, `SameSite=Lax`,
üretimde `Secure=True`).

**Öneri:** `SESSION_COOKIE_AGE`'i 3–7 güne indir; uzun oturum isteyen için giriş formuna
opsiyonel "beni xatırla" kutusu ekle (`request.session.set_expiry`). Şifre sıfırlama
için 3 gün yerine 1 gün daha uygun.

---

## A-08 · `client_ip` içindeki X-Forwarded-For tuzağı

**Dosya:** `core/ratelimit.py:49`

Mevcut dağıtım **doğru kurulmuş**: nginx `X-Real-IP`'i `proxy_set_header` ile üzerine
yazıyor (`deploy/nginx-panelim.conf:38`) ve README `DJANGO_RATELIMIT_IP_META_KEY=HTTP_X_REAL_IP`
diyor. Sorun yok — ama kırılgan.

`client_ip` başlıktan `raw.split(",")[0]` alıyor. Biri yaygın tavsiyeye uyup bu değişkeni
`HTTP_X_FORWARDED_FOR` yaparsa, nginx `$proxy_add_x_forwarded_for` ile istemcinin
gönderdiği değeri **başa ekleyeceği** için saldırgan `X-Forwarded-For: 1.2.3.4` yollayarak
tüm IP tabanlı limitleri (giriş, kayıt, şifre sıfırlama) atlar.

**Öneri:** Koda savunma ekle — yalnızca beyaz listedeki başlıklara izin ver, veya XFF
kullanılıyorsa **sondan** güvenilen vekil sayısı kadar geriden oku. En azından
`.env.example` ve README'ye açık bir uyarı satırı.

---

## A-09 · Yönetici hesabında ikinci faktör yok

Admin girişi artık hız sınırlı (D-01 kapatıldı) ama hâlâ tek faktörlü. Bu hesap ödemeleri
onaylıyor, bakiyeleri elle değiştiriyor ve tüm dekontları okuyabiliyor — parolanın
sızması durumunda başka hiçbir engel yok.

**Öneri:** `django-otp` ile TOTP zorunluluğu (yalnızca `is_staff` için), ayrıca admin
yolunu `/admin/` dışına taşı ve nginx katmanında IP allow-list uygula.

---

# ✅ Saldırı yüzeyinde doğru bulunan noktalar

- **Fiyat manipülasyonu mümkün değil:** `create_order` servisi veritabanından yeniden
  çekiyor (`is_active`, `category__is_active` filtreleriyle) ve ücreti sunucu tarafında
  yeniden hesaplıyor — istemciden gelen fiyat hiçbir yerde güvenilmiyor.
- **SSRF yok:** `target_url` yalnızca sağlayıcıya veri olarak iletiliyor, uygulama bu
  adrese hiçbir istek atmıyor.
- **Para çekme yolu yok** — teşvik istismarının nakde dönüşmesini yapısal olarak engelliyor.
- **Yarış koşullarına karşı korunmuş:** cüzdan işlemleri `select_for_update` + `atomic`,
  sipariş gönderimi şartlı UPDATE ile "sahipleniliyor", ödeme oturumu kısmi
  `UniqueConstraint` ile tekilleştirilmiş.
- **Giriş ve şifre sıfırlamada kullanıcı enumerasyonu yok** (Django varsayılanı korunmuş).
- **Dosya yükleme sağlam:** Pillow ile içerik doğrulama, uzantı beyaz listesi, boyut
  sınırı, `MEDIA_ROOT` dışında saklama, yetki kontrollü tek çıkış noktası, `nosniff`.
- **Devre dışı bırakılan kullanıcının oturumu anında kapanıyor** (`InactiveUserLogoutMiddleware`).
- **E-posta kodu kaba kuvvete kapalı:** hash'li saklama, 5 deneme sonrası kod iptali,
  yeniden gönderme hem soğuma hem saatlik tavanla sınırlı.
- **Dağıtım yapılandırması doğru:** nginx başlıkları üzerine yazıyor, `check --deploy` temiz.

---

# Önerilen uygulama sırası

## Bu hafta (yaklaşık 1,5 gün)
1. **A-02/3** Turnstile'ı aç — iki ortam değişkeni, dakikalar içinde *(en yüksek fayda/maliyet)*
2. **A-03** Minimum sipariş tutarı — bedava sipariş yolunu kapat *(1–2 saat)*
3. **A-01/1-2** `/services/` sayfalama + hız sınırı *(yarım gün)*
4. **A-05** Dışa aktarım uçlarına hız sınırı ve streaming *(2–3 saat)*

## Sonraki hafta (yaklaşık 2 gün)
5. **A-02/1-2** Bonusu e-posta doğrulamasına bağla + e-posta normalizasyonu *(1 gün)*
6. **A-06** İniş sayfası slug çözümünü önbelleğe al *(yarım gün)*
7. **A-07** Oturum ömrünü kısalt *(1 saat)*

## Yapısal / planlanacak
8. **A-04** Kayıt akışını enumerasyona kapat *(ürün kararı gerektirir)*
9. **A-09** Admin için TOTP *(yarım gün)*
10. **A-08** XFF savunması ve dokümantasyon uyarısı *(1 saat)*

---

# Bu denetimin kapsamadıkları

- **Gerçek yük testi yapılmadı** — A-01'deki DoS matematiği tek istek ölçümlerinden
  türetildi, eşzamanlı yük altında davranış (gunicorn işçi sayısı, kuyruk) ölçülmedi
- **Sağlayıcı API'sine karşı kötüye kullanım** (örneğin sipariş spam'inin sağlayıcı
  hesabımıza etkisi) test edilmedi — gerçek sipariş vermeyi gerektirir
- **Otomatik güvenlik taraması yapılmadı** (`pip-audit`, `bandit`, bağımlılık CVE taraması)
- **Ödeme akışının uçtan uca kötüye kullanımı** (sahte dekont ile onay alma, aynı
  dekontun tekrar kullanımı) manuel admin süreci gerektirdiği için test edilmedi
- Ölçümler geliştirme sunucusunda (tek işçi, SQLite) yapıldı; üretimde PostgreSQL ve
  gunicorn ile mutlak sayılar değişir — **oranlar** ve darboğazın yeri (CPU, SQL değil) geçerli
