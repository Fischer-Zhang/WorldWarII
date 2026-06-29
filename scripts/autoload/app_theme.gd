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

const CJK_FONT_PATH := "res://assets/fonts/NotoSansCJKtc-Regular.otf"

func _ready() -> void:
	# Runtime load (not preload) so this script always compiles even on a fresh
	# checkout where the font has not been imported yet — a preload would be a
	# parse error that the headless test runner flags as a failure.
	var font := load(CJK_FONT_PATH)
	if font is Font:
		ThemeDB.fallback_font = font
	else:
		push_warning("AppTheme: bundled CJK font not loadable (not imported?)")
