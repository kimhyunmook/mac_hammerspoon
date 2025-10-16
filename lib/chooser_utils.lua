-- chooser_utils.lua
-- 공용 Chooser 유틸리티 모듈

local M = {}

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
