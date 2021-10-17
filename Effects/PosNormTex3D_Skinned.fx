
float4x4 gWorld : WORLD;
float4x4 gWorldViewProj : WORLDVIEWPROJECTION;
float3 gLightDirection = float3(-0.577f, -0.577f, 0.577f);
float4x4 gBones[70];

Texture2D gDiffuseMap;
SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;     AddressV = Wrap; };

RasterizerState Solid
{
    FillMode = SOLID;
    CullMode = FRONT;
};

struct VS_INPUT
{
    float3 pos : POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD;
    float4 BlendWeights : BLENDWEIGHTS;
    float4 BlendIndices : BLENDINDICES;
	};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float3 normal : NORMAL;
    float2 texCoord : TEXCOORD;
};



VS_OUTPUT VS(VS_INPUT input)
{

    VS_OUTPUT output;

    float4 originalPosition = float4(input.pos, 1);
    float4 transformedPosition = 0;
    float3 transformedNormal = 0;

    for (int i = 0; i < 4; ++i)
    {
        float currentBoneIndex = input.BlendIndices[i];
        if (currentBoneIndex > -1)
        {
            transformedPosition += input.BlendWeights[i] * mul(originalPosition, gBones[input.BlendIndices[i]]);
            transformedNormal += input.BlendWeights[i] * mul(input.normal, gBones[input.BlendIndices[i]]);
            transformedPosition[3] = 1;
        }
    }
	
	    output.pos = mul(transformedPosition, gWorldViewProj);     output.normal = normalize(mul(transformedNormal, (float3x3) gWorld)); 
    output.texCoord = input.texCoord;
    return output;
}

float4 PS(VS_OUTPUT input) : SV_TARGET
{

    float4 diffuseColor = gDiffuseMap.Sample(samLinear, input.texCoord);
    float3 color_rgb = diffuseColor.rgb;
    float color_a = diffuseColor.a;
	
	    float diffuseStrength = dot(input.normal, -gLightDirection);
    diffuseStrength = diffuseStrength * 0.5 + 0.5;
    diffuseStrength = saturate(diffuseStrength);
    color_rgb = color_rgb * diffuseStrength;

    return float4(color_rgb, color_a);
}

technique11 Default
{
    pass P0
    {
        SetRasterizerState(Solid);
        SetVertexShader(CompileShader(vs_4_0, VS()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, PS()));
    }
}

