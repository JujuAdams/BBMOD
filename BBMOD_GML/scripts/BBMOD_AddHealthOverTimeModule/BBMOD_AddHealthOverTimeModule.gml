/// @func BBMOD_AddHealthOverTimeModule([_change[, _period]])
/// @extends BBMOD_ParticleModule
/// @desc
/// @param {Real} [_change]
/// @param {Real} [_period]
function BBMOD_AddHealthOverTimeModule(_change=-1.0, _period=1.0)
	: BBMOD_ParticleModule() constructor
{
	/// @var {Real}
	Change = _change;

	/// @var {Real}
	Period = _period;

	static on_update = function (_emitter, _deltaTime) {
		if (_emitter.ParticlesAlive > 0)
		{
			ds_grid_add_region(
				_emitter.Particles,
				BBMOD_EParticle.HealthLeft, 0,
				BBMOD_EParticle.HealthLeft, _emitter.ParticlesAlive - 1,
				Change * ((_deltaTime * 0.000001) / Period));
		}
	};
}