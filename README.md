# mac_hammerspoon

## 사용법

### 1. 설치

터미널을 열고 아래 명령어를 실행하세요:

```bash
# 기존 설정이 있다면 백업 (선택사항)
# mv ~/.hammerspoon ~/.hammerspoon.backup

# 저장소를 ~/.hammerspoon 폴더로 직접 클론
cd ~
git clone https://github.com/kimhyunmook/mac_hammerspoon.git .hammerspoon
```

### 2. 설치 확인

```bash
cd ~/.hammerspoon
git status
```

정상적으로 설치되었다면 Git 상태가 표시됩니다.

### 3. 설정 적용

- 화면 상단 해머 모양 아이콘을 클릭
- **Reload Config** 선택

## 설정 커스터마이징

`config.lua` 파일에서 개인 설정을 변경할 수 있습니다:

```lua
config.cursor = {
    defaultFolder = os.getenv("HOME") .. "/Desktop/back"  -- 원하는 경로로 변경
}
```
