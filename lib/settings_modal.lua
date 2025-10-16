-- settings_modal.lua
-- JSON 기반 설정 모달

local M = {}

-- JSON 설정 파일에 저장하는 함수
local function saveSettingsToJson(settings)
    local settingsPath = hs.configdir .. "/settings.json"
    
    print("💾 설정 저장 시작...")
    print("📁 저장할 기본 폴더: " .. (settings.defaultFolder or ""))
    print("🎨 Chooser 너비: " .. (settings.chooserWidth or ""))
    print("📏 Chooser 행 수: " .. (settings.chooserRows or ""))
    print("🌙 다크 모드: " .. tostring(settings.bgDark))
    print("🔍 전체 설정 객체:", hs.inspect(settings))
    print("📂 설정 파일 경로: " .. settingsPath)
    
    local settingsData = {
        cursor = {
            defaultFolder = settings.defaultFolder,
            chooser = {
                width = settings.chooserWidth,
                rows = settings.chooserRows,
                bgDark = settings.bgDark,
                placeholder = "📁 Cursor에서 열 폴더를 선택하세요",
                showSubText = true,
                iconSize = 24
            }
        }
    }
    
    -- JSON 인코딩 시도
    local jsonContent = hs.json.encode(settingsData, true) -- pretty print
    if not jsonContent then
        print("❌ JSON 인코딩 실패")
        return false, "JSON 인코딩에 실패했습니다"
    end
    
    print("✅ JSON 인코딩 완료 (" .. #jsonContent .. " bytes)")
    
    -- Node.js fs.writeFileSync처럼 강제 덮어쓰기
    print("🔄 파일 강제 덮어쓰기 시작...")
    
    -- 임시 파일명 생성
    local tempPath = settingsPath .. ".tmp"
    
    -- 1단계: 임시 파일에 쓰기
    local tempFile = io.open(tempPath, "w")
    if not tempFile then
        print("❌ 임시 파일 생성 실패: " .. tempPath)
        return false, "임시 파일을 생성할 수 없습니다"
    end
    
    local writeResult = tempFile:write(jsonContent)
    tempFile:flush()
    tempFile:close()
    
    if not writeResult then
        print("❌ 임시 파일 쓰기 실패")
        os.remove(tempPath)  -- 임시 파일 정리
        return false, "임시 파일 쓰기에 실패했습니다"
    end
    
    print("✅ 임시 파일 쓰기 완료")
    
    -- 2단계: 기존 파일 삭제
    if hs.fs.attributes(settingsPath) then
        print("🗑️ 기존 파일 삭제 중...")
        os.remove(settingsPath)
    end
    
    -- 3단계: 임시 파일을 원본 파일로 이동
    local moveResult = os.rename(tempPath, settingsPath)
    if not moveResult then
        print("❌ 파일 이동 실패, 직접 복사 시도")
        
        -- 이동 실패 시 직접 복사
        local srcFile = io.open(tempPath, "r")
        local dstFile = io.open(settingsPath, "w")
        
        if srcFile and dstFile then
            local content = srcFile:read("*all")
            dstFile:write(content)
            dstFile:flush()
            srcFile:close()
            dstFile:close()
            os.remove(tempPath)  -- 임시 파일 정리
            print("✅ 직접 복사 완료")
        else
            print("❌ 직접 복사 실패")
            return false, "파일 복사에 실패했습니다"
        end
    else
        print("✅ 파일 이동 완료")
    end
    
    print("✅ 설정 파일 저장 완료: " .. settingsPath)
    
    -- 파일이 실제로 저장되었는지 확인
    local verifyFile = io.open(settingsPath, "r")
    if verifyFile then
        local content = verifyFile:read("*all")
        verifyFile:close()
        if #content > 0 then
            print("✅ 파일 저장 검증 완료")
            print("📄 저장된 내용:", content)
            
            -- 저장된 내용이 실제로 새로운 설정과 일치하는지 확인
            local savedSettings = hs.json.decode(content)
            if savedSettings and savedSettings.cursor then
                print("🔍 저장된 기본 폴더:", savedSettings.cursor.defaultFolder)
                print("🔍 저장된 너비:", savedSettings.cursor.chooser.width)
                print("🔍 저장된 행 수:", savedSettings.cursor.chooser.rows)
                print("🔍 저장된 다크모드:", savedSettings.cursor.chooser.bgDark)
                
                -- 원본 설정과 비교
                if savedSettings.cursor.defaultFolder == settings.defaultFolder then
                    print("✅ 기본 폴더 저장 확인됨")
                else
                    print("❌ 기본 폴더 저장 불일치!")
                end
            end
            
            return true, "설정이 성공적으로 저장되었습니다"
        else
            print("❌ 파일이 비어있음")
            return false, "저장된 파일이 비어있습니다"
        end
    else
        print("❌ 저장된 파일을 읽을 수 없음")
        return false, "저장된 파일을 읽을 수 없습니다"
    end
end

-- config 모듈 강제 리로드 함수
local function reloadConfig()
    print("🔄 config 모듈 리로드 시작...")
    
    -- config 모듈이 이미 로드되어 있는지 확인
    local config = package.loaded["config"]
    if config and config.reload then
        -- 새로운 reload 함수 사용
        local success = config.reload()
        if success then
            print("✅ config 실시간 리로드 완료")
            return true
        else
            print("❌ config 실시간 리로드 실패")
            return false
        end
    else
        -- 기존 방식: package.loaded에서 config 제거하여 강제 리로드
        package.loaded["config"] = nil
        
        local success, config = pcall(require, "config")
        if success then
            print("✅ config 모듈 리로드 완료")
            print("📁 새로운 기본 폴더: " .. (config.cursor.defaultFolder or ""))
            return true
        else
            print("❌ config 모듈 리로드 실패: " .. tostring(config))
            return false
        end
    end
end

-- 설정 모달 생성 (Chooser 방식으로 변경)
function M.showSettingsModal()
    print("🔧 설정 모달 시작...")
    
    -- config 로드 시도
    local success, config = pcall(require, "config")
    if not success then
        print("❌ config 로드 실패: " .. tostring(config))
        hs.alert.show("❌ 설정 로드에 실패했습니다.", 2)
        return
    end
    
    -- 현재 설정값들
    local defaultFolder = config.cursor.defaultFolder or ""
    local chooserWidth = config.cursor.chooser.width or 50
    local chooserRows = config.cursor.chooser.rows or 8
    local bgDark = config.cursor.chooser.bgDark or false
    
    print("📁 기본 폴더: " .. defaultFolder)
    
    -- 설정 선택 옵션들 (더 세련된 UI)
    local choices = {
        {
            text = "📁 기본 폴더 경로 변경",
            subText = "현재: " .. defaultFolder,
            action = "defaultFolder",
            currentValue = defaultFolder,
            image = hs.image.imageFromName("NSFolder")
        },
        {
            text = "🎨 Chooser 너비 설정",
            subText = "현재: " .. chooserWidth .. "% " .. string.rep("█", math.floor(chooserWidth/10)) .. string.rep("░", 9-math.floor(chooserWidth/10)),
            action = "chooserWidth",
            currentValue = chooserWidth,
            image = hs.image.imageFromName("NSResize")
        },
        {
            text = "📏 Chooser 행 수 설정",
            subText = "현재: " .. chooserRows .. "행 " .. string.rep("▬", math.min(chooserRows, 10)),
            action = "chooserRows",
            currentValue = chooserRows,
            image = hs.image.imageFromName("NSListViewTemplate")
        },
        {
            text = "🌙 다크 모드 설정",
            subText = "현재: " .. (bgDark and "🔅 켜짐" or "🔆 꺼짐"),
            action = "bgDark",
            currentValue = bgDark,
            image = hs.image.imageFromName(bgDark and "NSStatusAvailable" or "NSStatusUnavailable")
        },
        {
            text = "💾 설정 저장",
            subText = "현재 설정을 JSON 파일에 저장",
            action = "save",
            image = hs.image.imageFromName("NSSaveDocumentTemplate")
        }
    }
    
    -- 임시 설정 저장용 테이블
    local tempSettings = {
        defaultFolder = defaultFolder,
        chooserWidth = chooserWidth,
        chooserRows = chooserRows,
        bgDark = bgDark
    }
    
    local function showChooser()
        local chooser = hs.chooser.new(function(choice)
            if not choice then return end
            
            print("🎯 선택된 항목: " .. choice.action)
            
            if choice.action == "defaultFolder" then
                -- 기본 폴더 경로 입력 (더 세련된 UI)
                local button, inputText = hs.dialog.textPrompt(
                    "📁 기본 폴더 경로 설정", 
                    "Cursor에서 열 기본 폴더의 전체 경로를 입력하세요:\n\n예: /Users/username/Desktop/projects", 
                    tempSettings.defaultFolder
                )
                print("🔍 버튼:", button, "입력 텍스트:", inputText)
                
                if button == "OK" and inputText and inputText ~= "" then
                    -- 경로 유효성 검사
                    if hs.fs.attributes(inputText) then
                        tempSettings.defaultFolder = inputText
                        print("📁 기본 폴더 변경됨: " .. inputText)
                        hs.alert.show("✅ 기본 폴더가 변경되었습니다", 2)
                    else
                        hs.alert.show("⚠️ 해당 경로를 찾을 수 없습니다:\n" .. inputText, 3)
                    end
                elseif button == "OK" then
                    hs.alert.show("⚠️ 유효한 폴더 경로를 입력해주세요", 2)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "chooserWidth" then
                -- Chooser 너비 입력 (더 세련된 UI)
                local button, inputText = hs.dialog.textPrompt(
                    "🎨 Chooser 너비 설정", 
                    "Chooser 창의 화면 너비 비율을 설정하세요:\n\n현재: " .. tempSettings.chooserWidth .. "%\n범위: 10% ~ 90%\n\n추천: 50-70%", 
                    tostring(tempSettings.chooserWidth)
                )
                print("🔍 너비 - 버튼:", button, "입력:", inputText)
                
                if button == "OK" and inputText and inputText ~= "" then
                    local width = tonumber(inputText)
                    if width and width >= 10 and width <= 90 then
                        tempSettings.chooserWidth = width
                        print("🎨 Chooser 너비 변경됨: " .. width)
                        hs.alert.show("✅ Chooser 너비가 " .. width .. "%로 변경되었습니다", 2)
                    else
                        hs.alert.show("⚠️ 너비는 10-90 사이의 숫자여야 합니다\n\n입력된 값: " .. inputText, 3)
                    end
                elseif button == "OK" then
                    hs.alert.show("⚠️ 유효한 숫자를 입력해주세요 (10-90)", 2)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "chooserRows" then
                -- Chooser 행 수 입력 (더 세련된 UI)
                local button, inputText = hs.dialog.textPrompt(
                    "📏 Chooser 행 수 설정", 
                    "Chooser 창에 표시할 최대 줄 수를 설정하세요:\n\n현재: " .. tempSettings.chooserRows .. "행\n범위: 3 ~ 20행\n\n추천: 8-12행", 
                    tostring(tempSettings.chooserRows)
                )
                print("🔍 행 수 - 버튼:", button, "입력:", inputText)
                
                if button == "OK" and inputText and inputText ~= "" then
                    local rows = tonumber(inputText)
                    if rows and rows >= 3 and rows <= 20 then
                        tempSettings.chooserRows = rows
                        print("📏 Chooser 행 수 변경됨: " .. rows)
                        hs.alert.show("✅ Chooser 행 수가 " .. rows .. "행으로 변경되었습니다", 2)
                    else
                        hs.alert.show("⚠️ 행 수는 3-20 사이의 숫자여야 합니다\n\n입력된 값: " .. inputText, 3)
                    end
                elseif button == "OK" then
                    hs.alert.show("⚠️ 유효한 숫자를 입력해주세요 (3-20)", 2)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "bgDark" then
                -- 다크 모드 토글 (모달이 닫히지 않도록 즉시 다시 열기)
                tempSettings.bgDark = not tempSettings.bgDark
                print("🌙 다크 모드 변경됨: " .. tostring(tempSettings.bgDark))
                hs.alert.show(
                    (tempSettings.bgDark and "🌙" or "☀️") .. " 다크 모드가 " .. 
                    (tempSettings.bgDark and "활성화" or "비활성화") .. "되었습니다", 2
                )
                
                -- 즉시 새로운 chooser를 표시하여 모달이 닫히지 않도록 함
                hs.timer.doAfter(0.1, function()
                    showChooser()
                end)
                
            elseif choice.action == "save" then
                -- 설정 저장
                print("💾 설정 저장 시작...")
                local saveSuccess, saveMessage = saveSettingsToJson(tempSettings)
                if saveSuccess then
                    print("✅ 설정 저장 성공")
                    
                    -- config 모듈 리로드
                    local reloadSuccess = reloadConfig()
                    if reloadSuccess then
                        print("✅ 실시간 반영 완료")
                        hs.alert.show("🎉 설정이 성공적으로 저장되고 즉시 적용되었습니다!", 3)
                    else
                        print("⚠️ 설정 저장은 성공했지만 실시간 반영 실패")
                        hs.alert.show("✅ 설정이 저장되었습니다!\n\n🔄 Hammerspoon을 다시 로드하면 적용됩니다.", 3)
                    end
                else
                    print("❌ 설정 저장 실패: " .. (saveMessage or "알 수 없는 오류"))
                    hs.alert.show("❌ 설정 저장에 실패했습니다.\n\n📝 오류: " .. (saveMessage or "알 수 없는 오류"), 3)
                end
                
            end
        end)
        
        -- 업데이트된 선택지들 (더 세련된 UI)
        local updatedChoices = {
            {
                text = "📁 기본 폴더 경로 변경",
                subText = "현재: " .. tempSettings.defaultFolder,
                action = "defaultFolder",
                currentValue = tempSettings.defaultFolder,
                image = hs.image.imageFromName("NSFolder")
            },
            {
                text = "🎨 Chooser 너비 설정",
                subText = "현재: " .. tempSettings.chooserWidth .. "% " .. string.rep("█", math.floor(tempSettings.chooserWidth/10)) .. string.rep("░", 9-math.floor(tempSettings.chooserWidth/10)),
                action = "chooserWidth",
                currentValue = tempSettings.chooserWidth,
                image = hs.image.imageFromName("NSResize")
            },
            {
                text = "📏 Chooser 행 수 설정",
                subText = "현재: " .. tempSettings.chooserRows .. "행 " .. string.rep("▬", math.min(tempSettings.chooserRows, 10)),
                action = "chooserRows",
                currentValue = tempSettings.chooserRows,
                image = hs.image.imageFromName("NSListViewTemplate")
            },
            {
                text = "🌙 다크 모드 설정",
                subText = "현재: " .. (tempSettings.bgDark and "🔅 켜짐" or "🔆 꺼짐"),
                action = "bgDark",
                currentValue = tempSettings.bgDark,
                image = hs.image.imageFromName(tempSettings.bgDark and "NSStatusAvailable" or "NSStatusUnavailable")
            },
                    {
                        text = "💾 설정 저장",
                        subText = "현재 설정을 JSON 파일에 저장",
                        action = "save",
                        image = hs.image.imageFromName("NSSaveDocumentTemplate")
                    }
        }
        
        chooser:choices(updatedChoices)
        chooser:placeholderText("⚙️ Hammerspoon 설정을 선택하세요")
        chooser:width(70)  -- 조금 더 넓게
        chooser:rows(7)    -- 조금 더 줄여서 깔끔하게
        chooser:bgDark(true)
        chooser:searchSubText(true)  -- 서브텍스트에서도 검색 가능
        chooser:show()
    end
    
    showChooser()
    print("✅ 설정 모달 표시 완료")
end

return M
