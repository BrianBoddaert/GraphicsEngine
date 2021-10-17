/*
******************
* DAE Ubershader *
******************

FirstName: Brian
LastName: Boddaert
Class: 2DAE_GD02

using lambert

**This Shader Contains:

- Diffuse (Texture & Color)
	- Regular Diffuse
- Specular
	- Specular Level (Texture & Value)
	- Shininess (Value)
	- Models
		- Blinn
		- Phong
- Ambient (Color)
- EnvironmentMapping (CubeMap)
	- Reflection + Fresnel Falloff
	- Refraction
- Normal (Texture)
- Opacity (Texture & Value)

-Techniques
	- WithAlphaBlending
	- WithoutAlphaBlending
*/

float4x4 gMatrixWVP : WORLDVIEWPROJECTION;
float4x4 gMatrixViewInverse : VIEWINVERSE;
float4x4 gMatrixWorld : WORLD;


RasterizerState gRS_FrontCulling
{
	CullMode = FRONT;
};

BlendState gBS_EnableBlending
{
	BlendEnable[0] = TRUE;
	SrcBlend = SRC_ALPHA;
	DestBlend = INV_SRC_ALPHA;
};


SamplerState gTextureSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
	AddressW = WRAP;
};


float3 gLightDirection :DIRECTION
<
	string UIName = "Light Direction";
	string Object = "TargetLight";
> = float3(0.577f, 0.577f, 0.577f);


bool gUseTextureDiffuse
<
	string UIName = "Diffuse Texture";
	string UIWidget = "Bool";
> = false;

float4 gColorDiffuse
<
	string UIName = "Diffuse Color";
	string UIWidget = "Color";
> = float4(1, 1, 1, 1);

Texture2D gTextureDiffuse
<
	string UIName = "Diffuse Texture";
	string UIWidget = "Texture";
> ;

float4 gColorSpecular
<
	string UIName = "Specular Color";
	string UIWidget = "Color";
> = float4(1, 1, 1, 1);

Texture2D gTextureSpecularIntensity
<
	string UIName = "Specular Level Texture";
	string UIWidget = "Texture";
> ;

bool gUseTextureSpecularIntensity
<
	string UIName = "Specular Level Texture";
	string UIWidget = "Bool";
> = false;

int gShininess
<
	string UIName = "Shininess";
	string UIWidget = "Slider";
	float UIMin = 1;
	float UIMax = 100;
	float UIStep = 0.1f;
> = 15;

float4 gColorAmbient
<
	string UIName = "Ambient Color";
	string UIWidget = "Color";
> = float4(0, 0, 0, 1);

float gAmbientIntensity
<
	string UIName = "Ambient Intensity";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 1;
> = 0.0f;


bool gFlipGreenChannel
<
	string UIName = "Flip Green Channel";
	string UIWidget = "Bool";
> = false;

bool gUseTextureNormal
<
	string UIName = "Normal Mapping";
	string UIWidget = "Bool";
> = false;

Texture2D gTextureNormal
<
	string UIName = "Normal Texture";
	string UIWidget = "Texture";
> ;

TextureCube gCubeEnvironment
<
	string UIName = "Environment Cube";
	string ResourceType = "Cube";
> ;

bool gUseEnvironmentMapping
<
	string UIName = "Environment Mapping";
	string UIWidget = "Bool";
> = false;

float gReflectionStrength
<
	string UIName = "Reflection Strength";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 1;
	float UIStep = 0.1;
> = 0.0f;

float gRefractionStrength
<
	string UIName = "Refraction Strength";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 1;
	float UIStep = 0.1;
> = 0.0f;

float gRefractionIndex
<
	string UIName = "Refraction Index";
> = 0.3f;

bool gUseFresnelFalloff
<
	string UIName = "Fresnel FallOff";
	string UIWidget = "Bool";
> = false;

float4 gFresnelColor
<
	string UIName = "Fresnel Color";
	string UIWidget = "Color";
> = float4(1, 1, 1, 1);

float gFresnelPower
<
	string UIName = "Fresnel Power";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 100;
	float UIStep = 0.1;
> = 1.0f;

float gFresnelMultiplier
<
	string UIName = "Fresnel Multiplier";
	string UIWidget = "slider";
	float UIMin = 1;
	float UIMax = 100;
	float UIStep = 0.1;
> = 1.0;

float gFresnelHardness
<
	string UIName = "Fresnel Hardness";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 100;
	float UIStep = 0.1;
> = 0;

float gOpacityIntensity
<
	string UIName = "Opacity Intensity";
	string UIWidget = "slider";
	float UIMin = 0;
	float UIMax = 1;
> = 1.0f;

bool gUseTextureOpacity <
	string UIName = "Opacity Map";
	string UIWidget = "Bool";
> = false;

Texture2D gTextureOpacity
<
	string UIName = "Opacity Map";
	string UIWidget = "Texture";
> ;

bool gUseSpecularBlinn
<
	string UIName = "Specular Blinn";
	string UIWidget = "Bool";
> = false;

bool gUseSpecularPhong
<
	string UIName = "Specular Phong";
	string UIWidget = "Bool";
> = false;

struct VS_Input
{
	float3 Position: POSITION;
	float3 Normal: NORMAL;
	float3 Tangent: TANGENT;
	float2 TexCoord: TEXCOORD0;
};

struct VS_Output
{
	float4 Position: SV_POSITION;
	float4 WorldPosition: COLOR0;
	float3 Normal: NORMAL;
	float3 Tangent: TANGENT;
	float2 TexCoord: TEXCOORD0;
};

float3 CalculateBlinn(float3 viewDirection, float3 normal, float2 texCoord)
{
	float3 halfVector = -normalize(viewDirection + gLightDirection);

	float specularStrength = pow(saturate(dot(halfVector, normal)), gShininess);

	float3 specColor = gColorSpecular.rgb * specularStrength;

	if (gUseTextureSpecularIntensity)
	{
		specColor = specColor * gTextureSpecularIntensity.Sample(gTextureSampler, texCoord).r;
	}

	return specColor;
}

float3 CalculatePhong(float3 viewDirection, float3 normal, float2 texCoord)
{
	float3 reflectDir = reflect(-gLightDirection, normal);

	float specularStrength = pow(saturate(dot(reflectDir, viewDirection)), gShininess);

	float3 specColor = gColorSpecular.rgb * specularStrength;

	if (gUseTextureSpecularIntensity)
	{
		specColor = specColor * gTextureSpecularIntensity.Sample(gTextureSampler, texCoord).r;
	}

	return specColor;
}

float3 CalculateSpecular(float3 viewDirection, float3 normal, float2 texCoord)
{
	float3 specColor = float3(0, 0, 0);

	if (gUseSpecularBlinn)
	{
		specColor = CalculateBlinn(viewDirection, normal, texCoord);
	}
	else if (gUseSpecularPhong)
	{
		specColor = CalculatePhong(viewDirection, normal, texCoord);
	}

	return specColor;
}

float3 CalculateNormal(float3 tangent, float3 normal, float2 texCoord)
{
	if (!gUseTextureNormal)
	{
		return normal;
	}

	float3 binormal = normalize(cross(normal, tangent));

	if (gFlipGreenChannel)
	{
		binormal = -binormal;
	}

	float3x3 localAxis = float3x3(tangent, binormal, normal);

	float3 normalSample = gTextureNormal.Sample(gTextureSampler, texCoord);

	float3 sampledNormal = 2.f * normalSample - 1.f;

	float3 newNormal = mul(sampledNormal, localAxis);

	return newNormal;
}

float3 CalculateDiffuse(float3 normal, float2 texCoord)
{
	float diffuseStrength = saturate(sqrt(dot(normal, -gLightDirection) * .5f + .5f));
	float3 diffColor = gColorDiffuse * diffuseStrength;
	if (gUseTextureDiffuse)
	{
		diffColor = diffColor * gTextureDiffuse.Sample(gTextureSampler, texCoord);
	}

	return diffColor;
}

float3 CalculateFresnelFalloff(float3 normal, float3 viewDirection, float3 environmentColor)
{
	if (!gUseFresnelFalloff)
	{
		return environmentColor;
	}
	float fresnel = mul(saturate(pow(1 - saturate(abs(dot(normal, viewDirection))), gFresnelPower)), gFresnelMultiplier);
	float3 YUp = (0, -1, 0);
	float fresnelMask = pow((1 - saturate(dot(YUp, normal))), gFresnelHardness);

	if (gUseEnvironmentMapping)
	{
		return fresnel * fresnelMask * environmentColor;
	}

	return fresnel * fresnelMask * gFresnelColor;
}

float3 CalculateEnvironment(float3 viewDirection, float3 normal)
{
	if (!gUseEnvironmentMapping)
	{
		return float3(0, 0, 0);
	}
	float3 reflectedVector = reflect(viewDirection, normal);
	float3 refractedVector = refract(viewDirection, normal, gRefractionIndex);

	float3 environmentColor = gCubeEnvironment.Sample(gTextureSampler, reflectedVector) * gReflectionStrength + gCubeEnvironment.Sample(gTextureSampler, refractedVector).rgb * gRefractionStrength;
	return environmentColor;
}

float CalculateOpacity(float2 texCoord)
{
	float opacity = gOpacityIntensity;

	if (gUseTextureOpacity)
	{
		opacity = gTextureOpacity.Sample(gTextureSampler, texCoord).r;
	}

	return opacity;
}

VS_Output MainVS(VS_Input input) {
	VS_Output output = (VS_Output)0;

	output.Position = mul(float4(input.Position, 1.0), gMatrixWVP);
	output.WorldPosition = mul(float4(input.Position, 1.0), gMatrixWorld);
	output.Normal = mul(input.Normal, (float3x3)gMatrixWorld);
	output.Tangent = mul(input.Tangent, (float3x3)gMatrixWorld);
	output.TexCoord = input.TexCoord;

	return output;
}

float4 MainPS(VS_Output input) : SV_TARGET{
		input.Normal = normalize(input.Normal);
	input.Tangent = normalize(input.Tangent);

	float3 viewDirection = normalize(input.WorldPosition.xyz - gMatrixViewInverse[3].xyz);

		float3 newNormal = CalculateNormal(input.Tangent, input.Normal, input.TexCoord);

		float3 specColor = CalculateSpecular(viewDirection, newNormal, input.TexCoord);

		float3 diffColor = CalculateDiffuse(newNormal, input.TexCoord);

		float3 ambientColor = gColorAmbient * gAmbientIntensity;

		float3 environmentColor = CalculateEnvironment(viewDirection, newNormal);

		environmentColor = CalculateFresnelFalloff(newNormal, viewDirection, environmentColor);

		float3 finalColor = diffColor + specColor + environmentColor + ambientColor;

		float opacity = CalculateOpacity(input.TexCoord);

	return float4(finalColor,opacity);
}

technique10 WithAlphaBlending {
	pass p0 {
		SetRasterizerState(gRS_FrontCulling);
		SetBlendState(gBS_EnableBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetVertexShader(CompileShader(vs_4_0, MainVS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, MainPS()));
	}
}

technique10 WithoutAlphaBlending {
	pass p0 {
		SetRasterizerState(gRS_FrontCulling);
		SetVertexShader(CompileShader(vs_4_0, MainVS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, MainPS()));
	}
}