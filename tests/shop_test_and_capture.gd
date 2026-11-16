extends SceneTree
## Usta Şef Dükkân UI/UX doğrulama ve görsel yakalama scripti.

const OUT := "/home/umut/.gemini/antigravity/brain/1be90e02-8e7b-4b9e-a152-5603c78b3d28/scratch/"

func _init() -> void:
	call_deferred("_run")


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("Ekran görüntüsü kaydedildi: ", name, " ", img.get_size())


func _run() -> void:
	print("--- USTA ŞEF DÜKKÂN TESTİ VE EKRAN GÖRÜNTÜSÜ BAŞLIYOR ---")
	var scene_res := load("res://node_2d.tscn") as PackedScene
	var game := scene_res.instantiate()
	root.add_child(game)
	await _wait(0.3)

	# 1. Usta Şef Modunu Başlat
	game._on_play_button_pressed()
	game._on_mode_chosen(1) # 1 = SKILLED
	await _wait(0.5)

	assert(game.active_mode == game.GameMode.SKILLED, "Usta Şef modu aktif olmalı")
	assert(game.hud.visible == true, "HUD başlangıçta görünür olmalı")
	assert(game.skilled_shop.visible == false, "Dükkân başlangıçta gizli olmalı")

	# Oyuncuya başlangıç için 400 para verelim ki tereyağı/ekmek satın alınabilsin
	# Seviyeleri de test başlangıç durumuna (1, 1, 0) ayarlayalım (kayıtlı dosyadan bağımsız olması için)
	game.skilled_mgr.bread_level = 1
	game.skilled_mgr.butter_level = 1
	game.skilled_mgr.air_boost_level = 0
	game.skilled_mgr.money = 400
	game._refresh_hud()

	# 2. Dükkânı Aç
	print("Dükkân açılıyor...")
	game._on_shop_opened()
	await _wait(0.4)

	# 3. Kontroller
	assert(game.hud.visible == false, "Dükkân açıldığında Klasik Oyun HUD'u gizlenmeli!")
	assert(game.skilled_shop.visible == true, "Dükkân paneli görünür olmalı")
	assert(game.skilled_shop.get_node("%ShopMoneyLabel").text == "400", "Dükkân başlığında oyuncu parası 400 görünmeli")

	# Kart boyutları kontrolü (üç kart da aynı genişlik ve yükseklikte olmalı)
	var bread_card: Control = game.skilled_shop.get_node("%ShopPanel").find_child("BreadUpgrade", true, false)
	var butter_card: Control = game.skilled_shop.get_node("%ShopPanel").find_child("ButterUpgrade", true, false)
	var air_card: Control = game.skilled_shop.get_node("%ShopPanel").find_child("AirUpgrade", true, false)

	print("Kart boyutları:")
	print("  Bread: ", bread_card.size)
	print("  Butter: ", butter_card.size)
	print("  Air: ", air_card.size)
	assert(bread_card.size.x == butter_card.size.x and butter_card.size.x == air_card.size.x, "Üç kartın genişlikleri eşit olmalı")
	assert(bread_card.size.y == butter_card.size.y and butter_card.size.y == air_card.size.y, "Üç kartın yükseklikleri eşit olmalı")

	# İlk dükkân ekran görüntüsü
	await _shot("shop_opened_400coins")

	# 4. Satın alma testi: Ekmek geliştir (250 altın)
	var bread_btn: Button = game.skilled_shop.get_node("%BreadUpgradeBtn")
	assert(bread_btn.disabled == false, "400 para ile 250'lik ekmek butonu aktif olmalı")
	bread_btn.pressed.emit()
	await _wait(0.3)

	assert(game.skilled_mgr.bread_level == 2, "Ekmek seviyesi 2 olmalı")
	assert(game.skilled_mgr.money == 150, "Kalan para 400 - 250 = 150 olmalı")
	assert(game.skilled_shop.get_node("%ShopMoneyLabel").text == "150", "Dükkânda para 150 olarak güncellenmeli")
	assert(bread_btn.disabled == true, "150 para ile bir sonraki seviye (350) yetersiz olduğu için pasif olmalı")

	# 5. Para ekle ve Tereyağı + Hava takviyesi al
	game.skilled_mgr.money = 1500
	game.skilled_shop.refresh()
	await _wait(0.2)

	var butter_btn: Button = game.skilled_shop.get_node("%ButterUpgradeBtn")
	butter_btn.pressed.emit()
	await _wait(0.2)
	assert(game.skilled_mgr.butter_level == 2, "Tereyağı seviyesi 2 olmalı")

	var air_btn: Button = game.skilled_shop.get_node("%AirUpgradeBtn")
	air_btn.pressed.emit()
	await _wait(0.2)
	assert(game.skilled_mgr.air_boost_level == 1, "Hava takviyesi seviyesi 1 olmalı")

	# Güncellenmiş dükkân ekran görüntüsü
	await _shot("shop_upgraded_state")

	# 6. Dükkânı Kapat
	print("Dükkân kapatılıyor...")
	var close_btn: Button = game.skilled_shop.get_node("%CloseButton")
	close_btn.pressed.emit()
	await _wait(0.4)

	assert(game.skilled_shop.visible == false, "KAPAT basılınca dükkân gizlenmeli")
	assert(game.hud.visible == true, "Dükkân kapatılınca oyun HUD'u tekrar görünür olmalı!")
	print("HUD para değeri: ", game.hud.get_node("%MoneyValue").text)
	assert(game.hud.get_node("%MoneyValue").text == str(game.skilled_mgr.money), "HUD'daki para güncel olmalı")

	# Oyun ekranı görüntüsü
	await _shot("gameplay_after_shop_close")

	print("--- TÜM DÜKKÂN TESTLERİ BAŞARIYLA GEÇTİ! ---")
	quit(0)
