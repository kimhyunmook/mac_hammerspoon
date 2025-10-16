-- settings.lua
-- 설정 모달 단축키 (⌘ + ⌥ + ,)

local settingsModal = require("lib.settings_modal")

hs.hotkey.bind({"cmd", "alt"}, ",", function()
    hs.alert.show("⚙️ 설정 모달을 엽니다...", 1)
    settingsModal.showSettingsModal()
end)
