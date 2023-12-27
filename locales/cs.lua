local Translations = {
    error = {
        invalid_ext = "Thats not a valid extension, only %{fileext} extension links are allowed.",
    },
    info = {
        use_printer = "Použít tiskárnu"

    },
    command = {
        spawn_printer = "Spawnout tiskárnu"
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic