# godot-platform2d
This addon provides 2 new node types for 2d platformer-style games (both inherit from StaticBody2D):
- ThinPlatform: this object is defined by a curve and provides a StaticBody2d that "follows" that curve. It is drawn using a texture that is rendered along that curve. It can be used to create thin platforms.
- ThickPlatform: this object is defined by a closed curve and provides a StaticBody2d inside that curve. It is drawn using a "fill" texture and "border" textures. There are 2 border textures that are used depending on the edge angle.

It also provides example scenes for:
- player that can can run, jump, fall, wall slide, wall jump, die and respawn
- coins that can be collected
- traps that kill the player
- checkpoints that define a new respawn point when reached

## Common exported variables

- **MovingPlatform** is a boolean parameter that will automatically update the platform's constant linear velocity when the platform is moving.
- **Curve** is the curve that defines the platform's shape (make sure to make it unique when copying a platform or the curve will be shared)
- **Bake Interval** is the distance between 2 points in the rendered platform. Keep this as high as possible (depending on the platform's shape) to improve rendering performance
- **Style** is a (custom) resource that defines how the platform looks

## ThinPlatform style resource

- **Left Texture** is the texture drawn on the left side of the platform.
- **Mid Texture** is the texture used to draw the platform. It must have the *repeat* attribute.
- **Right Texture** is the texture drawn on the right side of the platform.
- **Left Overflow** (resp. **Right Overflow**) is the "amount" of the left (resp. right) texture that "overflows" from the platform (useful when the texture shows non-solid stuff like grass).
- **Thickness** is the thickness of the platform.
- **Position** is the position of the curve in the platform's thickness and can be used to adjust the positions of the texture and the StaticBody2D. Set it to 1 when the texture has no perspective effect (the world is strictly viewed from the side) and somewhere between 0 and 1 when the top of platforms is drawn.

## ThickPlatform style resource

- **Fill Texture** is the texture used to fill the platform. It must have the *repeat* attribute.
- **Top Texture** is a texture used to draw the edge on the top of the of the platform. It must have the *repeat* attribute.
- **Top Left/Right Texture** are the textures drawn on the edges of the top texture.
- **Side Texture** is a texture used to draw the edge of sides and bottom of the platform. It must have the *repeat* attribute.
- **Top/Side Thickness** are the thickness of the border textures
- **Top/Side Position** are the position of the curve in the platform's border and can be used to adjust the positions of the textures and the StaticBody2D.
- **Top Left/Right Overflow** is the "amount" of the edge texture that "overflows" from the top.
- **Angle** is the threshold angle used to select between top and side textures. Transitions between textures only happen at control points.

## Styles

ThinPlatform and ThickPlatform styles can be created, removed, loaded and saved using the **Style** menu in the 2d view toolbar. This menu will be removed once I figure out how to have a correct menu for custom resources in the inspector.
