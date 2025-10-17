-- config.lua
-- Hammerspoon 전역 설정 파일 (JSON 파일에서 실시간 로드)

local config = {}

-- JSON 설정 파일 경로
local settingsPath = hs.configdir .. "/settings.json"

-- JSON 파일에서 설정 로드하는 함수
local function loadSettings()
    
    local settingsFile = io.open(settingsPath, "r")
    if not settingsFile then
        -- JSON 파일이 없으면 기본값 반환
        return {
            cursor = {
                defaultFolder = os.getenv("HOME") .. "/Desktop/back",
                chooser = {
                    width = 50,
                    rows = 8,
                    bgDark = true,
                    placeholder = "📁 Cursor에서 열 폴더를 선택하세요",
                    showSubText = true,
                    iconSize = 24
                }
            }
        }
    end
    
    local settingsContent = settingsFile:read("*all")
    settingsFile:close()
    
    if not settingsContent or #settingsContent == 0 then
        return {
            cursor = {
                defaultFolder = os.getenv("HOME") .. "/Desktop/back",
                chooser = {
                    width = 50,
                    rows = 8,
                    bgDark = true,
                    placeholder = "📁 Cursor에서 열 폴더를 선택하세요",
                    showSubText = true,
                    iconSize = 24
                }
            }
        }
    end
    
    
    local success, settings = pcall(hs.json.decode, settingsContent)
    if success and settings then
        return settings
    else
        -- JSON 파싱 실패 시 기본값 반환
        return {
            cursor = {
                defaultFolder = os.getenv("HOME") .. "/Desktop/back",
                chooser = {
                    width = 50,
                    rows = 8,
                    bgDark = true,
                    placeholder = "📁 Cursor에서 열 폴더를 선택하세요",
                    showSubText = true,
                    iconSize = 24
                }
            }
        }
    end
end

-- 설정을 실시간으로 로드하는 함수
local function getCurrentSettings()
    return loadSettings()
end

-- 초기 설정 로드
local initialSettings = loadSettings()
config.cursor = initialSettings.cursor

-- 실시간 설정 가져오기 함수 추가
config.getSettings = getCurrentSettings
config.reload = function()
    local newSettings = getCurrentSettings()
    config.cursor = newSettings.cursor
    return true
end

-- ===== 향후 다른 설정 추가 가능 =====
-- config.kakao = settings.kakao

return config

