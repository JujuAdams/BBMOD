/// @module Core

/// @func BBMOD_Light()
///
/// @extends BBMOD_Class
///
/// @desc Base class for lights.
function BBMOD_Light()
	: BBMOD_Class() constructor
{
	BBMOD_CLASS_GENERATED_BODY;

	/// @var {Bool} Use `false` to disable the light. Defaults to `true` (the
	/// light is enabled).
	Enabled = true;

	/// @var {Real} Bitwise OR of 1 << render pass in which the light is enabled.
	/// By default this is {@link BBMOD_ERenderPass.Forward}
	/// and {@link BBMOD_ERenderPass.ReflectionCapture}, which means the light
	/// is visible only in the forward render pass and during capture of
	/// reflection probes.
	///
	/// @example
	/// ```gml
	/// flashlight = new BBMOD_SpotLight();
	/// // Make the flashlight visible only in the forward render pass
	/// flashlight.RenderPass = (1 << BBMOD_ERenderPass.Forward);
	/// ```
	///
	/// @see BBMOD_ERenderPass
	RenderPass = (1 << BBMOD_ERenderPass.Forward)
		| (1 << BBMOD_ERenderPass.ReflectionCapture);

	/// @var {Struct.BBMOD_Vec3} The position of the light.
	Position = new BBMOD_Vec3();

	/// @var {Bool} If `true` then the light affects also materials with baked
	/// lightmaps. Defaults to `true`.
	AffectLightmaps = true;

	/// @var {Bool} If `true` then the light should casts shadows. This may
	/// not be implemented for all types of lights! Defaults to `false`.
	CastShadows = false;

	/// @var {Real} The resolution of the shadowmap surface. Must be power of 2.
	/// Defaults to 512.
	ShadowmapResolution = 512;

	/// @var {Function}
	/// @private
	__getZFar = undefined;

	/// @var {Function}
	/// @private
	__getViewMatrix = undefined;

	/// @var {Function}
	/// @private
	__getProjMatrix = undefined;

	/// @var {Function}
	/// @private
	__getShadowmapMatrix = undefined;
}
