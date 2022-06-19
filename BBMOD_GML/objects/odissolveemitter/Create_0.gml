event_inherited();

position = new BBMOD_Vec3(x, y, z);

emitter = new BBMOD_ParticleEmitter(position, DissolveParticleSystem());

light = new BBMOD_PointLight(new BBMOD_Color(0, 255, 127, 0), position, 40);

bbmod_light_point_add(light);
