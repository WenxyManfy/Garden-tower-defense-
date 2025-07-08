-- ========== КОНФИГУРАЦИЯ ==========
local BOT_TOKEN = ""  -- Token
local ADMIN_CHAT_ID = 6712440322    -- ID
local MAX_RETRIES = 3               -- Попытки проверки ключа
local LICENSE_KEY = ""
local IS_LICENSE_VALID = false

-- ========== СИСТЕМА ЛИЦЕНЗИРОВАНИЯ ==========
local function checkLicense(key)
    local http = game:GetService("HttpService")
    local deviceId = game:GetService("RbxAnalyticsService"):GetClientId()
    
    local url = string.format(
        "https://api.telegram.org/bot%s/sendMessage?chat_id=%d&text=/check_key_api%%20%s%%20%s&parse_mode=HTML",
        BOT_TOKEN,
        ADMIN_CHAT_ID,
        key,
        deviceId
    )
    
    for attempt = 1, MAX_RETRIES do
        local success, response = pcall(function()
            return http:GetAsync(url, true)
        end)
        
        if success then
            local data = http:JSONDecode(response)
            if data and data.ok and data.result and data.result.text then
                local result = http:JSONDecode(data.result.text)
                if type(result.valid) == "boolean" then
                    return result.valid, result.reason or "success"
                end
            end
        end
        wait(1) -- Пауза между попытками
    end
    return false, "connection_failed"
end

-- ========== ИНТЕРФЕЙС АКТИВАЦИИ ==========
local function createLicenseUI()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Очистка старого интерфейса
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "LicenseUI" then gui:Destroy() end
    end
    
    -- Основное окно
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LicenseUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.35, 0, 0.25, 0)
    frame.Position = UDim2.new(0.325, 0, 0.375, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = frame
    
    -- Элементы интерфейса
    local elements = {
        title = {
            Type = "TextLabel",
            Props = {
                Text = "АКТИВАЦИЯ ПРОДУКТА",
                Size = UDim2.new(0.8, 0, 0.2, 0),
                Position = UDim2.new(0.1, 0, 0.05, 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 22,
                BackgroundTransparency = 1
            }
        },
        
        inputBox = {
            Type = "TextBox",
            Props = {
                Size = UDim2.new(0.8, 0, 0.25, 0),
                Position = UDim2.new(0.1, 0, 0.3, 0),
                PlaceholderText = "Введите лицензионный ключ...",
                Text = "",
                ClearTextOnFocus = false,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                Font = Enum.Font.Gotham,
                TextSize = 18
            }
        },
        
        submitButton = {
            Type = "TextButton",
            Props = {
                Size = UDim2.new(0.4, 0, 0.2, 0),
                Position = UDim2.new(0.3, 0, 0.65, 0),
                Text = "АКТИВИРОВАТЬ",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(0, 120, 215),
                Font = Enum.Font.GothamBold,
                TextSize = 18,
                AutoButtonColor = true
            }
        },
        
        messageLabel = {
            Type = "TextLabel",
            Props = {
                Size = UDim2.new(0.8, 0, 0.15, 0),
                Position = UDim2.new(0.1, 0, 0.55, 0),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 80, 80),
                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextWrapped = true,
                BackgroundTransparency = 1
            }
        }
    }
    
    -- Создаем элементы
    local uiElements = {}
    for name, element in pairs(elements) do
        local instance = Instance.new(element.Type)
        for prop, value in pairs(element.Props) do
            instance[prop] = value
        end
        instance.Parent = frame
        uiElements[name] = instance
        
        if element.Type == "TextBox" or element.Type == "TextButton" then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.1, 0)
            corner.Parent = instance
        end
    end

    -- Обработка активации
    uiElements.submitButton.MouseButton1Click:Connect(function()
        local key = uiElements.inputBox.Text
        if #key < 10 then
            uiElements.messageLabel.Text = "❌ Ключ должен содержать минимум 10 символов"
            return
        end
        
        uiElements.submitButton.Text = "ПРОВЕРКА..."
        uiElements.submitButton.Active = false
        
        local isValid, reason = checkLicense(key)
        
        if isValid then
            LICENSE_KEY = key
            IS_LICENSE_VALID = true
            uiElements.messageLabel.Text = "✅ Лицензия активирована!"
            uiElements.messageLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            
            wait(1.5)
            screenGui:Destroy()
            startMainScript()
        else
            uiElements.submitButton.Text = "АКТИВИРОВАТЬ"
            uiElements.submitButton.Active = true
            
            local errorMessages = {
                ["connection_failed"] = "❌ Ошибка соединения с сервером",
                ["expired_or_inactive"] = "❌ Ключ неактивен или просрочен",
                ["not_found"] = "❌ Ключ не найден",
                ["default"] = "❌ Ошибка активации"
            }
            
            uiElements.messageLabel.Text = errorMessages[reason] or errorMessages.default
        end
    end)
    
    uiElements.inputBox:CaptureFocus()
end

-- ========== ОСНОВНОЙ СКРИПТ ==========
local function startMainScript()
    -- Координаты цели
    local targetPosition = Vector3.new(-330.2, 64.7, -70.8)
    local standPosition = Vector3.new(-325.9, 64.7, -82.7)
    local lookDownOffset = 0.4
    local requiredToolName = "Strawberry"

    -- Сервисы
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- Поиск инструмента
    local function findTool(character)
        local player = Players.LocalPlayer
        if not player then return nil end
        
        -- Проверка в инвентаре
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == requiredToolName then
                    return item
                end
            end
        end
        
        -- Проверка в руках
        if character then
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("Tool") and item.Name == requiredToolName then
                    return item
                end
            end
        end
        
        return nil
    end

    -- Обновление персонажа
    local function updateCharacter()
        local player = Players.LocalPlayer
        if not player then return end
        
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        -- Фиксация позиции
        humanoidRootPart.CFrame = CFrame.new(standPosition)
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Управление инструментом
        local tool = findTool(character)
        if tool then
            if tool.Parent ~= character then
                -- Удаляем другие инструменты
                for _, item in ipairs(character:GetChildren()) do
                    if item:IsA("Tool") then
                        item.Parent = player.Backpack
                    end
                end
                tool.Parent = character
            end
        else
            -- Убираем все инструменты если нет нужного
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("Tool") then
                    item.Parent = player.Backpack
                end
            end
        end
        
        -- Управление камерой
        local cameraPos = camera.CFrame.Position
        local lookDirection = (targetPosition - cameraPos).Unit
        lookDirection = (lookDirection + Vector3.new(0, -lookDownOffset, 0)).Unit
        camera.CFrame = CFrame.new(cameraPos, cameraPos + lookDirection)
    end

    -- Запуск системы
    RunService.Heartbeat:Connect(updateCharacter)
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        wait(1)
        updateCharacter()
    end)
end

-- ========== ЗАПУСК СИСТЕМЫ ==========
createLicenseUI()
