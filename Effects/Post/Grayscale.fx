SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Mirror;
    AddressV = Mirror;
};

Texture2D gTexture;

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
	    output.Position = float4(input.Position,1.0f);
	    output.TexCoord = input.TexCoord;
	
	return output;
}


float4 PS(PS_INPUT input): SV_Target
{
        float4 result = gTexture.Sample(samPoint, input.TexCoord);
		float meanVal = (result.x + result.y + result.z) / 3.0f;

	    return float4(meanVal,meanVal,meanVal ,result.w);
}


technique11 Grayscale
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

