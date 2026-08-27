# NovaPanel

Azərbaycan bazarı üçün dinamik SMM panelinin ilkin Django versiyası.

## Lokal işə salma

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python manage.py migrate
.\.venv\Scripts\python manage.py seed_demo
.\.venv\Scripts\python manage.py runserver
```

- Sayt: http://127.0.0.1:8000/
- Admin: http://127.0.0.1:8000/admin/
- Demo admin: `admin` / `Admin123!` (yalnız lokal inkişaf üçün)

### Demo məlumatları barədə xəbərdarlıq

`seed_demo` komandası yalnız lokal inkişaf və nümayiş mühiti üçündür. Komandanın yaratdığı provayder, kateqoriya və servislər `is_demo=True` işarəsi daşıyır və admin panelində narıncı **DEMO** nişanı ilə göstərilir.

Production-a keçməzdən əvvəl demo qeydlərini silin və ya demo servisləri `is_active=False` edin. Production kataloqu və sifarişləri üçün yalnız real API provayderinə bağlı, yoxlanılmış məlumatlardan istifadə edin.

## Şifrə sıfırlama e-poçtu

Lokal inkişafda (`DJANGO_DEBUG=True`) Django console e-poçt backend-indən istifadə edir. “Şifrəni unutmusunuz?” formasını göndərdikdən sonra bərpa keçidi `runserver` işləyən terminalda görünür; real məktub göndərilmir.

Production-da SMTP məcburidir. `.env.example` faylındakı `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` və `EMAIL_USE_TLS` dəyişənlərini real provayder məlumatları ilə doldurun. `EMAIL_HOST` təyin edilməzsə tətbiq səssiz işləmək əvəzinə başlanğıcda açıq konfiqurasiya xətası verir.

İstehsala çıxmazdan əvvəl `SECRET_KEY`, `DEBUG`, hostlar, verilənlər bazası və bütün giriş məlumatları mühit dəyişənlərinə keçirilməlidir.

## Statik fayllar və yayım

`STATIC_ROOT` `staticfiles/` qovluğudur. Production-da (`DJANGO_DEBUG=False`) `ManifestStaticFilesStorage`
işə düşür — fayl adına məzmun hash-i əlavə olunur, ona görə **hər deploy-da** statik fayllar yığılmalıdır:

```bash
python manage.py collectstatic --noinput
```

Bu addım atlanarsa şablonlardakı `{% static %}` çağırışları manifest tapa bilmir və səhifələr xəta verir.
Nginx/Caddy `STATIC_ROOT` qovluğunu `/static/` ünvanından servis etməlidir.

Yayım üçün əlavə mühit dəyişənləri (`.env.example`-a bax):

| Dəyişən | Təyinatı |
|---|---|
| `DJANGO_CSRF_TRUSTED_ORIGINS` | HTTPS-də POST formalarının işləməsi üçün etibarlı mənbələr. Boş buraxılsa `DJANGO_ALLOWED_HOSTS`-dan `https://` sxemi ilə avtomatik qurulur. |
| `DJANGO_TRUST_PROXY_SSL_HEADER` | Susmaya görə `True`. Tərs vekilin arxasında `X-Forwarded-Proto` başlığına etibar edilir; bu olmadan `SECURE_SSL_REDIRECT` sonsuz yönləndirmə dövrü yaradır. Tətbiq birbaşa internetə açıqdırsa `False` edin. |
| `DJANGO_RATELIMIT_IP_META_KEY` | Sürət limitinin ziyarətçini hansı başlıqdan tanıdığı. **Tərs vekilin arxasında mütləq təyin edilməlidir** — aşağıya bax. |
| `DJANGO_RATELIMIT_ENABLE` | Susmaya görə aktiv. Yalnız nasazlıq axtarışında söndürün. |
| `DJANGO_MAX_DEPOSIT_AMOUNT` | Bir müraciətdə balansa əlavə edilə bilən maksimum məbləğ (susmaya görə `10000.00`). |

Yayımdan əvvəl konfiqurasiyanı yoxlayın:

```bash
python manage.py check --deploy
```

## PanelBaku servis sinxronizasiyası

API açarını mənbə koduna yazmayın. PowerShell sessiyasında təyin edib sinxronlaşdırın:

```powershell
$env:PANELBAKU_API_KEY="sizin-api-acariniz"
.\.venv\Scripts\python manage.py sync_panelbaku
```

API-də artıq olmayan servisləri də deaktiv etmək istəyəndə:

```powershell
.\.venv\Scripts\python manage.py sync_panelbaku --deactivate-missing
```

## Vaxtı bitmiş ödəniş sessiyalarının təmizlənməsi

Vaxtı keçmiş və hələ təsdiqlənməmiş ödəniş sessiyalarını toplu şəkildə `expired` statusuna keçirin:

```powershell
.\.venv\Scripts\python manage.py expire_payment_sessions
```

Dəyişiklik etmədən əvvəl neçə qeydin təsirlənəcəyini yoxlamaq üçün:

```powershell
.\.venv\Scripts\python manage.py expire_payment_sessions --dry-run
```

Production mühitində bu komandanı Windows Task Scheduler və ya cron vasitəsilə hər 5 dəqiqədən bir işlədin. Komanda yalnız vaxtı bitmiş `awaiting_payment` qeydlərini dəyişir; admin təsdiqini gözləyən `pending` ödənişlərə toxunmur.

## Takılmış sifarişlərin bərpası

Provayderə çatdırıla bilməyən sifarişlər `queued` və ya `submission_unknown` statusunda qalır: pul tutulub, amma sifariş nə icra olunur, nə də geri qaytarılır. Bu komanda onları ələ alır:

```powershell
.\.venv\Scripts\python manage.py recover_stuck_orders
```

Davranış:

- 30 dəqiqədən çox takılı qalmış sifariş yenidən provayderə göndərilir;
- `--max-attempts` (susmaya görə 3) cəhddən sonra da alınmırsa məbləğ istifadəçinin balansına qaytarılır və sifariş `canceled` olur;
- hər cəhd `last_synced_at`-ı yeniləyir, ona görə eyni sifariş hər icrada deyil, `--minutes` aralığı ilə sınanır;
- provayderdə artıq qarşılığı olan (`provider_order_id` dolu) sifarişlərə toxunulmur — onlar `sync_order_statuses` komandasının işidir.

Planı dəyişiklik etmədən görmək üçün:

```powershell
.\.venv\Scripts\python manage.py recover_stuck_orders --dry-run
```

Production-da hər 10 dəqiqədən bir işlədin. `--minutes` dəyəri istifadəçiyə verilən "30 dəqiqə ərzində ya işə düşəcək, ya da məbləğ balansınıza qayıdacaq" sözü ilə uyğun saxlanmalıdır.

## Bank qəbzlərinin saxlanması

Ödəniş qəbzləri fərdi maliyyə sənədidir və **`MEDIA_ROOT`-dan kənarda** saxlanılır (`DJANGO_PRIVATE_MEDIA_ROOT`, susmaya görə `private-media/`). Veb serveri bu qovluğa **heç bir halda** birbaşa giriş verməməlidir; yeganə çıxış yolu icazə yoxlayan `payment_receipt` view-udur — qəbzi yalnız sahibi və `is_staff` istifadəçilər endirə bilər.

Qəbul edilən fayllar: `jpg`, `jpeg`, `png`, `webp`, `pdf`; maksimum 5 MB (`DJANGO_RECEIPT_MAX_BYTES`). Şəkillər Pillow ilə açılıb formatı təsdiqlənir, ona görə `.png` adı verilmiş HTML və ya SVG faylı qəbul edilmir. Yüklənən ad tamamilə atılır, fayl `payment_receipts/<il>/<ay>/<uuid>.<uzantı>` kimi yazılır.

Yedəkləmə planına `private-media/` qovluğunu da daxil edin — bu qovluq `.gitignore`-dadır və `collectstatic` ona toxunmur.

## Yedəkləmə və bərpa

Kullanıcı bakiyeleri verilənlər bazasındadır — məlumat itkisi birbaşa pul itkisidir. Gündəlik yedəkləmə iki fayl yaradır:

- verilənlər bazası — `pg_dump --format=custom` (sıxılmış, seçmə bərpaya icazə verir),
- qəbzlər — `PRIVATE_MEDIA_ROOT` `tar.gz`-ə yığılır (K-03: bu qovluq `MEDIA_ROOT`-dan kənardadır, `collectstatic` ona toxunmur).

```bash
python manage.py backup_database --keep-days 14
```

Celery beat proqramında gündəlik işlədilir (`core.backup_database`). Yedəklərin qovluğu `DJANGO_BACKUP_DIR` (susmaya görə `backups/`) — bunu tətbiqin özündən **fiziki olaraq ayrı** bir yerə (ayrı disk, S3, uzaq server) köçürün; eyni sunucuda saxlamaq sunucu itəndə yedəyi də itirir.

`pg_dump`/`pg_restore`/`createdb`/`dropdb`-nin sistem `PATH`-də olması gözlənilir (Ubuntu/Debian-da `postgresql-client` paketi ilə gəlir).

### Bərpa provası

**Yedəyin olması bərpa oluna bildiyini sübut etmir.** `restore_drill` dump-ı AYRI bir bazaya bərpa edir, sətir saylarını canlı baza ilə müqayisə edir, sonra o bazanı silir — canlı bazaya heç toxunmadan yedəyin işlək olduğunu sübut edir:

```bash
python manage.py restore_drill                    # ən son yedəyi sınayır
python manage.py restore_drill backups/db-20260115-030000.dump
```

Uyğunsuzluq varsa (məsələn, dump korlanıb) əmr `CommandError` ilə uğursuz olur — "yedək var, amma bərpa olunmur" sükutla keçməməlidir. Bunu ayda bir dəfə əl ilə (və ya ayrı, seyrək bir cron işi ilə) işlədin.

## Redis (keş + sürət limiti)

```
REDIS_URL=redis://localhost:6379/0
```

İki yerdə istifadə olunur:

- **Keş** — `default_markup_percent` kimi dəyərlər. Əvvəl `LocMemCache` idi: gunicorn-un hər işçisində ayrı nüsxə, yəni admin panelindən dəyişdirilən mənfəət faizi işçilərin bir hissəsində 5 dəqiqəyə qədər köhnə qalırdı (O-05).
- **Sürət limiti sayğacı** — `core/ratelimit.py::hit`. Modulun dəyişən yeganə hissəsi budur; dekorator interfeysi və bütün çağırış yerləri toxunulmadı.

`REDIS_URL` verilməyibsə tətbiq işləyir: keş LocMem-ə, sayğac SQL-ə düşür. Lokal inkişaf Redis qurmadan davam edir.

Yerli yoxlama:

```bash
docker run -d --name novapanel-redis -p 56379:6379 redis:7-alpine
REDIS_URL='redis://localhost:56379/0' python manage.py test core
```

## Mali mutabakat

`Wallet.balance` əslində `WalletTransaction` ledger-inin bir keşidir — hər balans dəyişikliyi bir ledger sətri yaratmalıdır. Bu iki dəyər arasında uyğunsuzluq (kod səhvi, əl ilə SQL, natamam migration) heç bir mexanizmlə aşkar edilmirdi.

```bash
python manage.py reconcile_wallets
```

İki səviyyəli yoxlama aparır:

1. **Yekun cəm** — hər cüzdan üçün `sum(WalletTransaction.amount)` `Wallet.balance`-a bərabərdirmi?
2. **Tarixçə zənciri** — əməliyyatlar xronoloji sırayla təkrar hesablananda, hər sətirdə yazılmış `balance_after` faktiki running cəmə bərabərdirmi? Bu, yalnız yekun cəmi yoxlamaqdan güclüdür: iki səhv bir-birini kompensasiya edib son nəticədə üst-üstə düşə bilər, amma tarixçənin ortasında iz buraxar. Sürət lazımdırsa `--skip-chain-check` ilə söndürülə bilər.

**Heç nəyi düzəltmir** — yalnız aşkar edir və raportlaşdırır. Mali uyğunsuzluğun avtomatik "düzəldilməsi" səhv tərəfi seçə bilər; qərar insan nəzarətindən keçməlidir.

Uyğunsuzluq tapılsa əmr **çıxış kodu 1** ilə bitir (cron/monitorinqin fərqinə varması üçün) və Celery beat proqramında 6 saatlıq tezliklə işlədilir (`core.reconcile_wallets`) — tapılan uyğunsuzluq ERROR kimi loglanır və Sentry-yə düşür.

## Sürət limiti

Qeydiyyat, giriş, şifrə sıfırlama, sifariş, balans artırma və kataloq uclarında sürət limiti var.

Sayğacın yeri `REDIS_URL`-dən asılıdır: təyin edilibsə **Redis** (`INCR` atomikdir, açar pəncərə ilə birlikdə özü yox olur), yoxdursa **SQL** (`core.RateLimitCounter`). Redis əlçatmaz olarsa SQL-ə düşülür və hadisə WARNING kimi loglanır — **fail-open edilmir**, çünki Redis-in nasazlığı qeydiyyat və giriş uclarını qorumasız qoymamalıdır.

| Uc | Limit |
|---|---|
| `signup` | 5 / saat / IP |
| `login` | 10 / 15 dəq / IP **və** 10 / 15 dəq / istifadəçi adı |
| `password_reset` | 5 / saat / IP |
| `add_balance` | 10 / saat / istifadəçi |
| `new_order` | 30 / saat / istifadəçi |
| `services_more` | 60 / 10 dəq / IP |

**Tərs vekilin arxasında `DJANGO_RATELIMIT_IP_META_KEY` mütləq təyin edilməlidir.** Susmaya görə `REMOTE_ADDR` oxunur; nginx/Caddy arxasında bu dəyər hər ziyarətçi üçün eynidir (vekilin öz ünvanı), yəni **bütün istifadəçilər tək sayğaca düşür** və kataloqa normal baxış belə bloklanır.

nginx konfiqurasiyasında:

```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $remote_addr;
```

**`$remote_addr` yazılır, `$proxy_add_x_forwarded_for` YOX.** Fərq qorumanın olub-olmaması deməkdir:

`$proxy_add_x_forwarded_for` müştərinin göndərdiyi `X-Forwarded-For` başlığının **üzərinə əlavə edir**, onu silmir. Yəni hücumçu öz sorğusuna `X-Forwarded-For: 1.2.3.4` yazıb göndərsə, nginx-in ötürdüyü dəyər `1.2.3.4, <həqiqi-ip>` olur və siyahının başında hücumçunun uydurduğu ünvan durur. Tətbiq ilk dəyəri götürdüyünə görə hər sorğuda başqa saxta IP göstərmək kifayətdir — **sürət limiti tamamilə keçilir**, çünki hər sorğu ayrı sayğaca düşür.

`$remote_addr` isə başlığı **üzərinə yazır**: dəyər həmişə TCP bağlantısının həqiqi mənbəyidir və müştəri ona təsir edə bilmir. Qayda ümumidir — kimliyə görə qərar verən hər başlıq vekil tərəfindən yazılmalı, əlavə edilməməlidir.

Bu, yalnız birbaşa internetə baxan tək vekil üçündür. Öndə CDN varsa (Cloudflare və s.), həqiqi ünvanı onun öz başlığından götürün (`CF-Connecting-IP`) və `DJANGO_RATELIMIT_IP_META_KEY`-i ona uyğun təyin edin.

Sayğac cədvəlini vaxtaşırı yığışdırın (gündə bir dəfə kifayətdir):

```bash
python manage.py purge_rate_limit_counters --hours 24
```

## Arxa fon işləri (Celery)

`submit_order` artıq sorğunun içində sinxron işləmir. Sifariş dərhal `queued` statusunda qəbul edilir, göndəriş isə arxa fonda baş verir — provayder yavaşlasa istifadəçi 25 saniyə gözləmir, nginx timeout riski yoxdur.

Broker Redis-dir (yuxarıdakı `REDIS_URL`). Nəticə backend-i qurulmayıb: heç yerdə `task.get()` çağrılmır.

```bash
celery -A config worker --loglevel=info
celery -A config beat --loglevel=info
```

Windows-da inkişaf zamanı `--pool=solo` lazımdır:

```powershell
celery -A config worker --loglevel=info --pool=solo
```

### Zamanlanmış işlər

Proqram **verilənlər bazasındadır** (`django-celery-beat`) və admin panelindən dəyişdirilə bilir — fayl əsaslı zamanlayıcı ilə hər dəyişiklik deploy tələb edərdi.

| İş | Tezlik |
|---|---|
| `sync_order_statuses` | 5 dəq |
| `expire_payment_sessions` | 5 dəq |
| `recover_stuck_orders` | 10 dəq |
| `purge_rate_limit_counters` | 24 saat (yalnız SQL sürət limiti rejimində əhəmiyyətlidir) |

`recover_stuck_orders`-ın tezliyi istifadəçiyə verilən "30 dəqiqə ərzində ya işə düşəcək, ya da məbləğ balansınıza qayıdacaq" sözü ilə uyğun saxlanmalıdır — bu iş 30 dəqiqədən **az** aralıqla işləməlidir ki, söz tutulsun.

### Yenidən cəhd siyasəti

`submit_order` provayder xətalarını özü üç sinfə ayırır və `submission_unknown` halında **bilərəkdən** geri ödəniş etmir (K-04/K-06) — sifarişin provayderə çatıb-çatmadığı məhz bilinmir, dərhal təkrar göndərmək eyni sifarişin iki dəfə alınmasına səbəb ola bilər.

Ona görə task yalnız **gözlənilməyən** istisalarda (baza kəsintisi, şəbəkə) üstəl geri çəkilmə ilə təkrar cəhd edir (30s → 60s → 120s..., ən çox 10 dəqiqə, təsadüfi yayılma ilə). `submission_unknown` isə `recover_stuck_orders`-ın işidir.

İşçi task-ın ortasında ölsə (`acks_late=True`) task yenidən paylanır. Bu təhlükəsizdir: `submit_order` sifarişi şərtli `UPDATE` ilə "sahiblənir" (K-04), ona görə təkrar icra provayderə ikinci sifariş göndərmir.

## Verilənlər bazası (PostgreSQL)

Production **PostgreSQL** olmalıdır. SQLite eşzamanlı yazmada bütün bazanı kilitləyir və `select_for_update` semantikası orada yoxdur — cüzdan əməliyyatları isə məhz eşzamanlılığa həssasdır (`create_order`, `create_payment_session`).

Bağlantı tək dəyişəndən oxunur:

```
DATABASE_URL=postgres://istifadeci:parol@localhost:5432/novapanel
```

`DATABASE_URL` verilməyibsə tətbiq SQLite-a düşür — lokal inkişaf Postgres qurmadan işləsin deyə. **Yayımda bu dəyişən mütləq təyin edilməlidir.**

Parolda `@`, `/` və ya `#` varsa faiz-kodlaşdırılmalıdır (`@` → `%40`). Tətbiq onu açır; açılmasaydı bağlantı "parol səhvdir" deyə düşərdi və səbəbi tapmaq çətin olardı.

Uzaq və ya idarə olunan bazada şifrələmə rejimi URL-də verilir:

```
DATABASE_URL=postgres://user:pass@db.example.com:5432/novapanel?sslmode=require
```

Bağlantılar `CONN_MAX_AGE` (susmaya görə 60 san) ilə təkrar istifadə olunur və hər dəfə sağlamlığı yoxlanılır. Öndə pgbouncer-in "transaction" rejimi varsa `DJANGO_DB_CONN_MAX_AGE=0` edin.

Testlər CI-da həqiqi Postgres servisində işləyir; yerli olaraq da yoxlaya bilərsiniz:

```bash
docker run -d --name novapanel-pg -e POSTGRES_USER=novapanel -e 'POSTGRES_PASSWORD=test@pass'   -e POSTGRES_DB=novapanel -p 55432:5432 postgres:16-alpine
DATABASE_URL='postgres://novapanel:test%40pass@localhost:55432/novapanel' python manage.py test core
```

## Loglama və xəta izləmə

Bütün loglar **stdout**-a yazılır; Linux VPS-də onları systemd toplayır:

```bash
journalctl -u novapanel -f
```

Fayl döndürmə tətbiqin işi deyil — journald özü idarə edir. Səviyyə `DJANGO_LOG_LEVEL` ilə (susmaya görə `INFO`).

Django susmaya görə `django.request` xətalarını yalnız `mail_admins`-ə göndərir; `ADMINS` boş olduğu üçün **500-lər heç yerə düşmürdü**. İndi `django.request` də stdout-dadır.

### Sentry

`SENTRY_DSN` boş olarsa Sentry ümumiyyətlə başladılmır — lokal inkişaf və testlər Sentry hesabı tələb etmir.

```
SENTRY_DSN=https://...@o0.ingest.sentry.io/0
SENTRY_ENVIRONMENT=production
SENTRY_RELEASE=<deploy-dakı commit sha>
```

Məxfilik: `send_default_pii=False` — IP, kuki və istifadəçi gövdəsi susmaya görə göndərilmir. Bundan əlavə Sentry-nin öz siyahısına **bu tətbiqin həssas sahələri** əlavə edilib, çünki onlar orada yoxdur:

| Sahə | Niyə |
|---|---|
| `code` | E-poçt təsdiq kodu — təsdiq səhifəsindəki hər xəta onu POST gövdəsi ilə aparardı |
| `cf-turnstile-response` | CAPTCHA tokeni |
| `card_number`, `payment_card_number`, `reference` | Bank rekvizitləri və köçürmə arayışı |
| `password1/2`, `new_password1/2`, `old_password` | Forma sahə adları `password` ilə üst-üstə düşmür |

Performans izləmə (`SENTRY_TRACES_SAMPLE_RATE`) susmaya görə **0**-dır: bu tətbiqdə həll etdiyi problem yoxdur, amma kvotanı sürətlə yeyir.

`django.security.DisallowedHost` Sentry-də susdurulub — saxta `Host` başlığı ilə gələn botlar tətbiqin nasazlığı deyil, kvotanı yeyir.

## E-poçt təsdiqi

Qeydiyyat və panelə giriş sərbəstdir. Təsdiq yalnız **balans artırmadan əvvəl** tələb olunur: istifadəçi ilk dəfə balans səhifəsinə keçəndə e-poçtuna 6 rəqəmli kod gedir və kodu daxil etmədən ödəniş sessiyası aça bilmir.

Niyə qeydiyyatda deyil: qeydiyyatı bloklamaq real istifadəçini kataloqa baxmadan itirir. Saxta hesabın dəyəri isə yalnız pul axınına çıxanda yaranır — qapı da oradadır.

| Qayda | Dəyər |
|---|---|
| Kodun uzunluğu | 6 rəqəm |
| Etibarlılıq müddəti | 10 dəqiqə |
| Maksimum səhv cəhd | 5 (sonra kod ləğv olunur) |
| «Yenidən göndər» gözləməsi | 60 saniyə |
| «Yenidən göndər» tavanı | 5 / saat / istifadəçi |

Kod verilənlər bazasında düz mətn saxlanılmır: 6 rəqəm cəmi bir milyon variantdır, ona görə adi sha256 deyil, Django-nun parol hash-eri (duz + yavaş funksiya) işlədilir.

Təsdiq **bir dəfəlikdir** — sonrakı depozitlərdə kod istənilmir. İstifadəçinin e-poçt ünvanı dəyişsə təsdiq özü-özünə düşür: bayraq yerinə təsdiqlənmiş ünvan saxlanılır və hər dəfə cari ünvanla müqayisə olunur, ona görə dəyişiklik admin panelindən, shell-dən və ya migration-dan gəlsə də nəticə eynidir.

Dəstək üçün admin paneldə **E-poçt təsdiqləri** bölməsi var (yalnız oxunur). Təsdiqi əl ilə vermək mümkün deyil — bu, qapını mənasız edərdi; istifadəçi ilişibsə «Aktiv kodu ləğv et» əməliyyatı ilə ona yeni kod istəmək imkanı verilir.

## CAPTCHA (Cloudflare Turnstile)

Qeydiyyat, giriş və şifrə bərpası formalarında Turnstile var. Açarları Cloudflare panelindən alıb mühit dəyişənlərinə yazın:

```
DJANGO_TURNSTILE_SITE_KEY=0x4AAA...
DJANGO_TURNSTILE_SECRET_KEY=0x4AAA...
```

**Hər ikisi boş olarsa yoxlama tamamilə aparılmır** — lokal inkişaf və testlər Cloudflare hesabı tələb etmir. Yalnız birini doldurmaq qorumanı işə salmır; bu hal konfiqurasiya səhvi kimi loglanır.

Widget tək başına heç nə qorumur: skript və ya `curl` ilə göndərilən POST onu heç görmür. Qoruma tokenin serverdə `siteverify` ucunda yoxlanmasındadır.

**Cloudflare-a çatmaq mümkün olmayanda sorğu buraxılır (fail-open)** və hadisə WARNING kimi loglanır. Səbəb: sürət limiti bu üç ucda onsuz da işləyir və əsl döşəmə odur; CAPTCHA ikinci qatdır. Fail-closed seçsək, bizim çıxış şəbəkəmizin bir neçə saniyəlik nasazlığı bütün girişi və qeydiyyatı dayandırardı. Token ümumiyyətlə göndərilməyibsə sorğu **rədd edilir** — o, Cloudflare nasazlığı deyil, sadəcə widget-i keçən sorğudur.

Sentry qoşulanda (Aşama 4) bu WARNING xəbərdarlığa bağlanmalıdır: davamlı fail-open sükutla davam etməməlidir.

## Şablonlarda sətir-daxili üslub və skript YOXDUR

`core/middleware.py` hər cavaba (admin xaric) CSP başlığı qoyur və orada
`style-src 'self'`, `script-src 'self'` var — **`'unsafe-inline'` yoxdur.**
Yəni brauzer bunları sadəcə atır, konsolda da səssiz keçir:

| Şablonda | Nəticə |
|---|---|
| `<div style="color:red">` | üslub tətbiq olunmur |
| `<style>…</style>` | blok tamamilə atılır |
| `<script>…</script>` (src-siz) | kod işə düşmür |
| `onclick="…"`, `onchange="…"` | hadisə heç vaxt işləmir |

Bu, canlıda real problem yaratmışdı: Bəxt Çarxı ümumiyyətlə çəkilmirdi,
bonus zolaqları rəngsiz görünürdü, filtr seçimləri formanı göndərmirdi.
Ona görə:

- üslub → `static/css/*.css` (panel səhifələri: `panel-features.css`),
- davranış → `static/js/*.js`, hadisələr `addEventListener` ilə,
- dinamik dəyər → `data-*` atributu + JS (`static/js/progress-bars.js`
  gedişat zolağının enini belə verir; `element.style` yazmaq CSP-yə düşmür),
- şablondan JS-ə data → `{{ dəyər|json_script:"id" }}`.

`core.tests.TemplateCspComplianceTests` bunu qoruyur: `templates/` altında
(admin xaric) sətir-daxili üslub atributu, `<style>`/`<script>` bloku və ya
`on…=` hadisə atributu görünsə test qırılır.

## v2 dizayn qatı

`static/css/v2.css` və `v2-dark.css` mövcud üslubun **üzərinə** yazılan qatdır —
`app.css`, `redesign.css` və `dark.css` redaktə edilmir. `base.html`-dəki sıra
məcburidir:

```
fonts.css → fonts-v2.css → app.css → redesign.css → v2.css → dark.css → v2-dark.css
```

Qaranlıq rejimin iki faylı var (`dark.css` + `v2-dark.css`) və hər ikisi eyni anda
açılıb-örtülməlidir. Bunu `static/js/theme-toggle.js` ilə `base.html`-dəki inline
skript birlikdə edir; birində dəyişiklik edəndə o birini də yeniləyin, əks halda
qaranlıq rejimdə yarım üslub qalır.

### Şriftlər — HƏLƏ ƏLAVƏ EDİLMƏYİB

`fonts-v2.css` üç ailəni gözləyir: **Bricolage Grotesque**, **JetBrains Mono**,
**Space Grotesk**. `.woff2` faylları repoda yoxdur, ona görə hazırda sayt ehtiyat
zənciri ilə (Manrope / DM Sans) render olunur — sınıq görünmür, sadəcə tipoqrafiya
dizaynda nəzərdə tutulan deyil.

Tamamlamaq üçün Google Fonts-dan yükləyib `static/fonts/` qovluğuna atın:

```
bricolage-grotesque-latin.woff2   bricolage-grotesque-latin-ext.woff2
jetbrains-mono-latin.woff2        jetbrains-mono-latin-ext.woff2
space-grotesk-latin.woff2         space-grotesk-latin-ext.woff2
```

**`latin-ext` mütləqdir** — `ə ğ ı ş ç ö ü` hərfləri yalnız orada var. Yalnız
`latin` qoşulsa Azərbaycan hərfləri başqa şriftlə düşür və mətn qarışıq görünür.

## Mərhələli çatdırılma (drip-feed)

`Order.quantity` **həmişə ümumi miqdardır** və istifadəçi məhz onun pulunu ödəyir.
Provayderə göndərilən miqdar isə `quantity // runs`-dır, çünki SMM API v2-də
`runs` ilə birlikdə gələn `quantity` **hər mərhələdəki** miqdar sayılır və ümumi
çatdırılma `quantity * runs` olur.

Dəyişməzlik: `quantity_per_run * runs == quantity`. Testlə qorunur
(`DripfeedTests.test_provider_quantity_times_runs_equals_paid_quantity`).

> **İlk dəfə canlıya çıxarmazdan əvvəl yoxlayın.** Bu semantika standartdır, amma
> provayderlər arasında fərq ola bilər. Kiçik bir sifariş verin — məsələn
> `quantity=20, runs=2` — və provayder panelində sifarişin **20** yoxsa **40**
> göründüyünə baxın. 40 görünürsə bölmə artıqdır və `submit_order`-da
> `quantity_per_run` əvəzinə `quantity` göndərilməlidir. Səhv istiqamətdə
> qalsa hər mərhələli sifarişdə `runs` qat artıq maya dəyəri ödəyərsiniz.

`runs=1` olduqda payload-a `runs`/`interval` ümumiyyətlə əlavə edilmir — bəzi
provayderlər sıfır dəyəri xəta sayır.
