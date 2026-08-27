# Antigravity Workspace Rule: AdemOS Memory & Companion Protocol

Bu qayda Antigravity agentinin AdemOS (Ikinci Beyin) vaultunda islemesi ucun xususi protokoldur.

## 1. Sessiyanin Baslangici (Memory Recall)
- Her sessiyanin evvelinde bu fayllari yoxla ve kontekste daxil et:
  - 🔮 850-Companion/Core.md (Kimlik ve esas kontekst)
  - 🔮 850-Companion/Kurallar.md (Adem-in teyin etdiyi daimi qaydalar)
  - 🔮 850-Companion/Last-Session.md (Son sessiyanin veziyyeti)
  - 🔮 850-Companion/Threads.md (Aktiv layiheler ve is xetleri)

## 2. Qaydalarin Idare Edilmesi (Kurallar)
- Istifadeci (Adem) davamli telimat ve ya duzelis verdikde, bunu derhal 🔮 850-Companion/Kurallar.md faylina kural ve sebeb formatinda elave et.

## 3. Sessiyanin Sonu ve Yaddasin Yenilenmesi (Session Handover)
- Ehemiyyetli qerarlar verildikde, layihe statusu deyisdikde ve ya tapsiriqlar tamamlandiqda:
  - 🔮 850-Companion/Last-Session.md faylini oxu ve en son sessiya xulasesi ile yenile.
  - 🔮 850-Companion/Threads.md faylini oxu ve aktiv/baglanmis movzulari aktual saxla.

## 4. Tehlukesizlik ve Gigiyena Qaydalari
- Oxu, sonra yaz: Movcud melumati silme; faylin uzerine yazmazdan evvel hemise movcud mezmunu oxu ve strukturunu qoru.
- Ses-kuyu yaddasa yazma: Ehemiyyetsiz, kicik sohbetleri ve ya tesadufi suallari yaddas fayllarina yazma - yalniz deyerli qerarlari, arxitektura deyisikliklerini ve layihe statuslarini saxla.
- Toxunulmazliq: Movcud Claude Code konfiqurasiyalarina (.claude/), hook-lara (.claude/hooks/) ve bu qaydanin ozune icazesiz toxunma ve deyisme.

## 5. Yeni Layihə Yaratma Protokolu
- İstifadəçi 'yeni layihə yarat' dedikdə:
  1. Əvvəlcə layihənin adını və məqsədini soruş.
  2. 🏰 300-Projects/<Layihə-Adı>/ altında ayrıca qovluq yarat.
  3. Layihə üçün 3 əsas sənədi hazırla:
     - Project.md (İcmal, arxitektura, texnologiyalar, hədəflər)
     - Tasks.md (Görüləcək işlər, prioritetlər və statuslar)
     - Decisions.md (Texniki və biznes qərarlarının arxivi)
  4. Layihənin kodunu həmin qovluqda saxlamağın uyğun olub-olmadığını layihənin tipinə görə müəyyən et (məs: mono-repo, xarici Git repo, yalnız sənədləşmə və s.).
  5. Mövcud layihələrə və yaddaş fayllarına icazəsiz toxunma.
