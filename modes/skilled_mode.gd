class_name SkilledMode
extends RefCounted
## Usta Şef Modu (Skilled Mode) ekonomi, yükseltme ve kalıcı kayıt yöneticisi.

const SAVE_PATH := "user://skilled_save.cfg"

# Yükseltme maliyetleri
const BREAD_COSTS := [250, 850, 2400, 6500]       # Seviye 1->2, 2->3, 3->4, 4->5
const BUTTER_COSTS := [300, 1100, 3200, 8800]     # Seviye 1->2, 2->3, 3->4, 4->5
const AIR_BOOST_COSTS := [600, 3500]              # Seviye 0->1, 1->2

# Tereyağı kalite çarpanları
const BUTTER_MULTIPLIERS := [1.0, 1.3, 1.7, 2.2, 2.85]

# Durum değişkenleri
var money: int = 0
var bread_level: int = 1        # 1..5
var butter_level: int = 1       # 1..5
var air_boost_level: int = 0    # 0..2


func _init() -> void:
	load_data()


# --- HESAPLAMA FORMÜLLERİ ----------------------------------------------------

## Başarılı tost inişinde/satışında kazanılacak para:
## temel_odul = katman * 8 + katman * katman * 6
## katman == 0 iken 3 para.
## Sonuç tereyağı kalite çarpanı ile çarpılır.
func calculate_reward(layers: int) -> int:
	var base := 3
	if layers > 0:
		base = layers * 8 + layers * layers * 6
	var mult := get_butter_multiplier()
	return maxi(1, int(round(base * mult)))


## Ekmek geliştirmesi: maksimum_katman = 2 + ekmek_seviyesi
func get_max_butter_layers() -> int:
	return 2 + bread_level


## Ekmek geliştirmesi: tork_direnci = 1.0 - (ekmek_seviyesi - 1) * 0.15
## 1.0'dan 0.40'a kadar düşer (tereyağının tostu aşağı çekme torkunu zayıflatır).
func get_torque_resistance() -> float:
	return clampf(1.0 - (bread_level - 1) * 0.15, 0.2, 1.0)


## Tereyağı kalitesi çarpanı: [1.0, 1.3, 1.7, 2.2, 2.85]
func get_butter_multiplier() -> float:
	var idx := clampi(butter_level - 1, 0, BUTTER_MULTIPLIERS.size() - 1)
	return BUTTER_MULTIPLIERS[idx]


## Tur başına kullanılabilir ekstra hava takviyesi sayısı (0, 1 veya 2)
func get_max_air_boosts() -> int:
	return air_boost_level


# --- DÜKKAN & YÜKSELTME SİSTEMİ ----------------------------------------------

func get_upgrade_cost(type: String) -> int:
	match type:
		"bread":
			if bread_level >= 5:
				return -1
			return BREAD_COSTS[bread_level - 1]
		"butter":
			if butter_level >= 5:
				return -1
			return BUTTER_COSTS[butter_level - 1]
		"air_boost":
			if air_boost_level >= 2:
				return -1
			return AIR_BOOST_COSTS[air_boost_level]
		_:
			return -1


func can_upgrade(type: String) -> bool:
	var cost := get_upgrade_cost(type)
	return cost > 0 and money >= cost


func upgrade(type: String) -> bool:
	if not can_upgrade(type):
		return false
	var cost := get_upgrade_cost(type)
	money -= cost
	match type:
		"bread":
			bread_level += 1
		"butter":
			butter_level += 1
		"air_boost":
			air_boost_level += 1
	save_data()
	return true


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	save_data()


# --- KALICI KAYIT SİSTEMİ (ConfigFile) ---------------------------------------

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("skilled", "money", money)
	config.set_value("skilled", "bread_level", bread_level)
	config.set_value("skilled", "butter_level", butter_level)
	config.set_value("skilled", "air_boost_level", air_boost_level)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_warning("Usta Şef verileri kaydedilemedi: %d" % err)


func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		money = maxi(0, int(config.get_value("skilled", "money", 0)))
		bread_level = clampi(int(config.get_value("skilled", "bread_level", 1)), 1, 5)
		butter_level = clampi(int(config.get_value("skilled", "butter_level", 1)), 1, 5)
		air_boost_level = clampi(int(config.get_value("skilled", "air_boost_level", 0)), 0, 2)
	else:
		# İlk başlangıç varsayılanları
		money = 0
		bread_level = 1
		butter_level = 1
		air_boost_level = 0
