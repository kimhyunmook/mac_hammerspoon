-- chooser_utils.lua
-- 공용 Chooser 유틸리티 모듈

local M = {}

-- 최근 사용 기록 파일 경로
local RECENT_USAGE_FILE = hs.configdir .. "/.recent_usage.json"

-- 최근 사용 기록 로드 함수
local function loadRecentUsage()
    local file = io.open(RECENT_USAGE_FILE, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or #content == 0 then
        return {}
    end
    
    local success, data = pcall(hs.json.decode, content)
    if success and data then
        return data
    end
    
    return {}
end

-- 최근 사용 기록 저장 함수
local function saveRecentUsage(usageData)
    local file = io.open(RECENT_USAGE_FILE, "w")
    if not file then
        return false
    end
    
    local jsonContent = hs.json.encode(usageData, true)
    if not jsonContent then
        file:close()
        return false
    end
    
    file:write(jsonContent)
    file:close()
    return true
end

-- 항목 사용 기록 업데이트
-- @param category: 카테고리 (예: "cursor_folders", "settings_modal")
-- @param itemKey: 항목 키 (예: folder path, setting name)
-- @param itemData: 항목 데이터 (선택사항)
local function updateRecentUsage(category, itemKey, itemData)
    local usage = loadRecentUsage()
    
    if not usage[category] then
        usage[category] = {}
    end
    
    -- 기존 항목 제거 (중복 방지)
    for i = #usage[category], 1, -1 do
        if usage[category][i].key == itemKey then
            table.remove(usage[category], i)
        end
    end
    
    -- 새 항목을 맨 앞에 추가
    table.insert(usage[category], 1, {
        key = itemKey,
        data = itemData or {},
        timestamp = os.time()
    end)
    
    -- 최대 10개까지만 유지
    if #usage[category] > 10 then
        usage[category] = {table.unpack(usage[category], 1, 10)}
    end
    
    saveRecentUsage(usage)
end

-- 폴더 목록을 가져오는 함수
-- @param basePath: 기본 경로
-- @return table: 폴더 목록 {name, path}
local function getFolderList(basePath)
    local iter, dir_obj = hs.fs.dir(basePath)
    if not iter then return nil end
    
    local folders = {}
    for file in iter, dir_obj do
        if file ~= "." and file ~= ".." then
            local fullPath = basePath .. "/" .. file
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

-- Chooser 생성 및 설정 함수
-- @param config: 설정 객체
--   - choices: 선택 옵션들
--   - onSelect: 선택 시 실행할 함수 (choice 객체를 매개변수로 받음)
--   - placeholder: placeholder 텍스트
--   - width: chooser 너비
--   - rows: 표시할 행 수
--   - bgDark: 어두운 배경 사용 여부
--   - showSubText: 하위 텍스트 표시 여부
-- @return hs.chooser: 생성된 chooser 객체
function M.createChooser(config)
    local chooser = hs.chooser.new(function(choice)
        if choice and config.onSelect then
            config.onSelect(choice)
        end
    end)
    
    -- 기본 설정 적용
    if config.choices then
        chooser:choices(config.choices)
    end
    
    if config.placeholder then
        chooser:placeholderText(config.placeholder)
    end
    
    if config.width then
        chooser:width(config.width)
    end
    
    if config.rows then
        chooser:rows(config.rows)
    end
    
    if config.bgDark ~= nil then
        chooser:bgDark(config.bgDark)
    end
    
    -- 하위 텍스트 표시 설정
    if config.choices and config.showSubText == false then
        for i, choice in ipairs(config.choices) do
            choice.subText = nil
        end
        chooser:choices(config.choices) -- 업데이트된 choices 다시 설정
    end
    
    return chooser
end

-- 폴더 선택 Chooser 생성 함수
-- @param basePath: 기본 경로
-- @param config: chooser 설정 (width, rows, bgDark, placeholder, showSubText)
-- @param onSelect: 선택 시 실행할 함수 (folder 객체 {name, path}를 매개변수로 받음)
-- @return hs.chooser: 생성된 chooser 객체 또는 nil (폴더가 없을 때)
function M.createFolderChooser(basePath, config, onSelect)
    local folders = getFolderList(basePath)
    
    if not folders or #folders == 0 then
        return nil
    end
    
    -- 선택 옵션 생성
    local choices = {}
    for i, folder in ipairs(folders) do
        table.insert(choices, {
            text = folder.name,
            path = folder.path,
            subText = folder.path,
            name = folder.name -- 원본 데이터도 유지
        })
    end
    
    -- Chooser 설정
    local chooserConfig = {
        choices = choices,
        onSelect = function(choice)
            if onSelect then
                onSelect({
                    name = choice.name,
                    path = choice.path
                })
            end
        end,
        placeholder = config.placeholder or "📁 폴더를 선택하세요",
        width = config.width or 50,
        rows = config.rows or 8,
        bgDark = config.bgDark,
        showSubText = config.showSubText
    }
    
    return M.createChooser(chooserConfig)
end

-- 단일 폴더 자동 선택 또는 Chooser 표시
-- @param basePath: 기본 경로
-- @param config: chooser 설정
-- @param onSelect: 선택 시 실행할 함수
-- @param onNoFolders: 폴더가 없을 때 실행할 함수
function M.showFolderSelector(basePath, config, onSelect, onNoFolders)
    local folders = getFolderList(basePath)
    
    if not folders or #folders == 0 then
        if onNoFolders then
            onNoFolders(basePath)
        end
        return
    end
    
    if #folders == 1 then
        -- 폴더가 하나뿐이면 자동으로 선택
        onSelect(folders[1])
    else
        -- 여러 폴더가 있으면 Chooser 표시
        local chooser = M.createFolderChooser(basePath, config, onSelect)
        if chooser then
            chooser:show()
        end
    end
end

-- 최근 사용 기록 기반으로 choices 정렬
-- @param choices: 원본 choices 배열
-- @param category: 카테고리 이름
-- @param keyExtractor: 각 choice에서 키를 추출하는 함수 (선택사항)
-- @return table: 정렬된 choices 배열
function M.sortChoicesByRecentUsage(choices, category, keyExtractor)
    local recentUsage = loadRecentUsage()
    local recentItems = recentUsage[category] or {}
    
    -- 키 추출 함수가 없으면 기본값 사용
    if not keyExtractor then
        keyExtractor = function(choice)
            return choice.path or choice.text or choice.action
        end
    end
    
    -- 최근 사용 항목들을 맵으로 변환 (빠른 검색을 위해)
    local recentMap = {}
    for i, item in ipairs(recentItems) do
        recentMap[item.key] = i
    end
    
    -- 정렬 함수
    local function sortFunc(a, b)
        local keyA = keyExtractor(a)
        local keyB = keyExtractor(b)
        local rankA = recentMap[keyA] or 999
        local rankB = recentMap[keyB] or 999
        
        -- 최근 사용 순서대로 정렬
        if rankA ~= rankB then
            return rankA < rankB
        end
        
        -- 같은 순위면 알파벳 순
        return keyA < keyB
    end
    
    -- 복사본 생성 후 정렬
    local sortedChoices = {}
    for i, choice in ipairs(choices) do
        table.insert(sortedChoices, choice)
    end
    
    table.sort(sortedChoices, sortFunc)
    return sortedChoices
end

-- 항목 선택 기록 업데이트
-- @param category: 카테고리 이름
-- @param choice: 선택된 choice 객체
-- @param keyExtractor: 키 추출 함수 (선택사항)
function M.recordChoiceSelection(category, choice, keyExtractor)
    if not keyExtractor then
        keyExtractor = function(choice)
            return choice.path or choice.text or choice.action
        end
    end
    
    local key = keyExtractor(choice)
    local data = {
        text = choice.text,
        subText = choice.subText,
        action = choice.action,
        path = choice.path
    }
    
    updateRecentUsage(category, key, data)
end

-- config에서 chooser 설정을 가져오는 헬퍼 함수
-- @param config: 전체 config 객체
-- @param section: config 섹션 (예: "cursor")
-- @return table: chooser 설정 객체
function M.getChooserConfig(config, section)
    local sectionConfig = config[section]
    if not sectionConfig or not sectionConfig.chooser then
        return {}
    end
    
    return {
        width = sectionConfig.chooser.width,
        rows = sectionConfig.chooser.rows,
        bgDark = sectionConfig.chooser.bgDark,
        placeholder = sectionConfig.chooser.placeholder,
        showSubText = sectionConfig.chooser.showSubText
    }
end

return M
