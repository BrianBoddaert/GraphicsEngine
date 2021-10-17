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
    output.Position = float4(input.Position,1.0f);
	// Set the TexCoord
    output.TexCoord = input.TexCoord;
	
	return output;
}


//PIXEL SHADER
//------------
float4 PS(PS_INPUT input): SV_Target
{
	// Step 1: find the dimensions of the texture (the texture has a method for that)	
	float width, height;
	gTexture.GetDimensions(width,height);
	// Step 2: calculate dx and dy (UV space for 1 pixel)	
	float dx = 1/width;
	float dy = 1/height;
	
	float2 newTexCoord = input.TexCoord;
	
	float4 color = float4(0,0,0,0);
	// Step 3: Create a double for loop (5 iterations each)
	for (int i = 0; i < 5; i++)
	{
		for (int j = 0; j < 5; j++)
		{
			//Inside the loop, calculate the offset in each direction. Make sure not to take every pixel but move by 2 pixels each time		
			newTexCoord.x += dx *(i * 2);
			newTexCoord.y += dy *(j * 2);
			color += gTexture.Sample(samPoint, newTexCoord);
			newTexCoord = input.TexCoord;
		}
	}	
	// Step 4: Divide the final color by the number of passes (in this case 5*5)	
	float4 result = float4(color.x/25.0f,color.y/25.0f,color.z/25.0f,color.w);
	// Step 5: return the final color

	return result;
}


//TECHNIQUE
//---------
technique11 Blur
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