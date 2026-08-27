# Panel'im — SEO Denetimi

**Tarih:** 5 Avqust 2026
**Kapsam:** sitemap içeriği, yapısal veri, canonical'lar, meta etiketler, indeksleme, başlık hiyerarşisi
**Yöntem:** çalışan sunucuya karşı canlı HTTP istekleri + gerçek Chrome'da CSP/DOM doğrulaması
**Not:** Bu denetim, `denetim-raporu-2.md`'deki D-01…D-06 düzeltmeleri commit edildikten *sonra* yapıldı.

---

## Özet

Temel hijyen iyi: her sayfanın **benzersiz ve makul uzunlukta `<title>`'ı var**, her sayfada
tam olarak **bir `<h1>`** var, **404'ler doğru durum kodu döndürüyor**, sitemap 59 URL ile
üretiliyor ve içinde **tekrar eden URL yok**, görsellerde alt metni eksiği yok.

Ancak sitenin para kazandıran sayfaları — 51 platform iniş sayfası — SEO açısından
**neredeyse boş**. Fiyat ve limit bilgisi ekranda var ama arama motoruna hiçbir yapısal
veriyle bildirilmiyor, canonical yok, sosyal paylaşımda hepsi aynı jenerik kartı gösteriyor.

| Önem | Adet |
|---|---:|
| 🟠 Yüksek | 3 |
| 🟡 Orta | 4 |
| 🔵 Düşük | 6 |

---

# ⚠️ Önce: SEO dışı ama acil bir regresyon

## R-01 · Yeni CSP, sayfadaki satır içi scripti blokluyor

**Kritiklik:** 🟠 High (UX regresyonu) · **Dosya:** `core/middleware.py:52`, `templates/base.html:24`

D-06 için eklenen CSP `script-src 'self' https://challenges.cloudflare.com` — içinde
`'unsafe-inline'`, nonce veya hash **yok**. `base.html:24`'teki satır içi tema scripti
(FOUC önleyici) bu yüzden çalışmıyor.

**Kanıt — gerçek Chrome'da doğrulandı:**
```json
{ "inline_script_executed": false,
  "csp_violations": ["script-src-elem | inline"],
  "csp_enforced": true }
```

**Etki:** Tema tercihi "tünd" olan kullanıcı **her sayfa yüklemesinde açık temanın
yanıp sönmesini** görüyor; koyu tema ancak `theme-toggle.js` (deferred) çalışınca
uygulanıyor. İşlevsellik kaybolmuyor, ama her gezinmede göze çarpan bir titreme var.

**İyi haber — JSON-LD etkilenmiyor:** `application/ld+json` blokları DOM'da bozulmadan
duruyor ve ayrıştırılabiliyor (Organization 134 bayt, FAQPage 2389 bayt, ikisi de
`parse: OK`). Yapısal veride kayıp yok.

**Öneri:** CSP'ye nonce ekle — middleware'de istek başına `secrets.token_urlsafe(16)`
üret, `request.csp_nonce`'a yaz, politikaya `'nonce-{...}'` koy ve `base.html:24`'e
`<script nonce="{{ request.csp_nonce }}">` ekle. Alternatif (daha basit): scripti
`static/js/theme-init.js` dosyasına taşı ve `<head>` içinde `<script src>` ile senkron yükle.

**Zorluk:** Asan (1 saat)

---

# 🟠 YÜKSEK

## S-01 · Hiçbir sayfada canonical yok — filtreler duplicate content üretiyor

**Kategori:** SEO / İndeksleme · **Kritiklik:** 🟠 High · **Dosya:** `templates/base.html`

Sitenin **tamamında** tek bir `rel="canonical"` etiketi yok (`grep -rn "canonical"
templates/` boş döndü). Katalog sayfası ise `platform`, `sort`, `q` ve `page`
parametrelerini serbestçe kabul ediyor; her kombinasyon ayrı bir URL, aynı içerik.

**Kanıt:**
```
/services/                                   canonical=0  og:url=/services/
/services/?platform=Instagram                canonical=0  og:url=/services/?platform=Instagram
/services/?platform=Instagram&sort=price_asc canonical=0  og:url=/services/?platform=Instagram&sort=price_asc
/services/?sort=price_desc                   canonical=0  og:url=/services/?sort=price_desc
/services/?q=                                canonical=0  og:url=/services/?q=
/services/?page=1                            canonical=0  og:url=/services/?page=1
```

9 platform × 3 sıralama × arama terimleri = katalog sayfasının yüzlerce indekslenebilir
kopyası. `og:url` de `request.build_absolute_uri` kullandığı için sorgu dizesini
aynen taşıyor ve bu kopyaları pekiştiriyor.

**Öneri:**
1. `base.html`'e `<link rel="canonical" href="{{ canonical_url }}">` ekle; varsayılan
   olarak sorgu dizesiz mutlak yol olsun (`request.build_absolute_uri(request.path)`).
2. Filtreli katalog görünümlerine `<meta name="robots" content="noindex,follow">` ver —
   filtre sonuçlarının indekslenmesi istenmiyor, ama linkler taranabilir kalsın.
3. Kanonik hedef `/services/` olsun; platform bazlı SEO trafiği zaten
   `/xidmetler/<slug>/` iniş sayfalarına ait.

**Zorluk:** Asan (2–3 saat)

---

## S-02 · `og:title` ve `og:description` her sayfada aynı

**Kategori:** SEO / Sosyal paylaşım · **Kritiklik:** 🟠 High · **Dosya:** `templates/base.html:11,12`

`<title>` sayfa başına doğru şekilde özelleştirilmiş, ancak Open Graph etiketleri
`block` içinde değil — her sayfada site geneli `meta_title`'ı basıyor.

**Kanıt:**
```
/services/                      <title>: Xidmətlər · Panel'im
                                og:title: Panel'im — Sosial media xidmətləri bir paneldə
/xidmetler/instagram-beyenme/   <title>: Instagram Bəyənmə xidmətləri · Panel'im
                                og:title: Panel'im — Sosial media xidmətləri bir paneldə
/beledci/                       <title>: Bələdçi · Panel'im
                                og:title: Panel'im — Sosial media xidmətləri bir paneldə
/qaydalar/                      <title>: İstifadə qaydaları · Panel'im
                                og:title: Panel'im — Sosial media xidmətləri bir paneldə
```

**Etki:** 51 iniş sayfasından herhangi biri WhatsApp, Telegram veya Facebook'ta
paylaşıldığında **hepsi aynı jenerik ana sayfa kartını** gösteriyor. Azerbaycan
pazarında Telegram/WhatsApp paylaşımı birincil dağıtım kanalı olduğu için bu doğrudan
tıklama kaybı.

**Öneri:** `og:title` ve `og:description`'ı `{% block og_title %}{% block title %}{% endblock %}{% endblock %}`
şeklinde bloklara bağla; iniş sayfası ve bələdçi şablonlarında sayfaya özel değer ver.

**Zorluk:** Asan (1–2 saat)

---

## S-03 · 51 iniş sayfasında ürün/fiyat yapısal verisi yok

**Kategori:** SEO / Yapısal veri · **Kritiklik:** 🟠 High · **Dosya:** `templates/core/platform_landing.html`

Yapısal veri envanteri (canlı ölçüm):

| Sayfa | Bulunan şemalar |
|---|---|
| `/` | `Organization`, `FAQPage` (9 soru) ✅ |
| `/services/` | yalnızca `Organization` |
| `/xidmetler/instagram-beyenme/` (×51) | yalnızca `Organization` |
| `/beledci/` | yalnızca `Organization` |
| `/beledci/<slug>/` | yalnızca `Organization` |

İniş sayfalarında fiyat (`sale_rate`), minimum/maksimum limit ve teslim süresi ekranda
zaten var — ama arama motoruna bildirilmiyor. Bu, sitedeki **en büyük tek SEO fırsatı**:
`Product` + `Offer` şeması fiyat zengin sonuçlarını (rich results) açar ve rakip SMM
panellerinin çoğunda bu yok.

**Öneri:**
1. Her iniş sayfasına `ItemList` içinde `Product`/`Service` + `Offer`
   (`price`, `priceCurrency: "AZN"`, `availability`) ekle. `core/seo.py:json_ld` altyapısı
   zaten hazır ve script kapatma saldırısına karşı korumalı — yeniden kullan.
2. Bələdçi sayfalarına `Article` şeması ekle (`headline`, `datePublished`,
   `dateModified`, `author`). Şu anda `og:type` de yanlış: `website` yerine `article` olmalı.
3. Tüm alt sayfalara `BreadcrumbList` ekle — hiçbir sayfada yok.
4. Değişikliklerden sonra Google Rich Results Test ile doğrula.

**Zorluk:** Orta (1 gün)

---

# 🟡 ORTA

## S-04 · `og:image` yok — sosyal paylaşımlarda önizleme görseli çıkmıyor

**Kritiklik:** 🟡 Medium · **Dosya:** `templates/base.html:14`, `SiteSetting.og_image`

`og:image` yalnızca `site_setting.og_image` doluysa basılıyor; bu kurulumda boş.
Sonuç: `twitter:card` da `summary_large_image` yerine `summary`'ye düşüyor.

**Kanıt (ana sayfa çıktısı):**
```
og:type, og:title, og:description, og:url  → var
og:image                                   → YOK
twitter:card                               → "summary"  (görsel yok, küçük kart)
```

**Öneri:** 1200×630 bir varsayılan paylaşım görseli üret, `static/img/og-default.png`
olarak koy ve `SiteSetting.og_image` boşsa ona düş. Ek olarak `og:site_name` ve
`og:locale` (`az_AZ`) etiketleri eksik — ikisi de tek satır.

**Zorluk:** Asan (1 saat)

---

## S-05 · Meta description beş sayfada birebir aynı ve fazla uzun

**Kritiklik:** 🟡 Medium · **Dosya:** `templates/base.html:8`

`/`, `/services/`, `/qaydalar/`, `/mexfilik/`, `/odenis-ve-iade/` sayfalarının hepsi
aynı 197 karakterlik site geneli açıklamayı paylaşıyor. Yalnızca `platform_landing`
(128 karakter) ve `guide_list` (152 karakter) kendi açıklamasını tanımlamış.

197 karakter Google'ın ~155–160 karakterlik kesme sınırının üstünde — sonu görünmüyor.

**Öneri:** Her statik sayfaya kendi `{% block meta_description %}` değerini ver ve
site geneli açıklamayı 155 karakterin altına indir.

**Zorluk:** Asan (1 saat)

---

## S-06 · `robots.txt` her şeyi taramaya açıyor (önceki denetimden O-10 hâlâ açık)

**Kritiklik:** 🟡 Medium · **Dosya:** `core/views.py:231`

```
User-agent: *
Allow: /
Sitemap: http://localhost:8000/sitemap.xml
```

Ölçüm: `/accounts/login/`, `/signup/`, `/accounts/password_reset/` → **HTTP 200,
`robots` meta etiketi YOK**, robots.txt'de engellenmiyor. `/panel/` giriş sayfasına
302 yapıyor (o kısım sorunsuz).

Bu sayfaların indekslenmesinin hiçbir faydası yok; tarama bütçesini yiyor ve arama
sonuçlarında ince içerik olarak görünüyorlar.

**Öneri:**
```
User-agent: *
Disallow: /panel/
Disallow: /accounts/
Disallow: /signup/
Disallow: /services/more/
Allow: /
Sitemap: https://panelim.az/sitemap.xml
```
Ek olarak bu şablonlara `<meta name="robots" content="noindex,follow">` ekle —
robots.txt taramayı engeller, indekslemeyi garanti etmez.

**Zorluk:** Asan (30 dakika)

---

## S-07 · İniş sayfaları içerik olarak ince — tek başlık, alt başlık yok

**Kritiklik:** 🟡 Medium · **Dosya:** `templates/core/platform_landing.html`

**Kanıt (başlık sayımı):**
```
/                              h1×1, h2×2, h3×8, h2×2, h3×4, h2×4, h3×3, h2×4   ← sağlıklı
/xidmetler/instagram-beyenme/  h1×1                                              ← başka başlık YOK
/services/                     h1×1, h3×51                                       ← h2 atlanmış
```

51 iniş sayfasının her biri bir `<h1>` ve bir servis tablosundan ibaret. Arama motoru
için bunlar birbirinin neredeyse aynısı, ince sayfalar — hepsi sitemap'te ilan edildiği
hâlde sıralanma şansları düşük.

**Öneri:** Her iniş sayfasına platform+tür özel bölümler ekle (`<h2>`): "Necə sifariş
verilir", "Çatdırılma müddəti", "Tez-tez verilən suallar" (sayfaya özel `FAQPage`
şemasıyla), "Qiymətlər nəyə görə dəyişir". 200–300 kelime özgün metin bu sayfaları
ince içerik sınıfından çıkarır.

**Zorluk:** Orta (içerik yazımı gerektirir)

---

## S-08 · `/services/` sayfasında başlık seviyesi atlaması (h1 → h3)

**Kritiklik:** 🟡 Medium (SEO + erişilebilirlik) · **Dosya:** `templates/core/services.html`

Katalogda `<h1>`'den sonra doğrudan 51 adet `<h3>` geliyor, arada hiç `<h2>` yok.
Hem başlık anahatını bozuyor hem de ekran okuyucu gezinmesini zorlaştırıyor
(`denetim-raporu-2.md`'deki D-11 ile aynı aileden).

**Öneri:** Platform grubu başlıklarını `<h2>`, servis adlarını `<h3>` yap.

**Zorluk:** Asan (30 dakika)

---

# 🔵 DÜŞÜK

## S-09 · `get_priority` ölü kod — ana sayfa 1.0 yerine 0.6 ile yayınlanıyor

**Dosya:** `core/sitemaps.py:18`

```python
def get_priority(self, item):
    return 1.0 if item == "home" else self.priority
```

Django bu metodu **hiç çağırmıyor.** `django/contrib/sitemaps/__init__.py:125`
`self._get("priority", item)` diyor — yani `priority` adlı özniteliğe bakıyor,
`get_priority`'ye değil. Sınıf özniteliği `priority = 0.6` kazanıyor.

**Kanıt (canlı sitemap çıktısı):**
```xml
<url><loc>http://localhost:8000/</loc><changefreq>weekly</changefreq><priority>0.6</priority></url>
```

**Öneri:** Metodu `priority(self, item)` olarak yeniden adlandır ve sınıf özniteliğini
kaldır — Django callable ise item ile çağırır. (Not: Google `priority` sinyalini uzun
süredir yok sayıyor, bu yüzden etki düşük; asıl sorun sessizce çalışmayan kod.)

**Zorluk:** Asan (10 dakika)

---

## S-10 · Sitemap'teki 59 URL'nin yalnızca 3'ünde `lastmod` var

**Dosya:** `core/sitemaps.py`

Yalnızca `GuideSitemap` `lastmod` tanımlamış. `Service.updated_at` alanı mevcut ve
iniş sayfaları için kullanılabilir; statik sayfalar için de sabit bir tarih verilebilir.
Google `lastmod`'u tarama önceliklendirmede aktif olarak kullanıyor (`priority`'nin
aksine).

**Öneri:** `PlatformLandingSitemap.lastmod` → o gruptaki servislerin
`max(updated_at)` değeri.

**Zorluk:** Asan (1 saat)

---

## S-11 · Bələdçi yazılarında `Article` şeması ve doğru `og:type` yok

`/beledci/<slug>/` sayfalarında yalnızca `Organization` şeması var, `og:type` ise
`website`. Blog içeriği için `Article`/`BlogPosting` + `og:type="article"` olmalı.
(S-03'ün bir parçası olarak çözülebilir.)

---

## S-12 · Hiçbir sayfada `BreadcrumbList` yok

Site üç seviyeli (`/` → `/services/` → `/xidmetler/<slug>/`) ama breadcrumb yapısal
verisi yok. Arama sonuçlarında URL yerine gezinme yolu gösterilmesini sağlar; ekleme
maliyeti düşük.

---

## S-13 · `Organization` şeması minimal — `logo` alanı yok

`core/context_processors.py:10` yalnızca `name` ve `url` üretiyor (+ ayarlarda doluysa
`email` ve `sameAs`). Google'ın Organization dokümantasyonu `logo` alanını bekliyor —
bilgi panelinde marka logosunun görünmesi için gerekli.

**Öneri:** `logo` (mutlak URL, en az 112×112) ve mümkünse `contactPoint` ekle.

---

# ✅ Doğru yapılmış olanlar

- **Her sayfanın benzersiz `<title>`'ı var** ve uzunlukları makul (27–56 karakter)
- **Her sayfada tam olarak bir `<h1>`** — hiçbirinde eksik veya fazla yok
- **404'ler doğru durum kodu döndürüyor** (`/olmayan-sayfa/` ve `/xidmetler/olmayan-slug/`
  → HTTP 404), yumuşak 404 yok
- **Sitemap temiz üretiliyor:** 59 URL, **tekrar eden URL yok**, `sitemap.xml`
  robots.txt'de doğru şekilde ilan edilmiş
- **Görsel alt metni sorunu yok** — sitede yalnızca 1 `<img>` var (o da alt'lı), ikonlar
  satır içi SVG
- **URL yapısı temiz ve okunabilir:** `/xidmetler/instagram-beyenme/`, `/beledci/<slug>/` —
  Azerbaycan diline uygun, parametresiz, anlamlı
- **`json_ld` fonksiyonu güvenli:** `<`, `>`, `&` kaçışıyla script kapatma saldırısını
  engelliyor — üretilen JSON-LD gerçek Chrome'da sorunsuz ayrıştırılıyor
- **Ana sayfadaki `FAQPage` şeması geçerli** ve 9 soruyu doğru sarmalıyor
- **`lang="az"`** doğru tanımlanmış, `viewport` etiketi doğru

---

# Önerilen sıra

## Hızlı kazanımlar (yarım gün, hepsi "Asan")
1. **R-01** CSP nonce → tema titremesini bitir *(1 saat)*
2. **S-01** canonical + filtrelere `noindex` *(2–3 saat)*
3. **S-06** robots.txt'yi sıkılaştır *(30 dakika)*
4. **S-09** `get_priority` → `priority` *(10 dakika)*

## Dönüşüm etkisi yüksek (1 gün)
5. **S-02** sayfa başına `og:title`/`og:description` *(1–2 saat)*
6. **S-04** varsayılan `og:image` + `og:site_name`/`og:locale` *(1 saat)*
7. **S-05** sayfa başına meta description *(1 saat)*

## En büyük SEO fırsatı (1–2 gün)
8. **S-03** iniş sayfalarına `Product`/`Offer`, bələdçilere `Article`, her yere
   `BreadcrumbList` *(1 gün)*
9. **S-10** `lastmod` *(1 saat)*
10. **S-07** iniş sayfalarına özgün içerik *(içerik yazımı)*

---

# Bu denetimin kapsamadıkları

- **Gerçek arama konsolu verisi yok** — indeksleme durumu, tıklama ve gösterim
  sayıları ancak Google Search Console bağlandıktan sonra değerlendirilebilir
- **Sayfa hızı ve Core Web Vitals ölçülmedi** (SEO sıralama faktörü)
- **Yapısal veri Google Rich Results Test ile doğrulanmadı** — yalnızca sözdizimi ve
  DOM'da ayrıştırılabilirlik kontrol edildi
- **Backlink profili, rakip analizi ve anahtar kelime araştırması** kapsam dışı
- Test yerel sunucuda yapıldı; `localhost:8000` mutlak URL'leri üretimde gerçek alan
  adına dönüşür (ters vekil başlıkları doğru kurulduğu sürece — `SECURE_PROXY_SSL_HEADER`
  ayarlanmış durumda)
