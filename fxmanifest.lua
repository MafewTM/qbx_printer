fx_version 'cerulean'
game 'gta5'

description 'qbx_printer'
repository 'https://github.com/Qbox-project/qbx_printer'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
}


client_script 'client/main.lua'

server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'config/client.lua',
    'html/*.html',
    'html/*.js',
    'html/*.css',
    'html/*.png',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
