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
    defaultFolder = os.getenv("HOME") .. "/Desktop/back"
}

-- ===== 향후 다른 설정 추가 가능 =====
-- config.kakao = {
--     설정들...
-- }

return config

