float4x4 gWorldViewProj : WorldViewProjection;
float4x4 gViewInverse : ViewInverse;
Texture2D gParticleTexture;

SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = WRAP;
    AddressV = WRAP;
};

BlendState AlphaBlending 
{     
	BlendEnable[0] = TRUE;
	SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
	BlendOp = ADD;
	SrcBlendAlpha = ONE;
	DestBlendAlpha = ZERO;
	BlendOpAlpha = ADD;
	RenderTargetWriteMask[0] = 0x0f;
};

DepthStencilState DisableDepthWriting
{
		DepthEnable = TRUE;
		DepthWriteMask = ZERO;
};

RasterizerState BackCulling
{
	CullMode = BACK;
};


struct VS_DATA
{
	float3 Position : POSITION;
	float4 Color: COLOR;
	float Size: TEXCOORD0;
	float Rotation: TEXCOORD1;
};

struct GS_DATA
{
	float4 Position : SV_POSITION;
	float2 TexCoord: TEXCOORD0;
	float4 Color : COLOR;
};

VS_DATA MainVS(VS_DATA input)
{
	return input;
}

void CreateVertex(inout TriangleStream<GS_DATA> triStream, float3 pos, float2 texCoord, float4 col, float2x2 uvRotation)
{
		GS_DATA geomData = (GS_DATA) 0;
		geomData.Position = mul(float4(pos, 1.0f), gWorldViewProj);
					texCoord -= float2(0.5f,0.5f);
		texCoord = mul(texCoord, uvRotation);
		texCoord += float2(0.5f,0.5f);
		geomData.TexCoord = texCoord;
		geomData.Color = col;
		triStream.Append(geomData);
}

[maxvertexcount(4)]
void MainGS(point VS_DATA vertex[1], inout TriangleStream<GS_DATA> triStream)
{
		float3 topLeft, topRight, bottomLeft, bottomRight;
	float halfSize = vertex[0].Size/2;
	float3 origin = vertex[0].Position;

		topLeft = float3(-halfSize, halfSize,0);
    topRight = float3(halfSize, halfSize, 0);
    bottomLeft = float3(-halfSize, -halfSize, 0);
    bottomRight = float3(halfSize, -halfSize, 0);
		
	topLeft = mul(topLeft, gViewInverse);
    topRight =  mul(topRight, gViewInverse);
    bottomLeft =  mul(bottomLeft, gViewInverse);
    bottomRight =  mul(bottomRight, gViewInverse);
	
	topLeft+=origin;
    topRight+=origin;
    bottomLeft+=origin;
    bottomRight+=origin;
	
		float2x2 uvRotation = {cos(vertex[0].Rotation), - sin(vertex[0].Rotation), sin(vertex[0].Rotation), cos(vertex[0].Rotation)};
	
		CreateVertex(triStream,bottomLeft, float2(0,1), vertex[0].Color, uvRotation);
	CreateVertex(triStream,topLeft, float2(0,0), vertex[0].Color, uvRotation);
	CreateVertex(triStream,bottomRight, float2(1,1), vertex[0].Color, uvRotation);
	CreateVertex(triStream,topRight, float2(1,0), vertex[0].Color, uvRotation);
}

float4 MainPS(GS_DATA input) : SV_TARGET {
	
		float4 result = gParticleTexture.Sample(samPoint,input.TexCoord);
	return input.Color * result;
}

technique10 Default {

	pass p0 {
		SetVertexShader(CompileShader(vs_4_0, MainVS()));
		SetGeometryShader(CompileShader(gs_4_0, MainGS()));
		SetPixelShader(CompileShader(ps_4_0, MainPS()));
		
		SetRasterizerState(BackCulling);       
		SetDepthStencilState(DisableDepthWriting, 0);
        SetBlendState(AlphaBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF);
	}
}
