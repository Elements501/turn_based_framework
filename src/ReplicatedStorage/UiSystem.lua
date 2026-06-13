local UiSystem = {}
UiSystem.__index = UiSystem

export type UiSystemType = {
    unit: {},
    effectId: number,
    hpBar: Frame,
    hpText: TextLabel,
    energyBar: Frame,
    energyText: TextLabel,
    effectFrame: Frame,
    effectTemplate: Frame,
    effectMap: { [number]: Frame },
    UpdateHealth: (self: UiSystemType) -> (),
    UpdateEnergy: (self: UiSystemType) -> (),
    AddEffect: (self: UiSystemType, effect: {}) -> number,
    UpdateEffect: (self: UiSystemType, effectId: number, duration: number) -> (),
    RemoveEffect: (self: UiSystemType, effectId: number) -> (),
}

function UiSystem.new(part: BasePart, unit: {})
    -- Top-level billboard
    local topBar: BillboardGui = Instance.new("BillboardGui")
    topBar.Parent = part
    topBar.Adornee = part
    topBar.Name = "HpBar " .. unit.Id
    topBar.Size = UDim2.fromScale(5, 2.5)
    topBar.ExtentsOffset = Vector3.new(0, 3, 0)

    local listLayout: UIListLayout = Instance.new("UIListLayout")
    listLayout.Parent = topBar
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Health bar
    local hpBackground: Frame = Instance.new("Frame")
    hpBackground.Parent = topBar
    hpBackground.Name = "Health Bar"
    hpBackground.BackgroundColor3 = Color3.new(1, 1, 1)
    hpBackground.BackgroundTransparency = 0
    hpBackground.Size = UDim2.fromScale(1, 0.4)
    hpBackground.ZIndex = 0
    hpBackground.LayoutOrder = 2

    local hpBar: Frame = Instance.new("Frame")
    hpBar.Parent = hpBackground
    hpBar.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBar.BackgroundTransparency = 0
    hpBar.Size = UDim2.fromScale(0.96, 0.8)
    hpBar.Position = UDim2.fromScale(0.02, 0.1)
    hpBar.ZIndex = 1

    local hpText: TextLabel = Instance.new("TextLabel")
    hpText.Parent = hpBar
    hpText.Text = unit.Health .. " / " .. unit.MaxHealth
    hpText.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    hpText.Size = UDim2.fromScale(1, 1)
    hpText.TextScaled = true
    hpText.BackgroundTransparency = 1
    hpText.ZIndex = 2

    -- Energy Bar
    local energyBar: Frame = Instance.new("Frame")
    energyBar.Parent = topBar
    energyBar.BackgroundColor3 = Color3.new(0, 0, 0)
    energyBar.BackgroundTransparency = 0
    energyBar.Size = UDim2.fromScale(1, 0.2)
    energyBar.ZIndex = 1
    energyBar.LayoutOrder = 3

    local energyText: TextLabel = Instance.new("TextLabel")
    energyText.Parent = energyBar
    energyText.Text = unit.Energy .. " / " .. unit.MaxEnergy
    energyText.TextColor3 = Color3.new(1, 1, 1)
    energyText.Size = UDim2.fromScale(1, 1)
    energyText.TextScaled = true
    energyText.BackgroundTransparency = 1
    energyText.ZIndex = 2

    -- Status effect bar
    local effectFrame: Frame = Instance.new("Frame")
    effectFrame.Parent = topBar
    effectFrame.Name = "Status Bar"
    effectFrame.Size = UDim2.fromScale(1, 0.4)
    effectFrame.BackgroundTransparency = 1
    effectFrame.ZIndex = 0
    effectFrame.LayoutOrder = 1

    local effectPadding: UIPadding = Instance.new("UIPadding")
    effectPadding.Parent = effectFrame
    effectPadding.PaddingBottom = UDim.new(0.05, 0)

    local effectGrid: UIGridLayout = Instance.new("UIGridLayout")
    effectGrid.Parent = effectFrame
    effectGrid.SortOrder = Enum.SortOrder.LayoutOrder
    effectGrid.CellPadding = UDim2.fromScale(0.02, 0.05)
    effectGrid.CellSize = UDim2.fromScale(0.2, 1)

    -- Effect icon template (no parent — cloned on demand)
    local effectTemplate: Frame = Instance.new("Frame")
    effectTemplate.BackgroundTransparency = 1

    local effectImage: ImageLabel = Instance.new("ImageLabel")
    effectImage.Name = "EffectImage"
    effectImage.Parent = effectTemplate
    effectImage.Size = UDim2.fromScale(1, 1)
    effectImage.ZIndex = 0

    local effectText: TextLabel = Instance.new("TextLabel")
    effectText.Name = "EffectText"
    effectText.Parent = effectTemplate
    effectText.Size = UDim2.fromScale(1, 1)
    effectText.TextColor3 = Color3.new(0, 0, 0)
    effectText.TextScaled = true
    effectText.BackgroundTransparency = 1
    effectText.ZIndex = 1

    return setmetatable({
        unit = unit,
        effectId = 1,
        hpBar = hpBar,
        hpText = hpText,
        energyBar = energyBar,
        energyText = energyText,
        effectFrame = effectFrame,
        effectTemplate = effectTemplate,
        effectMap = {},
    }, UiSystem)
end

function UiSystem:UpdateHealth()
    self.hpText.Text = self.unit.Health .. " / " .. self.unit.MaxHealth
    self.hpBar.Size = UDim2.fromScale(self.unit.Health / self.unit.MaxHealth * 0.96, self.hpBar.Size.Y.Scale)
end

function UiSystem:UpdateEnergy()
    self.energyText.Text = self.unit.Energy .. " / " .. self.unit.MaxEnergy
end

function UiSystem:AddEffect(effect: {}): number
    local id = self.effectId
    local icon: Frame = self.effectTemplate:Clone()
    icon.Name = effect.Name
    icon.Parent = self.effectFrame
    icon.EffectText.Text = effect.Duration

    -- TODO: Set icon.EffectImage
    self.effectMap[id] = icon
    self.effectId += 1
    return id
end

function UiSystem:UpdateEffect(effectId: number, duration: number)
    local icon = self.effectMap[effectId]
    if not icon then return end

    icon.EffectText.Text = duration
end

function UiSystem:RemoveEffect(effectId: number)
    local icon = self.effectMap[effectId]
    if not icon then return end

    icon:Destroy()
    self.effectMap[effectId] = nil
end

return UiSystem
