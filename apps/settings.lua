-- settings.lua
-- 설정 모달 단축키 (⌘ + ⌥ + S) 및 메뉴바 아이콘

local settingsModal = require("lib.settings_modal")

local function openSettings()
    hs.alert.show("⚙️ 설정 모달을 엽니다...", 1)
    settingsModal.showSettingsModal()
end

local settingsHotkey = hs.hotkey.bind({"cmd", "alt"}, "S", openSettings)
if not settingsHotkey then
    hs.alert.show("⚠️ 설정 단축키(⌘⌥S) 등록에 실패했습니다. 메뉴바 ⚙️ 아이콘을 사용하세요.", 3)
end

SettingsMenubar = hs.menubar.new()
if SettingsMenubar then
    SettingsMenubar:setTitle("⚙️")
    SettingsMenubar:setTooltip("Hammerspoon 설정 (⌘⌥S)")
    SettingsMenubar:setClickCallback(openSettings)
end
