# mac_hammerspoon

- 먼저 hammerspoon 설치가 필요합니다.

## 사용법

### 1. 설치

#### 방법 A: 새로 설치 (기존 폴더가 없거나 백업 후 설치)

```bash
cd ~
# 기존 폴더가 있다면 백업
mv ~/.hammerspoon ~/.hammerspoon.backup

# 저장소를 ~/.hammerspoon 폴더로 직접 클론
git clone https://github.com/kimhyunmook/mac_hammerspoon.git .hammerspoon
```

#### 방법 B: 기존 폴더가 이미 있는 경우

```bash
cd ~/.hammerspoon

# 기존 Git 정보 제거 (있다면)
rm -rf .git

# Git 저장소 초기화 및 원격 저장소 연결
git init
git remote add origin https://github.com/kimhyunmook/mac_hammerspoon.git
git fetch
git reset --hard origin/main
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
