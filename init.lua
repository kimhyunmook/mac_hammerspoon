-- 설정 파일 확인 및 생성
local function ensureSettingsFile()
    local settingsPath = hs.configdir .. "/settings.json"
    local file = io.open(settingsPath, "r")
    
    if not file then
        -- settings.json 파일이 없으면 기본 설정으로 생성
        local defaultSettings = {
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
        
        local settingsFile = io.open(settingsPath, "w")
        if settingsFile then
            settingsFile:write(hs.json.encode(defaultSettings, true))
            settingsFile:close()
            hs.alert.show("기본 설정 파일을 생성했습니다: " .. settingsPath)
        else
            hs.alert.show("설정 파일 생성에 실패했습니다: " .. settingsPath)
        end
    else
        file:close()
    end
end

-- 설정 파일 확인
ensureSettingsFile()

-- 앱별 설정 로드
require("apps.kakao")
require("apps.cursor")
require("apps.settings")

