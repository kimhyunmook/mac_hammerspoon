-- kakao_toggle.lua
-- 카카오톡 토글 설정 (⌘ + ⌥ + K)

local appToggle = require("app_toggle")

-- 카카오톡 토글 설정
appToggle.setupAppToggle({
    mash = {"cmd", "alt"},
    key = "K",
    appName = "KakaoTalk",
    bundleID = "com.kakao.KakaoTalkMac",
    userAppPath = "/Users/" .. os.getenv("USER") .. "/Applications/KakaoTalk.app"
})

