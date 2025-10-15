-- template.lua
-- 새 앱 설정 템플릿

local appToggle = require("lib.app_toggle")

-- 앱 토글 설정 예시
appToggle.setupAppToggle({
    mash = {"cmd", "alt"},     -- 단축키 조합
    key = "T",                 -- 단축키 (T = Template)
    appName = "TemplateApp",   -- 앱 이름
    bundleID = "com.template.app",  -- 앱 번들 ID
    userAppPath = "/Users/" .. os.getenv("USER") .. "/Applications/TemplateApp.app"  -- 선택적 사용자 앱 경로
})

-- 사용법:
-- 1. 파일명을 원하는 앱 이름으로 변경 (예: slack.lua)
-- 2. 설정값들을 실제 앱 정보로 수정
-- 3. init.lua에 require("apps.파일명") 추가
-- 4. Hammerspoon Reload Config
