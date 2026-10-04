class_name Palette
extends RefCounted
## Palet warna TAPAK NUSA.
##
## Seluruh warna game dikumpulkan di satu tempat supaya gaya visual tetap
## konsisten dan mudah diubah tanpa menyentuh kode gameplay.

# --- Dasar ---------------------------------------------------------------
const CREAM := Color(0.9647, 0.9176, 0.8392, 1.0)  # #f6ead6
const CREAM_DIM := Color(0.8745, 0.8039, 0.6824, 1.0)  # #dfcdae
const CREAM_DARK := Color(0.7686, 0.6824, 0.5490, 1.0)  # #c4ae8c
const INK := Color(0.1686, 0.1294, 0.0941, 1.0)  # #2b2118
const INK_SOFT := Color(0.2431, 0.1961, 0.1529, 1.0)  # #3e3227

# --- Emas / aksen --------------------------------------------------------
const GOLD := Color(0.9490, 0.6941, 0.2039, 1.0)  # #f2b134
const GOLD_DEEP := Color(0.7882, 0.5412, 0.1333, 1.0)  # #c98a22
const GOLD_PALE := Color(0.9686, 0.8392, 0.5412, 1.0)  # #f7d68a

# --- Rumah & bangunan ----------------------------------------------------
const TERRACOTTA := Color(0.7098, 0.3294, 0.2471, 1.0)  # #b5543f
const TERRACOTTA_DARK := Color(0.5490, 0.2314, 0.1804, 1.0)  # #8c3b2e
const ROOF_TILE := Color(0.6588, 0.2902, 0.2196, 1.0)  # #a84a38
const ROOF_SHADOW := Color(0.4902, 0.2039, 0.1529, 1.0)  # #7d3427
const WOOD := Color(0.5451, 0.3529, 0.1686, 1.0)  # #8b5a2b
const WOOD_DARK := Color(0.4196, 0.2667, 0.1373, 1.0)  # #6b4423
const WOOD_LIGHT := Color(0.6902, 0.4784, 0.2706, 1.0)  # #b07a45
const BAMBOO := Color(0.6078, 0.6588, 0.2902, 1.0)  # #9ba84a
const BAMBOO_DARK := Color(0.4863, 0.5333, 0.2196, 1.0)  # #7c8838

# --- Dedaunan & tanah ----------------------------------------------------
const LEAF_DARK := Color(0.2471, 0.4196, 0.2000, 1.0)  # #3f6b33
const LEAF := Color(0.4353, 0.6039, 0.2941, 1.0)  # #6f9a4b
const LEAF_LIGHT := Color(0.5882, 0.7451, 0.3922, 1.0)  # #96be64
const GRASS := Color(0.4353, 0.6039, 0.2941, 1.0)  # #6f9a4b
const GRASS_DARK := Color(0.3333, 0.4824, 0.2314, 1.0)  # #557b3b
const GRASS_LIGHT := Color(0.5490, 0.6980, 0.3922, 1.0)  # #8cb264
const SOIL := Color(0.4784, 0.3529, 0.2196, 1.0)  # #7a5a38
const SOIL_DARK := Color(0.3529, 0.2510, 0.1608, 1.0)  # #5a4029
const PATH_SAND := Color(0.8510, 0.7059, 0.4863, 1.0)  # #d9b47c
const PATH_SAND_DARK := Color(0.7451, 0.6039, 0.4000, 1.0)  # #be9a66
const PATH_STONE := Color(0.6627, 0.6353, 0.5882, 1.0)  # #a9a296

# --- Air & sawah ---------------------------------------------------------
const WATER := Color(0.3725, 0.6588, 0.7804, 1.0)  # #5fa8c7
const WATER_DEEP := Color(0.2471, 0.4980, 0.6196, 1.0)  # #3f7f9e
const PADDY_WATER := Color(0.4980, 0.7490, 0.6588, 1.0)  # #7fbfa8
const RICE_GREEN := Color(0.6588, 0.7882, 0.4157, 1.0)  # #a8c96a
const RICE_GOLD := Color(0.8471, 0.7686, 0.4157, 1.0)  # #d8c46a

# --- Batu & kain ---------------------------------------------------------
const STONE := Color(0.6039, 0.6275, 0.6510, 1.0)  # #9aa0a6
const STONE_DARK := Color(0.4627, 0.4863, 0.5098, 1.0)  # #767c82
const INDIGO := Color(0.1843, 0.2824, 0.3451, 1.0)  # #2f4858
const BATIK_BROWN := Color(0.4196, 0.3098, 0.1647, 1.0)  # #6b4f2a
const ROSE := Color(0.7608, 0.3529, 0.4235, 1.0)  # #c25a6c
const PLUM := Color(0.4196, 0.2275, 0.3569, 1.0)  # #6b3a5b

# --- Langit & cahaya -----------------------------------------------------
const NIGHT_SKY := Color(0.1176, 0.1647, 0.2196, 1.0)  # #1e2a38
const DUSK_SKY := Color(0.8784, 0.5412, 0.2941, 1.0)  # #e08a4b
const DUSK_HIGH := Color(0.4157, 0.3529, 0.5490, 1.0)  # #6a5a8c
const LANTERN := Color(1.0000, 0.7882, 0.4196, 1.0)  # #ffc96b
const FIRE := Color(1.0000, 0.5412, 0.2392, 1.0)  # #ff8a3d
const SKY_DAY := Color(0.6588, 0.8392, 0.9137, 1.0)  # #a8d6e9
const SKY_WARM := Color(0.9686, 0.8706, 0.6941, 1.0)  # #f7deb1

# --- Karakter ------------------------------------------------------------
const SKIN_LIGHT := Color(0.8784, 0.6941, 0.5137, 1.0)  # #e0b183
const SKIN := Color(0.7882, 0.5412, 0.3569, 1.0)  # #c98a5b
const SKIN_DARK := Color(0.6431, 0.4196, 0.2706, 1.0)  # #a46b45
const HAIR_DARK := Color(0.1412, 0.1020, 0.0706, 1.0)  # #241a12
const HAIR_GREY := Color(0.8471, 0.8275, 0.7843, 1.0)  # #d8d3c8
const FABRIC_BLUE := Color(0.2431, 0.4863, 0.5608, 1.0)  # #3e7c8f
const FABRIC_GREEN := Color(0.3059, 0.4196, 0.2902, 1.0)  # #4e6b4a
const FABRIC_RED := Color(0.6980, 0.2275, 0.3412, 1.0)  # #b23a57
const FABRIC_YELLOW := Color(0.9098, 0.6902, 0.2941, 1.0)  # #e8b04b

# --- UI ------------------------------------------------------------------
const HINT := Color(0.5608, 0.8353, 0.6510, 1.0)  # #8fd5a6
const DANGER := Color(0.8784, 0.3922, 0.3020, 1.0)  # #e0644d
const SHADOW := Color(0.0500, 0.0400, 0.0300, 0.2000)
const DIM := Color(0.0300, 0.0200, 0.0150, 0.7600)

## Palet karakter (dipakai CharacterVisual). Kunci "style" menentukan detail
## tambahan: topi jerami, kebaya, cap, dst.
const CHARACTERS := {
	"raka": {
		"skin": SKIN, "hair": HAIR_DARK, "shirt": FABRIC_BLUE,
		"shirt_dark": Color(0.17, 0.35, 0.41, 1.0), "lower": Color(0.27, 0.31, 0.36, 1.0),
		"shoes": WOOD_DARK, "accent": GOLD, "style": "young",
		"hat": "", "bun": false, "skirt": false, "scarf": false, "scale": 1.0,
	},
	"mbah_seno": {
		"skin": SKIN_DARK, "hair": HAIR_GREY, "shirt": BATIK_BROWN,
		"shirt_dark": Color(0.30, 0.22, 0.12, 1.0), "lower": Color(0.22, 0.22, 0.24, 1.0),
		"shoes": WOOD_DARK, "accent": INDIGO, "style": "elder",
		"hat": "straw", "bun": false, "skirt": false, "scarf": true, "scale": 0.97,
	},
	"sari": {
		"skin": SKIN, "hair": HAIR_DARK, "shirt": FABRIC_RED,
		"shirt_dark": Color(0.51, 0.15, 0.24, 1.0), "lower": BATIK_BROWN,
		"shoes": WOOD_DARK, "accent": GOLD, "style": "woman",
		"hat": "", "bun": true, "skirt": true, "scarf": false, "scale": 0.95,
	},
	"pak_jaya": {
		"skin": SKIN, "hair": Color(0.20, 0.16, 0.12, 1.0), "shirt": FABRIC_GREEN,
		"shirt_dark": Color(0.22, 0.32, 0.20, 1.0), "lower": Color(0.24, 0.27, 0.31, 1.0),
		"shoes": WOOD_DARK, "accent": WOOD_LIGHT, "style": "craftsman",
		"hat": "", "bun": false, "skirt": false, "scarf": false, "scale": 1.02,
	},
	"bu_rini": {
		"skin": SKIN, "hair": HAIR_DARK, "shirt": FABRIC_BLUE,
		"shirt_dark": Color(0.17, 0.35, 0.41, 1.0), "lower": BATIK_BROWN,
		"shoes": WOOD_DARK, "accent": ROSE, "style": "woman",
		"hat": "", "bun": true, "skirt": true, "scarf": false, "scale": 0.95,
	},
	"dimas": {
		"skin": SKIN, "hair": HAIR_DARK, "shirt": Color(0.31, 0.36, 0.55, 1.0),
		"shirt_dark": Color(0.21, 0.25, 0.40, 1.0), "lower": Color(0.22, 0.26, 0.33, 1.0),
		"shoes": FABRIC_RED, "accent": FABRIC_RED, "style": "youth",
		"hat": "cap", "bun": false, "skirt": false, "scarf": false, "scale": 1.0,
	},
	"warga_petani": {
		"skin": SKIN_DARK, "hair": HAIR_DARK, "shirt": FABRIC_YELLOW,
		"shirt_dark": Color(0.72, 0.53, 0.20, 1.0), "lower": Color(0.25, 0.25, 0.28, 1.0),
		"shoes": WOOD_DARK, "accent": LEAF_DARK, "style": "elder",
		"hat": "straw", "bun": false, "skirt": false, "scarf": false, "scale": 0.99,
	},
	"warga_penjual": {
		"skin": SKIN, "hair": HAIR_DARK, "shirt": ROSE,
		"shirt_dark": Color(0.55, 0.24, 0.30, 1.0), "lower": BATIK_BROWN,
		"shoes": WOOD_DARK, "accent": GOLD, "style": "woman",
		"hat": "", "bun": true, "skirt": true, "scarf": false, "scale": 0.94,
	},
	"warga_anak": {
		"skin": SKIN_LIGHT, "hair": HAIR_DARK, "shirt": LEAF_LIGHT,
		"shirt_dark": Color(0.44, 0.58, 0.30, 1.0), "lower": FABRIC_BLUE,
		"shoes": FABRIC_RED, "accent": GOLD, "style": "child",
		"hat": "", "bun": false, "skirt": false, "scarf": false, "scale": 0.78,
	},
}


## Mengambil palet karakter; selalu mengembalikan palet yang valid.
static func character(id: String) -> Dictionary:
	if CHARACTERS.has(id):
		return CHARACTERS[id]
	return CHARACTERS["raka"]


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


static func shade(color: Color, amount: float) -> Color:
	if amount >= 0.0:
		return color.lightened(amount)
	return color.darkened(-amount)


static func mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)


## Warna motif batik untuk puzzle pola.
const MOTIF_COLORS := [INDIGO, BATIK_BROWN, GOLD, ROSE, PLUM, FABRIC_GREEN]

## Warna kertas/catatan budaya.
const NOTE_COLORS := [GOLD, HINT, ROSE, LEAF_LIGHT, DANGER, GOLD_PALE]
