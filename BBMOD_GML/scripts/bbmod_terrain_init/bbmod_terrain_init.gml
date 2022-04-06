/// @macro {Struct.BBMOD_DefaultShader} Shader for terrain materials.
#macro BBMOD_SHADER_TERRAIN __bbmod_shader_terrain()

/// @macro {Struct.BBMOD_DefaultMaterial} Base terrain material.
#macro BBMOD_MATERIAL_TERRAIN __bbmod_material_terrain()

function __bbmod_shader_terrain()
{
	static _shader = new BBMOD_DefaultShader(BBMOD_ShTerrain, BBMOD_VFORMAT_DEFAULT);
	return _shader;
}

function __bbmod_material_terrain()
{
	static _material = undefined;
	if (_material == undefined)
	{
		_material = new BBMOD_DefaultMaterial(__bbmod_shader_terrain());
		_material.set_shader(BBMOD_ERenderPass.Shadows, BBMOD_SHADER_DEPTH);
		_material.Mipmapping = mip_on;
		_material.Repeat = true;
		_material.AlphaBlend = true;
	}
	return _material;
}