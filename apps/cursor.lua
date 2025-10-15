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
    
    -- 타겟 폴더의 첫 번째 자식 폴더 찾기
    local function findFirstSubfolder(path)
        local iter, dir_obj = hs.fs.dir(path)
        if not iter then return nil end
        
        local folders = {}
        for file in iter, dir_obj do
            if file ~= "." and file ~= ".." then
                local fullPath = path .. "/" .. file
                local attr = hs.fs.attributes(fullPath)
                if attr and attr.mode == "directory" then
                    table.insert(folders, {name = file, path = fullPath})
                end
            end
        end
        
        -- 폴더를 이름순으로 정렬
        table.sort(folders, function(a, b) return a.name < b.name end)
        
        return folders
    end
    
    local subfolders = findFirstSubfolder(DEFAULT_FOLDER)
    
    if not subfolders or #subfolders == 0 then
        hs.alert.show("하위 폴더가 없습니다:\n" .. DEFAULT_FOLDER, 2)
        return
    end
    
    local targetPath
    if #subfolders == 1 then
        -- 폴더가 하나뿐이면 자동으로 선택
        targetPath = subfolders[1].path
        hs.alert.show("폴더를 열었습니다:\n" .. subfolders[1].name, 2)
    else
        -- 여러 폴더가 있으면 Hammerspoon Chooser 사용 (확실한 포커스)
        local choices = {}
        for i, folder in ipairs(subfolders) do
            table.insert(choices, {
                text = folder.name,
                path = folder.path,
                subText = folder.path
            })
        end
        
        local chooser = hs.chooser.new(function(choice)
            if choice then
                targetPath = choice.path
                -- Cursor 실행/활성화
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
        end)
        
        -- UI 커스터마이징 (config에서 설정 가져오기)
        chooser:choices(choices)
        chooser:placeholderText(config.cursor.chooser.placeholder)
        chooser:width(config.cursor.chooser.width)
        chooser:rows(config.cursor.chooser.rows)
        chooser:bgDark(config.cursor.chooser.bgDark)
        
        -- 경로 표시 여부 설정
        if not config.cursor.chooser.showSubText then
            for i, choice in ipairs(choices) do
                choice.subText = nil
            end
        end
        
        chooser:show()
        return  -- chooser가 비동기로 처리되므로 여기서 종료
    end
    
    -- 선택된 경로가 있으면 Cursor 실행/활성화
    if app then
        -- 실행 중이면 활성화하고 폴더 열기
        app:activate()
        hs.timer.doAfter(0.3, function()
            hs.execute('open -a Cursor "' .. targetPath .. '"', true)
            hs.alert.show("Cursor에서 폴더를 열었습니다", 1)
        end)
    else
        -- 실행 중이 아니면 실행
        hs.alert.show("Cursor 실행 중...", 1)
        launchCursor()
        hs.timer.doAfter(1, function()
            hs.execute('open -a Cursor "' .. targetPath .. '"', true)
        end)
    end
end)


