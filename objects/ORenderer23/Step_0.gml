var _window_width = max(window_get_width(), 1);
var _window_height = max(window_get_height(), 1);

var _surface_width = max(_window_width * application_surface_scale, 1);
var _surface_height = max(_window_height * application_surface_scale, 1);

if (surface_get_width(application_surface) != _surface_width
	|| surface_get_height(application_surface) != _surface_height)
{
	surface_resize(application_surface, _surface_width, _surface_height);
}

// Mouselook
var _mouse_x = window_mouse_get_x();
var _mouse_y = window_mouse_get_y();
var _mouse_sensitivity = 1;

if (mouse_check_button(mb_right))
{
	direction += (mouse_last_x - _mouse_x) * _mouse_sensitivity;
	direction_up += (mouse_last_y - _mouse_y) * _mouse_sensitivity;
}

mouse_last_x = _mouse_x;
mouse_last_y = _mouse_y;

// Move around
var _move_speed = keyboard_check(vk_shift) ? 1 : 0.25;

if (keyboard_check(ord("W")))
{
	x += lengthdir_x(_move_speed, direction);
	y += lengthdir_y(_move_speed, direction);
}
else if (keyboard_check(ord("S")))
{
	x -= lengthdir_x(_move_speed, direction);
	y -= lengthdir_y(_move_speed, direction);
}

if (keyboard_check(ord("A")))
{
	x += lengthdir_x(_move_speed, direction + 90);
	y += lengthdir_y(_move_speed, direction + 90);
}
else if (keyboard_check(ord("D")))
{
	x += lengthdir_x(_move_speed, direction - 90);
	y += lengthdir_y(_move_speed, direction - 90);
}

z += (keyboard_check(ord("E")) - keyboard_check(ord("Q"))) * _move_speed;

// Controls
var _strength = keyboard_check(vk_shift) ? 0.1 : 0.01;
var _diff = (keyboard_check(vk_add) - keyboard_check(vk_subtract)) * _strength;

global.bbmod_camera_exposure += _diff;
global.bbmod_camera_exposure = max(global.bbmod_camera_exposure, 0.1);

// Batching test
if (keyboard_check_pressed(vk_space))
{
	if (++mode_current >= EMode.SIZE)
	{
		mode_current = 0;
		if (!freezed)
		{
			mod_sphere.freeze();
			freezed = true;
		}
	}
}

switch (mode_current)
{
case EMode.Normal:
	break;

case EMode.Static:
	var _model = model[mode_current];
	if (_model == BBMOD_NONE)
	{
		_model = new BBMOD_StaticBatch(model[EMode.Normal].get_vertex_format(false));
		_model.start();
		for (var i = 0; i < 8; ++i)
		{
			for (var j = 0; j < 8; ++j)
			{
				_model.add(model[EMode.Normal],
					matrix_build(
						i * 5, j * 5, 0,
						0, 0, 0,
						1, 1, 1));
			}
		}
		_model.finish();
		_model.freeze();
		model[mode_current] = _model;
	}
	break;

case EMode.Dynamic:
	var _model = model[mode_current];
	if (_model == BBMOD_NONE)
	{
		_model = bbmod_dynamic_batch_create(model[EMode.Normal].model, BATCH_SIZE);
		bbmod_dynamic_batch_freeze(_model);
		model[mode_current] = _model;
	}

	var i/*:int*/= 0;
	var _time = current_time * 0.01;

	repeat (BATCH_SIZE)
	{
		var _idx = i * 8;

		var _rot = rotations[i];
		_rot += _time * 10;
		var _quat = ce_quaternion_create_from_axisangle([1, 0, 0], _rot);
		array_copy(data, _idx + 4, _quat, 0, 4);

		++i;
	}
	break;
}