//=============================================================================
//// Shader uses position and texture
//=============================================================================
SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Mirror;
    AddressV = Mirror;
};

Texture2D gTexture;
float gElapsedTime;
bool gEnabled;

/// Create Depth Stencil State (ENABLE DEPTH WRITING)
DepthStencilState EnableDepthWriting
{
    //Enable Depth Rendering
    DepthEnable = TRUE;
    //Disable Depth Writing
    DepthWriteMask = ALL;
};

/// Create Rasterizer State (Backface culling) 
RasterizerState BackCulling
{
    CullMode = BACK;
};


//IN/OUT STRUCTS
//--------------
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


//VERTEX SHADER
//-------------
PS_INPUT VS(VS_INPUT input)
{
    PS_INPUT output = (PS_INPUT)0;
    // Set the Position
    output.Position = float4(input.Position,1);
    // Set the TexCoord
    output.TexCoord = input.TexCoord;
    
    return output;
}


//PIXEL SHADER
//------------
float4 PS(PS_INPUT input): SV_Target
{
    float4 textureSample = gTexture.Sample(samPoint, input.TexCoord);

    if (!gEnabled)
        return float4(textureSample.x, textureSample.y , textureSample.z, 1);
    
    float floatingFactor = abs(sin(gElapsedTime)) * 0.04f;

    return float4(textureSample.x + floatingFactor * 3, textureSample.y - floatingFactor, textureSample.z - floatingFactor, 1);
}


//TECHNIQUE
//---------
technique11 LowHealth
{
    pass P0
    {          
        // Set states...
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );

        SetRasterizerState(BackCulling);       
        SetDepthStencilState(EnableDepthWriting, 0);
    }
}