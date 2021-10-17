float4x4 gTransform : WorldViewProjection;
Texture2D gSpriteTexture;
float2 gTextureSize;

SamplerState samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = WRAP;
    AddressV = WRAP;
};

BlendState EnableBlending
{
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
};

DepthStencilState NoDepth
{
    DepthEnable = FALSE;
};

RasterizerState BackCulling
{
    CullMode = BACK;
};


struct VS_DATA
{
    uint TextureId : TEXCOORD0;
    float4 TransformData : POSITION;     float4 TransformData2 : POSITION1;     float4 Color : COLOR;
};

struct GS_DATA
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR;
    float2 TexCoord : TEXCOORD0;
};

VS_DATA MainVS(VS_DATA input)
{
    return input;
}

void CreateVertex(inout TriangleStream<GS_DATA> triStream, float3 pos, float4 col, float2 texCoord, float rotation, float2 rotCosSin, float2 offset, float2 pivotOffset)
{
    if (rotation != 0)
    {
                pos.x -= pivotOffset.x;
        pos.y -= pivotOffset.y;

                
                pos = float3(pos.x - offset.x, pos.y - offset.y, pos.z);
        float3 originalPos = pos;
                pos.x = (originalPos.x * rotCosSin.x) - (originalPos.y * rotCosSin.y);
        pos.y = (originalPos.y * rotCosSin.x) + (originalPos.x * rotCosSin.y);

                pos = float3(pos.x + offset.x, pos.y + offset.y, pos.z);

    }
    else
    {
        pos.x -= pivotOffset.x;
        pos.y -= pivotOffset.y;
    }

        GS_DATA geomData = (GS_DATA)0;

    geomData.Position = mul(float4(pos, 1.0f), gTransform);
    geomData.Color = col;
    geomData.TexCoord = texCoord;
    triStream.Append(geomData);
}

[maxvertexcount(4)]
void MainGS(point VS_DATA vertex[1], inout TriangleStream<GS_DATA> triStream)
{
        float3 position = float3(vertex[0].TransformData.x, vertex[0].TransformData.y, vertex[0].TransformData.z);     float2 offset = float2(vertex[0].TransformData.x, vertex[0].TransformData.y);     float rotation = vertex[0].TransformData.w;     float2 pivot = float2(vertex[0].TransformData2.x, vertex[0].TransformData2.y);     float2 scale = float2(vertex[0].TransformData2.z, vertex[0].TransformData2.w);     float2 texCoord = vertex[0].TextureId;     float4 color = vertex[0].Color;
    float2 rotCosSin;

    if (rotation == 0)
    {
        rotCosSin = float2(0, 0);
    }
    else
    {
        rotCosSin = float2(cos(rotation), sin(rotation));
    }
    
                        
   
        pivot = gTextureSize * scale * pivot;

    float3 leftTop = position;
    float3 rightTop = position + float3(gTextureSize.x * scale.x, 0, 0);
    float3 leftBot = position + float3(0, gTextureSize.y * scale.y, 0);
    float3 rightBot = position + float3(gTextureSize.x * scale.x, gTextureSize.y * scale.y, 0);

        CreateVertex(triStream, leftTop, color, float2(0.0f, 0.0f), rotation, rotCosSin, offset, pivot);

        CreateVertex(triStream, rightTop, color, float2(1.0f, 0.0f), rotation, rotCosSin, offset, pivot);

        CreateVertex(triStream, leftBot, color, float2(0.0f, 1.0f), rotation, rotCosSin, offset, pivot);

        CreateVertex(triStream, rightBot, color, float2(1.0f, 1.0f), rotation, rotCosSin, offset, pivot);
}

float4 MainPS(GS_DATA input) : SV_TARGET
{
    return gSpriteTexture.Sample(samPoint, input.TexCoord) * input.Color;
}

technique10 DefaultTechniqueDX10
{
    pass p0
    {
        SetRasterizerState(BackCulling);
        SetBlendState(EnableBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
                SetVertexShader(CompileShader(vs_4_0, MainVS()));
        SetGeometryShader(CompileShader(gs_4_0, MainGS()));
        SetPixelShader(CompileShader(ps_4_0, MainPS()));
    }
}
