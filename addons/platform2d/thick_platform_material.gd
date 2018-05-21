tool
extends Resource

export(Texture)               var FillTexture = null setget set_fill_texture
export(Texture)               var FillNormalMap = null setget set_fill_normal_map
export(float)                 var FillSize = 1.0 setget set_fill_size
export(Texture)               var TopLeftTexture = null setget set_top_left_texture
export(Texture)               var TopTexture = null setget set_top_texture
export(Texture)               var TopRightTexture = null setget set_top_right_texture
export(float)                 var TopThickness = 100 setget set_top_thickness
export(float, 0.0, 1.0, 0.01) var TopPosition = 0.5 setget set_top_position
export(float, 0.0, 1.0, 0.01) var TopLeftOverflow = 0.0 setget set_top_left_overflow
export(float, 0.0, 1.0, 0.01) var TopRightOverflow = 0.0 setget set_top_right_overflow
export(Texture)               var SideTexture = null setget set_side_texture
export(float)                 var SideThickness = 10 setget set_side_thickness
export(float, 0.0, 1.0, 0.01) var SidePosition = 0.5 setget set_side_position
export(float, 0.0, 3.2, 0.01) var Angle = 0.5 setget set_angle

func set_fill_texture(t):
	FillTexture = t
	FillTexture.flags |= Texture.FLAG_REPEAT
	emit_signal("changed")

func set_fill_normal_map(t):
	FillNormalMap = t
	FillNormalMap.flags |= Texture.FLAG_REPEAT
	emit_signal("changed")

func set_fill_size(s):
	print("Setting fill size")
	FillSize = s
	emit_signal("changed")

func set_top_left_texture(t):
	TopLeftTexture = t
	emit_signal("changed")

func set_top_texture(t):
	TopTexture = t
	TopTexture.flags |= Texture.FLAG_REPEAT
	emit_signal("changed")

func set_top_right_texture(t):
	TopRightTexture = t
	emit_signal("changed")

func set_top_thickness(t):
	TopThickness = t
	emit_signal("changed")

func set_top_position(p):
	TopPosition = p
	emit_signal("changed")

func set_top_left_overflow(o):
	TopLeftOverflow = o
	emit_signal("changed")

func set_top_right_overflow(o):
	TopRightOverflow = o
	emit_signal("changed")

func set_side_texture(t):
	SideTexture = t
	SideTexture.flags |= Texture.FLAG_REPEAT
	emit_signal("changed")

func set_side_thickness(t):
	SideThickness = t
	emit_signal("changed")

func set_side_position(p):
	SidePosition = p
	emit_signal("changed")

func set_angle(a):
	Angle = a
	emit_signal("changed")

