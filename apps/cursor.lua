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
    
    -- 폴더 목록 가져오기
    local folders = {}
    local iter, dir_obj = hs.fs.dir(DEFAULT_FOLDER)
    if iter then
        for file in iter, dir_obj do
            if file ~= "." and file ~= ".." then
                local fullPath = DEFAULT_FOLDER .. "/" .. file
                local attr = hs.fs.attributes(fullPath)
                if attr and attr.mode == "directory" then
                    table.insert(folders, {name = file, path = fullPath})
                end
            end
        end
        table.sort(folders, function(a, b) return a.name < b.name end)
    end
    
    if not folders or #folders == 0 then
        hs.alert.show("하위 폴더가 없습니다:\n" .. DEFAULT_FOLDER, 2)
        return
    end
    
    -- 선택 옵션 생성
    local choices = {}
    for i, folder in ipairs(folders) do
        table.insert(choices, {
            text = folder.name,
            path = folder.path,
            subText = folder.path,
            name = folder.name
        })
    end
    
    -- 최근 사용 기록 기반으로 정렬
    choices = chooserUtils.sortChoicesByRecentUsage(choices, "cursor_folders", function(choice)
        return choice.path
    end)
    
    if #choices == 1 then
        -- 폴더가 하나뿐이면 자동으로 선택
        local folder = {name = choices[1].name, path = choices[1].path}
        chooserUtils.recordChoiceSelection("cursor_folders", choices[1])
        
        if app then
            app:activate()
            hs.timer.doAfter(0.3, function()
                hs.execute('open -a Cursor "' .. folder.path .. '"', true)
                hs.alert.show("Cursor에서 폴더를 열었습니다", 1)
            end)
        else
            hs.alert.show("Cursor 실행 중...", 1)
            launchCursor()
            hs.timer.doAfter(1, function()
                hs.execute('open -a Cursor "' .. folder.path .. '"', true)
            end)
        end
        return
    end
    
    -- 여러 폴더가 있으면 Chooser 표시
    local chooser = chooserUtils.createChooser({
        choices = choices,
        onSelect = function(choice)
            if choice then
                chooserUtils.recordChoiceSelection("cursor_folders", choice)
                
                local targetPath = choice.path
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
            end
        end,
        placeholder = chooserConfig.placeholder or "📁 폴더를 선택하세요",
        width = chooserConfig.width or 50,
        rows = chooserConfig.rows or 8,
        bgDark = chooserConfig.bgDark,
        showSubText = chooserConfig.showSubText
    })
    
    if chooser then
        chooser:show()
    end
    
    -- chooser가 표시되면 여기서 종료 (비동기 처리)
    return
end)


