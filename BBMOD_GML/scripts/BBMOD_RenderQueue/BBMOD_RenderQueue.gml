/// @module Core

/// @func bbmod_render_queues_get()
///
/// @desc Retrieves a read-only array of existing render queues, sorted by
/// their priority in an asceding order.
///
/// @return {Array<Struct.BBMOD_RenderQueue>} The array of render queues.
///
/// @see BBMOD_RenderQueue
function bbmod_render_queues_get()
{
	gml_pragma("forceinline");
	static _renderQueues = [];
	return _renderQueues;
}


/// @func BBMOD_RenderQueue([_name[, _priority]])
///
/// @extends BBMOD_Class
///
/// @desc A cointainer of render commands.
///
/// @param {String} [_name] The name of the render queue. Defaults to
/// "RenderQueue" + number of created render queues - 1 (e.g. "RenderQueue0",
/// "RenderQueue1" etc.) if `undefined`.
/// @param {Real} [_priority] The priority of the render queue. Defaults to 0.
///
/// @see bbmod_render_queue_get_default
/// @see BBMOD_ERenderCommand
function BBMOD_RenderQueue(_name=undefined, _priority=0)
	: BBMOD_Class() constructor
{
	BBMOD_CLASS_GENERATED_BODY;

	static Class_destroy = destroy;

	static IdNext = 0;

	/// @var {String} The name of the render queue. This can be useful for
	/// debugging purposes.
	Name = _name ?? ("RenderQueue" + string(IdNext++));

	/// @var {Real} The priority of the render queue. Render queues with lower
	/// priority come first in the array returned by {@link bbmod_render_queues_get}.
	/// @readonly
	Priority = _priority;

	/// @var {Array<Array>}
	/// @see BBMOD_ERenderCommand
	/// @private
	__renderCommands = [];

	/// @var {Real}
	/// @private
	__index = 0;

	/// @var {Real} Render passes that the queue has commands for.
	/// @private
	__renderPasses = 0;

	/// @func __get_next(_size)
	///
	/// @desc Retreives next render command available to reuse.
	///
	/// @param {Real} _size The size of the render command.
	///
	/// @return {Array} The render command.
	///
	/// @private
	static __get_next = function (_size)
	{
		gml_pragma("forceinline");
		var _command;
		if (array_length(__renderCommands) > __index)
		{
			_command = __renderCommands[__index++];
			if (array_length(_command) < _size)
			{
				array_resize(_command, _size);
			}
		}
		else
		{
			_command = array_create(_size);
			array_push(__renderCommands, _command);
			++__index;
		}
		return _command;
	};

	/// @func set_priority(_p)
	///
	/// @desc Changes the priority of the render queue. Render queues with lower
	/// priority come first in the array returned by {@link bbmod_render_queues_get}.
	///
	/// @param {Real} _p The new priority of the render queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static set_priority = function (_p)
	{
		gml_pragma("forceinline");
		Priority = _p;
		__bbmod_reindex_render_queues();
		return self;
	};

	/// @func ApplyMaterial(_material, _vertexFormat[, _enabledPasses])
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ApplyMaterial} command into
	/// the queue.
	///
	/// @param {Struct.BBMOD_Material} _material The material to apply.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The vertex format of
	/// models that will be rendered using this material.
	/// @param {Real} [_enabledPasses] Mask of enabled rendering passes. The
	/// material will not be applied if the current rendering pass is not one
	/// of them.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static ApplyMaterial = function (_material, _vertexFormat, _enabledPasses=~0)
	{
		gml_pragma("forceinline");
		__renderPasses |= _material.RenderPass;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.ApplyMaterial;
		_command[@ 1] = global.__bbmodMaterialProps;
		_command[@ 2] = _vertexFormat;
		_command[@ 3] = _material;
		_command[@ 4] = _enabledPasses;
		return self;
	};

	/// @func apply_material(_material, _vertexFormat[, _enabledPasses])
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ApplyMaterial} command into
	/// the queue.
	///
	/// @param {Struct.BBMOD_Material} _material The material to apply.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The vertex format of
	/// models that will be rendered using this material.
	/// @param {Real} [_enabledPasses] Mask of enabled rendering passes. The
	/// material will not be applied if the current rendering pass is not one
	/// of them.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.ApplyMaterial} instead.
	static apply_material = function (_material, _vertexFormat, _enabledPasses=~0)
	{
		gml_pragma("forceinline");
		return ApplyMaterial(_material, _vertexFormat, _enabledPasses);
	};

	/// @func ApplyMaterialProps(_materialPropertyBlock)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ApplyMaterialProps} command
	/// into the queue.
	///
	/// @param {Struct.BBMOD_MaterialPropertyBlock} _materialPropertyBlock The
	/// material property block to apply.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static ApplyMaterialProps = function (_materialPropertyBlock)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.ApplyMaterialProps;
		_command[@ 1] = _materialPropertyBlock;
		return self;
	};

	/// @func apply_material_props(_materialPropertyBlock)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ApplyMaterialProps} command
	/// into the queue.
	///
	/// @param {Struct.BBMOD_MaterialPropertyBlock} _materialPropertyBlock The
	/// material property block to apply.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.ApplyMaterialProps}
	/// instead.
	static apply_material_props = function (_materialPropertyBlock)
	{
		gml_pragma("forceinline");
		return ApplyMaterialProps(_materialPropertyBlock);
	};

	/// @func BeginConditionalBlock()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.BeginConditionalBlock} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static BeginConditionalBlock = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.BeginConditionalBlock;
		return self;
	};

	/// @func begin_conditional_block()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.BeginConditionalBlock} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.BeginConditionalBlock}
	/// instead.
	static begin_conditional_block = function ()
	{
		gml_pragma("forceinline");
		return BeginConditionalBlock();
	};

	/// @func CheckRenderPass(_passes)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.CheckRenderPass} command into
	/// the queue.
	///
	/// @param {Real} [_passes] Mask of allowed rendering passes.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static CheckRenderPass = function (_passes)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.CheckRenderPass;
		_command[@ 1] = _passes;
		return self;
	};

	/// @func check_render_pass(_passes)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.CheckRenderPass} command into
	/// the queue.
	///
	/// @param {Real} [_passes] Mask of allowed rendering passes.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.CheckRenderPass} instead.
	static check_render_pass = function (_passes)
	{
		gml_pragma("forceinline");
		return CheckRenderPass(_passes);
	};

	/// @func DrawMesh(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMesh} command into the
	/// queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawMesh = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix)
	{
		gml_pragma("forceinline");
		__renderPasses |= _material.RenderPass;
		var _command = __get_next(9);
		_command[@ 0] = BBMOD_ERenderCommand.DrawMesh;
		_command[@ 1] = global.__bbmodInstanceID;
		_command[@ 2] = global.__bbmodMaterialProps;
		_command[@ 3] = _vertexFormat;
		_command[@ 4] = _material;
		_command[@ 5] = _matrix;
		_command[@ 6] = _materialIndex;
		_command[@ 7] = _primitiveType;
		_command[@ 8] = _vertexBuffer;
		return self;
	};

	/// @func draw_mesh(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMesh} command into the
	/// queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.DrawMesh} instead.
	static draw_mesh = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix)
	{
		gml_pragma("forceinline");
		return DrawMesh(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix);
	};

	/// @func DrawMeshAnimated(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _boneTransform)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMeshAnimated} command into
	/// the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	/// @param {Array<Real>} _boneTransform An array with bone transformation
	/// data.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawMeshAnimated = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _boneTransform)
	{
		gml_pragma("forceinline");
		__renderPasses |= _material.RenderPass;
		var _command = __get_next(10);
		_command[@ 0] = BBMOD_ERenderCommand.DrawMeshAnimated;
		_command[@ 1] = global.__bbmodInstanceID;
		_command[@ 2] = global.__bbmodMaterialProps;
		_command[@ 3] = _vertexFormat;
		_command[@ 4] = _material;
		_command[@ 5] = _matrix;
		_command[@ 6] = _boneTransform;
		_command[@ 7] = _materialIndex;
		_command[@ 8] = _primitiveType;
		_command[@ 9] = _vertexBuffer;
		return self;
	};

	/// @func draw_mesh_animated(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _boneTransform)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMeshAnimated} command into
	/// the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	/// @param {Array<Real>} _boneTransform An array with bone transformation
	/// data.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.DrawMeshAnimated} instead.
	static draw_mesh_animated = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _boneTransform)
	{
		gml_pragma("forceinline");
		return DrawMeshAnimated(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _boneTransform);
	};

	/// @func DrawMeshBatched(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _batchData)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMeshBatched} command into
	/// the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	/// @param {Array<Real>, Array<Array<Real>>} _batchData Either a single array
	/// of batch data or an array of arrays of batch data.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawMeshBatched = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _batchData)
	{
		gml_pragma("forceinline");
		__renderPasses |= _material.RenderPass;
		var _command = __get_next(9);
		_command[@ 0] = BBMOD_ERenderCommand.DrawMeshBatched;
		_command[@ 1] = (global.__bbmodInstanceIDBatch != undefined)
				? global.__bbmodInstanceIDBatch
				: global.__bbmodInstanceID;
		_command[@ 2] = global.__bbmodMaterialProps;
		_command[@ 3] = _vertexFormat;
		_command[@ 4] = _material;
		_command[@ 5] = _matrix;
		_command[@ 6] = _batchData;
		_command[@ 7] = _primitiveType;
		_command[@ 8] = _vertexBuffer;
		return self;
	};

	/// @func draw_mesh_batched(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _batchData)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawMeshBatched} command into
	/// the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to draw.
	/// @param {Struct.BBMOD_VertexFormat} _vertexFormat The format of the vertex buffer.
	/// @param {Constant.PrimitiveType} _primitiveType The primitive type of
	/// the mesh.
	/// @param {Real} _materialIndex The material's index within the material array.
	/// @param {Struct.BBMOD_Material} _material The material to use.
	/// @param {Array<Real>} _matrix The world matrix.
	/// @param {Array<Real>, Array<Array<Real>>} _batchData Either a single array
	/// of batch data or an array of arrays of batch data.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.DrawMeshBatched} instead.
	static draw_mesh_batched = function (_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _batchData)
	{
		gml_pragma("forceinline");
		return DrawMeshBatched(_vertexBuffer, _vertexFormat, _primitiveType, _materialIndex, _material, _matrix, _batchData);
	};

	/// @func DrawSprite(_sprite, _subimg, _x, _y)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSprite} command into the
	/// queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSprite = function (_sprite, _subimg, _x, _y)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSprite;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimg;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		return self;
	};

	/// @func DrawSpriteExt(_sprite, _subimg, _x, _y, _xscale, _yscale, _rot, _col, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteExt} command into the
	/// queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _xscale The horizontal scaling of the sprite.
	/// @param {Real} _yscale The vertical scaling of the sprite.
	/// @param {Real} _rot The rotation of the sprite.
	/// @param {Constant.Color} _col The color with which to blend the sprite.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteExt = function (
		_sprite, _subimg, _x, _y, _xscale, _yscale, _rot, _col, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(10);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpriteExt;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimage;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		_command[@ 5] = _xscale;
		_command[@ 6] = _yscale;
		_command[@ 7] = _rot;
		_command[@ 8] = _col;
		_command[@ 9] = _alpha;
		return self;
	};

	/// @func DrawSpriteGeneral(_sprite, _subimg, _left, _top, _width, _height, _x, _y, _xscale, _yscale, _rot, _c1, _c2, _c3, _c4, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteGeneral} command into
	/// the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _left The x position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _top The y position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _width The width of the area to draw.
	/// @param {Real} _height The height of the area to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _xscale The horizontal scaling of the sprite.
	/// @param {Real} _yscale The vertical scaling of the sprite.
	/// @param {Real} _rot The rotation of the sprite.
	/// @param {Constant.Color} _c1 The color with which to blend the top left
	/// area of the sprite.
	/// @param {Constant.Color} _c2 The color with which to blend the top right
	/// area of the sprite.
	/// @param {Constant.Color} _c3 The color with which to blend the bottom
	/// right area of the sprite.
	/// @param {Constant.Color} _c4 The color with which to blend the bottom
	/// left area of the sprite.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteGeneral = function (
		_sprite, _subimg, _left, _top, _width, _height, _x, _y, _xscale, _yscale,
		_rot, _c1, _c2, _c3, _c4, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(17);
		_command[@  0] = BBMOD_ERenderCommand.DrawSpriteGeneral;
		_command[@  1] = _sprite;
		_command[@  2] = _subimage;
		_command[@  3] = _left;
		_command[@  4] = _top;
		_command[@  5] = _width;
		_command[@  6] = _height;
		_command[@  7] = _x;
		_command[@  8] = _y;
		_command[@  9] = _xscale;
		_command[@ 10] = _yscale;
		_command[@ 11] = _rot;
		_command[@ 12] = _c1;
		_command[@ 13] = _c2;
		_command[@ 14] = _c3;
		_command[@ 15] = _c4;
		_command[@ 16] = _alpha;
		return self;
	};

	/// @func DrawSpritePart(_sprite, _subimg, _left, _top, _width, _height, _x, _y)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpritePart} command into
	/// the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _left The x position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _top The y position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _width The width of the area to draw.
	/// @param {Real} _height The height of the area to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpritePart = function (
		_sprite, _subimg, _left, _top, _width, _height, _x, _y)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(9);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpritePart;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimage;
		_command[@ 3] = _left;
		_command[@ 4] = _top;
		_command[@ 5] = _width;
		_command[@ 6] = _height;
		_command[@ 7] = _x;
		_command[@ 8] = _y;
		return self;
	};

	/// @func DrawSpritePartExt(_sprite, _subimg, _left, _top, _width, _height, _x, _y, _xscale, _yscale, _col, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpritePartExt} command into
	/// the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _left The x position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _top The y position on the sprite of the top left corner
	/// of the area to draw.
	/// @param {Real} _width The width of the area to draw.
	/// @param {Real} _height The height of the area to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _xscale The horizontal scaling of the sprite.
	/// @param {Real} _yscale The vertical scaling of the sprite.
	/// @param {Constant.Color} _col The color with which to blend the sprite.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpritePartExt = function (
		_sprite, _subimg, _left, _top, _width, _height, _x, _y, _xscale, _yscale,
		_col, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(13);
		_command[@  0] = BBMOD_ERenderCommand.DrawSpritePartExt;
		_command[@  1] = _sprite;
		_command[@  2] = _subimg;
		_command[@  3] = _left;
		_command[@  4] = _top;
		_command[@  5] = _width;
		_command[@  6] = _height;
		_command[@  7] = _x;
		_command[@  8] = _y;
		_command[@  9] = _xscale;
		_command[@ 10] = _yscale;
		_command[@ 11] = _col;
		_command[@ 12] = _alpha;
		return self;
	};

	/// @func DrawSpritePos(_sprite, _subimg, _x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpritePos} command into the
	/// queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x1 The first x coordinate.
	/// @param {Real} _y1 The first y coordinate.
	/// @param {Real} _x2 The second x coordinate.
	/// @param {Real} _y2 The second y coordinate.
	/// @param {Real} _x3 The third x coordinate.
	/// @param {Real} _y3 The third y coordinate.
	/// @param {Real} _x4 The fourth x coordinate.
	/// @param {Real} _y4 The fourth y coordinate.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpritePos = function (
		_sprite, _subimg, _x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(12);
		_command[@  0] = BBMOD_ERenderCommand.DrawSpritePos;
		_command[@  1] = _sprite;
		_command[@  2] = _subimg;
		_command[@  3] = _x1;
		_command[@  4] = _y1;
		_command[@  5] = _x2;
		_command[@  6] = _y2;
		_command[@  7] = _x3;
		_command[@  8] = _y3;
		_command[@  9] = _x4;
		_command[@ 10] = _y4;
		_command[@ 11] = _alpha;
		return self;
	};

	/// @func DrawSpriteStretched(_sprite, _subimg, _x, _y, _w, _h)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteStretched} command
	/// into the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _w The width of the area the stretched sprite will occupy.
	/// @param {Real} _h The height of the area the stretched sprite will occupy.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteStretched = function (_sprite, _subimg, _x, _y, _w, _h)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(7);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpriteStretched;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimg;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		_command[@ 5] = _w;
		_command[@ 6] = _h;
		return self;
	};

	/// @func DrawSpriteStretchedExt(_sprite, _subimg, _x, _y, _w, _h, _col, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteStretchedExt} command
	/// into the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _w The width of the area the stretched sprite will occupy.
	/// @param {Real} _h The height of the area the stretched sprite will occupy.
	/// @param {Constant.Color} _col The color with which to blend the sprite.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteStretchedExt = function (
		_sprite, _subimg, _x, _y, _w, _h, _col, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(9);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpriteStretchedExt;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimg;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		_command[@ 5] = _w;
		_command[@ 6] = _h;
		_command[@ 7] = _col;
		_command[@ 8] = _alpha;
		return self;
	};

	/// @func DrawSpriteTiled(_sprite, _subimg, _x, _y)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteTiled} command into
	/// the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteTiled = function (_sprite, _subimg, _x, _y)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpriteTiled;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimg;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		return self;
	};

	/// @func DrawSpriteTiledExt(_sprite, _subimg, _x, _y, _xscale, _yscale, _col, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.DrawSpriteTiledExt} command
	/// into the queue.
	///
	/// @param {Asset.GMSprite} _sprite The sprite to draw.
	/// @param {Real} _subimg The sub-image of the sprite to draw.
	/// @param {Real} _x The x coordinate of where to draw the sprite.
	/// @param {Real} _y The y coordinate of where to draw the sprite.
	/// @param {Real} _xscale The horizontal scaling of the sprite.
	/// @param {Real} _yscale The vertical scaling of the sprite.
	/// @param {Constant.Color} _col The color with which to blend the sprite.
	/// @param {Real} _alpha The alpha of the sprite.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static DrawSpriteTiledExt = function (
		_sprite, _subimg, _x, _y, _xscale, _yscale, _col, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(9);
		_command[@ 0] = BBMOD_ERenderCommand.DrawSpriteTiledExt;
		_command[@ 1] = _sprite;
		_command[@ 2] = _subimg;
		_command[@ 3] = _x;
		_command[@ 4] = _y;
		_command[@ 5] = _xscale;
		_command[@ 6] = _yscale;
		_command[@ 7] = _col;
		_command[@ 8] = _alpha;
		return self;
	};

	/// @func EndConditionalBlock()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.EndConditionalBlock} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static EndConditionalBlock = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.EndConditionalBlock;
		return self;
	};

	/// @func end_conditional_block()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.EndConditionalBlock} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.EndConditionalBlock}
	/// instead.
	static end_conditional_block = function ()
	{
		gml_pragma("forceinline");
		return EndConditionalBlock();
	};

	/// @func PopGpuState()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.PopGpuState} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static PopGpuState = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.PopGpuState;
		return self;
	};

	/// @func pop_gpu_state()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.PopGpuState} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.PopGpuState} instead.
	static pop_gpu_state = function ()
	{
		gml_pragma("forceinline");
		return PopGpuState();
	};

	/// @func PushGpuState()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.PushGpuState} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static PushGpuState = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.PushGpuState;
		return self;
	};

	/// @func push_gpu_state()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.PushGpuState} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.PushGpuState} instead.
	static push_gpu_state = function ()
	{
		gml_pragma("forceinline");
		return PushGpuState();
	};

	/// @func ResetMaterial()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetMaterial} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static ResetMaterial = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.ResetMaterial;
		return self;
	};

	/// @func reset_material()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetMaterial} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.ResetMaterial} instead.
	static reset_material = function ()
	{
		gml_pragma("forceinline");
		return ResetMaterial();
	};

	/// @func ResetMaterialProps()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetMaterialProps} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static ResetMaterialProps = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.ResetMaterialProps;
		return self;
	};

	/// @func reset_material_props()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetMaterialProps} command
	/// into the queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.ResetMaterialProps}
	/// instead.
	static reset_material_props = function ()
	{
		gml_pragma("forceinline");
		return ResetMaterialProps();
	};

	/// @func ResetShader()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetShader} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static ResetShader = function ()
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(1);
		_command[@ 0] = BBMOD_ERenderCommand.ResetShader;
		return self;
	};

	/// @func reset_shader()
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.ResetShader} command into the
	/// queue.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.ResetShader} instead.
	static reset_shader = function ()
	{
		gml_pragma("forceinline");
		return ResetShader();
	};

	/// @func SetGpuAlphaTestEnable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuAlphaTestEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable alpha testing.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuAlphaTestEnable = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuAlphaTestEnable;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_alphatestenable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuAlphaTestEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable alpha testing.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuAlphaTestEnable}
	/// instead.
	static set_gpu_alphatestenable = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuAlphaTestEnable(_enable);
	};

	/// @func SetGpuAlphaTestRef(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuAlphaTestRef} command
	/// into the queue.
	///
	/// @param {Real} _value The new alpha test threshold value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuAlphaTestRef = function (_value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuAlphaTestRef;
		_command[@ 1] = _value;
		return self;
	};

	/// @func set_gpu_alphatestref(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuAlphaTestRef} command
	/// into the queue.
	///
	/// @param {Real} _value The new alpha test threshold value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuAlphaTestRef}
	/// instead.
	static set_gpu_alphatestref = function (_value)
	{
		gml_pragma("forceinline");
		return SetGpuAlphaTestRef(_value);
	};

	/// @func SetGpuBlendEnable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendEnable} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable alpha blending.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuBlendEnable = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuBlendEnable;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_blendenable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendEnable} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable alpha blending.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuBlendEnable}
	/// instead.
	static set_gpu_blendenable = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuBlendEnable(_enable);
	};

	/// @func SetGpuBlendMode(_blendmode)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendMode} command into
	/// the queue.
	///
	/// @param {Constant.BlendMode} _blendmode The new blend mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuBlendMode = function (_blendmode)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuBlendMode;
		_command[@ 1] = _blendmode;
		return self;
	};

	/// @func set_gpu_blendmode(_blendmode)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendMode} command into
	/// the queue.
	///
	/// @param {Constant.BlendMode} _blendmode The new blend mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuBlendMode}
	/// instead.
	static set_gpu_blendmode = function (_blendmode)
	{
		gml_pragma("forceinline");
		return SetGpuBlendMode(_blendmode);
	};

	/// @func SetGpuBlendModeExt(_src, _dest)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendModeExt} command
	/// into the queue.
	///
	/// @param {Constant.BlendMode} _src Source blend mode.
	/// @param {Constant.BlendMode} _dest Destination blend mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuBlendModeExt = function (_src, _dest)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuBlendModeExt;
		_command[@ 1] = _src;
		_command[@ 2] = _dest;
		return self;
	};

	/// @func set_gpu_blendmode_ext(_src, _dest)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendModeExt} command
	/// into the queue.
	///
	/// @param {Constant.BlendMode} _src Source blend mode.
	/// @param {Constant.BlendMode} _dest Destination blend mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuBlendModeExt}
	/// instead.
	static set_gpu_blendmode_ext = function (_src, _dest)
	{
		gml_pragma("forceinline");
		return SetGpuBlendModeExt(_src, _dest);
	};

	/// @func set_gpu_blendmode_ext_sepalpha(_src, _dest, _srcalpha, _destalpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendModeExtSepAlpha}
	/// command into the queue.
	///
	/// @param {Constant.BlendMode} _src Source blend mode.
	/// @param {Constant.BlendMode} _dest Destination blend mode.
	/// @param {Constant.BlendMode} _srcalpha Blend mode for source alpha channel.
	/// @param {Constant.BlendMode} _destalpha Blend mode for destination alpha
	/// channel.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuBlendModeExtSepAlpha = function (_src, _dest, _srcalpha, _destalpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuBlendModeExtSepAlpha;
		_command[@ 1] = _src;
		_command[@ 2] = _dest;
		_command[@ 3] = _srcalpha;
		_command[@ 4] = _destalpha;
		return self;
	};

	/// @func set_gpu_blendmode_ext_sepalpha(_src, _dest, _srcalpha, _destalpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuBlendModeExtSepAlpha}
	/// command into the queue.
	///
	/// @param {Constant.BlendMode} _src Source blend mode.
	/// @param {Constant.BlendMode} _dest Destination blend mode.
	/// @param {Constant.BlendMode} _srcalpha Blend mode for source alpha channel.
	/// @param {Constant.BlendMode} _destalpha Blend mode for destination alpha
	/// channel.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuBlendModeExtSepAlpha}
	/// instead.
	static set_gpu_blendmode_ext_sepalpha = function (_src, _dest, _srcalpha, _destalpha)
	{
		gml_pragma("forceinline");
		return SetGpuBlendModeExtSepAlpha(_src, _dest, _srcalpha, _destalpha);
	};

	/// @func SetGpuColorWriteEnable(_red, _green, _blue, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuColorWriteEnable} command
	/// into the queue.
	///
	/// @param {Bool} _red Use `true` to enable writing to the red color
	/// channel.
	/// @param {Bool} _green Use `true` to enable writing to the green color
	/// channel.
	/// @param {Bool} _blue Use `true` to enable writing to the blue color
	/// channel.
	/// @param {Bool} _alpha Use `true` to enable writing to the alpha channel.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuColorWriteEnable = function (_red, _green, _blue, _alpha)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuColorWriteEnable;
		_command[@ 1] = _red;
		_command[@ 2] = _green;
		_command[@ 3] = _blue;
		_command[@ 4] = _alpha;
		return self;
	};

	/// @func set_gpu_colorwriteenable(_red, _green, _blue, _alpha)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuColorWriteEnable} command
	/// into the queue.
	///
	/// @param {Bool} _red Use `true` to enable writing to the red color
	/// channel.
	/// @param {Bool} _green Use `true` to enable writing to the green color
	/// channel.
	/// @param {Bool} _blue Use `true` to enable writing to the blue color
	/// channel.
	/// @param {Bool} _alpha Use `true` to enable writing to the alpha channel.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuColorWriteEnable}
	/// instead.
	static set_gpu_colorwriteenable = function (_red, _green, _blue, _alpha)
	{
		gml_pragma("forceinline");
		return SetGpuColorWriteEnable(_red, _green, _blue, _alpha);
	};

	/// @func SetGpuCullMode(_cullmode)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuCullMode} command into
	/// the queue.
	///
	/// @param {Constant.CullMode} _cullmode The new coll mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuCullMode = function (_cullmode)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuCullMode;
		_command[@ 1] = _cullmode;
		return self;
	};

	/// @func set_gpu_cullmode(_cullmode)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuCullMode} command into
	/// the queue.
	///
	/// @param {Constant.CullMode} _cullmode The new coll mode.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuCullMode}
	/// instead.
	static set_gpu_cullmode = function (_cullmode)
	{
		gml_pragma("forceinline");
		return SetGpuCullMode(_cullmode);
	};

	/// @func SetGpuFog(_enable, _color, _start, _end)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuFog} command into the
	/// queue.
	///
	/// @param {Bool} _enable Use `true` to enable fog.
	/// @param {Constant.Color} _color The color of the fog.
	/// @param {Real} _start The distance from the camera at which the fog
	/// starts.
	/// @param {Real} _end The distance from the camera at which the fog reaches
	/// maximum intensity.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuFog = function (_enable, _color, _start, _end)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuFog;
		_command[@ 1] = _enable;
		_command[@ 2] = _color;
		_command[@ 3] = _start;
		_command[@ 4] = _end;
		return self;
	};

	/// @func set_gpu_fog(_enable, _color, _start, _end)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuFog} command into the
	/// queue.
	///
	/// @param {Bool} _enable Use `true` to enable fog.
	/// @param {Constant.Color} _color The color of the fog.
	/// @param {Real} _start The distance from the camera at which the fog
	/// starts.
	/// @param {Real} _end The distance from the camera at which the fog reaches
	/// maximum intensity.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuFog}
	/// instead.
	static set_gpu_fog = function (_enable, _color, _start, _end)
	{
		gml_pragma("forceinline");
		return SetGpuFog(_enable, _color, _start, _end);
	};

	/// @func SetGpuTexFilter(_linear)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexFilter} command into
	/// the queue.
	///
	/// @param {Bool} _linear Use `true` to enable linear texture filtering.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexFilter = function (_linear)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexFilter;
		_command[@ 1] = _linear;
		return self;
	};

	/// @func set_gpu_tex_filter(_linear)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexFilter} command into
	/// the queue.
	///
	/// @param {Bool} _linear Use `true` to enable linear texture filtering.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexFilter}
	/// instead.
	static set_gpu_tex_filter = function (_linear)
	{
		gml_pragma("forceinline");
		return SetGpuTexFilter(_linear);
	};

	/// @func SetGpuTexFilterExt(_name, _linear)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexFilterExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _linear Use `true` to enable linear texture filtering for
	/// the sampler.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexFilterExt = function (_name, _linear)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexFilterExt;
		_command[@ 1] = _name;
		_command[@ 2] = _linear;
		return self;
	};

	/// @func set_gpu_tex_filter_ext(_name, _linear)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexFilterExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _linear Use `true` to enable linear texture filtering for
	/// the sampler.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexFilterExt}
	/// instead.
	static set_gpu_tex_filter_ext = function (_name, _linear)
	{
		gml_pragma("forceinline");
		return SetGpuTexFilterExt(_name, _linear);
	};

	/// @func SetGpuTexMaxAniso(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxAniso} command into
	/// the queue.
	///
	/// @param {Real} _value The maximum level of anisotropy.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static set_gpu_tex_max_aniso = function (_value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMaxAniso;
		_command[@ 1] = _value;
		return self;
	};

	/// @func set_gpu_tex_max_aniso(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxAniso} command into
	/// the queue.
	///
	/// @param {Real} _value The maximum level of anisotropy.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMaxAniso}
	/// instead.
	static set_gpu_tex_max_aniso = function (_value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMaxAniso(_value);
	};

	/// @func SetGpuTexMaxAnisoExt(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxAnisoExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The maximum level of anisotropy.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMaxAnisoExt = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMaxAnisoExt;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_gpu_tex_max_aniso_ext(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxAnisoExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The maximum level of anisotropy.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMaxAnisoExt}
	/// instead.
	static set_gpu_tex_max_aniso_ext = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMaxAnisoExt(_name, _value);
	};

	/// @func SetGpuTexMaxMip(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxMip} command into
	/// the queue.
	///
	/// @param {Real} _value The maximum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMaxMip = function (_value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMaxMip;
		_command[@ 1] = _value;
		return self;
	};

	/// @func set_gpu_tex_max_mip(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxMip} command into
	/// the queue.
	///
	/// @param {Real} _value The maximum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMaxMip}
	/// instead.
	static set_gpu_tex_max_mip = function (_value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMaxMip(_value);
	};

	/// @func SetGpuTexMaxMipExt(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxMipExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The maximum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMaxMipExt = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMaxMipExt;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_gpu_tex_max_mip_ext(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMaxMipExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The maximum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMaxMipExt}
	/// instead.
	static set_gpu_tex_max_mip_ext = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMaxMipExt(_name, _value);
	};

	/// @func SetGpuTexMinMip(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMinMip} command into
	/// the queue.
	///
	/// @param {Real} _value The minimum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMinMip = function (_value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMinMip;
		_command[@ 1] = _value;
		return self;
	};

	/// @func set_gpu_tex_min_mip(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMinMip} command into
	/// the queue.
	///
	/// @param {Real} _value The minimum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMinMip}
	/// instead.
	static set_gpu_tex_min_mip = function (_value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMinMip(_value);
	};

	/// @func SetGpuTexMinMipExt(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMinMipExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The minimum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMinMipExt = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMinMipExt;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_gpu_tex_min_mip_ext(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMinMipExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The minimum mipmap level.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMinMipExt}
	/// instead.
	static set_gpu_tex_min_mip_ext = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMinMipExt(_name, _value);
	};

	/// @func SetGpuTexMipBias(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipBias} command into
	/// the queue.
	///
	/// @param {Real} _value The mipmap bias.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipBias = function (_value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipBias;
		_command[@ 1] = _value;
		return self;
	};

	/// @func set_gpu_tex_mip_bias(_value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipBias} command into
	/// the queue.
	///
	/// @param {Real} _value The mipmap bias.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipBias}
	/// instead.
	static set_gpu_tex_mip_bias = function(_value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipBias(_value);
	};

	/// @func SetGpuTexMipBiasExt(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipBiasExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The mipmap bias.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipBiasExt = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipBiasExt;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_gpu_tex_mip_bias_ext(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipBiasExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Real} _value The mipmap bias.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipBiasExt}
	/// instead.
	static set_gpu_tex_mip_bias_ext = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipBiasExt(_name, _value);
	};

	/// @func SetGpuTexMipEnable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable mipmapping.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipEnable = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipEnable;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_tex_mip_enable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable mipmapping.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipEnable}
	/// instead.
	static set_gpu_tex_mip_enable = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipEnable(_enable);
	};

	/// @func SetGpuTexMipEnableExt(_name, _enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipEnableExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _enable Use `true` to enable mipmapping.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipEnableExt = function (_name, _enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipEnableExt;
		_command[@ 1] = _name;
		_command[@ 2] = _enable;
		return self;
	};

	/// @func set_gpu_tex_mip_enable_ext(_name, _enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipEnableExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _enable Use `true` to enable mipmapping.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipEnableExt}
	/// instead.
	static set_gpu_tex_mip_enable_ext = function (_name, _enable)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipEnableExt(_name, _enable);
	};

	/// @func SetGpuTexMipFilter(_filter)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipFilter} command
	/// into the queue.
	///
	/// @param {Constant.MipFilter} _filter The mipmap filter.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipFilter = function (_filter)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipFilter;
		_command[@ 1] = _filter;
		return self;
	};

	/// @func set_gpu_tex_mip_filter(_filter)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipFilter} command
	/// into the queue.
	///
	/// @param {Constant.MipFilter} _filter The mipmap filter.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipFilter}
	/// instead.
	static set_gpu_tex_mip_filter = function (_filter)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipFilter(_filter);
	};

	/// @func SetGpuTexMipFilterExt(_name, _filter)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipFilterExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Constant.MipFilter} _filter The mipmap filter.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexMipFilterExt = function (_name, _filter)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexMipFilterExt;
		_command[@ 1] = _name;
		_command[@ 2] = _filter;
		return self;
	};

	/// @func set_gpu_tex_mip_filter_ext(_name, _filter)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexMipFilterExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Constant.MipFilter} _filter The mipmap filter.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexMipFilterExt}
	/// instead.
	static set_gpu_tex_mip_filter_ext = function (_name, _filter)
	{
		gml_pragma("forceinline");
		return SetGpuTexMipFilterExt(_name, _filter);
	};

	/// @func SetGpuTexRepeat(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexRepeat} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable texture repeat.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static set_gpu_tex_repeat = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexRepeat;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_tex_repeat(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexRepeat} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable texture repeat.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexRepeat}
	/// instead.
	static set_gpu_tex_repeat = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuTexRepeat(_enable);
	};

	/// @func SetGpuTexRepeatExt(_name, _enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexRepeatExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _enable Use `true` to enable texture repeat.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuTexRepeatExt = function (_name, _enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuTexRepeatExt;
		_command[@ 1] = _name;
		_command[@ 2] = _enable;
		return self;
	};

	/// @func set_gpu_tex_repeat_ext(_name, _enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuTexRepeatExt} command
	/// into the queue.
	///
	/// @param {String} _name The name of the sampler.
	/// @param {Bool} _enable Use `true` to enable texture repeat.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuTexRepeatExt}
	/// instead.
	static set_gpu_tex_repeat_ext = function (_name, _enable)
	{
		gml_pragma("forceinline");
		return SetGpuTexRepeatExt(_name, _enable);
	};

	/// @func SetGpuZFunc(_func)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZFunc} command into the
	/// queue.
	///
	/// @param {Constant.CmpFunc} _func The depth test function.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuZFunc = function (_func)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuZFunc;
		_command[@ 1] = _func;
		return self;
	};

	/// @func set_gpu_zfunc(_func)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZFunc} command into the
	/// queue.
	///
	/// @param {Constant.CmpFunc} _func The depth test function.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuZFunc}
	/// instead.
	static set_gpu_zfunc = function (_func)
	{
		gml_pragma("forceinline");
		return SetGpuZFunc(_func);
	};

	/// @func SetGpuZTestEnable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZTestEnable} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable testing against the detph
	/// buffer.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuZTestEnable = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuZTestEnable;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_ztestenable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZTestEnable} command into
	/// the queue.
	///
	/// @param {Bool} _enable Use `true` to enable testing against the detph
	/// buffer.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuZTestEnable}
	/// instead.
	static set_gpu_ztestenable = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuZTestEnable(_enable);
	};

	/// @func SetGpuZWriteEnable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZWriteEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable writing to the depth buffer.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetGpuZWriteEnable = function (_enable)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetGpuZWriteEnable;
		_command[@ 1] = _enable;
		return self;
	};

	/// @func set_gpu_zwriteenable(_enable)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetGpuZWriteEnable} command
	/// into the queue.
	///
	/// @param {Bool} _enable Use `true` to enable writing to the depth buffer.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetGpuZWriteEnable}
	/// instead.
	static set_gpu_zwriteenable = function (_enable)
	{
		gml_pragma("forceinline");
		return SetGpuZWriteEnable(_enable);
	};

	/// @func SetMaterialProps(_materialPropertyBlock)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetMaterialProps} command into
	/// the queue.
	///
	/// @param {Struct.BBMOD_MaterialPropertyBlock} _materialPropertyBlock The
	/// material property block to set as the current one.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetMaterialProps = function (_materialPropertyBlock)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetMaterialProps;
		_command[@ 1] = _materialPropertyBlock;
		return self;
	};

	/// @func set_material_props(_materialPropertyBlock)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetMaterialProps} command into
	/// the queue.
	///
	/// @param {Struct.BBMOD_MaterialPropertyBlock} _materialPropertyBlock The
	/// material property block to set as the current one.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetMaterialProps}
	/// instead.
	static set_material_props = function (_materialPropertyBlock)
	{
		gml_pragma("forceinline");
		return SetMaterialProps(_materialPropertyBlock);
	};

	/// @func SetProjectionMatrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetProjectionMatrix} command
	/// into the queue.
	///
	/// @param {Array<Real>} _matrix The new projection matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetProjectionMatrix = function (_matrix)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetProjectionMatrix;
		_command[@ 1] = _matrix;
		return self;
	};

	/// @func set_projection_matrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetProjectionMatrix} command
	/// into the queue.
	///
	/// @param {Array<Real>} _matrix The new projection matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetProjectionMatrix}
	/// instead.
	static set_projection_matrix = function (_matrix)
	{
		gml_pragma("forceinline");
		return SetProjectionMatrix(_matrix);
	};

	/// @func SetSampler(_nameOrIndex, _texture)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetSampler} command into the
	/// queue.
	///
	/// @param {String, Real} _nameOrIndex The name or index of the sampler.
	/// @param {Pointer.Texture} _texture The new texture.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetSampler = function (_nameOrIndex, _texture)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetSampler;
		_command[@ 1] = _nameOrIndex;
		_command[@ 2] = _texture;
		return self;
	};

	/// @func set_sampler(_nameOrIndex, _texture)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetSampler} command into the
	/// queue.
	///
	/// @param {String, Real} _nameOrIndex The name or index of the sampler.
	/// @param {Pointer.Texture} _texture The new texture.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetSampler}
	/// instead.
	static set_sampler = function (_nameOrIndex, _texture)
	{
		gml_pragma("forceinline");
		return SetSampler(_nameOrIndex, _texture);
	};

	/// @func SetShader(_shader)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetShader} command into the
	/// queue.
	///
	/// @param {Asset.GMShader} _shader The shader to set.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetShader = function (_shader)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetShader;
		_command[@ 1] = _shader;
		return self;
	};

	/// @func set_shader(_shader)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetShader} command into the
	/// queue.
	///
	/// @param {Asset.GMShader} _shader The shader to set.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetShader}
	/// instead.
	static set_shader = function (_shader)
	{
		gml_pragma("forceinline");
		return SetShader(_shader);
	};

	/// @func SetUniformFloat(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _value The new uniform value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformFloat = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformFloat;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_uniform_f(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _value The new uniform value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformFloat}
	/// instead.
	static set_uniform_f = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetUniformFloat(_name, _value);
	};

	/// @func SetUniformFloat2(_name, _v1, _v2)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat2} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformFloat2 = function (_name, _v1, _v2)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(4);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformFloat2;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		return self;
	};

	/// @func set_uniform_f2(_name, _v1, _v2)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat2} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformFloat2}
	/// instead.
	static set_uniform_f2 = function (_name, _v1, _v2)
	{
		gml_pragma("forceinline");
		return SetUniformFloat2(_name, _v1, _v2);
	};

	/// @func SetUniformFloat3(_name, _v1, _v2, _v3)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat3} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformFloat3 = function (_name, _v1, _v2, _v3)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformFloat3;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		_command[@ 4] = _v3;
		return self;
	};

	/// @func set_uniform_f3(_name, _v1, _v2, _v3)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat3} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformFloat3}
	/// instead.
	static set_uniform_f3 = function (_name, _v1, _v2, _v3)
	{
		gml_pragma("forceinline");
		return SetUniformFloat3(_name, _v1, _v2, _v3);
	};

	/// @func SetUniformFloat4(_name, _v1, _v2, _v3, _v4)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat4} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	/// @param {Real} _v4 The value of the fourth component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformFloat4 = function (_name, _v1, _v2, _v3, _v4)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(6);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformFloat4;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		_command[@ 4] = _v3;
		_command[@ 5] = _v4;
		return self;
	};

	/// @func set_uniform_f4(_name, _v1, _v2, _v3, _v4)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloat4} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	/// @param {Real} _v4 The value of the fourth component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformFloat4}
	/// instead.
	static set_uniform_f4 = function (_name, _v1, _v2, _v3, _v4)
	{
		gml_pragma("forceinline");
		return SetUniformFloat4(_name, _v1, _v2, _v3, _v4);
	};

	/// @func SetUniformFloatArray(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloatArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformFloatArray = function (_name, _array)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformFloatArray;
		_command[@ 1] = _name;
		_command[@ 2] = _array;
		return self;
	};

	/// @func set_uniform_f_array(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformFloatArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformFloatArray}
	/// instead.
	static set_uniform_f_array = function (_name, _array)
	{
		gml_pragma("forceinline");
		return SetUniformFloatArray(_name, _array);
	};

	/// @func SetUniformInt(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt} command into the
	/// queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _value The new uniform value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformInt = function (_name, _value)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformInt;
		_command[@ 1] = _name;
		_command[@ 2] = _value;
		return self;
	};

	/// @func set_uniform_i(_name, _value)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt} command into the
	/// queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _value The new uniform value.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformInt}
	/// instead.
	static set_uniform_i = function (_name, _value)
	{
		gml_pragma("forceinline");
		return SetUniformInt(_name, _value);
	};

	/// @func SetUniformInt2(_name, _v1, _v2)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt2} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformInt2 = function (_name, _v1, _v2)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(4);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformInt2;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		return self;
	};

	/// @func set_uniform_i2(_name, _v1, _v2)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt2} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformInt2}
	/// instead.
	static set_uniform_i2 = function (_name, _v1, _v2)
	{
		gml_pragma("forceinline");
		return SetUniformInt2(_name, _v1, _v2);
	};

	/// @func SetUniformInt3(_name, _v1, _v2, _v3)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt3} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformInt3 = function (_name, _v1, _v2, _v3)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(5);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformInt3;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		_command[@ 4] = _v3;
		return self;
	};

	/// @func set_uniform_i3(_name, _v1, _v2, _v3)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt3} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformInt3}
	/// instead.
	static set_uniform_i3 = function (_name, _v1, _v2, _v3)
	{
		gml_pragma("forceinline");
		return SetUniformInt3(_name, _v1, _v2, _v3);
	};

	/// @func SetUniformInt4(_name, _v1, _v2, _v3, _v4)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt4} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	/// @param {Real} _v4 The value of the fourth component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformInt4 = function (_name, _v1, _v2, _v3, _v4)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(6);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformInt4;
		_command[@ 1] = _name;
		_command[@ 2] = _v1;
		_command[@ 3] = _v2;
		_command[@ 4] = _v3;
		_command[@ 5] = _v4;
		return self;
	};

	/// @func set_uniform_i4(_name, _v1, _v2, _v3, _v4)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformInt4} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Real} _v1 The value of the first component.
	/// @param {Real} _v2 The value of the second component.
	/// @param {Real} _v3 The value of the third component.
	/// @param {Real} _v4 The value of the fourth component.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformInt4}
	/// instead.
	static set_uniform_i4 = function (_name, _v1, _v2, _v3, _v4)
	{
		gml_pragma("forceinline");
		return SetUniformInt4(_name, _v1, _v2, _v3, _v4);
	};

	/// @func SetUniformIntArray(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformIntArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformIntArray = function (_name, _array)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformIntArray;
		_command[@ 1] = _name;
		_command[@ 2] = _array;
		return self;
	};

	/// @func set_uniform_i_array(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformIntArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformIntArray}
	/// instead.
	static set_uniform_i_array = function (_name, _array)
	{
		gml_pragma("forceinline");
		return SetUniformIntArray(_name, _array);
	};

	/// @func SetUniformMatrix(_name)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformMatrix} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformMatrix = function (_name)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformMatrix;
		_command[@ 1] = _name;
		return self;
	};

	/// @func set_uniform_matrix(_name)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformMatrix} command into
	/// the queue.
	///
	/// @param {String} _name The name of the uniform.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformMatrix}
	/// instead.
	static set_uniform_matrix = function (_name)
	{
		gml_pragma("forceinline");
		return SetUniformMatrix(_name);
	};

	/// @func SetUniformMatrixArray(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformMatrixArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetUniformMatrixArray = function (_name, _array)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(3);
		_command[@ 0] = BBMOD_ERenderCommand.SetUniformMatrixArray;
		_command[@ 1] = _name;
		_command[@ 2] = _array;
		return self;
	};

	/// @func set_uniform_matrix_array(_name, _array)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetUniformMatrixArray} command
	/// into the queue.
	///
	/// @param {String} _name The name of the uniform.
	/// @param {Array<Real>} _array The array of values.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetUniformMatrixArray}
	/// instead.
	static set_uniform_matrix_array = function (_name, _array)
	{
		gml_pragma("forceinline");
		return SetUniformMatrixArray(_name, _array);
	};

	/// @func SetViewMatrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetViewMatrix} command into the
	/// queue.
	///
	/// @param {Array<Real>} _matrix The new view matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetViewMatrix = function (_matrix)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetViewMatrix;
		_command[@ 1] = _matrix;
		return self;
	};

	/// @func set_view_matrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetViewMatrix} command into the
	/// queue.
	///
	/// @param {Array<Real>} _matrix The new view matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetViewMatrix}
	/// instead.
	static set_view_matrix = function (_matrix)
	{
		gml_pragma("forceinline");
		return SetViewMatrix(_matrix);
	};

	/// @func SetWorldMatrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetWorldMatrix} command into
	/// the queue.
	///
	/// @param {Array<Real>} _matrix The new world matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SetWorldMatrix = function (_matrix)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(2);
		_command[@ 0] = BBMOD_ERenderCommand.SetWorldMatrix;
		_command[@ 1] = _matrix;
		return self;
	};

	/// @func set_world_matrix(_matrix)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SetWorldMatrix} command into
	/// the queue.
	///
	/// @param {Array<Real>} _matrix The new world matrix.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SetWorldMatrix}
	/// instead.
	static set_world_matrix = function (_matrix)
	{
		gml_pragma("forceinline");
		return SetWorldMatrix(_matrix);
	};

	/// @func SubmitVertexBuffer(_vertexBuffer, _prim, _texture)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SubmitVertexBuffer} command
	/// into the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to submit.
	/// @param {Constant.PrimitiveType} _prim Primitive type of the vertex
	/// buffer.
	/// @param {Pointer.Texture} _texture The texture to use.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	static SubmitVertexBuffer = function (_vertexBuffer, _prim, _texture)
	{
		gml_pragma("forceinline");
		__renderPasses |= 0xFFFFFFFF;
		var _command = __get_next(4);
		_command[@ 0] = BBMOD_ERenderCommand.SubmitVertexBuffer;
		_command[@ 1] = _vertexBuffer;
		_command[@ 2] = _prim;
		_command[@ 3] = _texture;
		return self;
	};

	/// @func submit_vertex_buffer(_vertexBuffer, _prim, _texture)
	///
	/// @desc Adds a {@link BBMOD_ERenderCommand.SubmitVertexBuffer} command
	/// into the queue.
	///
	/// @param {Id.VertexBuffer} _vertexBuffer The vertex buffer to submit.
	/// @param {Constant.PrimitiveType} _prim Primitive type of the vertex
	/// buffer.
	/// @param {Pointer.Texture} _texture The texture to use.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @deprecated Please use {@link BBMOD_RenderQueue.SubmitVertexBuffer}
	/// instead.
	static submit_vertex_buffer = function (_vertexBuffer, _prim, _texture)
	{
		gml_pragma("forceinline");
		return SubmitVertexBuffer(_vertexBuffer, _prim, _texture);
	};

	/// @func is_empty()
	///
	/// @desc Checks whether the render queue is empty.
	///
	/// @return {Bool} Returns `true` if there are no commands in the render
	/// queue.
	static is_empty = function ()
	{
		gml_pragma("forceinline");
		return (__index == 0);
	};

	/// @func has_commands(_renderPass)
	///
	/// @desc Checks whether the render queue has commands for given render pass.
	///
	/// @param {Real} _renderPass The render pass.
	///
	/// @return {Bool} Returns `true` if the render queue has commands for given
	/// render pass.
	///
	/// @see BBMOD_ERenderPass
	static has_commands = function (_renderPass)
	{
		gml_pragma("forceinline");
		return (__renderPasses & (1 << _renderPass));
	};

	/// @func submit([_instances])
	///
	/// @desc Submits render commands.
	///
	/// @param {Id.DsList<Id.Instance>} [_instances] If specified then only
	/// meshes with an instance ID from the list are submitted. Defaults to
	/// `undefined`.
	///
	/// @return {Struct.BBMOD_RenderQueue} Returns `self`.
	///
	/// @see BBMOD_RenderQueue.has_commands
	/// @see BBMOD_RenderQueue.clear
	static submit = function (_instances=undefined)
	{
		if (!has_commands(global.__bbmodRenderPass))
		{
			return self;
		}

		var _commandIndex = 0;
		var _renderCommands = __renderCommands;
		var _condition = false;
		var _skipCounter = 0;
		var _matchCounter = 0;

		repeat (__index)
		{
			var _command = _renderCommands[_commandIndex++];
			var i = 0;
			var _commandType = _command[i++];

			if (_skipCounter > 0)
			{
				switch (_commandType)
				{
				case BBMOD_ERenderCommand.BeginConditionalBlock:
					++_skipCounter;
					break;

				case BBMOD_ERenderCommand.EndConditionalBlock:
					--_skipCounter;
					break;
				}

				continue;
			}

			switch (_commandType)
			{
			case BBMOD_ERenderCommand.ApplyMaterial:
				{
					var _materialPropsOld = global.__bbmodMaterialProps;
					global.__bbmodMaterialProps = _command[i++];
					var _vertexFormat = _command[i++];
					var _material = _command[i++];
					var _enabledPasses = _command[i++];
					if (((1 << bbmod_render_pass_get()) & _enabledPasses) == 0
						|| !_material.apply(_vertexFormat))
					{
						global.__bbmodMaterialProps = _materialPropsOld;
						_condition = false;
						continue;
					}
					global.__bbmodMaterialProps = _materialPropsOld;
				}
				break;

			case BBMOD_ERenderCommand.ApplyMaterialProps:
				_command[i++].apply();
				break;

			case BBMOD_ERenderCommand.BeginConditionalBlock:
				if (!_condition)
				{
					++_skipCounter;
				}
				else
				{
					++_matchCounter;
				}
				break;

			case BBMOD_ERenderCommand.CheckRenderPass:
				if (((1 << bbmod_render_pass_get()) & _command[i++]) == 0)
				{
					_condition = false;
					continue;
				}
				break;

			case BBMOD_ERenderCommand.DrawMesh:
				{
					var _id = _command[i++];
					var _materialPropsOld = global.__bbmodMaterialProps;
					global.__bbmodMaterialProps = _command[i++];
					var _vertexFormat = _command[i++];
					var _material = _command[i++];
					if ((_instances != undefined && ds_list_find_index(_instances, _id) == -1)
						|| !_material.apply(_vertexFormat))
					{
						global.__bbmodMaterialProps = _materialPropsOld;
						_condition = false;
						continue;
					}
					with (BBMOD_SHADER_CURRENT)
					{
						set_instance_id(_id);
						matrix_set(matrix_world, _command[i++]);
						set_material_index(_command[i++]);
					}
					var _primitiveType = _command[i++];
					vertex_submit(_command[i++], _primitiveType, _material.BaseOpacity);
					global.__bbmodMaterialProps = _materialPropsOld;
				}
				break;

			case BBMOD_ERenderCommand.DrawMeshAnimated:
				{
					var _id = _command[i++];
					var _materialPropsOld = global.__bbmodMaterialProps;
					global.__bbmodMaterialProps = _command[i++];
					var _vertexFormat = _command[i++];
					var _material = _command[i++];
					if ((_instances != undefined && ds_list_find_index(_instances, _id) == -1)
						|| !_material.apply(_vertexFormat))
					{
						global.__bbmodMaterialProps = _materialPropsOld;
						_condition = false;
						continue;
					}
					with (BBMOD_SHADER_CURRENT)
					{
						set_instance_id(_id);
						matrix_set(matrix_world, _command[i++]);
						set_bones(_command[i++]);
						set_material_index(_command[i++]);
					}
					var _primitiveType = _command[i++];
					vertex_submit(_command[i++], _primitiveType, _material.BaseOpacity);
					global.__bbmodMaterialProps = _materialPropsOld;
				}
				break;

			case BBMOD_ERenderCommand.DrawMeshBatched:
				{
					var _id = _command[i++];
					var _materialPropsOld = global.__bbmodMaterialProps;
					global.__bbmodMaterialProps = _command[i++];
					var _vertexFormat = _command[i++];
					var _material = _command[i++];

					if (!_material.apply(_vertexFormat))
					{
						global.__bbmodMaterialProps = _materialPropsOld;
						_condition = false;
						continue;
					}

					var _matrix = _command[i++];
					var _batchData = _command[i++];

					////////////////////////////////////////////////////////////
					// Filter batch data by instance ID

					if (_instances != undefined)
					{
						if (is_array(_id))
						{
							var _hasInstances = false;

							if (is_array(_id[0]))
							{
								////////////////////////////////////////////////////
								// _id is an array of arrays of IDs

								_batchData = bbmod_array_clone(_batchData);

								var j = 0;
								repeat (array_length(_id))
								{
									var _idsCurrent = _id[j];
									var _idsCount = array_length(_idsCurrent);
									var _dataCurrent = bbmod_array_clone(_batchData[j]);
									_batchData[@ j] = _dataCurrent;
									var _slotsPerInstance = array_length(_dataCurrent) / _idsCount;
									var _hasData = false;

									var k = 0;
									repeat (_idsCount)
									{
										if (ds_list_find_index(_instances, _idsCurrent[k]) == -1)
										{
											var l = 0;
											repeat (_slotsPerInstance)
											{
												_dataCurrent[@ (k * _slotsPerInstance) + l] = 0.0;
												++l;
											}
										}
										else
										{
											_hasData = true;
											_hasInstances = true;
										}
										++k;
									}

									if (!_hasData)
									{
										// Filtered out all instances in _dataCurrent,
										// we can remove it from _batchData
										array_delete(_batchData, j, 1);
									}
									else
									{
										++j;
									}
								}
							}
							else
							{
								////////////////////////////////////////////////////
								// _id is an array of IDs

								_batchData = bbmod_array_clone(_batchData);

								var _idsCurrent = _id;
								var _idsCount = array_length(_idsCurrent);
								var _dataCurrent = _batchData;
								var _slotsPerInstance = array_length(_dataCurrent) / _idsCount;

								var k = 0;
								repeat (_idsCount)
								{
									if (ds_list_find_index(_instances, _idsCurrent[k]) == -1)
									{
										var l = 0;
										repeat (_slotsPerInstance)
										{
											_dataCurrent[@ (k * _slotsPerInstance) + l] = 0.0;
											++l;
										}
									}
									else
									{
										_hasInstances = true;
									}
									++k;
								}
							}

							if (!_hasInstances)
							{
								global.__bbmodMaterialProps = _materialPropsOld;
								_condition = false;
								continue;
							}
						}
						else
						{
							////////////////////////////////////////////////////
							// _id is a single ID
							if (ds_list_find_index(_instances, _id) == -1)
							{
								global.__bbmodMaterialProps = _materialPropsOld;
								_condition = false;
								continue;
							}
						}
					}

					////////////////////////////////////////////////////////////

					if (is_real(_id))
					{
						BBMOD_SHADER_CURRENT.set_instance_id(_id);
					}

					matrix_set(matrix_world, _matrix);
					var _primitiveType = _command[i++];
					var _vertexBuffer = _command[i++];
					if (is_array(_batchData[0]))
					{
						var _dataIndex = 0;
						repeat (array_length(_batchData))
						{
							BBMOD_SHADER_CURRENT.set_batch_data(_batchData[_dataIndex++]);
							vertex_submit(_vertexBuffer, _primitiveType, _material.BaseOpacity);
						}
					}
					else
					{
						BBMOD_SHADER_CURRENT.set_batch_data(_batchData);
						vertex_submit(_vertexBuffer, _primitiveType, _material.BaseOpacity);
					}

					global.__bbmodMaterialProps = _materialPropsOld;
				}
				break;

			case BBMOD_ERenderCommand.DrawSprite:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					draw_sprite(_sprite, _subimg, _x, _y);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteExt:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _xscale = _command[i++];
					var _yscale = _command[i++];
					var _rot = _command[i++];
					var _col = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_ext(_sprite, _subimg, _x, _y, _xscale, _yscale, _rot, _col, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteGeneral:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _left = _command[i++];
					var _top = _command[i++];
					var _width = _command[i++];
					var _height = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _xscale = _command[i++];
					var _yscale = _command[i++];
					var _rot = _command[i++];
					var _c1 = _command[i++];
					var _c2 = _command[i++];
					var _c3 = _command[i++];
					var _c4 = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_general(_sprite, _subimg, _left, _top, _width, _height, _x, _y,
						_xscale, _yscale, _rot, _c1, _c2, _c3, _c4, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpritePart:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _left = _command[i++];
					var _top = _command[i++];
					var _width = _command[i++];
					var _height = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					draw_sprite_part(_sprite, _subimg, _left, _top, _width, _height, _x, _y);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpritePartExt:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _left = _command[i++];
					var _top = _command[i++];
					var _width = _command[i++];
					var _height = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _xscale = _command[i++];
					var _yscale = _command[i++];
					var _col = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_part_ext(_sprite, _subimg, _left, _top, _width, _height, _x, _y,
						_xscale, _yscale, _col, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpritePos:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x1 = _command[i++];
					var _y1 = _command[i++];
					var _x2 = _command[i++];
					var _y2 = _command[i++];
					var _x3 = _command[i++];
					var _y3 = _command[i++];
					var _x4 = _command[i++];
					var _y4 = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_pos(_sprite, _subimg, _x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteStretched:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _w = _command[i++];
					var _h = _command[i++];
					draw_sprite_stretched(_sprite, _subimg, _x, _y, _w, _h);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteStretchedExt:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _w = _command[i++];
					var _h = _command[i++];
					var _col = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_stretched_ext(_sprite, _subimg, _x, _y, _w, _h, _col, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteTiled:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					draw_sprite_tiled(_sprite, _subimg, _x, _y);
				}
				break;

			case BBMOD_ERenderCommand.DrawSpriteTiledExt:
				{
					var _sprite = _command[i++];
					var _subimg = _command[i++];
					var _x = _command[i++];
					var _y = _command[i++];
					var _xscale = _command[i++];
					var _yscale = _command[i++];
					var _col = _command[i++];
					var _alpha = _command[i++];
					draw_sprite_tiled_ext(_sprite, _subimg, _x, _y, _xscale, _yscale, _col, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.EndConditionalBlock:
				if (--_matchCounter < 0)
				{
					show_error("Found unmatching end of conditional block in render queue " + Name + "!", true);
				}
				break;

			case BBMOD_ERenderCommand.PopGpuState:
				gpu_pop_state();
				break;

			case BBMOD_ERenderCommand.PushGpuState:
				gpu_push_state();
				break;

			case BBMOD_ERenderCommand.ResetMaterial:
				bbmod_material_reset();
				break;

			case BBMOD_ERenderCommand.ResetMaterialProps:
				bbmod_material_props_reset();
				break;

			case BBMOD_ERenderCommand.ResetShader:
				shader_reset();
				break;

			case BBMOD_ERenderCommand.SetGpuAlphaTestEnable:
				gpu_set_alphatestenable(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuAlphaTestRef:
				gpu_set_alphatestref(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuBlendEnable:
				gpu_set_blendenable(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuBlendMode:
				gpu_set_blendmode(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuBlendModeExt:
				{
					var _src = _command[i++];
					var _dest = _command[i++];
					gpu_set_blendmode_ext(_src, _dest);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuBlendModeExtSepAlpha:
				{
					var _src = _command[i++];
					var _dest = _command[i++];
					var _srcalpha = _command[i++];
					var _destalpha = _command[i++];
					gpu_set_blendmode_ext_sepalpha(_src, _dest, _srcalpha, _destalpha);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuColorWriteEnable:
				{
					var _red = _command[i++];
					var _green = _command[i++];
					var _blue = _command[i++];
					var _alpha = _command[i++];
					gpu_set_colorwriteenable(_red, _green, _blue, _alpha);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuCullMode:
				gpu_set_cullmode(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuFog:
				if (_command[i++])
				{
					var _color = _command[i++];
					var _start = _command[i++];
					var _end = _command[i++];
					gpu_set_fog(true, _color, _start, _end);
				}
				else
				{
					gpu_set_fog(false, c_black, 0, 1);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexFilter:
				gpu_set_tex_filter(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexFilterExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_filter_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMaxAniso:
				gpu_set_tex_max_aniso(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMaxAnisoExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_max_aniso_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMaxMip:
				gpu_set_tex_max_mip(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMaxMipExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_max_mip_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMinMip:
				gpu_set_tex_min_mip(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMinMipExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_min_mip_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipBias:
				gpu_set_tex_mip_bias(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipBiasExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_mip_bias_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipEnable:
				gpu_set_tex_mip_enable(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipEnableExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_mip_enable_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipFilter:
				gpu_set_tex_mip_filter(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexMipFilterExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_mip_filter_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuTexRepeat:
				gpu_set_tex_repeat(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuTexRepeatExt:
				{
					var _index = shader_get_sampler_index(shader_current(), _command[i++]);
					gpu_set_tex_repeat_ext(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetGpuZFunc:
				gpu_set_zfunc(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuZTestEnable:
				gpu_set_ztestenable(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetGpuZWriteEnable:
				gpu_set_zwriteenable(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetMaterialProps:
				bbmod_material_props_set(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetProjectionMatrix:
				matrix_set(matrix_projection, _command[i++]);
				break;

			case BBMOD_ERenderCommand.SetSampler:
				{
					var _nameOrIndex = _command[i++];
					var _index = is_string(_nameOrIndex)
						? shader_get_sampler_index(shader_current(), _nameOrIndex)
						: _nameOrIndex;
					texture_set_stage(_index, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetShader:
				shader_set(_command[i++]);
				break;

			case BBMOD_ERenderCommand.SetUniformFloat:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					shader_set_uniform_f(_uniform, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformFloat2:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					shader_set_uniform_f(_uniform, _v1, _v2);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformFloat3:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					var _v3 = _command[i++];
					shader_set_uniform_f(_uniform, _v1, _v2, _v3);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformFloat4:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					var _v3 = _command[i++];
					var _v4 = _command[i++];
					shader_set_uniform_f(_uniform, _v1, _v2, _v3, _v4);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformFloatArray:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					shader_set_uniform_f_array(_uniform, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformInt:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					shader_set_uniform_i(_uniform, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformInt2:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					shader_set_uniform_i(_uniform, _v1, _v2);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformInt3:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					var _v3 = _command[i++];
					shader_set_uniform_i(_uniform, _v1, _v2, _v3);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformInt4:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					var _v1 = _command[i++];
					var _v2 = _command[i++];
					var _v3 = _command[i++];
					var _v4 = _command[i++];
					shader_set_uniform_i(_uniform, _v1, _v2, _v3, _v4);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformIntArray:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					shader_set_uniform_i_array(_uniform, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetUniformMatrix:
				shader_set_uniform_matrix(shader_get_uniform(shader_current(), _command[i++]));
				break;

			case BBMOD_ERenderCommand.SetUniformMatrixArray:
				{
					var _uniform = shader_get_uniform(shader_current(), _command[i++]);
					shader_set_uniform_matrix_array(_uniform, _command[i++]);
				}
				break;

			case BBMOD_ERenderCommand.SetViewMatrix:
				matrix_set(matrix_view, _command[i++]);
				break;

			case BBMOD_ERenderCommand.SetWorldMatrix:
				matrix_set(matrix_world, _command[i++]);
				break;

			case BBMOD_ERenderCommand.SubmitVertexBuffer:
				{
					var _vertexBuffer = _command[i++];
					var _prim = _command[i++];
					var _texture = _command[i++];
					vertex_submit(_vertexBuffer, _prim, _texture);
				}
				break;
			}

			_condition = true;
		}

		return self;
	};

	/// @func clear()
	///
	/// @desc Clears the render queue.
	///
	/// @return {Struct.BBMOD_Material} Returns `self`.
	static clear = function ()
	{
		gml_pragma("forceinline");
		__renderPasses = 0;
		__index = 0;
		return self;
	};

	static destroy = function ()
	{
		Class_destroy();
		__renderCommands = undefined;
		__bbmod_remove_render_queue(self);
		return undefined;
	};

	__bbmod_add_render_queue(self);
}

function __bbmod_add_render_queue(_renderQueue)
{
	gml_pragma("forceinline");
	static _renderQueues = bbmod_render_queues_get();
	array_push(_renderQueues, _renderQueue);
	__bbmod_reindex_render_queues();
}

function __bbmod_remove_render_queue(_renderQueue)
{
	gml_pragma("forceinline");
	static _renderQueues = bbmod_render_queues_get();
	var _renderQueueCount = array_length(_renderQueues);
	for (var i = 0; i < _renderQueueCount; ++i)
	{
		if (_renderQueues[i] == _renderQueue)
		{
			array_delete(_renderQueues, i, 1);
			break;
		}
	}
	__bbmod_reindex_render_queues();
}

function __bbmod_reindex_render_queues()
{
	gml_pragma("forceinline");
	static _renderQueues = bbmod_render_queues_get();
	static _sortFn = function (_a, _b)
	{
		if (_b.Priority > _a.Priority) return -1;
		if (_b.Priority < _a.Priority) return +1;
		return 0;
	};
	array_sort(_renderQueues, _sortFn);
}

/// @func bbmod_render_queue_get_default()
///
/// @desc Retrieves the default render queue.
///
/// @return {Struct.BBMOD_RenderQueue} The default render queue.
///
/// @see BBMOD_RenderQueue
function bbmod_render_queue_get_default()
{
	static _renderQueue = new BBMOD_RenderQueue("Default");
	return _renderQueue;
}
