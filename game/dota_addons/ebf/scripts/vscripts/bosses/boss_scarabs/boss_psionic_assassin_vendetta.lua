boss_psionic_assassin_vendetta = class({})


function boss_psionic_assassin_vendetta:ShouldUseResources()
	return true
end

function boss_psionic_assassin_vendetta:GetIntrinsicModifierName()
	return "modifier_boss_psionic_assassin_vendetta_handler"
end

function boss_psionic_assassin_vendetta:TriggerVendetta()
	local caster = self:GetCaster()
	
	if caster:PassivesDisabled() then return end
	
	ParticleManager:FireParticle( "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "Hero_NyxAssassin.Vendetta", caster )
	caster:AddNewModifier( caster, self, "modifier_nyx_assassin_vendetta", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_boss_psionic_assassin_vendetta_handler = class({})
LinkLuaModifier( "modifier_boss_psionic_assassin_vendetta_handler", "bosses/boss_scarabs/boss_psionic_assassin_vendetta.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_psionic_assassin_vendetta_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_boss_psionic_assassin_vendetta_handler:OnDeath( params )
	if params.attacker == self:GetParent() and params.unit:IsRealHero() then
		self:GetAbility():TriggerVendetta()
	end
end

function modifier_boss_psionic_assassin_vendetta_handler:IsHidden() 
	return true
end