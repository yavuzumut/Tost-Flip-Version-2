shader_type canvas_item;
// Mod kartı seçim parıltısı.
// Kartın kendi dokusunun alfa kanalından, kesme tahtası siluetini (sap dahil)
// takip eden altın bir kontur + yumuşak hale üretir. Bu düğüm, kartın arkasında
// ve her yönde "pad" kadar daha büyük çizilir.

uniform vec4 glow_color : source_color = vec4(1.0, 0.76, 0.18, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.93, 0.52, 1.0);
uniform vec2 pad = vec2(0.07, 0.05);      // parıltı dikdörtgeninin her kenardaki dolgu oranı
uniform float rim_width = 0.018;          // kart UV birimi (x ekseni)
uniform float glow_width = 0.06;          // kart UV birimi (x ekseni)
uniform float aspect = 0.6667;            // kart genişlik / yükseklik
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 1.0;      // seçili kartın yavaş "nefes" efekti
uniform float rim_strength : hint_range(0.0, 1.0) = 1.0; // 0 = yalnızca yumuşak hale (gölge modu)

void fragment() {
	float strength = intensity * pulse;
	if (strength <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = (UV - pad) / (vec2(1.0) - 2.0 * pad);
		float rim = 0.0;
		float glow = 0.0;
		for (int i = 0; i < 16; i++) {
			float ang = float(i) * 0.39269908; // 2*PI / 16
			vec2 dir = vec2(cos(ang), sin(ang) * aspect);
			vec2 sample_rim_uv = uv + dir * rim_width;
			if (sample_rim_uv.x >= 0.0 && sample_rim_uv.x <= 1.0 && sample_rim_uv.y >= 0.0 && sample_rim_uv.y <= 1.0) {
				rim = max(rim, textureLod(TEXTURE, sample_rim_uv, 1.0).a);
			}
			vec2 sample_glow1_uv = uv + dir * glow_width;
			if (sample_glow1_uv.x >= 0.0 && sample_glow1_uv.x <= 1.0 && sample_glow1_uv.y >= 0.0 && sample_glow1_uv.y <= 1.0) {
				glow += textureLod(TEXTURE, sample_glow1_uv, 5.0).a;
			}
			vec2 sample_glow2_uv = uv + dir * glow_width * 0.5;
			if (sample_glow2_uv.x >= 0.0 && sample_glow2_uv.x <= 1.0 && sample_glow2_uv.y >= 0.0 && sample_glow2_uv.y <= 1.0) {
				glow += textureLod(TEXTURE, sample_glow2_uv, 4.0).a;
			}
		}
		glow /= 32.0;
		rim = smoothstep(0.15, 0.55, rim) * rim_strength;
		vec3 col = mix(glow_color.rgb, rim_color.rgb, rim * 0.7);
		float a = max(rim, glow * 0.9);
		COLOR = vec4(col, a * strength);
	}
}
