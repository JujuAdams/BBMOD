// FIXME: Temporary fix!
precision highp float;

////////////////////////////////////////////////////////////////////////////////
//
// Defines
//

// Maximum number of bones of animated models
#define MAX_BONES 64
#if defined(X_PARTICLES)
// Maximum number of particles
#define MAX_PARTICLES 64
// Maximum number of vec4 uniforms for dynamic batch data
#define MAX_BATCH_DATA_SIZE (3 * MAX_PARTICLES)
#else
// Maximum number of vec4 uniforms for dynamic batch data
#define MAX_BATCH_DATA_SIZE 128
#endif
// Maximum number of point lights
#define MAX_POINT_LIGHTS 8

////////////////////////////////////////////////////////////////////////////////
//
// Attributes
//
attribute vec4 in_Position;

#if !defined(X_2D) && !defined(X_PARTICLES)
attribute vec3 in_Normal;
#endif

attribute vec2 in_TextureCoord0;

#if defined(X_2D)
attribute vec4 in_Color;
#endif

#if !defined(X_2D) && !defined(X_PARTICLES)
attribute vec4 in_TangentW;
#endif

#if defined(X_ANIMATED)
attribute vec4 in_BoneIndex;
attribute vec4 in_BoneWeight;
#endif

#if defined(X_BATCHED) || defined(X_PARTICLES)
attribute float in_Id;
#endif

////////////////////////////////////////////////////////////////////////////////
//
// Uniforms
//
uniform vec2 bbmod_TextureOffset;
uniform vec2 bbmod_TextureScale;

#if defined(X_ANIMATED)
uniform vec4 bbmod_Bones[2 * MAX_BONES];
#endif

#if defined(X_BATCHED) || defined(X_PARTICLES)
uniform vec4 bbmod_BatchData[MAX_BATCH_DATA_SIZE];
#endif

#if !defined(X_PBR) && !defined(X_2D)
// [(x, y, z, range), (r, g, b, m), ...]
uniform vec4 bbmod_LightPointData[2 * MAX_POINT_LIGHTS];
#endif

#if !defined(X_OUTPUT_DEPTH) && !defined(X_PBR) && !defined(X_2D)
// 1.0 to enable shadows
uniform float bbmod_ShadowmapEnableVS;
// WORLD_VIEW_PROJECTION matrix used when rendering shadowmap
uniform mat4 bbmod_ShadowmapMatrix;
// The area that the shadowmap captures
uniform float bbmod_ShadowmapArea;
// Offsets vertex position by its normal scaled by this value
uniform float bbmod_ShadowmapNormalOffset;
#endif

////////////////////////////////////////////////////////////////////////////////
//
// Varyings
//
#pragma include("Varyings.xsh")

////////////////////////////////////////////////////////////////////////////////
//
// Includes
//
#pragma include("Color.xsh")
#pragma include("RGBM.xsh")

vec3 QuaternionRotate(vec4 q, vec3 v)
{
	return (v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v));
}

vec3 DualQuaternionTransform(vec4 real, vec4 dual, vec3 v)
{
	return (QuaternionRotate(real, v)
		+ 2.0 * (real.w * dual.xyz - dual.w * real.xyz + cross(real.xyz, dual.xyz)));
}

#if !defined(X_PARTICLES)
/// @desc Transforms vertex and normal by animation and/or batch data.
/// @param vertex Variable to hold the transformed vertex.
/// @param normal Variable to hold the transformed normal.
void Transform(out vec4 vertex, out vec3 normal)
{
	vertex = in_Position;
#if defined(X_2D)
	normal = vec3(0.0, 0.0, 1.0);
#else
	normal = in_Normal;
#endif

#if defined(X_ANIMATED)
	// Source:
	// https://www.cs.utah.edu/~ladislav/kavan07skinning/kavan07skinning.pdf
	// https://www.cs.utah.edu/~ladislav/dq/dqs.cg
	ivec4 i = ivec4(in_BoneIndex) * 2;
	ivec4 j = i + 1;

	vec4 real0 = bbmod_Bones[i.x];
	vec4 real1 = bbmod_Bones[i.y];
	vec4 real2 = bbmod_Bones[i.z];
	vec4 real3 = bbmod_Bones[i.w];

	vec4 dual0 = bbmod_Bones[j.x];
	vec4 dual1 = bbmod_Bones[j.y];
	vec4 dual2 = bbmod_Bones[j.z];
	vec4 dual3 = bbmod_Bones[j.w];

	if (dot(real0, real1) < 0.0) { real1 *= -1.0; dual1 *= -1.0; }
	if (dot(real0, real2) < 0.0) { real2 *= -1.0; dual2 *= -1.0; }
	if (dot(real0, real3) < 0.0) { real3 *= -1.0; dual3 *= -1.0; }

	vec4 blendReal =
		  real0 * in_BoneWeight.x
		+ real1 * in_BoneWeight.y
		+ real2 * in_BoneWeight.z
		+ real3 * in_BoneWeight.w;

	vec4 blendDual =
		  dual0 * in_BoneWeight.x
		+ dual1 * in_BoneWeight.y
		+ dual2 * in_BoneWeight.z
		+ dual3 * in_BoneWeight.w;

	float len = length(blendReal);
	blendReal /= len;
	blendDual /= len;

	vertex = vec4(DualQuaternionTransform(blendReal, blendDual, vertex.xyz), 1.0);
	normal = QuaternionRotate(blendReal, normal);
#endif

#if defined(X_BATCHED)
	int idx = int(in_Id) * 2;
	vec4 posScale = bbmod_BatchData[idx];
	vec4 rot = bbmod_BatchData[idx + 1];

	vertex = vec4(posScale.xyz + (QuaternionRotate(rot, vertex.xyz) * posScale.w), 1.0);
	normal = QuaternionRotate(rot, normal);
#endif
}
#endif // !X_PARTICLES

void DoPointLightVS(
	vec3 position,
	float range,
	vec3 color,
	vec3 vertex,
	vec3 N,
	inout vec3 diffuse)
{
	vec3 L = position - vertex;
	float dist = length(L);
	float att = clamp(1.0 - (dist / range), 0.0, 1.0);
	float NdotL = max(dot(N, normalize(L)), 0.0);
	diffuse += color * NdotL * att;
}

////////////////////////////////////////////////////////////////////////////////
//
// Main
//
void main()
{
#if defined(X_PARTICLES)
	vec3 normal = vec3(0.0, 0.0, -1.0);

	vec3 batchPosition = bbmod_BatchData[int(in_Id) * 3 + 0].xyz;
	vec3 batchScale = bbmod_BatchData[int(in_Id) * 3 + 1].xyz;
	v_vColor.rgb = xGammaToLinear(xDecodeRGBM(bbmod_BatchData[int(in_Id) * 3 + 2]));
	v_vColor.a = 1.0;

	vec4 position = in_Position;
	position.x *= length(gm_Matrices[MATRIX_WORLD][0].xyz);
	position.y *= length(gm_Matrices[MATRIX_WORLD][1].xyz);
	position.z *= length(gm_Matrices[MATRIX_WORLD][2].xyz);
	position.xyz *= batchScale;

	mat4 W = gm_Matrices[MATRIX_WORLD];
	W[3].xyz += batchPosition;
	mat4 V = gm_Matrices[MATRIX_VIEW];
	mat4 P = gm_Matrices[MATRIX_PROJECTION];

	W[0][0] = V[0][0]; W[1][0] = V[0][1]; W[2][0] = V[0][2];
	W[0][1] = V[1][0]; W[1][1] = V[1][1]; W[2][1] = V[1][2];
	W[0][2] = V[2][0]; W[1][2] = V[2][1]; W[2][2] = V[2][2];

	mat4 WV = V * W;
	vec4 positionWVP = (P * (WV * position));
	v_vVertex = (W * position).xyz;
#else // X_PARTICLES
	vec4 position;
	vec3 normal;
	Transform(position, normal);

	vec4 positionWVP = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * position;
	v_vVertex = (gm_Matrices[MATRIX_WORLD] * position).xyz;
#endif // !X_PARTICLES

	gl_Position = positionWVP;
	v_fDepth = positionWVP.z;
#if defined(X_2D)
	v_vColor = in_Color;
#endif
	v_vTexCoord = bbmod_TextureOffset + in_TextureCoord0 * bbmod_TextureScale;

#if defined(X_2D) || defined(X_PARTICLES)
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 bitangent = vec3(0.0, 1.0, 0.0);
#else
	vec3 tangent = in_TangentW.xyz;
	vec3 bitangent = cross(in_Normal, tangent) * in_TangentW.w;
#endif
	v_mTBN = mat3(gm_Matrices[MATRIX_WORLD]) * mat3(tangent, bitangent, normal);

#if !defined(X_OUTPUT_DEPTH) && !defined(X_PBR) && !defined(X_2D)
	#if defined(X_TERRAIN)
	v_vSplatmapCoord = in_TextureCoord0;
	#endif

	////////////////////////////////////////////////////////////////////////////
	// Point lights
	vec3 N = normalize(v_mTBN * vec3(0.0, 0.0, 1.0));

	for (int i = 0; i < MAX_POINT_LIGHTS; ++i)
	{
		vec4 positionRange = bbmod_LightPointData[i * 2];
		vec3 color = xGammaToLinear(xDecodeRGBM(bbmod_LightPointData[(i * 2) + 1]));
		DoPointLightVS(positionRange.xyz, positionRange.w, color, v_vVertex, N, v_vLight);
	}

	////////////////////////////////////////////////////////////////////////////
	// Vertex position in shadowmap
	if (bbmod_ShadowmapEnableVS == 1.0)
	{
		v_vPosShadowmap = (bbmod_ShadowmapMatrix
			* vec4(v_vVertex + N * bbmod_ShadowmapNormalOffset, 1.0)).xyz;
		v_vPosShadowmap.xy = v_vPosShadowmap.xy * 0.5 + 0.5;
	#if defined(_YY_HLSL11_) || defined(_YY_PSSL_)
		v_vPosShadowmap.y = 1.0 - v_vPosShadowmap.y;
	#endif
		v_vPosShadowmap.z /= bbmod_ShadowmapArea;
	}
#endif
}
