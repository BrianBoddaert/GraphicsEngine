SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Mirror;
    AddressV = Mirror;
};

Texture2D gTexture;
float gElapsedTime;
bool gEnabled;

DepthStencilState EnableDepthWriting
{
        DepthEnable = TRUE;
        DepthWriteMask = ALL;
};

RasterizerState BackCulling
{
    CullMode = BACK;
};


struct VS_INPUT
{
    float3 Position : POSITION;
    float2 TexCoord : TEXCOORD0;

};

struct PS_INPUT
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD1;
};


PS_INPUT VS(VS_INPUT input)
{
    PS_INPUT output = (PS_INPUT)0;
        output.Position = float4(input.Position,1);
        output.TexCoord = input.TexCoord;
    
    return output;
}


float4 PS(PS_INPUT input): SV_Target
{
    float4 textureSample = gTexture.Sample(samPoint, input.TexCoord);

    if (!gEnabled)
        return float4(textureSample.x, textureSample.y , textureSample.z, 1);
    
    float floatingFactor = abs(sin(gElapsedTime)) * 0.04f;

    return float4(textureSample.x + floatingFactor * 3, textureSample.y - floatingFactor, textureSample.z - floatingFactor, 1);
}


technique11 LowHealth
{
    pass P0
    {          
                SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );

        SetRasterizerState(BackCulling);       
        SetDepthStencilState(EnableDepthWriting, 0);
    }
}