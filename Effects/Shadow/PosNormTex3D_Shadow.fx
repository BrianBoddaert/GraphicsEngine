float4x4 gWorld : WORLD;
float4x4 gWorldViewProj : WORLDVIEWPROJECTION;
float4x4 gWorldViewProj_Light;
float3 gLightDirection = float3(-0.577f, -0.577f, 0.577f);
float gShadowMapBias = 0.01f;

Texture2D gDiffuseMap;
Texture2D gShadowMap;

SamplerComparisonState cmpSampler
{
	    Filter = COMPARISON_MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = MIRROR;

	    ComparisonFunc = LESS_EQUAL;
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;     AddressV = Wrap; };

SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
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

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output = (VS_OUTPUT) 0;
	
			
    output.pos = mul(float4(input.pos, 1), gWorldViewProj);
    output.normal = input.normal;
    output.texCoord = input.texCoord;
    output.lPos = mul(float4(input.pos, 1), gWorldViewProj_Light);
 
    return output;
}

float2 texOffset(int u, int v)
{
	    return float2(u * 1.0f / 1280, v * 1.0f / 720);
}

float EvaluateShadowMap(float4 lpos)
{
		    lpos.xyz /= lpos.w;
 
            
    if (lpos.x < -1.0f || lpos.x > 1.0f ||
        lpos.y < -1.0f || lpos.y > 1.0f ||
        lpos.z < 0.0f || lpos.z > 1.0f)
    {
        return 0;
    }
	
        lpos.x = lpos.x / 2 + 0.5;
    lpos.y = lpos.y / -2 + 0.5;
	
	    lpos.z -= 0.01f;
	
    float sum = 0;
    float x, y;
 
        for (y = -1.5; y <= 1.5; y += 1.0)
    {
        for (x = -1.5; x <= 1.5; x += 1.0)
        {
            sum += gShadowMap.SampleCmpLevelZero(cmpSampler, lpos.xy + texOffset(x, y), lpos.z);
        }
    }
 
    float shadowFactor = sum / 16.0 + 0.2f;     
    if (shadowFactor > 1.0f)
        shadowFactor = 1.f;
    
          	
        return shadowFactor;
}

float4 PS(VS_OUTPUT input) : SV_TARGET
{
    float shadowValue = EvaluateShadowMap(input.lPos);

    float4 diffuseColor = gDiffuseMap.Sample(samLinear, input.texCoord);
    float3 color_rgb = diffuseColor.rgb;
    float color_a = diffuseColor.a;
	
	    float diffuseStrength = dot(input.normal, -gLightDirection);
    diffuseStrength = diffuseStrength * 0.5 + 0.5;
    diffuseStrength = saturate(diffuseStrength);
    color_rgb = color_rgb * diffuseStrength;

    return float4(color_rgb * shadowValue, color_a);
}

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

