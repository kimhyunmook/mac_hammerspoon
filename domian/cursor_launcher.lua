-- cursor_launcher.lua
-- Cursor 런처 - 폴더 선택 후 Cursor에서 열기 (⌘ + ⌥ + A)

-- 설정 파일 불러오기
local config = require("config")

-- 설정값 가져오기
local DEFAULT_FOLDER = config.cursor.defaultFolder

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
    
    -- 기본 폴더가 존재하는지 확인
    if not hs.fs.attributes(DEFAULT_FOLDER) then
        hs.alert.show("설정된 폴더를 찾을 수 없습니다:\n" .. DEFAULT_FOLDER, 2)
        return
    end
    
    -- AppleScript를 사용하여 폴더 선택 다이얼로그 표시
    local appleScript = string.format([[
        set defaultFolder to POSIX file "%s" as alias
        try
            choose folder with prompt "Cursor에서 열 폴더를 선택하세요" default location defaultFolder
            return POSIX path of result
        on error
            return ""
        end try
    ]], DEFAULT_FOLDER)
    
    local ok, selectedPath, rawTable = hs.osascript.applescript(appleScript)
    
    -- 취소하거나 실패하면 종료
    if not ok or not selectedPath or selectedPath == "" then
        if selectedPath ~= "" then
            hs.alert.show("취소되었습니다", 0.5)
        end
        return
    end
    
    -- 경로 끝의 개행 문자 제거
    selectedPath = selectedPath:gsub("\n", ""):gsub("/$", "")
    
    -- 선택된 경로가 있으면 Cursor 실행/활성화
    if app then
        -- 실행 중이면 활성화하고 폴더 열기
        app:activate()
        hs.timer.doAfter(0.3, function()
            hs.execute('open -a Cursor "' .. selectedPath .. '"', true)
            hs.alert.show("Cursor에서 폴더를 열었습니다", 1)
        end)
    else
        -- 실행 중이 아니면 실행
        hs.alert.show("Cursor 실행 중...", 1)
        launchCursor()
        hs.timer.doAfter(1, function()
            hs.execute('open -a Cursor "' .. selectedPath .. '"', true)
        end)
    end
end)

