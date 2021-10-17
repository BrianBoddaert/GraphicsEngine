float4x4 gWorld : WORLD;
float4x4 gWorldViewProj : WORLDVIEWPROJECTION;
float4x4 gWorldViewProj_Light;
float3 gLightDirection = float3(-0.577f, -0.577f, 0.577f);
float gShadowMapBias = 0.01f;
float4x4 gBones[70];

Texture2D gDiffuseMap;
Texture2D gShadowMap;

SamplerComparisonState cmpSampler
{
	// sampler state
    Filter = COMPARISON_MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = MIRROR;

	// sampler comparison state
    ComparisonFunc = LESS_EQUAL;
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap; // or Mirror or Clamp or Border
    AddressV = Wrap; // or Mirror or Clamp or Border
};

struct VS_INPUT
{
    float3 pos : POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD;
    float4 BoneIndices : BLENDINDICES;
    float4 BoneWeights : BLENDWEIGHTS;
};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD;
    float4 lPos : TEXCOORD1;
};

DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
};

RasterizerState NoCulling
{
    CullMode = NONE;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output = (VS_OUTPUT) 0;

	//TODO: complete Vertex Shader 
	//Hint: use the previously made shaders PosNormTex3D_Shadow and PosNormTex3D_Skinned as a guide
    float4 originalPosition = float4(input.pos, 1);
    float4 transformedPosition = 0;
    float3 transformedNormal = 0;

	//Skinning
    for (int i = 0; i < 4; ++i)
    {
		//get current bone index
        float currentBoneIndex = input.BoneIndices[i];
		//
        if (currentBoneIndex > -1) //the vertex is attached to a bone
        {
            transformedPosition += input.BoneWeights[i] * mul(originalPosition, gBones[input.BoneIndices[i]]);
            transformedPosition[3] = 1.0;
            transformedNormal += input.BoneWeights[i] * mul(input.normal, gBones[input.BoneIndices[i]]);
        }
		
    }

    output.pos = mul(transformedPosition, gWorldViewProj); //funny result if gWorldViewProj_Light
    output.normal = normalize(mul(transformedNormal, (float3x3) gWorld));
    output.texCoord = input.texCoord;
    //store worldspace projected to light clip space with
    //a texcoord semantic to be interpolated acrmoss the surface
    output.lPos = mul(transformedPosition, gWorldViewProj_Light);
	
    return output;
}

float2 texOffset(int u, int v)
{
	//TODO: return offseted value (our shadow map has the following dimensions: 1280 * 720)
    return float2(u * 1.0f / 1280, v * 1.0f / 720);
}

float EvaluateShadowMap(float4 lPos)
{
	//TODO: complete
	//re-homogenize position after interpolation
    lPos.xyz /= lPos.w;
 
    //if position is not visible to the light - dont illuminate it
    //results in hard light frustum
    //if (lPos.x < -1.0f || lPos.x > 1.0f ||
    //    lPos.y < -1.0f || lPos.y > 1.0f ||
    //    lPos.z < 0.0f || lPos.z > 1.0f)
    //    return 0;
 
    //transform clip space coords to texture space coords (-1:1 to 0:1)
    lPos.x = lPos.x / 2 + 0.5;
    lPos.y = lPos.y / -2 + 0.5;
	
	//apply shadow map bias
    lPos.z -= 0.01f;
	
	//sample shadow map - point sampler
    //float shadowMapDepth = gShadowMap.Sample(samLinear, lPos.xy).r;
	
    float sum = 0;
    float x, y;
 
    //perform PCF filtering on a 4 x 4 texel neighborhood
    for (y = -1.5; y <= 1.5; y += 1.0)
    {
        for (x = -1.5; x <= 1.5; x += 1.0)
        {
            sum += gShadowMap.SampleCmpLevelZero(cmpSampler, lPos.xy + texOffset(x, y), lPos.z);
        }
    }
 
    float shadowFactor = sum / 16.0 + 0.2f; // /16.0
    
    if (shadowFactor > 1.0f)
        shadowFactor = 1.f;
 
    //if clip space z value greater than shadow map value then pixel is in shadow
  //  if (shadowFactor < lPos.z)
  //      return 0;
	
    //return shadowMapDepth * shadowFactor;
    return shadowFactor;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_TARGET
{
    float shadowValue = EvaluateShadowMap(input.lPos);

    float4 diffuseColor = gDiffuseMap.Sample(samLinear, input.texCoord);
    float3 color_rgb = diffuseColor.rgb;
    float color_a = diffuseColor.a;
	
	//HalfLambert Diffuse :)
    float diffuseStrength = dot(input.normal, -gLightDirection);
    diffuseStrength = diffuseStrength * 0.5 + 0.5;
    diffuseStrength = saturate(diffuseStrength);
    color_rgb = color_rgb * diffuseStrength;

    return float4(color_rgb * shadowValue, color_a);
	
}

//--------------------------------------------------------------------------------------
// Technique
//--------------------------------------------------------------------------------------
technique11 Default
{
    pass P0
    {
        SetRasterizerState(NoCulling);
        SetDepthStencilState(EnableDepth, 0);

        SetVertexShader(CompileShader(vs_4_0, VS()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, PS()));
    }
}

