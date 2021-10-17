float4x4 gWorld;
float4x4 gLightViewProj;
float4x4 gBones[70];
 
DepthStencilState depthStencilState
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
};

RasterizerState rasterizerState
{
    FillMode = SOLID;
    CullMode = NONE;
};

float4 ShadowMapVS(float3 position : POSITION) : SV_POSITION
{
	    return mul(float4(position, 1), mul(gWorld, gLightViewProj));
}

float4 ShadowMapVS_Skinned(float3 position : POSITION, float4 BoneIndices : BLENDINDICES, float4 BoneWeights : BLENDWEIGHTS) : SV_POSITION
{
		
    float4 output;

    float4 originalPosition = float4(position, 1);
    float4 transformedPosition = 0;


	    for (int i = 0; i < 4; ++i)
    {
		         int currentBoneIndex = BoneIndices[i];
		        if (currentBoneIndex > -1)         {
            transformedPosition += BoneWeights[i] * mul(originalPosition, gBones[currentBoneIndex]);
            transformedPosition[3] = 1.0;
        }
		
    }

    output = mul(transformedPosition, mul(gWorld, gLightViewProj));
    return output;
}
 
void ShadowMapPS_VOID(float4 position : SV_POSITION)
{
}

technique11 GenerateShadows
{
    pass P0
    {
        SetRasterizerState(rasterizerState);
        SetDepthStencilState(depthStencilState, 0);
        SetVertexShader(CompileShader(vs_4_0, ShadowMapVS()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, ShadowMapPS_VOID()));
    }
}

technique11 GenerateShadows_Skinned
{
    pass P0
    {
        SetRasterizerState(rasterizerState);
        SetDepthStencilState(depthStencilState, 0);
        SetVertexShader(CompileShader(vs_4_0, ShadowMapVS_Skinned()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, ShadowMapPS_VOID()));
    }
}