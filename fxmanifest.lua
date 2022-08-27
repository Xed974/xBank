fx_version 'cerulean'
games {'gta5'}

shared_scripts { "config.lua" }

client_scripts {
    "libs/RMenu.lua",
    "libs/menu/RageUI.lua",
    "libs/menu/Menu.lua",
    "libs/menu/MenuController.lua",
    "libs/components/*.lua",
    "libs/menu/elements/*.lua",
    "libs/menu/items/*.lua",
    "libs/menu/panels/*.lua",
    "libs/menu/windows/*.lua",

    "cl_bank.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    "sv.lua",
}