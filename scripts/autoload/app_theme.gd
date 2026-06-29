extends Node

# Assigns the bundled CJK font as the engine-wide fallback so ALL text renders
# Traditional Chinese on every machine — themed Controls (which currently chain
# to the fallback because no custom theme font is set), unit type glyphs and hex
# labels (both draw with ThemeDB.fallback_font directly).
#
# Without this, Godot's built-in default font has no CJK glyphs and text only
# rendered on hosts that happened to have a system CJK font installed via
# font-config fallback. A clean desktop — and especially the Web build, which
# cannot reach the host's system fonts — rendered every Chinese character as a
# tofu box. See assets/fonts/README.md.

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKtc-Regular.otf")

func _ready() -> void:
	ThemeDB.fallback_font = CJK_FONT
