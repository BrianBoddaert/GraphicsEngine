#include "stdafx.h"
#include "ModelAnimator.h"

ModelAnimator::ModelAnimator(MeshFilter* pMeshFilter) :
	m_pMeshFilter(pMeshFilter),
	m_Transforms(std::vector<DirectX::XMFLOAT4X4>()),
	m_IsPlaying(false),
	m_Reversed(false),
	m_ClipSet(false),
	m_TickCount(0),
	m_AnimationSpeed(1.0f),
	m_CurrentClipIndex(0),
	m_PlayOnce(false),
	m_PauseAfterPlay(false),
	m_IdleAnimationIndex(1)
{
	SetAnimation(0);
}

void ModelAnimator::SetAnimation(UINT clipNumber)
{
	UNREFERENCED_PARAMETER(clipNumber);

	m_CurrentClipIndex = clipNumber;
	m_ClipSet = false;

	if (clipNumber < m_pMeshFilter->m_AnimationClips.size())
	{
		AnimationClip animationClip = m_pMeshFilter->m_AnimationClips[clipNumber];
		SetAnimation(animationClip);
	}
	else
	{
		Reset();
		Logger::LogWarning(L"Warning :The clipnumber is bigger than the actual size of the m_AnimationClips!");
		return;
	}
}

void ModelAnimator::SetAnimation(std::wstring clipName)
{
	UNREFERENCED_PARAMETER(clipName);

	m_ClipSet = false;
		auto it = std::find_if(m_pMeshFilter->m_AnimationClips.begin(), m_pMeshFilter->m_AnimationClips.end(),
		[clipName](AnimationClip clip)
		{
			return clip.Name == clipName;
		});
		if (it != m_pMeshFilter->m_AnimationClips.end())
	{
		SetAnimation(*it);
	}
	else
	{
		Reset();
		Logger::LogWarning(L"Warning :The m_AnimationClips vector doesn't have a clip with the given name (clipName)!");
	}
}

void ModelAnimator::SetAnimation(AnimationClip clip)
{
	UNREFERENCED_PARAMETER(clip);

	if (clip.Name == m_CurrentClip.Name)
		return;

		m_ClipSet = true;
	m_CurrentClip = clip;
	Reset(false);
}

void ModelAnimator::Reset(bool pause)
{
	UNREFERENCED_PARAMETER(pause);
			if (pause)
	{
		m_IsPlaying = false;
	}

	m_TickCount = 0;
	m_AnimationSpeed = 1.0f;

	if (m_ClipSet)
	{
		std::vector<DirectX::XMFLOAT4X4> boneTransforms = m_CurrentClip.Keys[0].BoneTransforms;
		m_Transforms.assign(boneTransforms.begin(), boneTransforms.end());
	}
	else
	{
		for (size_t i = 0; i < m_pMeshFilter->m_BoneCount; i++)
		{
			m_Transforms[i] = DirectX::XMFLOAT4X4{ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };
		}
	}
}

void ModelAnimator::Update(const GameContext& gameContext)
{
	UNREFERENCED_PARAMETER(gameContext);
			if (m_IsPlaying && m_ClipSet)
	{
		auto passedTicks = gameContext.pGameTime->GetElapsed() * m_AnimationSpeed * m_CurrentClip.TicksPerSecond;
		passedTicks = fmod(passedTicks, m_CurrentClip.Duration); 

		if (m_Reversed)
		{
			m_TickCount -= passedTicks;
		}

		if (m_TickCount < 0)
		{
			m_TickCount += m_CurrentClip.Duration;
		}
		else
		{
			m_TickCount += passedTicks;
		}

		if (m_TickCount > m_CurrentClip.Duration)
		{
			m_TickCount -= m_CurrentClip.Duration;
		}

		AnimationKey keyA, keyB;

		for (size_t i = 0; i < m_CurrentClip.Keys.size(); i++)
		{
			if (m_CurrentClip.Keys[i].Tick < m_TickCount)
			{
				keyA = m_CurrentClip.Keys[i];
			}
		}
		for (size_t i = 0; i < m_CurrentClip.Keys.size(); i++)
		{
			if (m_CurrentClip.Keys[i].Tick > m_TickCount)
			{
				keyB = m_CurrentClip.Keys[i];
				break;
			}
		}

		float blendFactorA = keyB.Tick - m_TickCount;
		float offset = keyB.Tick - keyA.Tick;

		blendFactorA /= offset;
						m_Transforms.clear();
				for (size_t j = 0; j < m_pMeshFilter->m_BoneCount; j++)
		{

			const auto transformA = keyA.BoneTransforms[j];
			const auto transformB = keyB.BoneTransforms[j];

			auto transformAMatrix = DirectX::XMLoadFloat4x4(&transformA);
			auto transformBMatrix = DirectX::XMLoadFloat4x4(&transformB);

			DirectX::XMVECTOR transA{}, rotA{}, scaleA{}, transB{}, rotB{}, scaleB{};

			DirectX::XMMatrixDecompose(&scaleA, &rotA, &transA, transformAMatrix);
			DirectX::XMMatrixDecompose(&scaleB, &rotB, &transB, transformBMatrix);

			auto translation = DirectX::XMVectorLerp(transA, transB, blendFactorA);
			auto scale = DirectX::XMVectorLerp(scaleA, scaleB, blendFactorA);
			auto rot = DirectX::XMQuaternionSlerp(rotA, rotB, blendFactorA);

			auto newTranformMatrix = DirectX::XMMatrixAffineTransformation(scale, DirectX::g_XMZero, rot, translation);
			DirectX::XMFLOAT4X4 newTransformFloat4x4 = {};
			DirectX::XMStoreFloat4x4(&newTransformFloat4x4, newTranformMatrix);

			m_Transforms.push_back(newTransformFloat4x4);
			
		}

																
		if (m_PlayOnce)
		{
			if (m_TickCount >= m_CurrentClip.Duration - 1)
				PlayOnceEnded();
		}
	}


}	
void ModelAnimator::PlayOnceEnded()
{

	if (m_PauseAfterPlay)
		Pause();
	else SetAnimation(m_IdleAnimationIndex);


	m_PlayOnce = false;
}

void ModelAnimator::PlayOnce(bool pause)
{
	SetAnimation(m_CurrentClip);
	Play();
	m_PlayOnce = true;
	m_PauseAfterPlay = pause;

}
void ModelAnimator::PlayOnce(UINT clipNumber, bool pause)
{
	SetAnimation(clipNumber);
	Play();
	m_PlayOnce = true;
	m_PauseAfterPlay = pause;
}