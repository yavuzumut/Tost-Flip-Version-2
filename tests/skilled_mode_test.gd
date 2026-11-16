extends SceneTree
## Usta Şef Modu (Skilled Mode) mekaniklerini ve entegrasyonunu doğrulayan otomatik test.

const SkilledModeScript = preload("res://modes/skilled_mode.gd")

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- TEST BAŞLIYOR: Usta Şef Modu Kapsamlı Doğrulama ---")

	# 1. SkilledMode formülleri ve başlangıç durumu
	var test_mgr = SkilledModeScript.new()
	test_mgr.money = 0
	test_mgr.bread_level = 1
	test_mgr.butter_level = 1
	test_mgr.air_boost_level = 0

	assert(test_mgr.get_max_butter_layers() == 3, "Seviye 1 ekmekte maksimum katman 3 olmalı")
	assert(is_equal_approx(test_mgr.get_torque_resistance(), 1.0), "Seviye 1 ekmekte tork direnci 1.0 olmalı")
	assert(is_equal_approx(test_mgr.get_butter_multiplier(), 1.0), "Seviye 1 tereyağında çarpan 1.0 olmalı")
	assert(test_mgr.get_max_air_boosts() == 0, "Seviye 0 hava takviyesinde hak 0 olmalı")

	# Ödül formülü testi:
	# katman = 0 -> 3
	# katman = 1 -> (1*8 + 1*6) * 1.0 = 14
	# katman = 2 -> (2*8 + 4*6) * 1.0 = 40
	# katman = 3 -> (3*8 + 9*6) * 1.0 = 78
	assert(test_mgr.calculate_reward(0) == 3, "0 katman ödülü 3 olmalı")
	assert(test_mgr.calculate_reward(1) == 14, "1 katman ödülü 14 olmalı")
	assert(test_mgr.calculate_reward(2) == 40, "2 katman ödülü 40 olmalı")
	assert(test_mgr.calculate_reward(3) == 78, "3 katman ödülü 78 olmalı")
	print("✓ 1. SkilledMode temel matematik formülleri DOĞRU.")

	# 2. Yükseltme (Upgrade) mekaniği testi
	# Yetersiz para durumu
	assert(test_mgr.can_upgrade("bread") == false, "Para yetersizken satın alınamamalı")
	assert(test_mgr.upgrade("bread") == false, "Yetersiz parayla yükseltme başarısız olmalı")

	# Yeterli para ekleyip yükseltme
	test_mgr.add_money(10000)
	assert(test_mgr.money == 10000, "Para 10000 olmalı")

	# Ekmek yükseltme: Maliyet 250 -> Kalan 9750
	assert(test_mgr.upgrade("bread") == true, "Ekmek yükseltme başarılı olmalı")
	assert(test_mgr.bread_level == 2, "Ekmek seviyesi 2 olmalı")
	assert(test_mgr.money == 9750, "Kalan para 9750 olmalı")
	assert(test_mgr.get_max_butter_layers() == 4, "Seviye 2 ekmekte maksimum katman 4 olmalı")
	assert(is_equal_approx(test_mgr.get_torque_resistance(), 0.85), "Seviye 2 ekmekte tork direnci 0.85 olmalı")

	# Tereyağı yükseltme: Maliyet 300 -> Kalan 9450
	assert(test_mgr.upgrade("butter") == true, "Tereyağı yükseltme başarılı olmalı")
	assert(test_mgr.butter_level == 2, "Tereyağı seviyesi 2 olmalı")
	assert(test_mgr.money == 9450, "Kalan para 9450 olmalı")
	assert(is_equal_approx(test_mgr.get_butter_multiplier(), 1.3), "Seviye 2 tereyağında çarpan 1.3 olmalı")
	# 2 katman ödülü çarpanla: round(40 * 1.3) = 52
	assert(test_mgr.calculate_reward(2) == 52, "Tereyağı çarpanı ile ödül 52 olmalı")

	# Hava takviyesi yükseltme: Maliyet 600 -> Kalan 8850
	assert(test_mgr.upgrade("air_boost") == true, "Hava takviyesi yükseltme başarılı olmalı")
	assert(test_mgr.air_boost_level == 1, "Hava takviyesi seviyesi 1 olmalı")
	assert(test_mgr.money == 8850, "Kalan para 8850 olmalı")
	assert(test_mgr.get_max_air_boosts() == 1, "Seviye 1 hava takviyesinde hak 1 olmalı")
	print("✓ 2. Geliştirme (Upgrade) sistemi ve maliyet düşüşleri DOĞRU.")

	# 3. Kayıt ve Yükleme (Persistence) Testi
	test_mgr.save_data()
	var load_mgr = SkilledModeScript.new()
	assert(load_mgr.money == 8850, "Kayıttan para doğru yüklenmeli (8850)")
	assert(load_mgr.bread_level == 2, "Kayıttan ekmek seviyesi doğru yüklenmeli (2)")
	assert(load_mgr.butter_level == 2, "Kayıttan tereyağı seviyesi doğru yüklenmeli (2)")
	assert(load_mgr.air_boost_level == 1, "Kayıttan hava takviyesi doğru yüklenmeli (1)")
	print("✓ 3. Kayıt (user://skilled_save.cfg) ve yükleme DOĞRU.")

	# 4. Sahne (node_2d.tscn) Entegrasyonu
	var scene_res := load("res://node_2d.tscn") as PackedScene
	if scene_res == null:
		push_error("node_2d.tscn yüklenemedi!")
		quit(1)
		return

	var root_node := scene_res.instantiate()
	root.add_child(root_node)

	# Mod seçimi ekranını aç
	root_node._on_play_button_pressed()
	assert(root_node.state == root_node.GameState.MODE_SELECT, "Oyun MODE_SELECT durumunda olmalı")
	assert(root_node.mode_select_menu.visible == true, "Mod seçim menüsü görünür olmalı")

	# Usta Şef Modunu seç (index 1)
	root_node._on_mode_chosen(1)
	assert(root_node.active_mode == root_node.GameMode.SKILLED, "Aktif mod SKILLED olmalı")
	assert(root_node.state == root_node.GameState.READY, "Oyun READY durumuna geçmeli")
	assert(root_node.hud.get_node("%MoneyPanel").visible == true, "Para paneli görünür olmalı")
	assert(root_node.hud.get_node("%ShopButton").visible == true, "Dükkan butonu görünür olmalı")
	assert(root_node.hud.get_node("%AirBoostPanel").visible == true, "Hava takviyesi paneli görünür olmalı")
	assert(root_node.remaining_air_boosts == root_node.skilled_mgr.get_max_air_boosts(), "Hava hakları başlangıçta tam olmalı")
	print("✓ 4. Mod seçimi ve Usta Şef HUD entegrasyonu DOĞRU.")

	# 5. Oynanış ve Tost Satış Mekaniği
	root_node.toast.launch()
	root_node.state = root_node.GameState.FLYING

	# Başarılı iniş yapalım (butter_down = false)
	root_node._on_toast_landed(false)
	assert(root_node.butter_layers == 1, "İlk inişte katman 1 olmalı")
	assert(root_node.hud.get_node("%SellButton").visible == true, "Başarılı inişte Tostu Sat butonu görünmeli")
	var expected_sale: int = root_node.skilled_mgr.calculate_reward(1)
	assert(root_node._pending_sale_reward == expected_sale, "Bekleyen satış ödülü doğru hesaplanmalı")

	# Tost Satış butonuna basış
	var money_before: int = root_node.skilled_mgr.money
	root_node._on_sell_pressed()
	assert(root_node.skilled_mgr.money == money_before + expected_sale, "Satış sonrası para eklenmeli")
	assert(root_node.butter_layers == 0, "Satış sonrası katman sıfırlanmalı")
	assert(root_node.hud.get_node("%SellButton").visible == false, "Satış sonrası buton gizlenmeli")
	assert(root_node.state == root_node.GameState.READY, "Satış sonrası yeni tura hazır olunmalı")
	print("✓ 5. Tost Satış mekaniği ve bakiye aktarımı DOĞRU.")

	# 6. Havada Takviye (Air Boost) Testi
	# Hava takviyesi hakkı verelim
	root_node.remaining_air_boosts = 1
	root_node.toast.launch()
	root_node.state = root_node.GameState.FLYING
	var vel_before_boost: float = root_node.toast.linear_velocity.y

	# Space tuşu simülasyonu
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_SPACE
	root_node._unhandled_input(key_event)

	assert(root_node.remaining_air_boosts == 0, "Space basılınca takviye hakkı 1 azalmalı")
	assert(root_node.toast.linear_velocity.y < vel_before_boost, "Takviye tostu yukarı itmeli (daha negatif y hızı)")
	print("✓ 6. Havada Takviye (Space) mekaniği DOĞRU.")

	# 7. Dükkân Paneli Açma ve Güncelleme Testi
	root_node._on_shop_opened()
	assert(root_node.skilled_shop.visible == true, "Dükkan paneli görünür olmalı")
	root_node.skilled_shop.hide()
	assert(root_node.skilled_shop.visible == false, "Dükkan paneli kapatılabilmeli")
	print("✓ 7. Dükkân paneli UI bağlantısı DOĞRU.")

	print("--- TÜM USTA ŞEF MODU TESTLERİ EKSİKSİZ VE BAŞARIYLA GEÇTİ! ---")
	quit(0)
