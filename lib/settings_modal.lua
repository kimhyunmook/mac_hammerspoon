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
    hs.alert.show("⚙️ 설정 모달을 엽니다...", 1)
    
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
    
    -- 설정 선택 옵션들
    local choices = {
        {
            text = "📁 기본 폴더 경로 변경",
            subText = "현재: " .. defaultFolder,
            action = "defaultFolder",
            currentValue = defaultFolder
        },
        {
            text = "🎨 Chooser 너비 변경",
            subText = "현재: " .. chooserWidth .. "% (10-90)",
            action = "chooserWidth",
            currentValue = chooserWidth
        },
        {
            text = "📏 Chooser 행 수 변경",
            subText = "현재: " .. chooserRows .. "행 (3-20)",
            action = "chooserRows",
            currentValue = chooserRows
        },
        {
            text = "🌙 다크 모드 토글",
            subText = "현재: " .. (bgDark and "켜짐" or "꺼짐"),
            action = "bgDark",
            currentValue = bgDark
        },
        {
            text = "💾 모든 설정 저장",
            subText = "현재 설정을 JSON 파일에 저장",
            action = "save"
        },
        {
            text = "❌ 설정 모달 닫기",
            subText = "변경사항을 저장하지 않고 닫기",
            action = "close"
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
                -- 기본 폴더 경로 입력 (올바른 textPrompt 사용법 - 두 개의 반환값 처리)
                local button, inputText = hs.dialog.textPrompt("기본 폴더 경로", "새로운 기본 폴더 경로를 입력하세요:", tempSettings.defaultFolder)
                print("🔍 버튼:", button, "입력 텍스트:", inputText)
                
                -- textPrompt는 (버튼라벨, 입력텍스트) 두 개의 값을 반환
                if button == "OK" and inputText and inputText ~= "" then
                    tempSettings.defaultFolder = inputText
                    print("📁 기본 폴더 변경됨: " .. inputText)
                    hs.alert.show("기본 폴더가 변경되었습니다", 2)
                else
                    print("📁 입력값이 유효하지 않음 - 버튼:", button, "텍스트:", inputText)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "chooserWidth" then
                -- Chooser 너비 입력
                local button, inputText = hs.dialog.textPrompt("Chooser 너비", "화면 너비 비율을 입력하세요 (10-90):", tostring(tempSettings.chooserWidth))
                print("🔍 너비 - 버튼:", button, "입력:", inputText)
                
                if button == "OK" and inputText and inputText ~= "" then
                    local width = tonumber(inputText)
                    if width and width >= 10 and width <= 90 then
                        tempSettings.chooserWidth = width
                        print("🎨 Chooser 너비 변경됨: " .. width)
                        hs.alert.show("Chooser 너비가 변경되었습니다", 2)
                    else
                        hs.alert.show("너비는 10-90 사이의 숫자여야 합니다", 2)
                    end
                else
                    print("🎨 너비 입력값이 유효하지 않음 - 버튼:", button, "텍스트:", inputText)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "chooserRows" then
                -- Chooser 행 수 입력
                local button, inputText = hs.dialog.textPrompt("Chooser 행 수", "최대 표시 줄 수를 입력하세요 (3-20):", tostring(tempSettings.chooserRows))
                print("🔍 행 수 - 버튼:", button, "입력:", inputText)
                
                if button == "OK" and inputText and inputText ~= "" then
                    local rows = tonumber(inputText)
                    if rows and rows >= 3 and rows <= 20 then
                        tempSettings.chooserRows = rows
                        print("📏 Chooser 행 수 변경됨: " .. rows)
                        hs.alert.show("Chooser 행 수가 변경되었습니다", 2)
                    else
                        hs.alert.show("행 수는 3-20 사이의 숫자여야 합니다", 2)
                    end
                else
                    print("📏 행 수 입력값이 유효하지 않음 - 버튼:", button, "텍스트:", inputText)
                end
                showChooser() -- 다시 chooser 표시
                
            elseif choice.action == "bgDark" then
                -- 다크 모드 토글
                tempSettings.bgDark = not tempSettings.bgDark
                print("🌙 다크 모드 변경됨: " .. tostring(tempSettings.bgDark))
                hs.alert.show("다크 모드가 " .. (tempSettings.bgDark and "켜졌습니다" or "꺼졌습니다"), 2)
                showChooser() -- 다시 chooser 표시
                
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
                        hs.alert.show("✅ 설정이 저장되고 실시간으로 적용되었습니다!", 3)
                    else
                        print("⚠️ 설정 저장은 성공했지만 실시간 반영 실패")
                        hs.alert.show("✅ 설정이 저장되었습니다!\n\nHammerspoon을 다시 로드하면 적용됩니다.", 3)
                    end
                else
                    print("❌ 설정 저장 실패: " .. (saveMessage or "알 수 없는 오류"))
                    hs.alert.show("❌ 설정 저장에 실패했습니다.\n\n" .. (saveMessage or "알 수 없는 오류"), 3)
                end
                
            elseif choice.action == "close" then
                -- 설정 모달 닫기
                print("❌ 설정 모달 닫기")
                hs.alert.show("설정 모달을 닫습니다", 1)
            end
        end)
        
        -- 업데이트된 선택지들
        local updatedChoices = {
            {
                text = "📁 기본 폴더 경로 변경",
                subText = "현재: " .. tempSettings.defaultFolder,
                action = "defaultFolder",
                currentValue = tempSettings.defaultFolder
            },
            {
                text = "🎨 Chooser 너비 변경",
                subText = "현재: " .. tempSettings.chooserWidth .. "% (10-90)",
                action = "chooserWidth",
                currentValue = tempSettings.chooserWidth
            },
            {
                text = "📏 Chooser 행 수 변경",
                subText = "현재: " .. tempSettings.chooserRows .. "행 (3-20)",
                action = "chooserRows",
                currentValue = tempSettings.chooserRows
            },
            {
                text = "🌙 다크 모드 토글",
                subText = "현재: " .. (tempSettings.bgDark and "켜짐" or "꺼짐"),
                action = "bgDark",
                currentValue = tempSettings.bgDark
            },
            {
                text = "💾 모든 설정 저장",
                subText = "현재 설정을 JSON 파일에 저장",
                action = "save"
            },
            {
                text = "❌ 설정 모달 닫기",
                subText = "변경사항을 저장하지 않고 닫기",
                action = "close"
            }
        }
        
        chooser:choices(updatedChoices)
        chooser:placeholderText("⚙️ 설정을 선택하세요")
        chooser:width(60)
        chooser:rows(8)
        chooser:bgDark(true)
        chooser:show()
    end
    
    showChooser()
    print("✅ 설정 모달 표시 완료")
end

return M
