extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_res := load("res://node_2d.tscn") as PackedScene
	var root_node := scene_res.instantiate()
	root.add_child(root_node)

	# Oyunu başlat
	root_node._on_play_button_pressed()
	root_node.toast.reset_to(root_node._start_pos)
	root_node.toast.show()

	# 2 kare bekle ki tüm Viewport ve HUD çizilsin
	await process_frame
	await process_frame

	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	img.save_png("/home/umut/.gemini/antigravity/brain/0c0bda92-d995-4119-97ab-510f4b563af8/scratch/gameplay_rendered.png")
	print("Ekran görüntüsü kaydedildi!")
	quit(0)
