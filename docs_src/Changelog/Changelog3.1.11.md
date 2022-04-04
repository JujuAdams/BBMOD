# Changelog 3.1.11
This tiny release mainly adds support for orthographic camera projection, as requested by one of our Patrons.

## GML API:
### Core module:
* Added new methods `ApplyWorld`, `ApplyView` and `ApplyProjection` to `BBMOD_Matrix`, using which you can set it as the current world/view/projection matrix respectively.
* Added new method `BBMOD_Matrix.Transform`, using which you can transform a `BBMOD_Vec4` with the matrix.

### Camera module:
* Added new property `BBMOD_Camera.Orthographic`, using which you can enable orthographic projection.
* Added new property `BBMOD_Camera.Width`, using which you can configure the width of orthographic projection. Height is computed from `BBMOD_Camera.AspectRation`.
* Added new method `BBMOD_Camera.world_to_screen`, using which you can get screen-space position of a point in world-space.
