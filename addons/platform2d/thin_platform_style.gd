tool
extends Resource

export(Texture)               var LeftTexture = null setget set_left_texture
export(Texture)               var MidTexture = null setget set_mid_texture
export(Texture)               var RightTexture = null setget set_right_texture
export(float, 0.0, 1.0, 0.01) var LeftOverflow = 0.0 setget set_left_overflow
export(float, 0.0, 1.0, 0.01) var RightOverflow = 0.0 setget set_right_overflow
export(float)                 var Thickness = 100 setget set_thickness
export(float, 0.0, 1.0, 0.01) var Position = 0.5 setget set_position

func set_left_texture(t):
	LeftTexture = t
	emit_signal("changed")

func set_mid_texture(t):
	MidTexture = t
	MidTexture.flags |= Texture.FLAG_REPEAT
	emit_signal("changed")

func set_right_texture(t):
	RightTexture = t
	emit_signal("changed")

func set_left_overflow(o):
	LeftOverflow = o
	emit_signal("changed")

func set_right_overflow(o):
	RightOverflow = o
	emit_signal("changed")

func set_thickness(t):
	Thickness = t
	emit_signal("changed")

func set_position(p):
	Position = p
	emit_signal("changed")

