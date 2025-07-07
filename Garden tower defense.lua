-- ========== НАСТРОЙКИ ЛИЦЕНЗИИ ==========
local BOT_TOKEN = "7589448582:AAHYcT5DWujUBvhDdx_zE1P-ljbncUS3aOs"  -- token
local ADMIN_CHAT_ID = 6712440322    -- ID 
local LICENSE_KEY = ""
local IS_LICENSE_VALID = false

-- ========== СИСТЕМА ЛИЦЕНЗИРОВАНИЯ ==========
local function checkLicense(key)
    local http = game:GetService("HttpService")
    local deviceId = game:GetService("RbxAnalyticsService"):GetClientId()
    
    local url = "https://api.telegram.org/bot"..BOT_TOKEN.."/sendMessage"
    local body = {
        chat_id = ADMIN_CHAT_ID,
        text = "/check_key_api "..key.." "..deviceId,
        parse_mode = "HTML"
    }
    
    local success, response = pcall(function()
        return http:PostAsync(url, http:JSONEncode(body))
    end)
    
    if success then
        local data = http:JSONDecode(response)
        if data.ok and data.result.text then
            local result = http:JSONDecode(data.result.text)
            return result.valid or false, result.reason or "unknown_error"
        end
    end
    return false, "connection_failed"
end

local function showLicenseUI()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Очистка старого интерфейса
    local oldUI = playerGui:FindFirstChild("LicenseUI")
    if oldUI then oldUI:Destroy() end
    
    -- Создание нового интерфейса
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LicenseUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.3, 0)
    frame.Position = UDim2.new(0.3, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.05, 0)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Text = "АКТИВАЦИЯ ЛИЦЕНЗИИ"
    title.Size = UDim2.new(0.8, 0, 0.2, 0)
    title.Position = UDim2.new(0.1, 0, 0.05, 0)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.8, 0, 0.25, 0)
    inputBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    inputBox.PlaceholderText = "Введите ваш лицензионный ключ..."
    inputBox.Text = ""
    inputBox.ClearTextOnFocus = false
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 18
    inputBox.Parent = frame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0.1, 0)
    inputCorner.Parent = inputBox
    
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0.4, 0, 0.2, 0)
    submitButton.Position = UDim2.new(0.3, 0, 0.65, 0)
    submitButton.Text = "ПРОВЕРИТЬ КЛЮЧ"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    submitButton.Font = Enum.Font.GothamBold
    submitButton.TextSize = 18
    submitButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0.1, 0)
    buttonCorner.Parent = submitButton
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
    messageLabel.Position = UDim2.new(0.1, 0, 0.55, 0)
    messageLabel.Text = ""
    messageLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 16
    messageLabel.TextWrapped = true
    messageLabel.BackgroundTransparency = 1
    messageLabel.Parent = frame
    
    submitButton.MouseButton1Click:Connect(function()
        local key = inputBox.Text
        if string.len(key) < 10 then
            messageLabel.Text = "❌ Ключ слишком короткий"
            return
        end
        
        submitButton.Text = "ПРОВЕРКА..."
        submitButton.Active = false
        
        local isValid, reason = checkLicense(key)
        
        if isValid then
            LICENSE_KEY = key
            IS_LICENSE_VALID = true
            messageLabel.Text = "✅ Лицензия активирована!"
            messageLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            
            wait(1)
            screenGui:Destroy()
            startMainScript()
        else
            submitButton.Text = "ПРОВЕРИТЬ КЛЮЧ"
            submitButton.Active = true
            
            if reason == "expired_or_inactive" then
                messageLabel.Text = "❌ Ключ неактивен или просрочен"
            elseif reason == "not_found" then
                messageLabel.Text = "❌ Ключ не найден"
            elseif reason == "connection_failed" then
                messageLabel.Text = "❌ Ошибка соединения с сервером"
            else
                messageLabel.Text = "❌ Неверный ключ"
            end
        end
    end)
    
    inputBox:CaptureFocus()
end

-- ========== ОСНОВНОЙ СКРИПТ ==========
local function startMainScript()
    -- Координаты цели
    local targetPosition = Vector3.new(-330.2, 64.7, -70.8)
    local standPosition = Vector3.new(-325.9, 64.7, -82.7)
    local lookDownOffset = 0.4
    local requiredToolName = "Strawberry"

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local function findStrawberryTool(character)
        local player = Players.LocalPlayer
        if not player then return nil end
        
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == requiredToolName then
                    return item
                end
            end
        end
        
        if character then
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("Tool") and item.Name == requiredToolName then
                    return item
                end
            end
        end
        
        return nil
    end

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
        
        humanoidRootPart.CFrame = CFrame.new(standPosition)
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        local strawberryTool = findStrawberryTool(character)
        
        if strawberryTool then
            if strawberryTool.Parent ~= character then
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = player.Backpack
                    end
                end
                strawberryTool.Parent = character
            end
        else
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = player.Backpack
                end
            end
        end
        
        local cameraPos = camera.CFrame.Position
        local lookDirection = (targetPosition - cameraPos).Unit
        lookDirection = (lookDirection + Vector3.new(0, -lookDownOffset, 0)).Unit
        camera.CFrame = CFrame.new(cameraPos, cameraPos + lookDirection)
    end

    RunService.Heartbeat:Connect(updateCharacter)

    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        wait(1)
        updateCharacter()
    end)
end

-- ========== ЗАПУСК ==========
showLicenseUI()
