extends SceneTree
## Sandviç Ustası sipariş, malzeme, kontrol hakkı ve sahne entegrasyonu.

const SandwichModeScript = preload("res://modes/sandwich_mode.gd")


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- TEST BAŞLIYOR: Sandviç Ustası Doğrulama ---")

	var mgr = SandwichModeScript.new()
	mgr.order = {"butter": 1, "salami": 1, "lettuce": 0, "jam": 0}
	mgr.total_target = 2
	mgr.stack.clear()
	mgr.clicks_left = SandwichModeScript.MAX_CLICKS
	mgr.restore_time_scale()

	assert(mgr.try_collect("butter", false) == "grounded", "Yerde malzeme alınamamalı")
	assert(mgr.try_collect("lettuce", true) == "not_in_order", "Siparişte olmayan malzeme reddedilmeli")
	assert(mgr.try_collect("butter", true) == "ok", "Siparişteki tereyağı alınmalı")
	assert(mgr.try_collect("butter", true) == "enough", "Fazla tereyağı reddedilmeli")
	assert(mgr.try_collect("salami", true) == "ok", "Siparişteki salam alınmalı")
	assert(mgr.is_order_filled() == true, "Eksiksiz sipariş dolu sayılmalı")
	assert(is_equal_approx(Engine.time_scale, 1.0), "Sipariş dolunca zaman ölçeği 1 olmalı")

	mgr.clicks_left = 3
	assert(mgr.use_control() == true, "Kontrol hakkı harcanmalı")
	assert(mgr.clicks_left == 2, "Kalan hak 2 olmalı")
	mgr.clicks_left = 0
	assert(mgr.use_control() == false, "Hak bitince kontrol reddedilmeli")

	var win: Dictionary = mgr.evaluate_landing(true)
	assert(win["success"] == true, "Doğru yüz + doğru sipariş başarı olmalı")
	assert(int(win["points"]) == SandwichModeScript.SUCCESS_SCORE, "Başarı puanı 100 olmalı")

	mgr.stack.clear()
	var miss: Dictionary = mgr.evaluate_landing(true)
	assert(miss["success"] == false, "Eksik sipariş başarısız olmalı")
	assert(miss["reason"] == "wrong_order", "Eksik sipariş nedeni wrong_order olmalı")

	var flip: Dictionary = mgr.evaluate_landing(false)
	assert(flip["reason"] == "wrong_face", "Ters iniş wrong_face olmalı")
	assert(is_equal_approx(Engine.time_scale, 1.0), "Değerlendirme zaman ölçeğini geri almalı")
	print("✓ 1. Sipariş, malzeme reddi, kontrol hakkı ve iniş değerlendirmesi DOĞRU.")

	mgr.on_launched()
	assert(mgr.clicks_left == 3, "Fırlatınca kontrol hakkı 3 olmalı")
	assert(mgr.time_scale == SandwichModeScript.SLOW_MO_SCALE, "Fırlatınca yavaş çekim açılmalı")
	assert(is_equal_approx(Engine.time_scale, SandwichModeScript.SLOW_MO_SCALE), "Engine.time_scale yavaş çekimde olmalı")
	mgr.restore_time_scale()
	assert(is_equal_approx(Engine.time_scale, 1.0), "restore_time_scale Engine.time_scale'i 1 yapmalı")
	print("✓ 2. Yavaş çekim uygulama ve geri alma DOĞRU.")

	mgr.generate_order()
	var total := 0
	for key in mgr.order.keys():
		total += int(mgr.order[key])
	assert(total == mgr.total_target, "Sipariş adetleri toplam hedefe eşit olmalı")
	assert(mgr.total_target >= 2 and mgr.total_target <= 4, "Sipariş 2-4 malzeme olmalı")
	print("✓ 3. Rastgele sipariş üretimi DOĞRU (adet: %d)." % mgr.total_target)

	var scene_res := load("res://node_2d.tscn") as PackedScene
	if scene_res == null:
		push_error("node_2d.tscn yüklenemedi!")
		quit(1)
		return

	var root_node := scene_res.instantiate()
	root.add_child(root_node)

	root_node._on_play_button_pressed()
	assert(root_node.state == root_node.GameState.MODE_SELECT, "Mod seçimi açılmalı")
	assert(root_node.mode_select_menu._unlocked_cards.has(root_node.mode_select_menu._card_sandwich), "Sandviç kartı açık olmalı")

	root_node._on_mode_chosen(2)
	assert(root_node.active_mode == root_node.GameMode.SANDWICH, "Aktif mod SANDWICH olmalı")
	assert(root_node.state == root_node.GameState.READY, "Sandviç modu READY olmalı")
	assert(root_node.hud.get_node("%SandwichPanel").visible == true, "Sandviç HUD görünür olmalı")
	assert(root_node.hud.get_node("%ButterPanel").visible == false, "Tereyağı paneli gizli olmalı")
	assert(root_node.hud.get_node("%MoneyPanel").visible == false, "Usta Şef para paneli gizli olmalı")
	assert(root_node.ingredient_stations.visible == true, "Malzeme istasyonları görünür olmalı")
	assert(root_node.ingredient_stations.get_child_count() == 4, "4 malzeme istasyonu olmalı")
	print("✓ 4. Mod seçimi ve Sandviç HUD entegrasyonu DOĞRU.")

	var lives_before: int = root_node.lives
	root_node.sandwich_mgr.order = {"butter": 1, "salami": 0, "lettuce": 0, "jam": 0}
	root_node.sandwich_mgr.total_target = 1
	root_node.sandwich_mgr.stack.clear()
	root_node.toast.launch()
	root_node.state = root_node.GameState.FLYING
	assert(root_node.sandwich_mgr.try_collect("butter", true) == "ok", "Uçuşta tereyağı toplanmalı")
	root_node._on_toast_landed(false)
	assert(root_node.score == 100, "Doğru sandviç +100 puan vermeli")
	assert(root_node.lives == lives_before, "Sandviç başarısı can azaltmamalı")
	print("✓ 5. Doğru sipariş puanlaması DOĞRU.")

	root_node._show_main_menu()
	assert(is_equal_approx(Engine.time_scale, 1.0), "Menüye dönüş zaman ölçeğini sıfırlamalı")
	root_node._on_mode_chosen(0)
	assert(root_node.active_mode == root_node.GameMode.CLASSIC, "Klasik moda dönüş çalışmalı")
	assert(root_node.hud.get_node("%SandwichPanel").visible == false, "Klasikte sandviç HUD gizli olmalı")
	assert(root_node.ingredient_stations.visible == false, "Klasikte istasyonlar gizli olmalı")
	print("✓ 6. Klasik moda dönüş ve zaman ölçeği temizliği DOĞRU.")

	print("--- TÜM SANDVİÇ USTASI TESTLERİ BAŞARIYLA GEÇTİ! ---")
	quit(0)
