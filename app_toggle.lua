-- app_toggle.lua
-- 범용 앱 토글 함수 모듈
-- 실행 시 Dock에 잠깐 보일 수 있음. (macOS 제한)

local M = {}

-- 범용 앱 토글 함수
-- @param config: 설정 객체
--   - mash: 단축키 조합 (예: {"cmd", "alt"})
--   - key: 단축키 키 (예: "K")
--   - appName: 앱 이름 (예: "KakaoTalk")
--   - bundleID: 앱 번들 ID (예: "com.kakao.KakaoTalkMac")
--   - userAppPath: 사용자 Applications 경로 (선택, 예: "/Users/user/Applications/KakaoTalk.app")
function M.setupAppToggle(config)
    local mash = config.mash
    local key = config.key
    local appName = config.appName
    local bundleID = config.bundleID
    local userAppPath = config.userAppPath

    local function getApp()
        local app = hs.application.get(bundleID)
        if not app then app = hs.application.find(appName) end
        return app
    end

    hs.hotkey.bind(mash, key, function()
        local app = getApp()
        if not app then
            -- 실행 (사용자 복제본 우선)
            if userAppPath and hs.fs.attributes(userAppPath) then
                hs.application.launchOrFocus(userAppPath)
            else
                local ok = hs.application.launchOrFocus(bundleID)
                if not ok then hs.application.launchOrFocus(appName) end
            end
            hs.timer.doAfter(0.5, function()
                local a = getApp()
                if a then a:activate() end
            end)
        else
            -- 이미 실행 중이면
            if app:isFrontmost() then
                -- 앱 종료 (Dock 아이콘은 자연스럽게 사라짐)
                app:kill()
            else
                app:activate()
            end
        end
    end)
end

return M

