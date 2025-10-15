-- config.lua
-- Hammerspoon 전역 설정 파일

local config = {}

-- ===== Cursor 설정 =====
-- 폴더 선택 시작 경로
-- 환경 변수나 절대 경로 사용 가능
-- 예시:
--   os.getenv("HOME") .. "/Desktop/back"
--   os.getenv("HOME") .. "/Documents/projects"
--   "/Users/username/workspace"
config.cursor = {
    defaultFolder = os.getenv("HOME") .. "/Desktop/back",
    
    -- Chooser UI 커스터마이징
    chooser = {
        width = 50,          -- 화면 너비의 퍼센트 (10-90)
        rows = 8,            -- 최대 표시 줄 수 (3-20)
        bgDark = true,       -- 다크 모드 (true/false)
        placeholder = "📁 Cursor에서 열 폴더를 선택하세요",
        showSubText = true,  -- 경로 표시 여부
        iconSize = 24        -- 아이콘 크기 (16, 24, 32, 48)
    }
}

-- ===== 향후 다른 설정 추가 가능 =====
-- config.kakao = {
--     설정들...
-- }

return config

