# NovaPanel — Ürün ve Teknik Yol Haritası

**Sürüm:** 2.0 · **Tarih:** 2 Avqust 2026 · **Kapsam:** `NovaPanel` Django uygulaması (core + config + templates + static)
**Doküman sahibi:** Axrm · **Durum:** Onay bekliyor

---

## 1. Yönetici özeti

NovaPanel'in çekirdek iş mantığı sağlam kurulmuş. Cüzdan işlemleri kilitli ve atomik,
ödeme oturumları kuruş eşleştirmesiyle ayrıştırılıyor, sağlayıcı API'sinin üç farklı hata
sınıfı (konfigürasyon / reddetme / iletim belirsizliği) ayrı ayrı ele alınmış, 84 test
yazılmış. Bu, çoğu benzer projeden ileride bir başlangıç noktası.

Buna karşılık uygulama **üretim ortamına hazır değil** ve bunun sebebi eksik ekranlar
değil, eksik altyapı. Üç mali risk açık duruyor:

1. **Kâr ölçülemiyor.** `Order` modelinde sağlayıcı maliyeti anlık olarak saklanmıyor;
   fiyat değiştiğinde geçmiş marj geri hesaplanamaz.
2. **Mutabakat yok.** Kullanıcı bakiyelerinin toplamı bir yükümlülüktür; bunun banka ve
   sağlayıcı bakiyesiyle karşılaştırıldığı hiçbir rapor yok.
3. **Kısmi tamamlanan siparişler iade edilmiyor.** `sync_order_status` yalnızca `canceled`
   durumunda iade yapıyor; `partial` durumunda teslim edilmeyen miktarın parası
   kullanıcıda kalıyor. Bu bir hatadır, tercih değil.

Ayrıca uygulama SQLite üzerinde, arka plan kuyruğu olmadan, hata izleme ve yedekleme
olmadan çalışıyor. Sipariş durumları yalnızca elle çalıştırılan bir yönetim komutuyla
güncelleniyor.

**Öneri:** Ekran ve metin çalışmasından önce **R0 (Yayın öncesi zorunlu)** paketi
tamamlanmalı. R0 olmadan yapılan her ekran iyileştirmesi, altında para kaybı riski taşıyan
bir sistemin üzerine kozmetik katman eklemektir.

**Toplam tahmini efor:** 34–41 adam·gün, 6 sürüme bölünmüş.

---

## 2. Mevcut durum değerlendirmesi

Olgunluk ölçeği: **1** yok · **2** başlangıç · **3** çalışır · **4** sağlam · **5** olgun

| Alan | Olgunluk | Gerekçe |
|---|:---:|---|
| Veri modeli | 4 | Kısıtlar, indeksler, `CheckConstraint`'ler doğru kurgulanmış. `provider_charge` eksiği tek ciddi boşluk. |
| İşlem bütünlüğü | 4 | `select_for_update` + `transaction.atomic` doğru kullanılmış. |
| Sağlayıcı entegrasyonu | 3 | Hata sınıflandırması iyi; refill/cancel/multi-status metotları yok, yeniden deneme yok. |
| Test kapsamı | 4 | 84 test. Entegrasyon ve uçtan uca senaryo eksik. |
| Yönetim paneli | 3 | Temel işlemler var; istatistik, manuel müdahale ve denetim izi yok. |
| Kullanıcı arayüzü | 2 | Katalogdan sipariş verilemiyor, sipariş detayı yok, mobil tablo düzeni kırık. |
| Metin ve terminoloji | 2 | `servis`/`xidmət` karışık, durum adları teknik, hata mesajları eylem önermiyor. |
| Üretim altyapısı | 1 | SQLite, kuyruk yok, yedek yok, izleme yok, `LOGGING` tanımsız. |
| Güvenlik | 2 | HSTS/SSL ayarları doğru; hız sınırı, CAPTCHA, e-posta doğrulama ve medya erişim kontrolü yok. |
| Mali raporlama | 1 | Kâr, mutabakat ve nakit akışı görünürlüğü yok. |
| Hukuki / kurumsal | 1 | Şahsi karta havale modeli; vergi ve iş hesabı yapısı kurulmamış. |

---

## 3. Sürüm planı

| Sürüm | Ad | Amaç | Efor | Ön koşul |
|---|---|---|---:|---|
| **R0** | Yayın öncesi zorunlu | Para kaybı ve veri kaybı riskini kapat | 9–11 g | — |
| **R1** | Doğru bilgi | Yanıltıcı ve hatalı gösterimleri kaldır | 2–3 g | R0 |
| **R2** | Dönüşüm | Katalogdan siparişe giden yolu aç | 4–5 g | R1 |
| **R3** | Panel iskeleti | Büyümeye açık panel yapısı + sipariş görünürlüğü | 5–6 g | R2 |
| **R4** | Ödeme deneyimi | Manuel ödeme akışındaki hata ve destek yükünü azalt | 3–4 g | R3 |
| **R5** | Marka ve içerik | Ana sayfa, terminoloji, SEO | 3–4 g | R2 |
| **R6** | Bakım borcu | Değişim maliyetini düşür | 4–5 g | paralel |

R6 ayrı bir sürüm olarak ele alınabileceği gibi, R2–R5 sırasında doğal olarak da
tamamlanabilir; yeni bileşenler zaten ayrı dosyalar olarak yazılırsa ek zaman gerekmez.

---

## R0 — Yayın öncesi zorunlu

**Sürüm hedefi:** Uygulama gerçek para kabul etmeye başladığında hiçbir işlem kaybolmasın,
her kayıp geri alınabilsin ve her hata görülebilsin.

**Çıkış kriteri:** Aşağıdaki dört cümlenin hepsi doğru olmalı —
(a) veritabanı her gün otomatik yedekleniyor ve bir kez geri yükleme denenmiş,
(b) arka plan görevleri kendiliğinden çalışıyor,
(c) her uygulama hatası bir yere düşüyor,
(d) günlük mutabakat raporu üretilebiliyor.

### R0-01 · Sipariş maliyetinin anlık kaydı
**Efor:** 0,5 g · **Dosya:** `core/models.py`, `core/services/orders.py`
**Sorun:** `Order` yalnızca satış tutarını (`charge`) saklıyor. Sağlayıcı fiyatı veya marj
değiştiğinde geçmiş siparişlerin kârı hesaplanamaz hâle geliyor.
**Yapılacak:** `Order`'a `provider_rate` ve `provider_charge` alanları; `create_order`
içinde sipariş anındaki değerlerle doldurulsun. Geçmiş kayıtlar için migration'da mevcut
`Service.provider_rate` ile geriye dönük tahmini doldurma (yaklaşık olduğu not edilerek).
**Kabul kriteri:** Servis fiyatı değiştirildikten sonra eski bir siparişin marjı doğru okunuyor.

### R0-02 · Kısmi siparişlerin iadesi
**Efor:** 0,5 g · **Dosya:** `core/services/orders.py::sync_order_status`
**Sorun:** Yalnızca `canceled` durumunda iade yapılıyor. Sağlayıcı `partial` döndürdüğünde
`remains` kadar teslim edilmemiş miktarın parası kullanıcıda kalıyor.
**Yapılacak:** `partial` durumunda `remains / quantity` oranında kısmi iade + `refund`
tipinde cüzdan işlemi. Çift iadeyi önlemek için `refunded_at` kontrolü korunmalı.
**Kabul kriteri:** 1000 adetlik siparişte 400 kalırsa kullanıcıya tutarın %40'ı iade ediliyor
ve aynı senkron ikinci kez çalıştığında tekrar iade yapılmıyor. Test yazılmalı.

### R0-03 · PostgreSQL'e geçiş
**Efor:** 1 g · **Dosya:** `config/settings.py`, `requirements.txt`
**Sorun:** SQLite eşzamanlı yazmada tüm veritabanını kilitliyor; `select_for_update`
semantiği taşınmıyor. Cüzdan işlemleri eşzamanlılığa duyarlı.
**Kabul kriteri:** Tüm testler PostgreSQL üzerinde geçiyor; bağlantı bilgileri ortam
değişkeninden okunuyor.

### R0-04 · Redis + arka plan kuyruğu
**Efor:** 2 g · **Yeni bileşen:** Celery (veya RQ) worker + beat
**Sorun:** `submit_order` istek içinde senkron çalışıyor; sağlayıcı yavaşlarsa kullanıcı 25
saniye bekliyor ve zaman aşımı riski doğuyor. `sync_order_statuses` ve
`expire_payment_sessions` komutlarını çağıran bir zamanlayıcı yok — yani şu anda sipariş
durumları hiç güncellenmiyor ve ödeme oturumları hiç sona ermiyor.
**Yapılacak:**
- Sipariş gönderimi kuyruğa alınsın; kullanıcı anında yanıt alsın.
- `submission_unknown` siparişler için üstel geri çekilmeli yeniden deneme.
- Zamanlanmış görevler: durum senkronu (5 dk), oturum sonlandırma (5 dk), sağlayıcı
  bakiyesi kontrolü (30 dk).
- Cache backend LocMem'den Redis'e — `default_markup_percent` cache'i şu an her süreçte ayrı.
**Kabul kriteri:** Sağlayıcı API'si kapalıyken sipariş verilebiliyor, sipariş `Hazırlanır`
durumunda kalıyor ve API döndüğünde kendiliğinden gönderiliyor.

### R0-05 · Yedekleme ve geri yükleme
**Efor:** 1 g
**Sorun:** Kullanıcı bakiyeleri veritabanında; veri kaybı doğrudan para kaybıdır.
**Yapılacak:** Günlük otomatik `pg_dump` + farklı bir fiziksel konumda saklama + yüklenen
dekont dosyalarının yedeği + **geri yükleme provası** (yedek alınıyor olması yeterli
değildir, geri yüklenebildiği bir kez kanıtlanmalıdır).
**Kabul kriteri:** Boş bir sunucuda yedekten ayağa kaldırma denemesi başarıyla yapılmış ve
süresi ölçülmüş.

### R0-06 · Mali mutabakat raporu
**Efor:** 1 g · **Yeni:** yönetim komutu + admin ekranı
**Sorun:** Kullanıcı bakiyelerinin toplamı şirket için bir borçtur. Bu borcun karşılığının
elde olup olmadığını gösteren hiçbir görünüm yok.
**Yapılacak:** Günlük rapor:
`Toplam kullanıcı bakiyesi` · `Onaylanan yatırım toplamı` · `Harcama toplamı` ·
`İade toplamı` · `Sağlayıcı bakiyesi` · `Beklenen fark`
Cüzdan işlemlerinden hesaplanan bakiye ile `Wallet.balance` alanı arasında sapma varsa
uyarı versin — bu sapma bir hata göstergesidir.
**Kabul kriteri:** Rapor tek komutla üretilebiliyor ve yönetim panelinden görülebiliyor.

### R0-07 · Hata izleme ve loglama
**Efor:** 0,5 g · **Dosya:** `config/settings.py`
**Sorun:** `LOGGING` tanımı hiç yok; sağlayıcı API hataları ve beklenmeyen istisnalar
hiçbir yere düşmüyor.
**Yapılacak:** Yapılandırılmış loglama + Sentry (veya muadili) + çalışma süresi izleme.
**Kritik uyarılar:** sağlayıcı bakiyesi eşik altında · `submission_unknown` sipariş sayısı
eşik üstünde · bekleyen ödeme 60 dakikayı aştı · mutabakat sapması sıfırdan farklı.

### R0-08 · Sağlayıcı bakiyesi görünürlüğü
**Efor:** 0,5 g · **Dosya:** `core/admin.py`, `core/services/panelbaku.py`
**Sorun:** `PanelBakuClient.balance()` yazılmış ama hiçbir yerde çağrılmıyor. Bakiye
bittiğinde tüm siparişler sessizce iade oluyor; sorun ancak müşteri şikâyetiyle fark ediliyor.
**Yapılacak:** Bakiye periyodik olarak çekilip saklansın, yönetim panelinde görünsün,
eşik altında uyarı üretsin.

### R0-09 · Hız sınırı ve kötüye kullanım savunması
**Efor:** 1 g
**Yapılacak:** Giriş, kayıt, şifre sıfırlama, sipariş oluşturma ve ödeme oturumu açma
uçlarına hız sınırı; kayıt ve giriş formlarına CAPTCHA (Turnstile — ücretsiz); kayıtta
e-posta doğrulama.
**Gerekçe:** Şu an sınırsız sahte hesap açılabiliyor ve ödeme oturumu üretilebiliyor;
ödeme oturumu üretimi kuruş havuzunu tükettiği için gerçek kullanıcıları da engeller.

### R0-10 · Dağıtım sertleştirmesi
**Efor:** 1 g · **Dosya:** `config/settings.py`, sunucu yapılandırması
**Yapılacak:**
- `CSRF_TRUSTED_ORIGINS` tanımı — **şu an yok, HTTPS'e geçildiğinde tüm POST istekleri kırılır.**
- Dekont dosyaları (`payment_receipts/`) doğrudan erişime kapatılsın; yalnızca sahibi ve
  yetkili personel görebilsin.
- Gunicorn + Nginx + systemd, statik dosya servisi, TLS sertifikası.
- `manage.py check --deploy` çıktısı temiz olmalı.

### R0-11 · Kurumsal ve bankacılık yapısı
**Efor:** teknik değil — süre öngörülemez, **erken başlatılmalı**
**Sorun:** `PaymentAccount` modeli şahsi karta havale üzerine kurulu. Aylık çok sayıda küçük
gelen transfer, bankanın izleme sistemlerinde ticari faaliyet olarak değerlendirilir;
hesap kısıtlama riski gerçektir ve gerçekleştiğinde tüm tahsilat durur.
**Yapılacak:** Fərdi sahibkar veya MMC kaydı · iş hesabı · vergi rejimi seçimi ·
`terms` / `privacy` / `payment_and_refund` sayfalarının hukuki gözden geçirmesi ·
kişisel veri aydınlatma metni.
**Not:** Bu kalem kod bloklamıyor ama **yayını bloklar.** Diğer maddelerle paralel yürütülmeli.

---

## R1 — Doğru bilgi

**Sürüm hedefi:** Arayüzde yanlış, uydurma veya karşılığı olmayan hiçbir bilgi kalmasın.
**Çıkış kriteri:** Ekranda gösterilen her rozet, sayı ve durum adının arkasında gerçek veri var.

| No | İş | Dosya | Efor |
|---|---|---|---:|
| R1-01 | Müşteri yorumları bölümü ekle | `templates/core/home.html` | 0,5 g |
| R1-02 | `account_type` kararı ve uygulaması | `services.html`, `models.py` | 0,5 g |
| R1-03 | Bərpa/Ləğv rozetleri kararı | `services.html` | 0,5 g |
| R1-04 | Dashboard sahte metriklerinin kaldırılması | `dashboard.html` | 0,25 g |
| R1-05 | Durum adlarının sadeleştirilmesi | `models.py`, şablonlar | 0,5 g |
| R1-06 | Hata ve bildirim metinlerinin yeniden yazımı | `views.py`, `orders.py`, `payments.py` | 0,5 g |

**R1-01 —** `testimonials` verisi `core/views.py:46`'da context'e gönderiliyor ama şablonda
hiç kullanılmıyor. Sosyal kanıt tamamen eksik ve veri hazır bekliyor. Boşken bölüm hiç
render edilmesin. Bölüm başlığı: eyebrow `RƏYLƏR` · başlık `Xidmətdən istifadə edənlər nə deyir?`

**R1-02 —** `templates/core/services.html:15` içinde `service.account_type` çağrılıyor ama
`Service` modelinde böyle bir alan yok; rozet hiçbir zaman görünmüyor. İki seçenek:
- **(A)** Modele `account_type` alanı eklenip senkronizasyonda doldurulması. Ana sayfada
  "bot və real hesab fərqi" bir satış argümanı olarak kullanıldığı için tutarlı olan budur.
- **(B)** Şablondan kaldırılması — bu durumda ana sayfadaki ilgili vaatler de çıkarılmalı.

**R1-03 — Karar gerektirir.** Katalogda `Bərpa` ve `Ləğv` rozetleri gösteriliyor, ancak
`PanelBakuClient` sınıfında `refill` ve `cancel` metotları yok; kullanıcının bu işlemleri
başlatabileceği hiçbir arayüz de yok. Yani **verilmiş ama karşılığı olmayan bir söz**
durumundadır ve iade taleplerinde aleyhine kullanılabilir. Seçenekler:
- **(A)** Rozetleri, refill/cancel akışı devreye alınana kadar gizle. *(0,25 g — önerilen)*
- **(B)** Refill/cancel akışını hemen geliştir. *(3 g — R3'e uygun)*

**R1-05 — Sipariş durumu gösterimi.** Kullanıcı sağlayıcı mimarisini bilmek zorunda değil.
Yönetim paneli teknik adları görmeye devam etsin; kullanıcıya ayrı bir gösterim sunulsun.

| Kod | Şu an (kullanıcıya) | Olacak (kullanıcıya) |
|---|---|---|
| `queued` | API-yə göndərilir | **Hazırlanır** |
| `pending` | Gözləmədə | **Növbədə** |
| `processing` | Davam edir | Davam edir |
| `submission_unknown` | Manual yoxlama tələb edir | **Yoxlanılır** |
| `completed` | Tamamlandı | Tamamlandı |
| `partial` | Qismən tamamlandı | Qismən tamamlandı |
| `canceled` | Ləğv edildi | **Ləğv edildi — məbləğ qaytarıldı** |

**R1-06 — Metin değişiklikleri.** İyi bir hata mesajı ne olduğunu, paranın nerede olduğunu
ve kullanıcının ne yapması gerektiğini söyler.

| Konum | Şu an | Olacak |
|---|---|---|
| `views.py::new_order` | Sifariş #12 provayderə göndərilmədi; məbləğ balansınıza qaytarıldı. | **Sifariş #12 yerinə yetirilə bilmədi. Məbləğ balansınıza qaytarıldı. Linki yoxlayıb yenidən cəhd edin.** |
| `views.py::new_order` | Sifariş #12 manual yoxlamaya göndərildi. Təkrar sifariş verməyin. | **Sifariş #12 qeydə alındı və yoxlanılır. 30 dəqiqə ərzində ya işə düşəcək, ya da məbləğ balansınıza qayıdacaq. Bu müddətdə təkrar sifariş verməyin.** |
| `orders.py` | Balans sifariş üçün kifayət etmir. | **Balans kifayət etmir. Bu sifariş üçün daha {eksik} ₼ lazımdır.** |
| `payments.py` | Yeni ödəniş sessiyası yaradıla bilmədi. Bir qədər sonra yenidən sınayın. | **Hazırda çox sayda ödəniş gözləyir. 1-2 dəqiqə sonra yenidən cəhd edin.** |
| `payments.py` | Bu ödəniş artıq aktiv deyil. | **Bu ödəniş sessiyası bağlanıb. Yeni sorğu yaradın.** |

---

## R2 — Dönüşüm

**Sürüm hedefi:** Katalogda servisi bulan kullanıcı, sayfayı terk etmeden sipariş verebilsin.
**Çıkış kriteri:** Katalog → sipariş yolu üç tıkla tamamlanıyor ve mobilde eksiksiz çalışıyor.

**Ana sorun:** Katalog tablosunda hiçbir eylem butonu yok. Kullanıcı servisi beğeniyor,
ardından ayrı bir sayfada, yüzlerce seçenekli düz bir `<select>` içinde aynı servisi
yeniden bulmak zorunda kalıyor. Dönüşüm kaybının en büyük tek kaynağı budur.

| No | İş | Efor | Ayrıntı |
|---|---|---:|---|
| R2-01 | Katalog satırına `Sifariş ver` butonu | 0,5 g | `new_order?service=<id>`; `new_order` view'ı GET parametresini forma initial geçirsin. Giriş yapmamış kullanıcı `login?next=` ile yönlensin — fiyatı gördüğü noktada kaybedilmesin. |
| R2-02 | Katalog mobil kart düzeni | 1 g | 768px altında 5 sütunlu tablo kart listesine dönüşsün. Kart sırası: servis adı → fiyat (büyük) → limit ve süre → rozetler → `Sifariş ver`. `#ID` sütunu mobilde gizlensin. |
| R2-03 | Satır içi fiyat hesaplayıcı | 0,5 g | Miktar yazıldıkça `2.000 ədəd = 4,80 ₼`. Etiket: `Miqdar yazın, qiyməti görün`. |
| R2-04 | Katalog özeti ve filtre davranışı | 0,5 g | Chip'lerin üstüne `142 xidmət · 6 platforma · qiymətlər AZN ilə`. Sıralama seçilince otomatik gönderim. Mobilde yapışkan filtre çubuğu. `Nəticələri göstər` → `Axtar`. |
| R2-05 | Katalog sayfalama | 0,5 g | `core/views.py::services` şu an `list(items)` ile tüm katalogu belleğe alıyor. Grup başına ilk 25 + `Daha çox göstər`. |
| R2-06 | Sipariş formunun yeniden düzeni | 1,5 g | Aranabilir servis seçici; platforma göre link örneği; yetersiz bakiyede form hatası yerine eylem kutusu; **gönderim öncesi özet onayı** (para harcanıyor ve geri alınamıyor). |

**R2-06 — Onay adımı içeriği:**
`Xidmət` · `Miqdar` · `Yekun məbləğ` · `Sifarişdən sonra qalan balans` → `Təsdiqlə və sifariş ver`

**Yetersiz bakiye kutusu:**
> **Balans kifayət etmir.** Bu sifariş üçün daha **{eksik} ₼** lazımdır. → `[Balans artır]`

**Link örnek metinleri:**

| Platform | Örnek |
|---|---|
| Instagram | `https://instagram.com/istifadeci_adi` |
| TikTok | `https://tiktok.com/@istifadeci_adi` |
| YouTube | `https://youtube.com/watch?v=...` |
| Telegram | `https://t.me/kanal_adi` |

---

## R3 — Panel iskeleti

**Sürüm hedefi:** Panel, gelecek ekranları (destek, API, toplu sipariş, ayarlar) taşıyacak
bir yapıya kavuşsun; kullanıcı siparişinin durumunu kendi başına takip edebilsin.
**Çıkış kriteri:** "Siparişim ne durumda?" sorusu destek kanalına gelmeden panelde
cevaplanabiliyor.

| No | İş | Efor | Ayrıntı |
|---|---|---:|---|
| R3-01 | `base_panel.html` — panel layout'u | 1 g | Sol menü: `İcmal` · `Sifariş ver` · `Sifarişlərim` · `Balans` · `Əməliyyat tarixçəsi` · `Dəstək` · `Ayarlar`. Public sayfalar `base.html`'de kalsın. |
| R3-02 | Header'da bakiye | 0,5 g | Her sayfada sağ üstte `12,40 ₼` + `+` butonu. Şu an bakiye yalnızca dashboard'da, `Balans artır` linki menüde hiç yok. Çıkış butonu kullanıcı menüsüne taşınsın. |
| R3-03 | Dashboard özet kartları | 0,5 g | Mevcut kartlardan ikisi yanlış bilgi veriyor (`orders\|length` aslında `[:8]` limiti; "Hesab statusu" sabit metin). Yerine: `Balans` · `Davam edən sifarişlər` · `Tamamlanan sifarişlər` · `Ümumi xərc`. |
| R3-04 | **Sipariş detay ekranı** | 1,5 g | `/panel/order/<id>/` — şu an yok. İçerik: durum zaman çizelgesi, ilerleme (`remains` verisinden), hedef link, tutar, iade bilgisi, sağlayıcı hatası varsa kullanıcı diliyle açıklaması. |
| R3-05 | Sipariş ve işlem geçmişi sayfaları | 1 g | Dashboard'daki `[:8]` kesitler yerine filtreli, aranabilir, sayfalanmış tam listeler. CSV dışa aktarım. |
| R3-06 | İlerleme göstergesi | 0,25 g | `processing` siparişlerde `1.200 / 2.000 tamamlandı`. Veri mevcut, hiç kullanılmıyor. |
| R3-07 | İlk kullanıcı başlangıç kartı | 0,25 g | Sipariş sayısı 0 iken üç adımlı yönlendirme. |
| R3-08 | Bekleyen ödeme şeridi | 0,25 g | Onay bekleyen ödeme varsa panelin üstünde bilgi şeridi. |

**R3-07 — Başlangıç kartı metni:**
> **Üç addımda başlayın**
> 1. Balans artırın — kartla köçürmə, adətən 10 dəqiqə ərzində təsdiqlənir
> 2. Kataloqdan xidməti seçin — qiymət və limitlər açıq göstərilir
> 3. Linki və miqdarı yazıb sifarişi təsdiqləyin
> `[Balans artır]` `[Kataloqa bax]`

**R3-08 — Şerit metni:**
> **1 ödəniş yoxlanılır.** Təsdiqləndikdən sonra məbləğ avtomatik balansınıza əlavə olunacaq.

---

## R4 — Ödeme deneyimi

**Sürüm hedefi:** Manuel havale akışında kullanıcı hatası ve buna bağlı destek yükü en aza insin.
**Çıkış kriteri:** Yanlış tutar gönderimi kaynaklı destek talebi sıfıra yakın.

Kuruş eşleştirme mantığı (`payable_amount`) doğru kurgulanmış, ancak **kullanıcı tutarı
yuvarlarsa ödeme otomatik olarak eşleşmez.** Bu ekranın tek işi o tutarı doğru aktarmaktır;
tasarımın tamamı bu amaca hizmet etmelidir.

| No | İş | Efor |
|---|---|---:|
| R4-01 | `payment_detail` yeniden düzeni | 1 g |
| R4-02 | Dekont ve referans alanı | 0,5 g |
| R4-03 | E-posta bildirimleri | 1 g |
| R4-04 | Yönetim tarafı ödeme onay ekranı | 1 g |

**R4-01 — Ekran sırası (yukarıdan aşağı):**
1. Adım göstergesi — `Məbləğ → Köçürmə → Təsdiq → Yoxlanılır`
2. Geri sayım (mevcut, korunsun)
3. **Köçürüləcək məbləğ** — sayfanın en büyük ögesi, kopyalama butonu ile
4. Uyarı kutusu (aşağıdaki metin)
5. Kart numarası (kopyalama butonu) + kart sahibi + banka görseli
6. `Köçürməni etdim` birincil butonu, `Ləğv et` ikincil linki

**Uyarı metni — vurgulu ve uyarı renginde:**
> **Məbləği dəyişməyin.** Qəpik hissəsi ödənişinizi tanımaq üçündür.
> **{{ payable_amount }} ₼** — tam olaraq bu məbləği köçürün.
> Yuvarlaqlaşdırsanız ödəniş avtomatik tanınmayacaq.

**R4-02 —** `PaymentRequest.receipt` alanı modelde var ancak `PaymentRequestForm` içinde
yok; kullanıcı **makbuz yükleyemiyor.** `Köçürməni etdim` adımına isteğe bağlı dosya alanı
ve `reference` alanı eklenmeli.
Etiket: `Qəbz və ya ekran görüntüsü (istəyə bağlı)` · Yardım: `Qəbz əlavə etsəniz təsdiq daha tez olur.`

**Onay sonrası ekran metni:**
> **Ödənişiniz yoxlanılır.** Adətən 10-30 dəqiqə çəkir.
> Təsdiqləndikdən sonra məbləğ avtomatik balansınıza əlavə olunacaq və e-poçtla bildiriş alacaqsınız.

**R4-03 —** Şu an hiçbir işlem bildirimi gönderilmiyor. Gerekli olanlar: ödeme onaylandı,
ödeme reddedildi, sipariş tamamlandı, sipariş iade edildi. SMTP altyapısı `settings.py`'de
zaten hazır.

**R4-04 —** Yönetim tarafında ödeme onayı şu an yalnızca liste üzerinden toplu eylemle
yapılıyor. Onay verirken banka hareketiyle karşılaştırma yapılabilmesi için tek ekranda
tutar, dekont görseli, kullanıcının geçmiş ödemeleri ve onay/ret butonları bir arada
sunulmalı. **Sahte dekont senaryosu gerçektir**; onay her zaman banka hareketine dayanmalıdır.

---

## R5 — Marka ve içerik

**Sürüm hedefi:** Terminoloji tutarlılığı, ana sayfada güven, aramadan gelen trafik.

### R5-01 · Terim birliği (0,5 g)

Aynı kavram için iki kelime dolaşımda. Kamuya açık her yerde **`xidmət`** kullanılsın —
Azerbaycan dilinde daha doğal ve `sosial media xidmətləri` araması için uygun. `servis`
yalnızca yönetim panelinde ve API'de kalsın.

| Konum | Şu an | Olacak |
|---|---|---|
| `base.html` menü | Servislər | **Xidmətlər** |
| `base.html` menü | Yeni Sifariş | **Sifariş ver** |
| `services.html` sayfa başlığı | SERVİS KATALOQU | **XİDMƏT KATALOQU** |
| `services.html` tablo başlığı | Servis | **Xidmət** |
| `home.html` bölüm başlıkları | karışık | tümü `xidmət` |
| `forms.py` alan etiketi | Servis | **Xidmət** |
| `models.py` `verbose_name` | Servis | değişmesin (yönetim paneli) |

### R5-02 · Ana sayfa düzeltmeleri (1,5 g)

- **Hero'daki uydurma metrikler** (`+2.4K izləyici`, `84K baxış`, `+34.8%`) tam da güven
  kurulması gereken yerde uydurma veri izlenimi bırakıyor. Ya gerçek toplam sipariş
  sayısına bağlanmalı, ya da rakamlar çıkarılıp soyut görselleştirmeye dönüştürülmeli.
- **Hero'da tekrar:** `blockquote.aeo-answer` ile altındaki `<p>` aynı bilgiyi veriyor.
- **Fiyat çıpası ekle:** `0,80 ₼-dan başlayan qiymətlər · qeydiyyatsız kataloq`
- **Karşılaştırma tablosundan şu satır çıkarılsın:**
  `Birbaşa provayder qiyməti | Üzərinə xidmət marjası əlavə olunur | Bəzi hallarda daha ucuz ola bilər`
  Şeffaflık iyi niyetli ancak bu satır ziyaretçiyi doğrudan alternatife yönlendiriyor.
  Yerine: `Ödəniş | AZN ilə, yerli bank kartı ilə | Çox vaxt xarici valyuta və xarici kart`
- **CTA çeşitliliği:** üç bölümde de aynı `Xidmətlərə bax` var.
  `mid-cta` → **`Qiymətləri müqayisə et`** · `final-cta` → **`Hesab aç və başla`**
- **Ton dengesi:** `problem-section` ve `trust-section` bölümlerinin ikisi de risk/uyarı
  dilinde. Uyarılar tek bölümde toplanmalı, `solution-section` kazanım diline çevrilmeli.
- **Eyebrow sayısı:** her bölümde büyük harfli etiket var, vurgu değerini yitirmiş. En çok
  dört bölümde kalsın.
- **Sosyal kanıt:** R1-01'deki yorumlar bölümü + isteğe bağlı anonim canlı sipariş akışı.

### R5-03 · SEO içerik altyapısı (1,5 g)

Teknik SEO hazır (sitemap, robots, JSON-LD, meta yönetimi) ancak üzerine konulacak içerik
yok. Kategori bazlı iniş sayfaları (`/xidmetler/instagram-izleyici/`) ve birkaç rehber yazı,
mevcut altyapının karşılığını almanın tek yolu.

---

## R6 — Bakım borcu

**Sürüm hedefi:** Sonraki her değişikliğin maliyetini düşürmek. Kullanıcıya görünmez.

| No | İş | Efor | Gerekçe |
|---|---|---:|---|
| R6-01 | Şablonların bileşenlere bölünmesi | 2 g | `services.html:15` tek satırda tüm tabloyu içeriyor; `dashboard.html`'de üç tablo tek satırda. Bu yapıda küçük bir tasarım değişikliği bile risklidir. |
| R6-02 | CSS birleştirme ve tema değişkenleri | 1 g | `app.css` + `redesign.css` + `dark.css` sırayla yükleniyor; `redesign.css` büyük olasılıkla `app.css`'i eziyor, hangi kuralın geçerli olduğu belirsiz. Manuel tema düğmesi de eklenmeli. |
| R6-03 | Erişilebilirlik | 0,5 g | `.tag` anlamı yalnızca renkle taşıyor; tablo başlıklarında `scope` yok; `announcement` bandı kapatılamıyor; `<details>` gruplarında `aria-expanded` eksik. |
| R6-04 | Font yükleme | 0,25 g | İki aile, yedi ağırlık, render bloklayıcı. Dörde indir ve kendi sunucundan servis et. |
| R6-05 | CI ve staging | 1 g | Testler otomatik çalışsın; sağlayıcı API'sinin sandbox'ı olmadığı için canlıda gerçek parayla test ediliyor. |

**R6-01 — oluşturulacak bileşenler:**
`includes/service_row.html` · `includes/service_card.html` · `includes/stat_card.html` ·
`includes/order_row.html` · `includes/status_tag.html` · `includes/empty_state.html`

---

## 4. Risk kaydı

| # | Risk | Olasılık | Etki | Önlem | İlgili kalem |
|---|---|:---:|:---:|---|---|
| 1 | Şahsi banka hesabının kısıtlanması, tahsilatın durması | Orta | **Çok yüksek** | Kurumsal yapı ve iş hesabına erken geçiş | R0-11 |
| 2 | Veritabanı kaybı → bakiyelerin kaybı | Düşük | **Çok yüksek** | Günlük yedek + geri yükleme provası | R0-05 |
| 3 | Kısmi siparişlerin iade edilmemesi → şikâyet ve itibar kaybı | **Yüksek** (hâlihazırda mevcut) | Yüksek | Kısmi iade mantığı | R0-02 |
| 4 | Sağlayıcı bakiyesinin habersiz tükenmesi → toplu iade | **Yüksek** | Yüksek | Bakiye izleme ve uyarı | R0-08 |
| 5 | Zararına satış (marj görünmediği için) | Orta | Yüksek | Maliyet snapshot'ı + marj raporu | R0-01, R0-06 |
| 6 | Tek sağlayıcıya bağımlılık | Orta | Yüksek | İkinci sağlayıcı hesabı ve devretme mantığı | Sonraki dalga |
| 7 | Sahte dekontla haksız bakiye | Orta | Orta | Onayın banka hareketine dayandırılması | R4-04 |
| 8 | Ödeme oturumu spam'i ile kuruş havuzunun tükenmesi | Düşük | Orta | Hız sınırı + CAPTCHA | R0-09 |
| 9 | Verilmiş ama karşılığı olmayan `Bərpa` sözü | Orta | Orta | Rozeti gizle veya akışı geliştir | R1-03 |
| 10 | Katalog büyüdükçe sayfanın çökmesi | Orta | Orta | Sayfalama | R2-05 |

---

## 5. Başarı ölçütleri

Ölçülmeyen iyileştirme, yapılmamış iyileştirmedir. Ölçüm altyapısı R0'da kurulmalı.

| Ölçüt | Bugün | Hedef | Kaynak |
|---|---|---|---|
| Katalog → sipariş dönüşümü | ölçülmüyor | temel çizgi + %30 | Analitik + `Order` |
| Ortalama ödeme onay süresi | ölçülmüyor | < 30 dk (mesai saatlerinde) | `customer_confirmed_at` → `processed_at` |
| Yanlış tutar kaynaklı destek talebi | ölçülmüyor | < %2 | Manuel etiketleme |
| `submission_unknown` oranı | ölçülmüyor | < %1 | `Order.status` |
| Brüt marj | **hesaplanamıyor** | ölçülebilir olması | R0-01 sonrası |
| Mutabakat sapması | ölçülmüyor | **0** | R0-06 raporu |
| Mobil dönüşümün masaüstüne oranı | ölçülmüyor | > 0,7 | Analitik |

---

## 6. Yayın öncesi kontrol listesi

R0 tamamlandığında ve ilk gerçek ödeme kabul edilmeden önce:

- [ ] `manage.py check --deploy` uyarısız geçiyor
- [ ] `DEBUG=False`, `SECRET_KEY` ortam değişkeninden, `ALLOWED_HOSTS` doğru
- [ ] `CSRF_TRUSTED_ORIGINS` tanımlı ve HTTPS üzerinden form gönderimi test edildi
- [ ] Tüm testler PostgreSQL üzerinde geçiyor
- [ ] Yedek alınıyor **ve** boş sunucuda geri yükleme bir kez denendi
- [ ] Arka plan işçisi ve zamanlayıcı çalışıyor; durum senkronu doğrulandı
- [ ] Hata izleme aktif; kasıtlı bir hata tetiklenip bildirim alındığı görüldü
- [ ] Sağlayıcı bakiyesi panelde görünüyor, uyarı eşiği ayarlandı
- [ ] Dekont dosyalarına yetkisiz erişim denendi ve engellendiği doğrulandı
- [ ] Demo veriler temizlendi (`is_demo=True` kayıtlar), demo yönetici hesabı kaldırıldı
- [ ] Hız sınırı ve CAPTCHA canlıda test edildi
- [ ] `terms`, `privacy`, `payment_and_refund` sayfaları hukuki gözden geçirmeden geçti
- [ ] İş hesabı ve vergi kaydı tamam; `PaymentAccount` kayıtları güncellendi
- [ ] Mutabakat raporu üretiliyor ve sapma sıfır
- [ ] Küçük tutarlı uçtan uca canlı test yapıldı: yatırım → onay → sipariş → tamamlanma → iade

---

## 7. Operasyon hazırlığı

Yazılım dışı; ancak bunlar tanımlanmadan yayına çıkmak, yazılım hatası olarak görünen
operasyon hataları üretir.

| Konu | Karara bağlanmalı |
|---|---|
| Ödeme onayı | Kim onaylıyor, hangi saatlerde? Mesai dışı gelen ödemeler ne olacak? Panelde dürüst bir çalışma saati bilgisi, tutulamayan bir sözden iyidir. |
| Sağlayıcı bakiyesi | Kim, hangi eşikte dolduruyor? Mesai dışı tükenirse ne olur? |
| İade politikası | Hangi durumda iade var, hangi durumda yok? Yazılı olmalı ve `payment_and_refund` sayfasıyla uyumlu olmalı. |
| Destek | Kanal, yanıt süresi taahhüdü, sık sorunlar için hazır cevaplar. |
| Runbook | `submission_unknown` sipariş geldiğinde, sağlayıcı kapandığında, mutabakat sapması oluştuğunda izlenecek adımlar. |
| Fiyatlandırma | Sağlayıcı fiyatları değişiyor; marj hangi sıklıkla gözden geçirilecek? |

---

## 8. Kapsam dışı — sonraki dalga

Bu yol haritası mevcut ürünü yayına hazır hâle getirmeyi hedefler. Aşağıdakiler yeni
yetenekler olduğu için ayrı planlanmalıdır; bunların hepsi R3-01'deki sol menüde yer
bulacak şekilde tasarlanmalıdır:

| Özellik | Neden önemli | Tahmini efor |
|---|---|---:|
| Refill / Cancel akışı | Modelde alanlar var, karşılığı yok (R1-03 kararına bağlı) | 3 g |
| Destek talebi (ticket) sistemi | Şu an tek kanal Telegram; sipariş bağlamı kayboluyor | 4 g |
| **Kullanıcı API'si + API anahtarı** | Bayi müşteriler SMM panellerinin ana ciro kalemidir | 5 g |
| Toplu sipariş (mass order) | Bayi kullanımının ön koşulu | 2 g |
| Profil ve güvenlik ayarları | Şifre değiştirme URL'i bile tanımlı değil | 2 g |
| Yönetim istatistik ekranı | Günlük ciro, marj, bekleyen iş yükü | 3 g |
| İkinci sağlayıcı ve devretme | Tek tedarikçi bağımlılığını kaldırır | 4 g |
| Otomatik ödeme entegrasyonu | Manuel onay yükünü ortadan kaldırır | 5 g |
| Kupon, referans, kademeli fiyat | Büyüme araçları; marj şu an kullanıcı bazlı ayarlanamıyor | 4 g |

---

## Ek A — Efor özeti

| Sürüm | Efor |
|---|---:|
| R0 · Yayın öncesi zorunlu | 9–11 g |
| R1 · Doğru bilgi | 2–3 g |
| R2 · Dönüşüm | 4–5 g |
| R3 · Panel iskeleti | 5–6 g |
| R4 · Ödeme deneyimi | 3–4 g |
| R5 · Marka ve içerik | 3–4 g |
| R6 · Bakım borcu | 4–5 g |
| **Toplam** | **34–41 g** |

Tek kişilik geliştirme temposuyla yaklaşık 8–10 hafta. R0-11 (kurumsal yapı) bu sürenin
dışındadır ve **ilk gün başlatılmalıdır** — resmî süreçler geliştirmeden bağımsız ilerler
ve yayını bloklayabilir.

## Ek B — Bekleyen kararlar

| # | Karar | Seçenekler | Öneri |
|---|---|---|---|
| 1 | `account_type` alanı | Modele ekle / şablondan kaldır | Ekle — ana sayfadaki vaatle tutarlı olur |
| 2 | `Bərpa` / `Ləğv` rozetleri | Gizle / akışı geliştir | Şimdilik gizle, R3'ten sonra geliştir |
| 3 | Kuyruk teknolojisi | Celery / RQ | RQ — ihtiyaç bu ölçekte daha basit |
| 4 | Barındırma konumu | Yerel / yurt dışı | Yerel bankacılık ve veri mevzuatı açısından değerlendirilmeli |
| 5 | Kurumsal biçim | Fərdi sahibkar / MMC | Mali müşavire danışılmalı |
