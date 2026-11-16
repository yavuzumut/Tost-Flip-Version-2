# Tost Flip Version 2

## Proje Hakkında

Tost Flip, Godot ile geliştirilmiş 2D bir tost çevirme oyunudur. Oyuncu farklı oyun modlarında tostunu kontrol eder, modun hedeflerini tamamlar ve puan kazanır.

## Oyun Modları

- **Classic:** Tostu fırlatıp çevirerek tabağa başarılı iniş yapmaya çalışın.
- **Usta Şef:** Geliştirme dükkânı, bakiye ve havada takviye gibi ilerleme mekaniklerini kullanın.
- **Sandviç Ustası:** Sipariş malzemelerini toplayıp siparişe uygun bir sandviç hazırlayın; modun sınırlı yön kontrol haklarını yönetin.
- **Kemirgen:** Kuş, fare ve hamam böceği tehditleriyle uğraşın.
- **Uzay Sandviçi:** Yatay uçuşta malzeme toplayın, engellerden kaçının ve tur skorunuzu oturum boyunca biriktirin.

## Kullanılan Teknolojiler

- Godot Engine
- GDScript
- Godot sahne ve kaynak dosyaları (`.tscn`, `.tres`, `.gd`)

## Godot Sürümü

Proje Godot **4.7** için yapılandırılmıştır.

## Kurulum

1. Depoyu klonlayın:

   ```bash
   git clone https://github.com/yavuzumut/Tost-Flip-Version-2.git
   cd Tost-Flip-Version-2
   ```

2. Godot 4.7 ile `project.godot` dosyasını açın. Godot gerekli asset importlarını ilk açılışta oluşturur.

## Oyunu Çalıştırma

Godot Project Manager'da projeyi açıp **Run Project (F6/F5)** komutunu kullanın. Ana oyun sahnesi `project.godot` içinde tanımlıdır.

Headless doğrulama için Godot 4.7 kurulu bir ortamda:

```bash
godot --headless --editor --path . --quit
```

## Ekip Geliştirme ve Git Branch Yöntemi

- `main`, paylaşılabilir ve doğrulanmış ana daldır.
- Her iş için `feature/kisa-konu` biçiminde ayrı bir branch açın.
- Değişiklikleri küçük, açıklayıcı commit'lerle kaydedin.
- Tamamlanan işleri `main` dalına doğrudan göndermek yerine Pull Request ile incelemeye açın.
- İşe başlamadan önce `main` dalını güncelleyin; kendi feature branch'inizi güncel `main` üzerine merge veya rebase edin.
- `.godot/`, yerel export ayarları, işletim sistemi dosyaları, geçici dosyalar ve gizli imzalama anahtarları depoya eklenmemelidir. Godot `.import` ve `.uid` kaynak metadata dosyalarını silmeyin.
