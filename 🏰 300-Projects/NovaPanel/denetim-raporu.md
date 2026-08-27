# NovaPanel — Yayın Öncesi Tam Kod Denetimi

**Tarih:** 3 Avqust 2026 · **Kapsam:** tüm kaynak kod, şablonlar, statik dosyalar, migration'lar, testler, CI
**Yöntem:** dosya bazlı okuma + canlı doğrulama (Django test istemcisi ile gerçek istek, `collectstatic`, test paketi)
**Test durumu:** 93/93 geçiyor · `manage.py check` temiz

---

## Özet

Kod kalitesi genel olarak iyi: para akışı `transaction.atomic` + `select_for_update` ile korunmuş,
sağlayıcı hataları üç sınıfa ayrılmış, veritabanı kısıtları doğru kurulmuş, 93 test var.

Ancak **yayına çıkmaya hazır değil.** Aşağıda 8 kritik, 14 yüksek, 19 orta öncelikli bulgu var.
Bunlardan üçü şu anda canlı ortamda anında hataya yol açar:

1. `/xidmetler/<slug>/` sayfalarının **tamamı 500 veriyor** — ve bu 51 URL sitemap'te ilan ediliyor
2. `collectstatic` **çalışmıyor** — `STATIC_ROOT` tanımsız, dağıtım imkânsız
3. Dekont yükleme alanında **hiçbir dosya doğrulaması yok** — depolanmış XSS ve disk doldurma açık

Testlerin 93'ünün geçiyor olması yanıltıcı: kırık olan üç yolun hiçbiri test edilmiyor.

| Önem | Adet | Tanım |
|---|---:|---|
| 🔴 Kritik | 8 | Yayını bloklar; para, veri veya güvenlik kaybı |
| 🟠 Yüksek | 14 | Yayından kısa süre sonra kesin sorun çıkarır |
| 🟡 Orta | 19 | Kalite, performans, bakım |

---

# 🔴 KRİTİK

## K-01 · Tüm platform iniş sayfaları 500 veriyor

**Dosya:** `core/views.py:138`
**Doğrulandı:** `/xidmetler/instagram-beyenme/` → `KeyError: 'more_services'`

```python
"services": kind_group["services"] + kind_group["more_services"],
```

`group_services_by_platform` (`core/platforms.py:116-122`) `more_count` anahtarını üretiyor,
`more_services` diye bir anahtar hiç yok. Sonuç: **51 SEO iniş sayfasının hepsi 500.**

Bu sayfalar `core/sitemaps.py::PlatformLandingSitemap` üzerinden sitemap'te ilan ediliyor —
yani Google'a "bu 51 sayfayı tara" denip hepsinde sunucu hatası veriliyor. Arama sıralaması
açısından bundan kötü bir başlangıç yok.

**Neden yakalanmadı:** `platform_landing` için tek bir test yok.

**Düzeltme:** `group_services_by_platform` içinde kesilen kısmı `more_services` olarak sakla,
ya da `platform_landing` içinde `group_services_full` kullan. Ardından her iniş sayfasının
200 döndüğünü doğrulayan bir test yaz.

## K-02 · `collectstatic` çalışmıyor — dağıtım bloklu

**Dosya:** `config/settings.py:116-117`
**Doğrulandı:** `ImproperlyConfigured: You're using the staticfiles app without having set the STATIC_ROOT setting`

`STATIC_URL` ve `STATICFILES_DIRS` var, `STATIC_ROOT` yok. Üretimde statik dosyalar
toplanamaz; CSS/JS hiç servis edilemez. `.gitignore` içinde `staticfiles/` yazması,
bir noktada planlandığını ama tanımın eklenmediğini gösteriyor.

**Düzeltme:** `STATIC_ROOT = BASE_DIR / "staticfiles"` + `STORAGES` ile
`ManifestStaticFilesStorage` (önbellek kırma için — şu an `?v=20260802` elle yazılıyor).

## K-03 · Dekont yüklemede hiçbir doğrulama yok

**Dosya:** `core/forms.py:101-111`, `core/models.py:243`

```python
class PaymentConfirmForm(forms.ModelForm):
    class Meta:
        fields = ["reference", "receipt"]   # validator yok
```

`FileField` üzerinde ne boyut sınırı, ne uzantı beyaz listesi, ne içerik tipi kontrolü var.
Sonuçlar:

- **Depolanmış XSS:** kullanıcı `.svg` veya `.html` yükler, `MEDIA_ROOT` altından kendi
  alan adınızda servis edilir. Yönetici `admin.py:192`'deki "Qəbzi aç" bağlantısına
  tıkladığında betik **admin oturumu bağlamında** çalışır → oturum çalınması.
- **Disk doldurma:** boyut sınırı yok; birkaç GB'lık dosya yüklenebilir.
- **Yetkisiz erişim:** `payment_receipts/%Y/%m/` yolu korumasız. Üretimde Nginx bu klasörü
  doğrudan servis ederse başkasının banka dekontu görülebilir (KVKK/fərdi məlumatlar ihlali).

**Düzeltme:** uzantı beyaz listesi (`jpg/jpeg/png/webp/pdf`), 5 MB sınır, Pillow ile gerçek
görsel doğrulaması, dosya adını UUID ile değiştirme, ve dekontları `MEDIA_ROOT` yerine
yetki kontrollü bir view üzerinden servis etme.

## K-04 · `submit_order` yarış koşuluna açık — çift sipariş riski

**Dosya:** `core/services/orders.py:85-116`

```python
def submit_order(order_id, client=None):
    order = Order.objects.select_related("service__provider").get(pk=order_id)
    if order.provider_order_id or order.status not in {"queued"}:
        return order
```

Fonksiyon `transaction.atomic` içinde değil ve `select_for_update` kullanmıyor. Aynı sipariş
için iki eşzamanlı çağrı (kullanıcının çift tıklaması, ileride eklenecek kuyruk işçisi,
yeniden deneme) ikisi de kontrolü geçer ve **sağlayıcıya iki sipariş gönderilir.**
Kullanıcıdan bir kez tahsil edilir, sağlayıcıya iki kez ödeme yapılır. Doğrudan zarar.

**Düzeltme:** `Order.objects.select_for_update().filter(pk=order_id, status="queued", provider_order_id="")`
ile kilitli ve koşullu tek satırlık geçiş; ya da `provider_order_id` üzerinde kısmi unique kısıt.

## K-05 · `partial` siparişlerde iade yapılmıyor

**Dosya:** `core/services/orders.py:146`

```python
if local_status == "canceled":
    return refund_canceled_order(order.pk, ...)
```

Sağlayıcı `partial` döndürdüğünde — yani siparişin bir kısmı teslim edilmediğinde —
`remains` alanı güncelleniyor ama **teslim edilmeyen miktarın parası kullanıcıda kalmıyor,
sizde kalıyor.** Kullanıcı 1000 adet ödeyip 600 alıyor, 400'ün parası iade edilmiyor.

Yol haritasında `R0-02` olarak işaretlenmişti, hâlâ yapılmadı. Bu bir tercih değil, hatadır;
ilk şikâyette iade politikanızla çelişir.

## K-06 · `submission_unknown` siparişler için hiçbir kurtarma yok

**Dosya:** `core/services/orders.py:104-107`, `core/management/commands/sync_order_statuses.py:15-16`

Kullanıcıya gösterilen metin (`core/models.py:278`):

> "30 dəqiqə ərzində ya işə düşəcək, ya da məbləğ balansınıza qayıdacaq."

Bu **söz tutulmuyor.** `sync_order_statuses` yalnızca `pending` ve `processing` durumundaki,
`provider_order_id` dolu siparişleri tarıyor. `submission_unknown` ve `queued` durumundaki
siparişleri hiçbir süreç ele almıyor. Bir sipariş bu duruma düştüğünde:

- para kullanıcıdan alınmış
- sağlayıcıya gidip gitmediği bilinmiyor
- yeniden deneyen kimse yok
- iade eden kimse yok
- yöneticinin elle çözebileceği bir arayüz de yok (`OrderAdmin`'de eylem yok)

Sipariş sonsuza kadar orada kalır. Aynı şey `submit_order` beklenmedik bir istisna atarsa
`queued` siparişler için de geçerli.

## K-07 · Ödeme oturumu kötüye kullanıma açık — tahsilat durdurulabilir

**Dosya:** `core/services/payments.py:56-63`

Kuruş havuzu bir (hesap, taban tutar) çifti için yalnızca **99 slot**. Kullanıcı başına açık
oturum sınırı yok, hız sınırı yok, CAPTCHA yok. Tek bir kullanıcı `add_balance` uç noktasına
100 istek göndererek popüler bir tutarın (10 ₼, 20 ₼, 50 ₼) tüm havuzunu tüketebilir; o
tutarı yatırmak isteyen herkes 10 dakika boyunca

> "Hazırda çox sayda ödəniş gözləyir"

hatası alır. **Tahsilatınız durur.** Maliyeti sıfır olan bir saldırı.

**Düzeltme:** kullanıcı başına aynı anda tek açık oturum, `add_balance` uç noktasına hız
sınırı, ve havuz dolduğunda taban tutarı da değiştiren bir geri çekilme stratejisi.

## K-08 · `CSRF_TRUSTED_ORIGINS` tanımsız

**Dosya:** `config/settings.py`

HTTPS'e geçildiği anda tüm POST istekleri (giriş, kayıt, sipariş, ödeme onayı) CSRF hatası
verir. Site açılır ama **hiçbir form çalışmaz.** Django 4+ ile zorunlu.

**Düzeltme:** `CSRF_TRUSTED_ORIGINS = ["https://example.com", "https://www.example.com"]`
(ortam değişkeninden). Ayrıca ters vekil arkasında `SECURE_PROXY_SSL_HEADER` tanımlanmazsa
`SECURE_SSL_REDIRECT` sonsuz yönlendirme döngüsü yaratır.

---

# 🟠 YÜKSEK

## Y-01 · "Daha çox göstər" özelliği tamamen ölü

**Dosya:** `templates/core/services.html:18`, `core/views.py:86-124`
**Doğrulandı:** katalog sayfasında `data-show-more` sayısı **0**, `service-more` sayısı **0**

Üç ayrı kırık parça var:

1. Şablon `kind_group.more_services` kullanıyor — o anahtar üretilmiyor (K-01 ile aynı kök).
   Django şablonu eksik anahtarı sessizce boş sayar, buton hiç render edilmiyor.
2. `services_more` view'ı yazılmış ama **`core/urls.py` içinde hiçbir yola bağlanmamış** — ölü kod.
3. O view `core/includes/service_rows.html` şablonunu render etmeye çalışıyor —
   **böyle bir dosya yok** (`service_row.html` var, çoğul olan yok) → çağrılsa `TemplateDoesNotExist`.

Sonuç: her tür başına yalnızca ilk 25 servis görülebiliyor, kalan **624 servise arayüzden
hiçbir şekilde ulaşılamıyor.** Sattığınız ürünün üçte ikisi görünmez durumda.

## Y-02 · Sipariş formunda da aynı kısıt — servislerin çoğu seçilemiyor

**Dosya:** `core/forms.py:44`, `templates/core/new_order.html`

`GroupedServiceChoiceIterator` da `group_services_by_platform` kullanıyor, yani seçim
listesi de tür başına 25 ile sınırlı. Katalogdaki "Sifariş ver" butonu `?service=<id>` ile
gelse bile, o servis ilk 25'te değilse seçicide görünmüyor.

## Y-03 · Katalog sayfası hâlâ çok ağır

**Doğrulandı:** 618 KB HTML, 663 servis satırı, tek istekte

Sayfalama görsel olarak uygulanmış ama `core/views.py:70` hâlâ `list(items)` ile **tüm 949
servisi** veritabanından çekip Python nesnesine dönüştürüyor, `group_services_full` hepsini
gruplayıp sınıflandırıyor. Tarayıcı testi sırasında Chrome'un render motoru iki kez donup
ekran görüntüsü almayı reddetti.

**Düzeltme:** kesme işlemi Python'da değil, veritabanı seviyesinde yapılmalı.

## Y-04 · CSV dışa aktarımda formül enjeksiyonu

**Dosya:** `core/views.py:257-263`, `287-294`

Servis adları sağlayıcı API'sinden geliyor — yani sizin kontrolünüzde değil. `=`, `+`, `-`,
`@` ile başlayan bir ad, kullanıcı CSV'yi Excel'de açtığında **formül olarak çalışır.**
Klasik CSV injection. Kullanıcının kendi makinesinde komut çalıştırmaya kadar gidebilir.

**Düzeltme:** bu karakterlerle başlayan hücrelerin başına tek tırnak ekle.

## Y-05 · Sağlayıcı senkronizasyonu yönetici kararlarını eziyor

**Dosya:** `core/services/catalog_sync.py:150`

```python
service.is_active = True
```

Yönetici bir servisi kasten kapattıysa (sorunlu, zararına satılıyor, şikâyet var), bir
sonraki senkronizasyon **onu geri açıyor.** Aynı şekilde `provider_rate` hiçbir makullük
kontrolü olmadan üzerine yazılıyor: sağlayıcı hatalı bir fiyat döndürürse zararına satış
otomatik başlar.

**Düzeltme:** `manual_override` bayrağı; fiyat değişimi ±%X'i aşarsa servisi otomatik
kapatıp yöneticiyi uyar.

## Y-06 · Yönetici siparişe müdahale edemiyor

**Dosya:** `core/admin.py:109-117`

`OrderAdmin`'de hiçbir eylem yok: "iade et", "durumu senkronla", "yeniden gönder" yok.
Daha tehlikelisi: `status` alanı formda **düzenlenebilir**, ama elle `canceled` yapmak
hiçbir iade tetiklemiyor. Yönetici parayı iade ettiğini sanır, cüzdan hiç değişmez.

## Y-07 · Elle bakiye düzeltmesi imkânsız

**Dosya:** `core/admin.py:152-159`

`WalletTransaction` için `has_add_permission = False`. `adjustment` işlem tipi tanımlı ama
kullanılamıyor. Bir hata olduğunda (yanlış iade, eksik kredi, telafi) yöneticinin bakiyeyi
düzeltmesinin **hiçbir yolu yok** — veritabanına elle SQL yazmak dışında.

## Y-08 · Alınan tutar ile kredilenen tutar ayrıştırılamıyor

**Dosya:** `core/services/payments.py:122`

```python
credit_amount = payment.payable_amount or payment.amount
```

Kullanıcı 10,37 ₼ yerine 10,00 ₼ gönderdiyse yönetici ya onaylar (10,37 kredi verir, 0,37
zarar) ya reddeder. Gerçekten alınan tutarı girip onu kredilemenin yolu yok. Manuel havale
modelinde bu durum her gün yaşanır.

## Y-09 · Maksimum yatırım sınırı yok

**Dosya:** `core/forms.py:87-94`, `core/models.py:239`

`min_value=1` var, `max_value` yok. `max_digits=12` ile 9.999.999.999,99 ₼'lik bir müraciət
oluşturulabilir. Yönetici toplu onay ekranında yanlış satırı seçerse felaket.

## Y-10 · Bakım modu uygulanmıyor

**Dosya:** `core/models.py:43`

`SiteSetting.maintenance_mode` alanı var, yönetici panelinde görünüyor, **hiçbir yerde
kontrol edilmiyor.** Yönetici bakım moduna aldığını sanır, site normal çalışmaya devam eder.

## Y-11 · Sağlayıcı bakiyesi hiç kontrol edilmiyor

**Dosya:** `core/services/panelbaku.py:89`

`PanelBakuClient.balance()` yazılmış, hiçbir yerden çağrılmıyor. Sağlayıcı bakiyesi
bittiğinde tüm siparişler sessizce reddedilip iade ediliyor; siz ancak müşteri şikâyet
edince öğreniyorsunuz.

## Y-12 · Hız sınırı, CAPTCHA ve e-posta doğrulaması yok

Korumasız uçlar: `signup`, `login`, `password_reset`, `new_order`, `add_balance`,
`services_more`. Sınırsız sahte hesap açılabilir, parola deneme saldırısı yapılabilir,
K-07'deki ödeme saldırısı otomatikleştirilebilir.

## Y-13 · Loglama ve hata izleme yok

**Dosya:** `config/settings.py`

`LOGGING` tanımı yok, Sentry yok. Sağlayıcı API hataları, `submission_unknown` siparişler,
yakalanmamış istisnalar hiçbir yere düşmüyor. K-01'deki 500 hatası aylarca fark edilmeyebilirdi.

## Y-14 · Form ve model arasında URL uzunluğu uyuşmazlığı

**Dosya:** `core/forms.py:62` (`URLField`, uzunluk sınırı yok) → `core/models.py:299`
(`URLField`, varsayılan `max_length=200`)

200 karakterden uzun bir link form doğrulamasını geçer, veritabanına yazılırken patlar.
SQLite sessizce kabul eder, **PostgreSQL'de 500 verir** — ve o noktada cüzdandan para
zaten düşülmüştür (`create_order` içinde `Order.objects.create` çağrısında).

---

# 🟡 ORTA

| # | Bulgu | Dosya |
|---|---|---|
| O-01 | `provider_charge` snapshot'ı yok — kâr marjı geriye dönük hesaplanamıyor (`R0-01`) | `core/models.py:287` |
| O-02 | Mali mutabakat raporu yok — kullanıcı bakiyeleri toplamı ile varlıklar karşılaştırılmıyor | — |
| O-03 | CI yalnızca `DEBUG=True` ile çalışıyor; üretim ayar yolu (SSL, e-posta zorunluluğu) hiç test edilmiyor | `.github/workflows/ci.yml:11` |
| O-04 | CI'da `makemigrations --check` yok — model/migration kayması fark edilmez | `.github/workflows/ci.yml` |
| O-05 | Bağlam işlemcisi her istekte 2 sorgu atıyor, `get_or_create` GET isteğinde yazma deniyor | `core/context_processors.py:5,19` |
| O-06 | `platform_landing` her istekte tüm kataloğu belleğe alıp doğrusal arama yapıyor | `core/views.py:128-140` |
| O-07 | Sitemap üretimi de tüm kataloğu grupluyor | `core/sitemaps.py:24-31` |
| O-08 | `services_more` kimlik doğrulamasız ve pahalı — DoS vektörü (bağlanırsa) | `core/views.py:86` |
| O-09 | Geçersiz dekont formu sessizce yok sayılıyor, kullanıcıya hata gösterilmiyor | `core/views.py:389-392` |
| O-10 | `robots.txt` `/panel/` ve `/accounts/` yollarını da taramaya açıyor | `core/views.py:167` |
| O-11 | `Order.status` varsayılanı `pending`, ama `create_order` her zaman `queued` yazıyor | `core/models.py:303` |
| O-12 | `Category.name` üzerinde benzersizlik kısıtı yok — eşzamanlı senkronda çift kayıt | `core/models.py:73` |
| O-13 | `SiteSetting` tekilliği yalnızca admin katmanında; veritabanı seviyesinde korunmuyor | `core/models.py:29` |
| O-14 | `assign_initial_featured_services` her senkronda manuel "öne çıkan" seçimlerini eziyor | `core/services/catalog_sync.py:161` |
| O-15 | CSV dışa aktarımlarında satır sınırı yok — büyük hesapta bellek sorunu | `core/views.py:254,285` |
| O-16 | Sipariş linki servis platformuyla eşleşiyor mu kontrol edilmiyor (en sık destek sebebi) | `core/forms.py:62` |
| O-17 | Aynı link + servis için mükerrer sipariş uyarısı yok | `core/services/orders.py:30` |
| O-18 | `sync_order_status` içindeki `transaction.on_commit` atomik blok dışında — anlık çalışıyor | `core/services/orders.py:149` |
| O-19 | Statik dosya sürümleri elle yazılıyor (`?v=20260802-mobilefix`) — `ManifestStaticFilesStorage` yok | `templates/base.html:22-24` |

---

# Test kapsamı boşlukları

93 test var ama **kırık olan üç yolun hiçbiri test edilmiyor.** Bu, "testler geçiyor"
ifadesinin neden yanıltıcı olduğunu açıklıyor.

| Test edilmeyen | Sonuç |
|---|---|
| `platform_landing` (51 URL) | K-01 fark edilmedi |
| `services_more` | Y-01 fark edilmedi |
| `guide_detail`, `guide_list` içerik doğrulaması | — |
| Kısmi sipariş iadesi | K-05 (özellik zaten yok) |
| Eşzamanlı `submit_order` | K-04 |
| Dekont yükleme doğrulaması | K-03 |
| `collectstatic` / `check --deploy` | K-02, K-08 |
| Ödeme havuzu tükenmesi | K-07 |

**Öneri:** her URL yapılandırmasındaki her rotanın en az bir durum kodu testi olsun
(smoke test). Bu tek başına K-01'i yakalardı.

---

# Düzeltme sırası

## Aşama 1 — Bugün (yarım gün)
Bunlar küçük ve sitenin şu anda kırık olan kısımlarını onarır.

1. **K-01** `more_services` anahtarını üret → 51 sayfa ayağa kalksın
2. **Y-01** "Daha çox göstər" zincirini tamamla (`urls.py` yolu + `service_rows.html` + şablon anahtarı)
3. **K-02** `STATIC_ROOT` tanımla
4. **K-08** `CSRF_TRUSTED_ORIGINS` + `SECURE_PROXY_SSL_HEADER`
5. Tüm rotalar için smoke test yaz

## Aşama 2 — Para güvenliği (2 gün)
6. **K-05** kısmi iade
7. **K-04** `submit_order` kilitleme
8. **K-06** takılan sipariş toplayıcısı + yönetici müdahale eylemleri (Y-06)
9. **O-01** `provider_charge` snapshot'ı
10. **Y-07** elle bakiye düzeltmesi, **Y-08** alınan tutarı girme

## Aşama 3 — Güvenlik (1,5 gün)
11. **K-03** dosya yükleme doğrulaması + korumalı servis
12. **K-07** ödeme oturumu sınırlaması
13. **Y-12** hız sınırı + CAPTCHA + e-posta doğrulaması
14. **Y-04** CSV enjeksiyonu, **Y-09** maksimum tutar, **Y-14** URL uzunluğu

## Aşama 4 — Altyapı (3 gün)
15. **Y-13** loglama + Sentry, **Y-11** sağlayıcı bakiyesi izleme
16. PostgreSQL, Redis, arka plan kuyruğu, yedekleme
17. **O-03/O-04** CI'ya üretim ayar testi ve migration kayma kontrolü
18. **O-02** mutabakat raporu

## Aşama 5 — Performans ve tutarlılık (1,5 gün)
19. **Y-03** katalog sorgusunu veritabanı seviyesinde sınırla, **Y-02** sipariş seçicisi
20. **Y-05** senkronizasyon koruma bayrakları
21. **Y-10** bakım modu, kalan orta öncelikli maddeler

**Toplam:** yaklaşık 8,5 gün.

---

# Değişmeyen olumlu tespitler

Denetimin dengeli olması için: aşağıdakiler doğru yapılmış ve korunmalı.

- Cüzdan işlemleri `transaction.atomic` + `select_for_update` ile korunuyor; `create_order`
  ve `approve_payment` yarış koşullarına kapalı (`submit_order` istisnası K-04'te)
- `CheckConstraint`'ler bakiyenin negatife düşmesini veritabanı seviyesinde engelliyor
- Sağlayıcı hataları üç anlamlı sınıfa ayrılmış (konfigürasyon / kesin ret / belirsiz iletim)
  ve belirsiz durumda iade **yapılmıyor** — bu doğru ve çoğu projede yanlış yapılır
- `json_ld` fonksiyonu `<`, `>`, `&` kaçışıyla script kapatma saldırısını engelliyor
- Ödeme rekvizitleri müraciət anında kopyalanıyor; hesap silinse bile geçmiş bozulmuyor
- `refunded_at` kontrolü çift iadeyi engelliyor
- 93 test, iş mantığının çekirdeğini gerçekten kapsıyor
- `.env` doğru şekilde `.gitignore` içinde; gizli anahtarlar kodda değil
