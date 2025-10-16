-- Cursor 런처 - 폴더 선택 후 Cursor에서 열기 (⌘ + ⌥ + A)

-- 공용 모듈 로드
local chooserUtils = require("lib.chooser_utils")

-- 설정을 실시간으로 로드하는 함수
local function getConfig()
    local config = require("config")
    return config
end

-- Cursor 앱 설정
local appName = "Cursor"
local bundleID = "com.todesktop.230313mzl4w4u92"
local userAppPath = "/Users/" .. os.getenv("USER") .. "/Applications/Cursor.app"

local function getApp()
    local app = hs.application.get(bundleID)
    if not app then app = hs.application.find(appName) end
    return app
end

local function launchCursor(filePath)
    -- 사용자 복제본 우선
    if hs.fs.attributes(userAppPath) then
        hs.application.launchOrFocus(userAppPath)
    else
        local ok = hs.application.launchOrFocus(bundleID)
        if not ok then hs.application.launchOrFocus(appName) end
    end
    
    -- 앱이 실제로 시작될 때까지 감지
    hs.timer.waitUntil(
        function()
            local a = getApp()
            return a ~= nil
        end,
        function()
            local a = getApp()
            if a then 
                a:activate()
                -- 파일 경로가 있으면 해당 파일을 연다
                if filePath then
                    hs.execute('open -a "' .. userAppPath .. '" "' .. filePath .. '"', true)
                end
            end
        end,
        0.05
    )
end

hs.hotkey.bind({"cmd", "alt"}, "A", function()
    local app = getApp()
    
    -- 설정을 실시간으로 로드
    local config = getConfig()
    local DEFAULT_FOLDER = config.cursor.defaultFolder
    
    -- 기본 폴더가 존재하는지 확인
    if not hs.fs.attributes(DEFAULT_FOLDER) then
        hs.alert.show("설정된 폴더를 찾을 수 없습니다:\n" .. DEFAULT_FOLDER, 2)
        return
    end
    
    -- 공용 chooser 모듈 사용
    local chooserConfig = chooserUtils.getChooserConfig(config, "cursor")
    
    chooserUtils.showFolderSelector(
        DEFAULT_FOLDER,
        chooserConfig,
        function(folder)
            -- 폴더 선택 시 실행할 함수
            local targetPath = folder.path
            if app then
                app:activate()
                hs.timer.doAfter(0.3, function()
                    hs.execute('open -a Cursor "' .. targetPath .. '"', true)
                    hs.alert.show("Cursor에서 폴더를 열었습니다", 1)
                end)
            else
                hs.alert.show("Cursor 실행 중...", 1)
                launchCursor()
                hs.timer.doAfter(1, function()
                    hs.execute('open -a Cursor "' .. targetPath .. '"', true)
                end)
            end
        end,
        function(basePath)
            -- 폴더가 없을 때 실행할 함수
            hs.alert.show("하위 폴더가 없습니다:\n" .. basePath, 2)
        end
    )
    
    -- chooser가 표시되면 여기서 종료 (비동기 처리)
    return
end)


