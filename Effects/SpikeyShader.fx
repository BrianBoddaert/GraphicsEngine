
float4x4 m_MatrixWorldViewProj : WORLDVIEWPROJECTION;
float4x4 m_MatrixWorld : WORLD;
float3 m_LightDir = { 0.2f, -1.0f, 0.2f };

float gSpikeHeight
<
    string UIName = "Spike Height";
    string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 100;
    float UIStep = 0.1;
> = 8.0f;

RasterizerState FrontCulling
{
    CullMode = NONE;
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;     AddressV = Wrap; };

Texture2D m_TextureDiffuse;

struct VS_DATA
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD;
};

struct GS_DATA
{
    float4 Position : SV_POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
};

VS_DATA MainVS(VS_DATA vsData)
{
    return vsData;
}

void CreateVertex(inout TriangleStream<GS_DATA> triStream, float3 pos, float3 normal, float2 texCoord)
{
	    GS_DATA gsData = (GS_DATA)0;
	    gsData.Position = mul(float4(pos, 1.0), m_MatrixWorldViewProj);
	    gsData.Normal = mul(normal, (float3x3) m_MatrixWorld);
	    gsData.TexCoord = texCoord;
	    triStream.Append(gsData);
}

[maxvertexcount(6)]
void SpikeGenerator(triangle VS_DATA vertices[3], inout TriangleStream<GS_DATA> triStream)
{
	    float3 basePoint, top, left, right, spikeNormal, spikeDir,baseNormal,edge1,edge2;

	    basePoint = (vertices[0].Position + vertices[1].Position + vertices[2].Position) / 3;
	    baseNormal = (vertices[0].Normal + vertices[1].Normal + vertices[2].Normal) / 3;
    baseNormal = normalize(baseNormal);
	    top = basePoint + (gSpikeHeight * baseNormal);
	    spikeDir = (vertices[2].Position - vertices[0].Position) * 0.1f;
    left = basePoint - spikeDir;
    right = basePoint + spikeDir;
	    edge1 = left - top;
    edge2 = right - top;
    spikeNormal = cross(edge1,edge2);

	    CreateVertex(triStream, vertices[0].Position, vertices[0].Normal, vertices[0].TexCoord);
    CreateVertex(triStream, vertices[1].Position, vertices[1].Normal, vertices[1].TexCoord);
    CreateVertex(triStream, vertices[2].Position, vertices[2].Normal, vertices[2].TexCoord);

	    triStream.RestartStrip();

	    CreateVertex(triStream, top, spikeNormal, float2(0, 0));
    CreateVertex(triStream, left, spikeNormal, float2(0, 0));
    CreateVertex(triStream, right, spikeNormal, float2(0, 0));
}

float4 MainPS(GS_DATA input) : SV_TARGET
{
    input.Normal = -normalize(input.Normal);
    float alpha = m_TextureDiffuse.Sample(samLinear, input.TexCoord).a;
    float3 color = m_TextureDiffuse.Sample(samLinear, input.TexCoord).rgb;
    float s = max(dot(m_LightDir, input.Normal), 0.4f);

    return float4(color * s, alpha);
}

technique10 DefaultTechnique
{
    pass p0
    {
        SetRasterizerState(FrontCulling);
        SetVertexShader(CompileShader(vs_4_0, MainVS()));
        SetGeometryShader(CompileShader(gs_4_0, SpikeGenerator()));
        SetPixelShader(CompileShader(ps_4_0, MainPS()));
    }
}