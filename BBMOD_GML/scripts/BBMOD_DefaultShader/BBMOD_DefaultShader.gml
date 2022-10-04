/// @func BBMOD_DefaultShader(_shader, _vertexFormat)
///
/// @extends BBMOD_BaseShader
///
/// @desc Shader used by the default BBMOD materials.
///
/// @param {Asset.GMShader} _shader The shader resource.
/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The vertex format required
/// by the shader.
///
/// @see BBMOD_DefaultMaterial
function BBMOD_DefaultShader(_shader, _vertexFormat)
	: BBMOD_BaseShader(_shader, _vertexFormat) constructor
{
	static BaseShader_set_material = set_material;

	UIsRoughness = get_uniform("bbmod_IsRoughness");

	UNormalW = get_sampler_index("bbmod_NormalW");

	UIsMetallic = get_uniform("bbmod_IsMetallic");

	UMaterial = get_sampler_index("bbmod_Material");

	USubsurface = get_sampler_index("bbmod_Subsurface");

	UEmissive = get_sampler_index("bbmod_Emissive");

	ULightmap = get_sampler_index("bbmod_Lightmap");

	/// @func set_normal_smoothness(_texture)
	///
	/// @desc Sets the `bbmod_NormalW` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with normal vector in
	/// the RGB channels and smoothness in the A channel.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_normal_smoothness = function (_texture) {
		gml_pragma("forceinline");
		shader_set_uniform_f(UIsRoughness, 0.0);
		texture_set_stage(UNormalW, _texture);
		return self;
	};

	/// @func set_specular_color(_texture)
	///
	/// @desc Sets the `bbmod_Material` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with specular color in
	/// the RGB channels.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_specular_color = function (_texture) {
		gml_pragma("forceinline");
		shader_set_uniform_f(UIsMetallic, 0.0);
		texture_set_stage(UMaterial, _texture);
	};

	/// @func set_normal_roughness(_texture)
	///
	/// @desc Sets the `bbmod_NormalW` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with normal vector in
	/// the RGB channels and roughness in the A channel.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_normal_roughness = function (_texture) {
		gml_pragma("forceinline");
		shader_set_uniform_f(UIsRoughness, 1.0);
		texture_set_stage(UNormalW, _texture);
		return self;
	};

	/// @func set_metallic_ao(_texture)
	///
	/// @desc Sets the `bbmod_Material` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with metalness in the
	/// R channel and ambient occlusion in the G channel.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_metallic_ao = function (_texture) {
		gml_pragma("forceinline");
		shader_set_uniform_f(UIsMetallic, 1.0);
		texture_set_stage(UMaterial, _texture);
		return self;
	};

	/// @func set_subsurface(_texture)
	///
	/// @desc Sets the `bbmod_Subsurface` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with subsurface color
	/// in the RGB channels and its intensity in the A channel.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_subsurface = function (_texture) {
		gml_pragma("forceinline");
		texture_set_stage(USubsurface, _texture);
		return self;
	};

	/// @func set_emissive(_texture)
	///
	/// @desc Sets the `bbmod_Emissive` uniform.
	///
	/// @param {Pointer.Texture} _texture The new texture with RGBM encoded
	/// emissive color.
	///
	/// @return {Struct.BBMOD_DefaultShader} Returns `self`.
	static set_emissive = function (_texture) {
		gml_pragma("forceinline");
		texture_set_stage(UEmissive, _texture);
		return self;
	};

	static set_material = function (_material) {
		gml_pragma("forceinline");
		BaseShader_set_material(_material);

		// Normal smoothness/roughness
		if (_material.NormalSmoothness != undefined)
		{
			set_normal_smoothness(_material.NormalSmoothness);
		}

		if (_material.NormalRoughness != undefined)
		{
			set_normal_roughness(_material.NormalRoughness);
		}

		// Specular color/Metallic and AO
		if (_material.SpecularColor != undefined)
		{
			set_specular_color(_material.SpecularColor);
		}

		if (_material.MetallicAO != undefined)
		{
			set_metallic_ao(_material.MetallicAO);
		}

		// Subsurface
		set_subsurface(_material.Subsurface);

		// Emissive
		set_emissive(_material.Emissive);

		return self;
	};
}
