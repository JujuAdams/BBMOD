/// @enum Enumeration of edit axes.
enum BBMOD_EEditAxis
{
	/// @member No edit.
	None = 0,
	/// @member Edit on X axis.
	X = $1,
	/// @member Edit on Y axis.
	Y = $10,
	/// @member Edit on Z axis.
	Z = $100,
	/// @member Edit on all axes.
	All = $111,
};

/// @enum Enumeration of edit types.
enum BBMOD_EEditType
{
	/// @member Translate selected instances.
	Position,
	/// @member Rotate selected instances.
	Rotation,
	/// @member Scale selected instances.
	Scale,
	/// @member Total number of members of this enum.
	SIZE,
};

/// @func BBMOD_Gizmo()
/// @extends BBMOD_Class
/// @desc A gizmo.
/// @note Please note that this together with {@link BBMOD_Renderer} implements
/// *only* rendering of the gizmo and highlight of selected instances.
/// You will need to handle the actual editing of selected instances yourself!
function BBMOD_Gizmo()
	: BBMOD_Class() constructor
{
	BBMOD_CLASS_GENERATED_BODY;

	static Super_Class = {
		destroy: destroy,
	};

	/// @var {Struct.BBMOD_Model} The gizmo model.
	/// @note Please note that this model is not loaded asynchronnously,
	/// therefore it cannot be used on platforms that require asynchronnous
	/// loading, like HTML5!
	/// @readonly
	static Model = undefined;

	/// @var {Array<Struct.BBMOD_Material>} Materials used when mouse-picking
	/// the gizmo.
	static MaterialsSelect = undefined;

	if (!Model)
	{
		var _shaderSelect = new BBMOD_BaseShader(BBMOD_ShGizmoSelect, BBMOD_VFORMAT_DEFAULT);
		var _materialSelect = new BBMOD_BaseMaterial(_shaderSelect);
		_materialSelect.BaseOpacity = sprite_get_texture(BBMOD_SprGizmo, 1);
		_materialSelect.Culling = cull_noculling;
		MaterialsSelect = [_materialSelect];

		var _shader = new BBMOD_BaseShader(BBMOD_ShGizmo, BBMOD_VFORMAT_DEFAULT);
		var _material = new BBMOD_BaseMaterial(_shader);
		_material.BaseOpacity = sprite_get_texture(BBMOD_SprGizmo, 0);
		_material.Culling = cull_noculling;

		Model = new BBMOD_Model("Data/BBMOD/Models/Gizmo.bbmod")
		Model.Materials[0] = _material;
	}

	/// @var {Bool} Used to show/hide the gizmo. Default value is `true`, which
	/// makes it visible.
	Visible = true;

	/// @var {Bool} If `true` then the gizmo is editing selected instances.
	IsEditing = false;

	/// @var {Enum.BBMOD_EEditType} Determines how are the selected instances
	/// edited (translated/rotated/scaled).
	/// @see BBMOD_EEditType
	EditType = BBMOD_EEditType.Position;

	/// @var {Enum.BBMOD_EEditAxis} Determines on which axes are the selected
	/// instances edited.
	/// @see BBMOD_EEditAxis
	EditAxis = BBMOD_EEditAxis.None;

	/// @var {Real} The size of the gizmo. Default value is 10.
	Size = 10.0;

	/// @var {Struct.BBMOD_Vec3} The gizmo's position in world-space.
	/// @readonly
	Position = new BBMOD_Vec3();

	/// @var {Id.DsList<Id.Instance>} A list of selected instances.
	/// @readonly
	Selected = ds_list_create();

	/// @func select(_instance)
	/// @desc Adds an instance to selection.
	/// @param {Id.Instance} _instance The instance to select.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	static select = function (_instance) {
		gml_pragma("forceinline");
		if (!is_selected(_instance))
		{
			ds_list_add(Selected, _instance);
		}
		return self;
	};

	/// @func is_selected(_instance)
	/// @desc Checks whether an instance is selected.
	/// @param {Id.Instance} _instance The instance to check.
	/// @return {Bool} Returns `true` if the instance is selected.
	static is_selected = function (_instance) {
		gml_pragma("forceinline");
		return (ds_list_find_index(Selected, _instance) != -1);
	};

	/// @func unselect(_instance)
	/// @desc Removes an instance from selection.
	/// @param {Id.Instance} _instance The instance to unselect.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	static unselect = function (_instance) {
		gml_pragma("forceinline");
		var _index = ds_list_find_index(Selected, _instance);
		if (_index != -1)
		{
			ds_list_delete(Selected, _index);
		}
		return self;
	};

	/// @func toggle_select(_instance)
	/// @desc Unselects an instance if it's selected, or selects if it isn't.
	/// @param {Id.Instance} _instance The instance to toggle selection of.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	static toggle_select = function (_instance) {
		gml_pragma("forceinline");
		if (is_selected(_instance))
		{
			unselect(_instance);
		}
		else
		{
			select(_instance);
		}
		return self;
	};

	/// @func clear_selection()
	/// @desc Removes all instances from selection.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	static clear_selection = function () {
		gml_pragma("forceinline");
		ds_list_clear(Selected);
		return self;
	};

	/// @func submit([_materials])
	/// @desc Immediately submits the gizmo for rendering.
	/// @param {Array<Struct.BBMOD_Material>/Undefined} [_materials] Materials to use.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	/// @note If {@link BBMOD_Gizmo.Visible} is `false` then the gizmo is not submitted.
	/// This also changes the world matrix based on the gizmo's position and size!
	static submit = function (_materials=undefined) {
		gml_pragma("forceinline");
		if (Visible)
		{
			new BBMOD_Matrix().Scale(new BBMOD_Vec3(Size)).Translate(Position).ApplyWorld();
			Model.submit(_materials);
		}
		return self;
	};

	/// @func render([_materials])
	/// @desc Enqueues the gizmo for rendering.
	/// @param {Array<Struct.BBMOD_Material>/Undefined} [_materials] Materials to use.
	/// @return {Struct.BBMOD_Gizmo} Returns `self`.
	/// @note If {@link BBMOD_Gizmo.Visible} is `false` then the gizmo is not submitted.
	/// This also changes the world matrix based on the gizmo's position and size!
	static render = function (_materials=undefined) {
		gml_pragma("forceinline");
		if (Visible)
		{
			new BBMOD_Matrix().Scale(new BBMOD_Vec3(Size)).Translate(Position).ApplyWorld();
			Model.render(_materials);
		}
		return self;
	};

	static destroy = function () {
		method(self, Super_Class.destroy)();
		ds_list_destroy(Selected);
		return undefined;
	};
}