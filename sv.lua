ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local files = {}
local add = {}

local date = os.date('*t')
if date.day < 10 then date.day = '0' .. tostring(date.day) end if date.month < 10 then date.month = '0' .. tostring(date.month) end if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end if date.min < 10 then date.min = '0' .. tostring(date.min) end if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

local function getTransacJSON()
    local load = LoadResourceFile(GetCurrentResourceName(), "historique.json")
    files = json.decode(load)
end

local function sendToDiscordWithSpecialURL(Color, Title, Description)
	local Content = {
	        {
	            ["color"] = Color,
	            ["title"] = Title,
	            ["description"] = Description,
		        ["footer"] = {
	            ["text"] = "Banque",
	            ["icon_url"] = nil,
	            },
	        }
	    }
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Name, embeds = Content}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent("xBank:createaccount")
AddEventHandler("xBank:createaccount", function(nom, prenom)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    MySQL.Async.fetchAll("SELECT * FROM bank WHERE identifier = @identifier", {
        ['@identifier'] = xPlayer.getIdentifier()
    }, function(result)
        if result[1] == nil then
            local iban, mdp = math.random(0, 9999), math.random(0, 999)
            MySQL.Async.execute("INSERT INTO bank (identifier, iban, mdp, proprietaire) VALUES (@identifier, @iban, @mdp, @proprietaire)", {
                ['@identifier'] = xPlayer.getIdentifier(),
                ['@iban'] = iban,
                ['@mdp'] = mdp,
                ['@proprietaire'] = ("%s %s"):format(nom, prenom)
            }, function()
                TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", ("Votre compte a ??t?? cr???? avec succ??s.\n(Iban = ~r~%s~s~ et Mdp = ~r~%s~s~)"):format(iban ,mdp), "CHAR_BANK_FLEECA", 2)
                sendToDiscordWithSpecialURL(0, ("Nouveau compte cr??e.\n\nPropri??taire: %s %s\nIBAN: %s\nMot de passe: %s"):format(nom, prenom, iban, mdp))
            end)
        else
            TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", "Vous avez d??j?? un compte bancaire.", "CHAR_BANK_FLEECA", 2)
        end
    end)
end)

ESX.RegisterServerCallback("xBank:login", function(source, cb, iban, mdp)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    local donnes = {}
    MySQL.Async.fetchAll("SELECT * FROM bank WHERE iban = @iban AND mdp = @mdp", {
        ['@iban'] = iban,
        ['@mdp'] = mdp
    }, function(result)
        if (result) then
            for _,v in pairs(result) do
                MySQL.Async.fetchAll("SELECT accounts FROM users WHERE identifier = @identifier", {
                    ['@identifier'] = v.identifier
                }, function(result2) 
                    if (result2) then
                        local data = json.decode(result2[1].accounts)
                        table.insert(donnes, {identifier = v.identifier, iban = v.iban, mdp = v.mdp, proprietaire = v.proprietaire, solde = data.bank, money = data})
                        cb(donnes)
                    end
                end)
            end
        end
    end)
end)

RegisterNetEvent("xBank:addMoney")
AddEventHandler("xBank:addMoney", function(identifier, money, count, iban)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    if (xPlayer.getMoney()) >= count then
        money.bank = money.bank + count
        MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {
            ['@accounts'] = json.encode(money),
            ['@identifier'] = identifier
        }, function()
            TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", ("D??p??t d'un montant de ~g~%s$~s~ effectu?? avec succ??s."):format(count), "CHAR_BANK_FLEECA", 2)
            add = {
                type = "D??p??t",
                montant = count,
                iban = iban,
                date = ("%s/%s/%s ?? %s h %s min %s s"):format(date.day, date.month, date.year, date.hour, date.min, date.sec)
            }
            table.insert(files, add)
            SaveResourceFile(GetCurrentResourceName(), "historique.json", json.encode(files), -1)
        end)
    else
        TriggerClientEvent('esx:showNotification', source, '(~r~Erreur~s~)\nVous n\'avez pas assez d\'argent sur vous.')
    end
end)

RegisterNetEvent("xBank:removeMoney")
AddEventHandler("xBank:removeMoney", function(identifier, money, count, iban)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    if money.bank >= count then
        money.bank = money.bank - count
        MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {
            ['@accounts'] = json.encode(money),
            ['@identifier'] = identifier
        }, function()
            TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", ("Retrait d'un montant de ~g~%s$~s~ effectu?? avec succ??s."):format(count), "CHAR_BANK_FLEECA", 2)
            add = {
                type = "Retrait",
                montant = count,
                iban = iban,
                date = ("%s/%s/%s ?? %s h %s min %s s"):format(date.day, date.month, date.year, date.hour, date.min, date.sec)
            }
            table.insert(files, add)
            SaveResourceFile(GetCurrentResourceName(), "historique.json", json.encode(files), -1)
        end)
    else
        TriggerClientEvent('esx:showNotification', source, '(~r~Erreur~s~)\nVous n\'avez pas assez d\'argent sur votre compte.')
    end
end)

RegisterNetEvent("xBank:virement")
AddEventHandler("xBank:virement", function(identifier, money, count, ibanTarget, iban)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end

    MySQL.Async.fetchAll("SELECT identifier FROM bank WHERE iban = @iban", {
        ['@iban'] = ibanTarget
    }, function(result)
        if result[1] == nil then 
            TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", "Cette IBAN n'existe pas.", "CHAR_BANK_FLEECA", 2)
        else
            if money.bank >= count then
                money.bank = money.bank - count
                MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {
                    ['@accounts'] = json.encode(money),
                    ['@identifier'] = identifier
                }, function()
                    TriggerClientEvent('esx:showAdvancedNotification', source, "Fleeca Bank", "~y~Information~s~", ("Virement d'un montant de ~g~%s$~s~ ?? l'IBAN ~r~%s~s~ effectu?? avec succ??s."):format(count, ibanTarget), "CHAR_BANK_FLEECA", 2)
                end)

                for _,v in pairs(result) do
                    MySQL.Async.fetchAll("SELECT accounts FROM users WHERE identifier = @identifier", {
                        ['@identifier'] = v.identifier
                    }, function(result2) 
                        if (result2) then
                            local data = json.decode(result2[1].accounts)
                            data.bank = data.bank + count
                            MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {
                                ['@accounts'] = json.encode(data),
                                ['@identifier'] = v.identifier
                            }, function()
                                add = {
                                    type = "Virement",
                                    montant = count,
                                    iban = iban,
                                    destinataire = ibanTarget,
                                    date = ("%s/%s/%s ?? %s h %s min %s s"):format(date.day, date.month, date.year, date.hour, date.min, date.sec)
                                }
                                table.insert(files, add)
                                SaveResourceFile(GetCurrentResourceName(), "historique.json", json.encode(files), -1)
                            end)
                        end
                    end)
                end
            else
                TriggerClientEvent('esx:showNotification', source, '(~r~Erreur~s~)\nVous n\'avez pas assez d\'argent sur votre compte.')
            end
        end
    end)
end)

ESX.RegisterServerCallback("xBank:getTransac", function(source, cb, iban)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if (not xPlayer) then return end
    local transaction = {}
    getTransacJSON()

    for _,v in pairs(files) do
        if v.iban == iban then
            table.insert(transaction, {date = v.date, type = v.type, montant = v.montant})
        end
    end

    cb(transaction)
end)

--- Xed#1188
