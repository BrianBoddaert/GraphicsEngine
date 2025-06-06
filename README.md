[![image](https://github.com/user-attachments/assets/70b91008-0eba-495b-8d65-479497842d6d)
](https://www.youtube.com/watch?v=T_A0JKwylHs)

## Action game demo made with the engine.

Custom engine implementation on top of Overlord engine. This project includes custom HLSL shaders made through the DirectX11 pipeline, particle effects, text rendering, shadow mapping and a model animator.

### Shaders
I wrote my shaders in HLSL using FXComposer. My final shader made use of the following shaders / techniques:

- Diffuse
- Specular
	- Specular Level
	- Shininess
	- Blinn
	- Phong
- Ambient
- Environment Mapping (CubeMap)
	- Reflection with Fresnel Falloff
	- Refraction
- Normal
- Opacity
- Techniques
	- With Alpha Blending
	- Without Alpha Blending

### Shadow mapping

Shadow mapping is done by first generating a shadow map texture about depth information from the lights perspective and then rendering the shadow map to the scene. HLSL is used in the shadow map to disable the colors and only write the depth, and then it's used during the actual rendering to convert the vertex world coordinates to light clip space.

```
float EvaluateShadowMap(float4 lpos)
{
	//re-homogenize position after interpolation
    lpos.xyz /= lpos.w;
 
    //if position is not visible to the light - dont illuminate it
    //results in hard light frustum
    
    if (lpos.x < -1.0f || lpos.x > 1.0f ||
        lpos.y < -1.0f || lpos.y > 1.0f ||
        lpos.z < 0.0f || lpos.z > 1.0f)
    {
        return 0;
    }
	
    //transform clip space coords to texture space coords (-1:1 to 0:1)
    lpos.x = lpos.x / 2 + 0.5;
    lpos.y = lpos.y / -2 + 0.5;
	
	//apply shadow map bias
    lpos.z -= 0.01f;
	
    float sum = 0;
    float x, y;
 
    //perform PCF filtering on a 4 x 4 texel neighborhood
    for (y = -1.5; y < 1.5; y += 1.0)
        for (x = -1.5; x < 1.5; x += 1.0)
            sum += gShadowMap.SampleCmpLevelZero(cmpSampler, lpos.xy + texOffset(x, y), lpos.z).r;
 
    float shadowFactor = sum / 16.0;
    
    // If the clip space z is greater than the shadow map then it's in the shadow
    if (shadowFactor > lpos.z)
        shadowFactor = 1.f;
	
    return shadowFactor;
}

```

### Particle Effects

Particle emitters make use of the object pool pattern where the buffer is mapped to the GPU. The emitter is responsible for updating all the particles it has spawned. Particles are rendered at the end of the scene's render cycle with depth writing disabled to prevent artifacts with commonly used transparency in particles. In the geometry shader the vertices of every particle get created and rotated to always face the camera.

```
[maxvertexcount(4)]
void MainGS(point VS_DATA vertex[1], inout TriangleStream<GS_DATA> triStream)
{
	float3 topLeft, topRight, bottomLeft, bottomRight;
	float halfSize = vertex[0].Size/2;
	float3 origin = vertex[0].Position;

	//Vertices positions
	topLeft = float3(-halfSize, halfSize,0);
	topRight = float3(halfSize, halfSize, 0);
	bottomLeft = float3(-halfSize, -halfSize, 0);
	bottomRight = float3(halfSize, -halfSize, 0);
   
	//Transforming the vertices with the viewInverse's rotation (only using the matrix's 3x3). This rotates them to face the camera.
	topLeft = mul(topLeft, gViewInverse);
	topRight =  mul(topRight, gViewInverse);
	bottomLeft =  mul(bottomLeft, gViewInverse);
	bottomRight =  mul(bottomRight, gViewInverse);
	
	topLeft+=origin;
	topRight+=origin;
	bottomLeft+=origin;
	bottomRight+=origin;
	
	//This is the 2x2 rotation matrix I need to transform my TextureCoordinates (Texture Rotation)
	float2x2 uvRotation = {cos(vertex[0].Rotation), - sin(vertex[0].Rotation), sin(vertex[0].Rotation), cos(vertex[0].Rotation)};
	
	//Creating Geometry (Trianglestrip)
	CreateVertex(triStream,bottomLeft, float2(0,1), vertex[0].Color, uvRotation);
	CreateVertex(triStream,topLeft, float2(0,0), vertex[0].Color, uvRotation);
	CreateVertex(triStream,bottomRight, float2(1,1), vertex[0].Color, uvRotation);
	CreateVertex(triStream,topRight, float2(1,0), vertex[0].Color, uvRotation);
}
```
### Model animator

The animation files get transferred to files specific to the overlord engine (.ovm files), these files hold all the animation information in binary. After reading these files I lerp between the transforms to get a smooth transition.

```
//Interpolate between keys

//Figure out the BlendFactor.
float blendFactorA = keyB.Tick - m_TickCount;
float offset = keyB.Tick - keyA.Tick;

blendFactorA /= offset;

//Clear the m_Transforms vector
m_Transforms.clear();

//For every boneTransform in a key (So for every bone)
for (size_t j = 0; j < m_pMeshFilter->m_BoneCount; j++)
{
	//	Retrieve the transform from keyA (transformA)
	const auto transformA = keyA.BoneTransforms[j];
	// 	Retrieve the transform from keyB (transformB)
	const auto transformB = keyB.BoneTransforms[j];

	auto transformAMatrix = DirectX::XMLoadFloat4x4(&transformA);
	auto transformBMatrix = DirectX::XMLoadFloat4x4(&transformB);

	DirectX::XMVECTOR transA{}, rotA{}, scaleA{}, transB{}, rotB{}, scaleB{};

	//	Decompose both transforms
	DirectX::XMMatrixDecompose(&scaleA, &rotA, &transA, transformAMatrix);
	DirectX::XMMatrixDecompose(&scaleB, &rotB, &transB, transformBMatrix);

	//	Lerp between all the transformations (Position, Scale, Rotation)
	auto translation = DirectX::XMVectorLerp(transA, transB, blendFactorA);
	auto scale = DirectX::XMVectorLerp(scaleA, scaleB, blendFactorA);
	auto rot = DirectX::XMQuaternionSlerp(rotA, rotB, blendFactorA);

	//	Compose a transformation matrix with the lerp-results
	auto newTranformMatrix = DirectX::XMMatrixAffineTransformation(scale, DirectX::g_XMZero, rot, translation);
	DirectX::XMFLOAT4X4 newTransformFloat4x4 = {};
	DirectX::XMStoreFloat4x4(&newTransformFloat4x4, newTranformMatrix);

	m_Transforms.push_back(newTransformFloat4x4);
}

if (m_PlayOnce)
	if (m_TickCount >= m_CurrentClip.Duration - 1)
		PlayOnceEnded();
```
