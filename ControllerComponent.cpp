#include "stdafx.h"
#include "ControllerComponent.h"
#include "TransformComponent.h"
#include "PhysxProxy.h"
#include "GameObject.h"
#include "GameScene.h"

#pragma warning(push)
#pragma warning(disable: 26812)
ControllerComponent::ControllerComponent(physx::PxMaterial* material, float radius, float height, std::wstring name,
	physx::PxCapsuleClimbingMode::Enum climbingMode)
	: m_Radius(radius),
	m_Height(height),
	m_Name(std::move(name)),
	m_pController(nullptr),
	m_ClimbingMode(climbingMode),
	m_pMaterial(material),
	m_CollisionFlag(physx::PxControllerCollisionFlags()),
	m_CollisionGroups(physx::PxFilterData(static_cast<UINT32>(CollisionGroupFlag::Group0), 0, 0, 0))
{
}
#pragma warning(pop)

void ControllerComponent::Initialize(const GameContext&)
{
	if (m_pController != nullptr)
	{
		Logger::LogError(L"[ControllerComponent] Cannot initialize a controller twice");
		return;
	}

	physx::PxControllerManager* controllerManager = m_pGameObject->GetScene()->GetPhysxProxy()->GetControllerManager();

	physx::PxCapsuleControllerDesc capsuleControllerDesc;
	capsuleControllerDesc.setToDefault();
	capsuleControllerDesc.radius = m_Radius;
	capsuleControllerDesc.height = m_Height;
	capsuleControllerDesc.climbingMode = m_ClimbingMode;
	capsuleControllerDesc.upDirection = physx::PxVec3(0, 1, 0);
	capsuleControllerDesc.contactOffset = 0.1f;
	capsuleControllerDesc.position = ToPxExtendedVec3(m_pGameObject->GetTransform()->GetPosition());
	capsuleControllerDesc.material = m_pMaterial;
	capsuleControllerDesc.userData = this;

	
	m_pController = controllerManager->createController(capsuleControllerDesc);
	if (m_pController == nullptr)
	{
		Logger::LogError(L"[ControllerComponent] Failed to create controller");
		return;
	}

				using convert_type = std::codecvt_utf8<wchar_t>;
	std::wstring_convert<convert_type, wchar_t> converter;

		std::string converted_str = converter.to_bytes(m_Name);
	const char* name = converted_str.c_str();

	m_pController->getActor()->setName(name);
		m_pController->getActor()->userData = this;

	SetCollisionGroup(static_cast<CollisionGroupFlag>(m_CollisionGroups.word0));
	SetCollisionIgnoreGroups(static_cast<CollisionGroupFlag>(m_CollisionGroups.word1));
}

void ControllerComponent::Update(const GameContext&)
{
}

void ControllerComponent::Draw(const GameContext&)
{
}

void ControllerComponent::Translate(const DirectX::XMFLOAT3& position) const
{
	Translate(position.x, position.y, position.z);
}

void ControllerComponent::Translate(const float x, const float y, const float z) const
{
	if (m_pController == nullptr)
		Logger::LogError(L"[ControllerComponent] Cannot Translate. No controller present");
	else
		m_pController->setPosition(physx::PxExtendedVec3(x, y, z));
}

void ControllerComponent::Move(const DirectX::XMFLOAT3 displacement, const float minDist)
{
	if (m_pController == nullptr)
		Logger::LogError(L"[ControllerComponent] Cannot Move. No controller present");
	else
		m_CollisionFlag = m_pController->move(ToPxVec3(displacement), minDist, 0, nullptr, nullptr);
}

DirectX::XMFLOAT3 ControllerComponent::GetPosition() const
{
	if (m_pController != nullptr)
		return ToXMFLOAT3(m_pController->getPosition());

	return DirectX::XMFLOAT3();


}

DirectX::XMFLOAT3 ControllerComponent::GetFootPosition() const
{
	if (m_pController == nullptr)
		Logger::LogError(L"[ControllerComponent] Cannot get footposition. No controller present");
	else
		return ToXMFLOAT3(m_pController->getFootPosition());

	return DirectX::XMFLOAT3();
}

void ControllerComponent::SetCollisionIgnoreGroups(const CollisionGroupFlag ignoreGroups)
{
	using namespace physx;

	m_CollisionGroups.word1 = static_cast<PxU32>(ignoreGroups);

	if (m_pController != nullptr)
	{
		const auto actor = m_pController->getActor();
		const auto numShapes = actor->getNbShapes();
		const auto shapes = new PxShape * [numShapes];

		const auto numPointers = actor->getShapes(shapes, numShapes);
		for (PxU32 i = 0; i < numPointers; i++)
		{
#pragma warning (push)
#pragma warning (disable: 6385)
			auto shape = shapes[i];
#pragma warning (pop)
			shape->setSimulationFilterData(m_CollisionGroups);
					}
		delete[] shapes;
	}
}

void ControllerComponent::SetCollisionGroup(const CollisionGroupFlag group)
{
	using namespace physx;

	m_CollisionGroups.word0 = static_cast<UINT32>(group);

	if (m_pController != nullptr)
	{
		const auto actor = m_pController->getActor();
		const auto numShapes = actor->getNbShapes();
		const auto shapes = new PxShape * [numShapes];

		const auto numPointers = actor->getShapes(shapes, numShapes);
		for (PxU32 i = 0; i < numPointers; i++)
		{
#pragma warning (push)
#pragma warning (disable: 6385)
			auto shape = shapes[i];
#pragma warning (pop)
			shape->setSimulationFilterData(m_CollisionGroups);
			shape->setQueryFilterData(m_CollisionGroups);
		}
		delete[] shapes;
	}
}