/// @func BBMOD_AddVec4OnCollisionModule([_property[, _change]])
///
/// @extends BBMOD_ParticleModule
///
/// @desc A universal particle module that adds a value to four consecutive
/// particle properties it has a collision.
///
/// @param {Enum.BBMOD_EParticle/Undefined} [_property] The first of the four
/// consecutive properties. Defaults to `undefined`.
/// @param {Struct.BBMOD_Vec4} [_change] The value to add to particles' health. Defaults
/// to `(1.0, 1.0, 1.0, 1.0)`.
///
/// @see BBMOD_EParticle.HasCollided
function BBMOD_AddVec4OnCollisionModule(_property=undefined, _change=new BBMOD_Vec4(1.0))
	: BBMOD_ParticleModule() constructor
{
	/// @var {Enum.BBMOD_EParticle/Undefined} The first of the four consecutive
	/// properties. Default value is `undefined`.
	Property = _property;

	/// @var {Struct.BBMOD_Vec4} The value to add on collision. Default value is
	/// `(1.0, 1.0, 1.0, 1.0)`.
	Change = _change;

	static on_update = function (_emitter, _deltaTime) {
		if (Property != undefined)
		{
			var _y2 = _emitter.ParticlesAlive - 1;
			if (_y2 >= 0)
			{
				var _particles = _emitter.Particles;
				var _gridCompute = _emitter.GridCompute;
				var _change = Change;

				ds_grid_set_region(
					_gridCompute,
					0, 0,
					0, _y2,
					_change.X);

				ds_grid_set_region(
					_gridCompute,
					1, 0,
					1, _y2,
					_change.Y);

				ds_grid_set_region(
					_gridCompute,
					2, 0,
					2, _y2,
					_change.Z);

				ds_grid_set_region(
					_gridCompute,
					3, 0,
					3, _y2,
					_change.W);

				ds_grid_multiply_grid_region(
					_gridCompute,
					_particles,
					BBMOD_EParticle.HasCollided, 0,
					BBMOD_EParticle.HasCollided, _y2,
					0, 0);

				ds_grid_multiply_grid_region(
					_gridCompute,
					_particles,
					BBMOD_EParticle.HasCollided, 0,
					BBMOD_EParticle.HasCollided, _y2,
					1, 0);

				ds_grid_multiply_grid_region(
					_gridCompute,
					_particles,
					BBMOD_EParticle.HasCollided, 0,
					BBMOD_EParticle.HasCollided, _y2,
					2, 0);

				ds_grid_multiply_grid_region(
					_gridCompute,
					_particles,
					BBMOD_EParticle.HasCollided, 0,
					BBMOD_EParticle.HasCollided, _y2,
					3, 0);

				ds_grid_add_grid_region(
					_particles,
					_gridCompute,
					0, 0,
					3, _y2,
					Property, 0);
			}
		}
	};
}
