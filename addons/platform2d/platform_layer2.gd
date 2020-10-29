tool
extends Node2D

func _ready():
	pass

func _draw():
	var parent = get_parent()
	var curves
	curves = parent.get_top_curves()
	var style = parent.Style2
	for c in curves:
		parent.draw_top(self, c, style.LeftTexture, style.MidTexture, style.RightTexture, style.LeftOverflow, style.RightOverflow, style.Thickness, style.Position)
