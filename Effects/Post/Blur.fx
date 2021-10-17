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
		float width, height;
	gTexture.GetDimensions(width,height);
		float dx = 1/width;
	float dy = 1/height;
	
	float2 newTexCoord = input.TexCoord;
	
	float4 color = float4(0,0,0,0);
		for (int i = 0; i < 5; i++)
	{
		for (int j = 0; j < 5; j++)
		{
						newTexCoord.x += dx *(i * 2);
			newTexCoord.y += dy *(j * 2);
			color += gTexture.Sample(samPoint, newTexCoord);
			newTexCoord = input.TexCoord;
		}
	}	
		float4 result = float4(color.x/25.0f,color.y/25.0f,color.z/25.0f,color.w);
	
	return result;
}


technique11 Blur
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