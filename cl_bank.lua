ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local nom, prenom = "", ""
local iban, mdp = 0, 0
local account = {}
local historique = {}
local open = false
local mainMenu = RageUI.CreateMenu("Fleeca Bank", "Interaction", nil, nil, "root_cause5", "img_vert")
local create_account = RageUI.CreateSubMenu(mainMenu, "Fleeca Bank", "Interaction")
local login = RageUI.CreateSubMenu(mainMenu, "Fleeca Bank", "Interaction")
local accountOn = RageUI.CreateSubMenu(login, "Fleeca Bank", "Interaction")
local transac = RageUI.CreateSubMenu(accountOn, "Fleeca Bank", "Interaction")
mainMenu.Display.Header = true
mainMenu.Closed = function()
    open = false
    FreezeEntityPosition(PlayerPedId(), false)
    nom, prenom = "", ""
    iban, mdp = 0, 0
    account = {}
end

local function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)

    AddTextEntry('FMMC_KEY_TIP1', TextEntry) 
    
    blockinput = true 
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "Somme", ExampleText, "", "", "", MaxStringLenght) 
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Citizen.Wait(0)
    end 

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500) 
        blockinput = false
        return result 
    else
        Citizen.Wait(500) 
        blockinput = false 
        return nil 
    end
end

local function LoginAccount(iban, mdp)
    ESX.TriggerServerCallback("xBank:login", function(result) 
        account = result
    end, iban, mdp)
end

local function getTransac(iban)
    ESX.TriggerServerCallback("xBank:getTransac", function(result)
        historique = result
    end, iban)
end

local function MenuBank()
    if open then
        open = false
        RageUI.Visible(mainMenu, false)
    else
        open = true
        RageUI.Visible(mainMenu, true)
        Citizen.CreateThread(function()
            while open do
                Wait(0)
                RageUI.IsVisible(mainMenu, function()
                    RageUI.Button("~g~→~s~ Se connecter", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {}, login)
                    RageUI.Button("~g~→~s~ Créer un compte", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {}, create_account)
                end)
                RageUI.IsVisible(create_account, function()
                    RageUI.Button("Nom", nil, {RightLabel = nom}, true, {
                        onSelected = function()
                            local name = KeyboardInput("Votre nom:", "", 10)
                            if name ~= "" and name ~= nil then
                                if (not tonumber(name)) then nom = name end
                            end
                        end
                    })
                    RageUI.Button("Prénom", nil, {RightLabel = prenom}, true, {
                        onSelected = function()
                            local name = KeyboardInput("Votre prénom:", "", 10)
                            if name ~= "" and name ~= nil then
                                if (not tonumber(name)) then prenom = name end
                            end
                        end
                    })
                    RageUI.Line()
                    RageUI.Button("Valider la création de votre compte", nil, {RightLabel = "→→"}, true, {
                        onSelected = function()
                            if nom ~= nil and nom ~= "" then
                                if prenom ~= nil and prenom ~= "" then
                                    TriggerServerEvent("xBank:createaccount", nom, prenom)
                                    nom, prenom = "", ""
                                    RageUI.GoBack()
                                else
                                    ESX.ShowNotification("(~r~Erreur~s~)\nPrénom invalide.")
                                end
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nNom invalide.")
                            end
                        end
                    })
                end)
                RageUI.IsVisible(login, function()
                    RageUI.Button("Iban", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            local number = KeyboardInput("Votre iban:", "", 4)
                            if number ~= nil and number ~= "" then
                                if tonumber(number) then iban = number else ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.") end
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.")
                            end
                        end
                    })
                    RageUI.Button("Mot de passe", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            local number = KeyboardInput("Votre mot de passe:", "", 4)
                            if number ~= nil and number ~= "" then
                                if tonumber(number) then mdp = number else ESX.ShowNotification("(~r~Erreur~s~)\nMot de passe invalide.") end
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nMot de passe invalide.")
                            end
                        end
                    })
                    RageUI.Line()
                    if iban ~= nil and iban ~= "" and iban ~= 0 then
                        if mdp ~= nil and mdp ~= "" and mdp ~= 0 then
                            RageUI.Button("Se connecter", nil, {RightLabel = "→→"}, true, {
                                onSelected = function()
                                    LoginAccount(tonumber(iban), tonumber(mdp))
                                    RageUI.Visible(accountOn, true)
                                end
                            })
                            RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end})
                        else RageUI.Button("Se connecter", nil, {}, false, {}) RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end}) end
                    else RageUI.Button("Se connecter", nil, {}, false, {}) RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end}) end
                end)
                RageUI.IsVisible(accountOn, function()
                    if #account > 0 then
                        for _,v in pairs(account) do
                            RageUI.Separator(("Titulaire du compte: ~g~%s~s~"):format(v.proprietaire))
                            RageUI.Separator(("Votre IBAN: ~g~%s~s~"):format(v.iban))
                            RageUI.Separator(("Solde: ~g~%s$~s~"):format(v.solde))
                            RageUI.Line()
                            RageUI.Button("Déposer de l'argent", nil, {RightLabel = "→"}, true, {
                                onSelected = function()
                                    local count = KeyboardInput("Combien:", "", 6)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            TriggerServerEvent("xBank:addMoney", v.identifier, v.money, tonumber(count), tonumber(v.iban))
                                            LoginAccount(tonumber(iban), tonumber(mdp))
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                    end
                                end
                            })
                            RageUI.Button("Retirer de l'argent", nil, {RightLabel = "→"}, true, {
                                onSelected = function()
                                    local count = KeyboardInput("Combien:", "", 6)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            TriggerServerEvent("xBank:removeMoney", v.identifier, v.money, tonumber(count), tonumber(v.iban))
                                            LoginAccount(tonumber(iban), tonumber(mdp))
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                    end 
                                end
                            })
                            RageUI.Button("Virement", nil, {RightLabel = "→"}, true, {
                                onSelected = function()
                                    local ibanTarget = KeyboardInput("Son iban:", "", 4)
                                    local count = KeyboardInput("Combien:", "", 6)
                                    if ibanTarget ~= nil and ibanTarget ~= "" then
                                        if tonumber(ibanTarget) then
                                            if count ~= nil and count ~= "" then
                                                if tonumber(count) then
                                                    TriggerServerEvent("xBank:virement", v.identifier, v.money, tonumber(count), tonumber(ibanTarget), tonumber(v.iban))
                                                    LoginAccount(tonumber(iban), tonumber(mdp))
                                                else
                                                    ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                                end
                                            else
                                                ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                            end
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.")
                                    end 
                                end
                            })
                            RageUI.Button("Historique des transactions", nil, {RightLabel = "→"}, true, {
                                onSelected = function()
                                    getTransac(tonumber(v.iban))
                                    RageUI.Visible(transac, true)
                                end
                            })
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Iban ou Mot de passe invalide.")
                        RageUI.Separator("")
                    end
                end)
                RageUI.IsVisible(transac, function()
                    if #historique > 0 then
                        for _,v in pairs(historique) do
                            RageUI.Button(("~g~→~s~ %s"):format(v.date), nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {
                                onActive = function()
                                    RageUI.Info("~g~Détails:~s~", {"Type", "Montant"}, {("~r~%s"):format(v.type), ("~g~%s$~s~"):format(v.montant)})
                                end
                            })
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Ce compte n'a pas été utilisé.")
                        RageUI.Separator("")
                    end
                end)
            end
        end)
    end
end

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        for k in pairs(xBank.Position) do
            local pos = xBank.Position
            local pPos = GetEntityCoords(PlayerPedId())
            local dst = Vdist(pPos.x, pPos.y, pPos.z, pos[k].x, pos[k].y, pos[k].z)

            if dst <= xBank.MarkerDistance then
                wait = 0
                DrawMarker(xBank.MarkerType, pos[k].x, pos[k].y, pos[k].z, 0.0, 0.0, 0.0, 0.0,0.0,0.0, xBank.MarkerSizeLargeur, xBank.MarkerSizeEpaisseur, xBank.MarkerSizeHauteur, xBank.MarkerColorR, xBank.MarkerColorG, xBank.MarkerColorB, xBank.MarkerOpacite, xBank.MarkerSaute, true, p19, xBank.MarkerTourne)
            end
            if dst <= xBank.OpenMenuDistance then
                wait = 0
                if (not open) then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ~g~intéragir~s~.")
                end
                if IsControlJustPressed(1, 51) then
                    FreezeEntityPosition(PlayerPedId(), true)
                    MenuBank()
                end
            end
        end
        Citizen.Wait(wait)
    end
end)


local open2 = false
local mainMenu2 = RageUI.CreateMenu("Fleeca Bank", "Interaction", nil, nil, "root_cause5", "img_vert")
local login2 = RageUI.CreateSubMenu(mainMenu2, "Fleeca Bank", "Interaction")
local accountOn2 = RageUI.CreateSubMenu(login2, "Fleeca Bank", "Interaction")
mainMenu2.Display.Header = true
mainMenu2.Closed = function()
    open2 = false
    FreezeEntityPosition(PlayerPedId(), false)
    iban, mdp = 0, 0
    account = {}
end

local function MenuATM()
    local retrait = xBank.MaxATM
    if open2 then
        open2 = false
        RageUI.Visible(mainMenu2, false)
    else
        open2 = true
        RageUI.Visible(mainMenu2, true)
        Citizen.CreateThread(function()
            while open2 do
                Wait(0)
                RageUI.IsVisible(mainMenu2, function()
                    RageUI.Button("~g~→~s~ Se connecter", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {}, login2)
                end)
                RageUI.IsVisible(login2, function()
                    RageUI.Button("Iban", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            local number = KeyboardInput("Votre iban:", "", 4)
                            if number ~= nil and number ~= "" then
                                if tonumber(number) then iban = number else ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.") end
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nIban invalide.")
                            end
                        end
                    })
                    RageUI.Button("Mot de passe", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            local number = KeyboardInput("Votre mot de passe:", "", 4)
                            if number ~= nil and number ~= "" then
                                if tonumber(number) then mdp = number else ESX.ShowNotification("(~r~Erreur~s~)\nMot de passe invalide.") end
                            else
                                ESX.ShowNotification("(~r~Erreur~s~)\nMot de passe invalide.")
                            end
                        end
                    })
                    RageUI.Line()
                    if iban ~= nil and iban ~= "" and iban ~= 0 then
                        if mdp ~= nil and mdp ~= "" and mdp ~= 0 then
                            RageUI.Button("Se connecter", nil, {RightLabel = "→→"}, true, {
                                onSelected = function()
                                    LoginAccount(tonumber(iban), tonumber(mdp))
                                    RageUI.Visible(accountOn2, true)
                                end
                            })
                            RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end})
                        else RageUI.Button("Se connecter", nil, {}, false, {}) RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end}) end
                    else RageUI.Button("Se connecter", nil, {}, false, {}) RageUI.Button("Mot de passe oublié", nil, {RightBadge = RageUI.BadgeStyle.Star}, true, {onSelected = function() ESX.ShowAdvancedNotification("Fleeca Bank", "~y~Information~s~", "Merci de contacter l'administration.", "CHAR_BANK_FLEECA", 2) end}) end
                end)
                RageUI.IsVisible(accountOn2, function()
                    if #account > 0 then
                        for _,v in pairs(account) do
                            RageUI.Separator(("Titulaire du compte: ~g~%s~s~"):format(v.proprietaire))
                            RageUI.Separator(("Votre IBAN: ~g~%s~s~"):format(v.iban))
                            RageUI.Separator(("Solde: ~g~%s$~s~"):format(v.solde))
                            RageUI.Line()
                            RageUI.Button("Retirer de l'argent", ("Maximum: %s"):format(xBank.MaxATM), {RightLabel = "→"}, true, {
                                onSelected = function()
                                    local count = KeyboardInput("Combien:", "", 6)
                                    if count ~= nil and count ~= "" then
                                        if tonumber(count) then
                                            if (retrait - count) >= 0 then
                                                retrait = retrait - count
                                                TriggerServerEvent("xBank:removeMoney", v.identifier, v.money, tonumber(count), tonumber(v.iban))
                                                LoginAccount(tonumber(iban), tonumber(mdp))
                                                print(retrait)
                                            else
                                                ESX.ShowNotification("(~r~Erreur~s~)\nVous ne pouvez pas retirer dans un ATM.")
                                            end
                                        else
                                            ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                        end
                                    else
                                        ESX.ShowNotification("(~r~Erreur~s~)\nMontant invalide.")
                                    end 
                                end
                            })
                        end
                    else
                        RageUI.Separator("")
                        RageUI.Separator("~r~Iban ou Mot de passe invalide.")
                        RageUI.Separator("")
                    end
                end)
            end
        end)
    end
end

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        
        local getObject, dst = ESX.Game.GetClosestObject()
        local model = GetEntityModel(getObject)
        local AtmProps = {-1364697528, 506770882, -870868698, -1126237515}

        for _,v in pairs(AtmProps) do
            if v == model then
                if dst <= 2.0 then
                    wait = 0
                    if (not open2) then
                        ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ~g~intéragir~s~.")
                    end
                    if IsControlJustPressed(1, 51) then
                        FreezeEntityPosition(PlayerPedId(), true)
                        MenuATM()
                    end
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

--- Xed#1188
