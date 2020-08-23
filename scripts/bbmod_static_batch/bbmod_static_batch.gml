/// @enum An enumeration of members of a StaticBatch structure.
enum BBMOD_EStaticBatch
{
	/// @member The vertex buffer.
	VertexBuffer,
	/// @member The format of the vertex buffer.
	VertexFormat,
	/// @member The size of the StaticBatch structure.
	SIZE
};

/// @func bbmod_static_batch_create(_vformat)
/// @desc Creates a new static batch.
/// @param {real} _vformat The vertex format of the static batch. Must not have
/// bones!
/// @return {array} The created static batch.
/// @see bbmod_model_get_vertex_format
function bbmod_static_batch_create(_vformat)
{
	var _static_batch = array_create(BBMOD_EStaticBatch.SIZE, 0);
	_static_batch[@ BBMOD_EStaticBatch.VertexBuffer] = vertex_create_buffer();
	_static_batch[@ BBMOD_EStaticBatch.VertexFormat] = _vformat;
	return _static_batch;
}

/// @func bbmod_static_batch_destroy(_static_batch)
/// @desc Destroys a StaticBatch structure.
/// @param {array} _static_batch A StaticBatch structure to destroy.
function bbmod_static_batch_destroy(_static_batch)
{
	vertex_delete_buffer(_static_batch[BBMOD_EStaticBatch.VertexBuffer]);
}

/// @func bbmod_static_batch_begin(_static_batch)
/// @desc Begins adding models into a static batch.
/// @param {array} static_batch The static batch.
/// @see bbmod_static_batch_add
/// @see bbmod_static_batch_end
function bbmod_static_batch_begin(_static_batch)
{
	gml_pragma("forceinline");
	vertex_begin(_static_batch[BBMOD_EStaticBatch.VertexBuffer],
		_static_batch[BBMOD_EStaticBatch.VertexFormat]);
}

/// @func bbmod_static_batch_add(_static_batch, _model, _transform)
/// @desc Adds a model to a static batch.
/// @param {array} _static_batch The static batch.
/// @param {array} _model The model.
/// @param {array} _transform A transformation matrix of the model.
/// @example
/// ```gml
/// mod_tree = bbmod_load("Tree.bbmod");
/// var _vformat = bbmod_model_get_vertex_format(mod_tree, false);
/// batch = bbmod_static_batch_create(_vformat);
/// bbmod_static_batch_begin(batch);
/// with (OTree)
/// {
///     var _transform = matrix_build(x, y, z, 0, 0, direction, 1, 1, 1);
///     bbmod_static_batch_add(other.batch, other.mod_tree, _transform);
/// }
/// bbmod_static_batch_end(batch);
/// bbmod_static_batch_freeze(batch);
/// ```
/// @note You must first call
/// [bbmod_static_batch_begin](./bbmod_static_batch_begin.html)
/// before using this function!
/// @see bbmod_static_batch_begin
/// @see bbmod_static_batch_end
function bbmod_static_batch_add(_static_batch, _model, _transform)
{
	gml_pragma("forceinline");
	_bbmod_model_to_static_batch(_model, _static_batch, _transform);
}

/// @func bbmod_static_batch_end(_static_batch)
/// @desc Ends adding models into a static batch.
/// @param {array} _static_batch The static batch.
/// @see bbmod_static_batch_begin
function bbmod_static_batch_end(_static_batch)
{
	gml_pragma("forceinline");
	vertex_end(_static_batch[BBMOD_EStaticBatch.VertexBuffer]);
}

/// @func bbmod_static_batch_freeze(_static_batch)
/// @desc Freezes a static batch. This makes it render faster but disables
/// adding more models to the batch.
/// @param {array} _static_batch The static batch.
function bbmod_static_batch_freeze(_static_batch)
{
	gml_pragma("forceinline");
	vertex_freeze(_static_batch[BBMOD_EStaticBatch.VertexBuffer]);
}

/// @func bbmod_static_batch_render(_static_batch, _material)
/// @desc Submits a StaticBatch for rendering.
/// @param {array} _static_batch A StaticBatch structure.
/// @param {array} _material A Material structure.
function bbmod_static_batch_render(_static_batch, _material)
{
	var _render_pass = global.bbmod_render_pass;

	if ((_material[BBMOD_EMaterial.RenderPath] & _render_pass) == 0)
	{
		// Do not render the mesh if it doesn't use a material that can be used
		// in the current render path.
		return;
	}

	bbmod_material_apply(_material);
	var _tex_base = _material[BBMOD_EMaterial.BaseOpacity];
	vertex_submit(_static_batch[BBMOD_EStaticBatch.VertexBuffer], pr_trianglelist, _tex_base);
}

/// @func BBMOD_StaticBatch(_vformat)
/// @desc An OOP wrapper around BBMOD_EStaticBatch.
/// @param {real} _vformat The vertex format of the static batch. Must not have
/// bones!
function BBMOD_StaticBatch(_vformat) constructor
{
	/// @var {array} A BBMOD_EStaticBatch that this struct wraps.
	static_batch = bbmod_static_batch_create(_vformat);

	static start = function () {
		bbmod_static_batch_begin(static_batch);
	};

	/// @param {BBMOD_Model} _model The model.
	/// @param {array} _transform A transformation matrix of the model.
	static add = function (_model, _transform) {
		bbmod_static_batch_add(static_batch, _model.model, _transform);
	};

	static finish = function () {
		bbmod_static_batch_end(static_batch);
	};

	static freeze = function () {
		bbmod_static_batch_freeze(static_batch);
	};

	/// @param {array} _material A Material structure.
	static render = function (_material) {
		bbmod_static_batch_render(static_batch, _material);
	};
}