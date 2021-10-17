#include "stdafx.h"
#include "ParticleEmitterComponent.h"
#include <utility>
#include "EffectHelper.h"
#include "ContentManager.h"
#include "TextureDataLoader.h"
#include "Particle.h"
#include "TransformComponent.h"
#include "GameObject.h"

ParticleEmitterComponent::ParticleEmitterComponent(std::wstring  assetFile, int particleCount, float lifetime) :
	m_pVertexBuffer(nullptr),
	m_pEffect(nullptr),
	m_pParticleTexture(nullptr),
	m_pInputLayout(nullptr),
	m_pInputLayoutSize(0),
	m_Settings(ParticleEmitterSettings()),
	m_ParticleCount(particleCount),
	m_ActiveParticles(0),
	m_LastParticleInit(0.0f),
	m_AssetFile(std::move(assetFile)),
	m_Transperancy(1.0f),
	m_Lifetime(lifetime)
{
	for (int i = 0; i < m_ParticleCount; i++)
	{
		m_Particles.push_back(new Particle(m_Settings));
	}
}

ParticleEmitterComponent::~ParticleEmitterComponent()
{
	for (int i = 0; i < m_ParticleCount; i++)
	{
		SafeDelete(m_Particles[i]);
	}

	m_Particles.clear();

	SafeRelease(m_pInputLayout);
	SafeRelease(m_pVertexBuffer);
}

void ParticleEmitterComponent::Initialize(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);

	LoadEffect(gameContext);
	CreateVertexBuffer(gameContext);

	m_pParticleTexture = ContentManager::Load<TextureData>(m_AssetFile);
}

void ParticleEmitterComponent::LoadEffect(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);

	m_pEffect = ContentManager::Load<ID3DX11Effect>(L"./Resources/Effects/ParticleRenderer.fx");
	m_pDefaultTechnique = m_pEffect->GetTechniqueByIndex(0);
	m_pWvpVariable = m_pEffect->GetVariableByName("gWorldViewProj")->AsMatrix();
	m_pViewInverseVariable = m_pEffect->GetVariableByName("gViewInverse")->AsMatrix();
	m_pTextureVariable = m_pEffect->GetVariableByName("gParticleTexture")->AsShaderResource();

	EffectHelper::BuildInputLayout(gameContext.pDevice, m_pDefaultTechnique, &m_pInputLayout, m_pInputLayoutSize);
}

void ParticleEmitterComponent::CreateVertexBuffer(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);

	if (m_pVertexBuffer)
	{
		SafeRelease(m_pVertexBuffer);
	}

	D3D11_BUFFER_DESC buffDesc;
	buffDesc.Usage = D3D11_USAGE_DYNAMIC;
	buffDesc.ByteWidth = sizeof(ParticleVertex) * m_ParticleCount;
	buffDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	buffDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	buffDesc.MiscFlags = 0;

	gameContext.pDevice->CreateBuffer(&buffDesc, nullptr, &m_pVertexBuffer);
}

void ParticleEmitterComponent::Update(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);

	float deltaT = gameContext.pGameTime->GetElapsed();

	m_Lifetime -= deltaT;

	if (m_Lifetime <= 0)
	{
		m_pGameObject->SetIsMarkedForDelete(true);
		return;
	}

	float particleInterval = ((m_Settings.MaxEnergy + m_Settings.MinEnergy) / 2) / m_ParticleCount;

	m_LastParticleInit += gameContext.pGameTime->GetElapsed();

	m_ActiveParticles = 0;

	D3D11_MAPPED_SUBRESOURCE mappedResource;
	gameContext.pDeviceContext->Map(m_pVertexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedResource);
	ParticleVertex* pBuffer = (ParticleVertex*)mappedResource.pData;

	for (Particle* particle : m_Particles)
	{
		particle->Update(gameContext);

		if (particle->IsActive())
		{
			pBuffer[m_ActiveParticles] = particle->GetVertexInfo();
			pBuffer[m_ActiveParticles].Color.w = m_Transperancy;

			m_ActiveParticles++;
		}
		else if (m_LastParticleInit >= particleInterval)
		{
			particle->Init(GetTransform()->GetWorldPosition());

			pBuffer[m_ActiveParticles] = particle->GetVertexInfo();
			pBuffer[m_ActiveParticles].Color.w = m_Transperancy;

			m_ActiveParticles++;

			m_LastParticleInit = 0;
		}


	}

	gameContext.pDeviceContext->Unmap(m_pVertexBuffer, 0);

}

void ParticleEmitterComponent::Draw(const GameContext&)
{
}

void ParticleEmitterComponent::PostDraw(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);

	m_pWvpVariable->SetMatrix(&gameContext.pCamera->GetViewProjection()._11);

	m_pViewInverseVariable->SetMatrix(&gameContext.pCamera->GetViewProjectionInverse()._11);

	m_pTextureVariable->SetResource(m_pParticleTexture->GetShaderResourceView());

	UINT offset = 0;

	const UINT stridesSize = sizeof(ParticleVertex);
	gameContext.pDeviceContext->IASetInputLayout(m_pInputLayout);

	gameContext.pDeviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY::D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);

	gameContext.pDeviceContext->IASetVertexBuffers(0, 1, &m_pVertexBuffer, &stridesSize, &offset);

	D3DX11_TECHNIQUE_DESC techDesc;
	m_pDefaultTechnique->GetDesc(&techDesc);

	for (size_t i = 0; i < techDesc.Passes; i++)
	{
		m_pDefaultTechnique->GetPassByIndex(i)->Apply(0, gameContext.pDeviceContext);
		gameContext.pDeviceContext->Draw(m_ActiveParticles, 0);
	}
}