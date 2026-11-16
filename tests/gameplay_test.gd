extends SceneTree
## Tost Flip oynanış, HUD, can, tereyağı ve denge mekaniklerini doğrulayan otomatik test.

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- TEST BAŞLIYOR: Tost Flip Oynanış ve HUD Doğrulama ---")
	var scene_res := load("res://node_2d.tscn") as PackedScene
	if scene_res == null:
		push_error("node_2d.tscn yüklenemedi!")
		quit(1)
		return

	var root_node := scene_res.instantiate()
	root.add_child(root_node)

	# 1. Başlangıç durumu kontrolü
	assert(root_node.state == root_node.GameState.MAIN_MENU, "Oyun MAIN_MENU durumunda başlamalı")
	assert(root_node.gameplay_area.visible == false, "GameplayArea menüde gizli olmalı")
	assert(root_node.hud.visible == false, "HUD menüde gizli olmalı")
	print("✓ 1. Başlangıç menü durumu DOĞRU.")

	# 2. Oyna butonuna basış ve Klasik Mod seçimi
	root_node._on_play_button_pressed()
	assert(root_node.state == root_node.GameState.MODE_SELECT, "Oyun MODE_SELECT durumuna geçmeli")
	assert(root_node.mode_select_menu.visible == true, "Mod seçim menüsü görünür olmalı")
	root_node._on_mode_chosen(0)
	assert(root_node.state == root_node.GameState.READY, "Klasik Mod seçilince READY durumuna geçmeli")
	assert(root_node.gameplay_area.visible == true, "GameplayArea görünür olmalı")
	assert(root_node.hud.visible == true, "HUD görünür olmalı")
	assert(root_node.lives == 3, "Başlangıç canı 3 olmalı")
	assert(root_node.butter_layers == 0, "Başlangıç tereyağı katmanı 0 olmalı")
	assert(root_node.score == 0, "Başlangıç skoru 0 olmalı")
	print("✓ 2. Oyna ve sahne geçişi DOĞRU.")

	# 3. Fırlatma (sol tık)
	root_node.toast.launch()
	root_node.state = root_node.GameState.FLYING
	assert(root_node.toast.airborne == true, "Tost havada olmalı")
	assert(root_node.toast.linear_velocity.y < 0, "Tost yukarı doğru hızlanmalı")
	print("✓ 3. Tost fırlatma DOĞRU.")

	# 4. Havada dönüş ve denge
	root_node.toast.spin(-1)
	var bal: float = root_node.toast.get_balance()
	assert(absf(bal) > 0.0, "Dönüş sonrası denge değeri 0 olmamalı")
	root_node.hud.set_balance(bal)
	print("✓ 4. Havada dönüş ve denge göstergesi DOĞRU (Denge: %f)" % bal)

	# 5. Başarılı iniş (butter_down = false)
	root_node._on_toast_landed(false)
	assert(root_node.score == 1, "İlk başarılı inişte skor 1 olmalı")
	assert(root_node.butter_layers == 1, "Başarılı inişte tereyağı katmanı 1 olmalı")
	assert(root_node.lives == 3, "Başarılı inişte can kaybolmamalı")
	assert(root_node.toast.butter_layers == 1, "Tostun fiziksel katmanı 1 olmalı")
	print("✓ 5. Başarılı iniş mekaniği DOĞRU (+1 katman, +1 puan, can tam).")

	# 6. İkinci başarılı iniş (1 katman varken skor 1 + 1 = 2 puan artmalı)
	root_node.state = root_node.GameState.FLYING
	root_node._on_toast_landed(false)
	assert(root_node.score == 3, "İkinci inişte skor 1 + 2 = 3 olmalı (1 + katman bonusu)")
	assert(root_node.butter_layers == 2, "Tereyağı katmanı 2 olmalı")
	print("✓ 6. Katman bonuslu puanlama DOĞRU (Skor: %d, Katman: %d)." % [root_node.score, root_node.butter_layers])

	# 7. Başarısız iniş (butter_down = true) -> Can 1 azalmalı, katman 0 olmalı, skor korunmalı
	root_node.state = root_node.GameState.FLYING
	root_node._on_toast_landed(true)
	assert(root_node.lives == 2, "Başarısız inişte can 2'ye düşmeli")
	assert(root_node.butter_layers == 0, "Başarısız inişte tereyağı katmanı 0'lanmalı")
	assert(root_node.score == 3, "Başarısız inişte mevcut skor (3) korunmalı (artık sıfırlanmıyor)")
	print("✓ 7. Can kaybı ve katman sıfırlanma kuralı DOĞRU (Kalan can: %d, Skor korundu: %d)." % [root_node.lives, root_node.score])

	# 8. Kalan canların tükenmesi ve GAME_OVER
	root_node.state = root_node.GameState.FLYING
	root_node._on_toast_landed(true) # 1 can kaldı
	assert(root_node.lives == 1, "Can 1 olmalı")
	root_node.state = root_node.GameState.FLYING
	root_node._on_toast_landed(true) # 0 can kaldı
	assert(root_node.lives == 0, "Can 0 olmalı")
	assert(root_node.state == root_node.GameState.GAME_OVER, "0 canda durum GAME_OVER olmalı")
	print("✓ 8. 0 Can durumunda GAME_OVER geçişi DOĞRU.")

	# 9. Tekrar Oyna
	root_node._on_retry_pressed()
	assert(root_node.state == root_node.GameState.READY, "Tekrar oyna sonrası durum READY olmalı")
	assert(root_node.lives == 3, "Tekrar oyna sonrası can 3'e dönmeli")
	assert(root_node.score == 0, "Tekrar oyna sonrası skor 0 olmalı")
	assert(root_node.butter_layers == 0, "Tekrar oyna sonrası katman 0 olmalı")
	print("✓ 9. Tekrar Oyna sıfırlaması DOĞRU.")

	# 10. Ana Menü ve Koleksiyon
	root_node._show_main_menu()
	assert(root_node.state == root_node.GameState.MAIN_MENU, "Ana menüye dönüş DOĞRU")
	root_node._on_collection_button_pressed()
	assert(root_node.state == root_node.GameState.COLLECTION, "Koleksiyon ekranına geçiş DOĞRU")
	root_node._on_back_button_pressed()
	assert(root_node.state == root_node.GameState.MAIN_MENU, "Koleksiyondan ana menüye dönüş DOĞRU")
	print("✓ 10. Menü ve Koleksiyon entegrasyonu DOĞRU.")

	print("--- TÜM TESTLER BAŞARIYLA GEÇTİ! ---")
	quit(0)
