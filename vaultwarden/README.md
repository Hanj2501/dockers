# Vaultwarden with Encrypted Rclone Backup

자체 호스팅 비밀번호 관리자 + Google Drive 자동 암호화 백업

---

## 📋 목차

1. [빠른 시작](#-빠른-시작)
2. [주요 기능](#-주요-기능)
3. [시스템 요구사항](#-시스템-요구사항)
4. [설치 가이드](#-설치-가이드)
5. [Rclone 설정 상세](#-rclone-설정-상세)
6. [Rclone 연결 테스트](#-rclone-연결-테스트)
7. [Nginx Proxy Manager 설정](#-nginx-proxy-manager-설정)
8. [초기 설정](#-초기-설정)
9. [백업 시스템](#-백업-시스템)
10. [재해 복구](#-재해-복구)
11. [유용한 명령어](#-유용한-명령어)
12. [문제 해결](#-문제-해결)
13. [보안 권장사항](#-보안-권장사항)

---

## 🚀 빠른 시작

### 초기 설치 (원라인)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/install-vaultwarden.sh | bash
```

### 재해 복구 (원라인)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/restore-vaultwarden.sh | bash
```

### 수동 설치
```bash
# 1. 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/install-vaultwarden.sh

# 2. 실행 권한 부여
chmod +x install-vaultwarden.sh

# 3. 설치 실행
./install-vaultwarden.sh
```

---

## ✨ 주요 기능

### Vaultwarden
- ✅ 자체 호스팅 비밀번호 관리자
- ✅ Bitwarden 호환 (모든 클라이언트 사용 가능)
- ✅ Admin 패널 (사용자 관리)
- ✅ 2FA 지원 (TOTP, WebAuthn)
- ✅ 첨부 파일 지원
- ✅ 무료, 무제한 사용자

### 백업 시스템
- ✅ Google Drive 자동 백업
- ✅ AES-256 암호화 (Rclone crypt)
- ✅ 설정 파일 자동 백업 (재해 복구용)
- ✅ 연도별 백업 로그 (`backup-2025.log`)
- ✅ 사용자 정의 백업 주기
- ✅ 원라인 재해 복구

### 자동화
- ✅ docker-compose.yml 자동 생성
- ✅ Admin 토큰 자동 생성
- ✅ 네트워크 자동 확인/생성
- ✅ 백업 자동 실행

---

## 💻 시스템 요구사항

### 필수 사항
- Docker 20.10 이상
- Docker Compose V2 이상
- Google 계정 (Google Drive 백업용)
- 도메인 (Nginx Proxy Manager 사용)

### 권장 사항
- RAM: 1GB 이상
- Storage: 10GB 이상
- CPU: 1 Core 이상

### 설치 확인
```bash
# Docker 버전 확인
docker --version
docker compose version

# Docker 설치 (필요시)
curl -fsSL https://get.docker.com | sudo bash
```

---

## 📦 설치 가이드

### 1단계: 스크립트 실행
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/install-vaultwarden.sh | bash
```

### 2단계: 설정 입력

#### 컨테이너 이름
```
Vaultwarden 컨테이너 이름을 입력하세요 (기본값: vaultwarden):
> vaultwarden
```
- 기본값 사용 권장
- 다른 이름 사용 시 모든 명령어에서 해당 이름 사용

#### 도메인
```
Vaultwarden 도메인을 입력하세요 (예: vault.example.com):
> vault.yourdomain.com
```
- 반드시 실제 사용할 도메인 입력
- Nginx Proxy Manager에서 동일한 도메인 설정 필요

#### 네트워크
```
Docker 네트워크 이름을 입력하세요 (기본값: main):
> main
```
- Nginx Proxy Manager와 동일한 네트워크 사용
- 기본값 `main` 권장

#### 백업 주기
```
백업 주기를 선택하세요:
  1) 1시간
  2) 6시간
  3) 12시간
  4) 24시간 [권장]
  5) 사용자 정의
> 4
```
- **권장**: 24시간 (86400초)
- 빈번한 백업은 Google Drive API 제한 발생 가능

#### 백업 폴더
```
Google Drive 백업 루트 폴더명을 입력하세요 (기본값: vaultwarden-backups):
> vaultwarden-backups
```
- Google Drive에 생성될 최상위 폴더명

#### Admin 비밀번호
```
Admin 비밀번호: ****************
Admin 비밀번호 확인: ****************
```
- 최소 12자 이상 권장
- Admin 페이지 접속에 사용

### 3단계: Rclone 설정

스크립트가 자동으로 Rclone 설정 프로세스를 시작합니다.

---

## 🔐 Rclone 설정 상세

### Step 1: Google Drive 기본 리모트 (gdrive)

#### 1. Rclone 설정 시작
```
Rclone 설정을 시작하시겠습니까? (y/N): y
```

#### 2. 새 리모트 생성
```
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
```

#### 3. 리모트 이름
```
name> gdrive
```

#### 4. Storage 선택
```
Storage> drive
```
또는 번호 입력 (Google Drive 찾기)

#### 5. 기본값 사용
```
client_id> (엔터)
client_secret> (엔터)
scope> (엔터)
root_folder_id> (엔터)
service_account_file> (엔터)
```

#### 6. Advanced config
```
Edit advanced config?
y/n> n
```

#### 7. Auto config
```
Use auto config?
y/n> n
```

#### 8. 인증 URL 복사
```
If your browser doesn't open automatically go to the following link:
https://accounts.google.com/o/oauth2/auth?...

Enter verification code> 
```
- 브라우저에서 URL 열기
- Google 계정 로그인
- Rclone 권한 허용
- 인증 코드 복사하여 입력

#### 9. Team Drive
```
Configure this as a Shared Drive (Team Drive)?
y/n> n
```

#### 10. 설정 확인
```
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y
```

### Step 2: 암호화 리모트 (gdrive-crypt)

#### 1. 새 리모트 생성
```
n/s/q> n
```

#### 2. 리모트 이름
```
name> gdrive-crypt
```

#### 3. Storage 선택
```
Storage> crypt
```

#### 4. Remote 경로
```
remote> gdrive:vaultwarden-backups/encrypted
```
⚠️ **중요**: `vaultwarden-backups`는 앞에서 입력한 백업 폴더명과 동일해야 함

#### 5. Filename encryption
```
filename_encryption> 1
```
- 1 = standard (권장)

#### 6. Directory name encryption
```
directory_name_encryption> 1
```
- 1 = true (권장)

#### 7. Password (매우 중요!)
```
password:
y) Yes type in my own password
g) Generate random password
y/g> y
Enter the password: ****************
Confirm the password: ****************
```

⚠️ **매우 중요**: 
- 이 비밀번호를 잃어버리면 백업을 복원할 수 없습니다!
- 강력한 비밀번호 사용
- 안전한 곳에 별도로 보관 필수

#### 8. Salt password
```
password2:
y) Yes type in my own password
g) Generate random password
n) No leave this optional password blank (default)
y/g/n> (엔터)
```
- 기본값 (자동 생성) 권장

#### 9. Advanced config
```
Edit advanced config?
y/n> n
```

#### 10. 설정 확인
```
y/e/d> y
```

#### 11. 종료
```
q) Quit config
q> q
```

---

## 🧪 Rclone 연결 테스트

### 1. 리모트 목록 확인
```bash
docker run --rm -v $(pwd)/rclone-config:/config/rclone rclone/rclone listremotes
```

**예상 출력:**
```
gdrive:
gdrive-crypt:
```

### 2. Google Drive 연결 테스트
```bash
# gdrive 테스트 (비암호화)
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone lsd gdrive:
```

**예상 출력:**
```
          -1 2025-12-07 17:30:00        -1 vaultwarden-backups
```

### 3. 암호화 리모트 테스트
```bash
# gdrive-crypt 테스트 (암호화)
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone lsd gdrive-crypt:vaultwarden-backups/
```

**예상 출력:**
```
          -1 2025-12-07 17:30:00        -1 vaultwarden-data
```

### 4. 테스트 파일 업로드
```bash
# 테스트 파일 생성
echo "Test backup file" > test.txt

# 암호화하여 업로드
docker run --rm \
  -v $(pwd)/rclone-config:/config/rclone \
  -v $(pwd):/data \
  rclone/rclone copy /data/test.txt gdrive-crypt:vaultwarden-backups/test/

# 업로드 확인
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone ls gdrive-crypt:vaultwarden-backups/test/
```

### 5. 테스트 파일 다운로드 및 확인
```bash
# 다운로드
docker run --rm \
  -v $(pwd)/rclone-config:/config/rclone \
  -v $(pwd):/data \
  rclone/rclone copy gdrive-crypt:vaultwarden-backups/test/test.txt /data/test-download.txt

# 내용 확인
cat test-download.txt
```

**예상 출력:**
```
Test backup file
```

### 6. Google Drive 웹에서 확인
1. https://drive.google.com 접속
2. `vaultwarden-backups` 폴더 확인
3. `encrypted` 폴더 - 암호화된 파일명 확인 (읽을 수 없음)
4. `rclone-config` 폴더 - 설정 파일 확인 (평문)

### 7. 테스트 정리
```bash
# 테스트 파일 삭제
rm -f test.txt test-download.txt

# Google Drive 테스트 폴더 삭제
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone purge gdrive-crypt:vaultwarden-backups/test/
```

### 연결 문제 해결

#### 오류: "Failed to create file system"
```bash
# Rclone 설정 확인
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone config show
```

#### 오류: "couldn't decrypt filename"
- 암호화 비밀번호가 틀렸거나
- 잘못된 리모트 경로 사용
- Rclone 설정 재확인 필요

#### 오류: "rate limit exceeded"
- Google Drive API 제한
- 10~30분 대기 후 재시도
- 백업 주기 늘리기 (24시간 권장)

---

## 🌐 Nginx Proxy Manager 설정

### 1. Proxy Host 추가
1. Nginx Proxy Manager Admin 패널 접속
2. `Hosts` → `Proxy Hosts` → `Add Proxy Host`

### 2. Details 탭
```
Domain Names: vault.yourdomain.com
Scheme: http
Forward Hostname / IP: vaultwarden
Forward Port: 80
```

**중요 설정:**
- ✅ `Cache Assets` 활성화
- ✅ `Block Common Exploits` 활성화
- ✅ `Websockets Support` 활성화

### 3. SSL 탭
```
SSL Certificate: Request a new SSL Certificate
```
- ✅ `Force SSL` 활성화
- ✅ `HTTP/2 Support` 활성화
- ✅ `HSTS Enabled` 활성화
- ✅ `I Agree to the Let's Encrypt Terms of Service` 체크

이메일 입력 후 `Save`

### 4. 접속 테스트
```bash
# HTTPS 접속 확인
curl -I https://vault.yourdomain.com
```

**예상 출력:**
```
HTTP/2 200
server: nginx
```

---

## 🎯 초기 설정

### 1. 웹 접속
브라우저에서 `https://vault.yourdomain.com` 접속

### 2. 계정 생성
1. `Create Account` 클릭
2. 이메일 주소 입력
3. Master Password 설정 (강력한 비밀번호!)
4. Password Hint (선택)
5. `Submit` 클릭

### 3. 로그인 및 확인
1. 생성한 계정으로 로그인
2. Vault가 정상 작동하는지 확인
3. 테스트 항목 추가

### 4. 회원가입 비활성화 (중요!)
```bash
# docker-compose.yml 수정
nano docker-compose.yml
```

**변경:**
```yaml
# 변경 전
- SIGNUPS_ALLOWED=true

# 변경 후
- SIGNUPS_ALLOWED=false
```

**적용:**
```bash
docker compose restart vaultwarden
```

### 5. Admin 패널 접속
1. `https://vault.yourdomain.com/admin` 접속
2. Admin 비밀번호 입력 (설치 시 설정한 비밀번호)
3. 사용자 관리, 설정 확인

### 6. 2FA 활성화 (권장)
1. 사용자 설정 → `Two-step Login`
2. Authenticator App 선택
3. QR 코드 스캔 (Google Authenticator, Authy 등)
4. 복구 코드 안전하게 보관

---

## 💾 백업 시스템

### 디렉토리 구조
```
vaultwarden/
├── docker-compose.yml              # Docker Compose 설정
├── .admin-token                    # Admin 토큰 (로컬만)
├── .vaultwarden-config            # 설정 심볼릭 링크
├── vaultwarden-data/               # Vaultwarden 데이터
│   ├── db.sqlite3                  # 데이터베이스
│   ├── db.sqlite3-shm
│   ├── db.sqlite3-wal
│   ├── attachments/                # 첨부파일
│   └── sends/                      # Send 파일
├── rclone-config/                  # Rclone 설정 (백업됨)
│   ├── rclone.conf                 # Rclone 설정파일
│   └── .vaultwarden-config         # Vaultwarden 설정
└── backup-logs/                    # 백업 로그 (로컬만)
    └── backup-2025.log             # 연도별 로그
```

### Google Drive 백업 구조
```
vaultwarden-backups/                # 백업 루트 폴더
├── vaultwarden-data/               # 암호화된 Vaultwarden 데이터
│   ├── [암호화된 파일명]           # db.sqlite3 (암호화)
│   ├── [암호화된 폴더명]/          # attachments (암호화)
│   └── [암호화된 폴더명]/          # sends (암호화)
├── rclone-config/                  # Rclone 설정 (비암호화)
│   ├── rclone.conf                 # 재해 복구에 필요
│   └── .vaultwarden-config         # 설정 정보
└── encrypted/                      # 암호화 원본 위치
```

### 백업 로그 확인
```bash
# 실시간 로그
tail -f backup-logs/backup-$(date +%Y).log

# 전체 로그 보기
cat backup-logs/backup-$(date +%Y).log

# 최근 백업 확인
docker compose logs vaultwarden-backup --tail 50
```

### 백업 로그 예시
```
[2025-12-07 18:00:01] Starting encrypted backup...
2025/12/07 18:00:05 INFO  : db.sqlite3: Copied (new)
2025/12/07 18:00:06 INFO  : attachments/: Copied (new)
[2025-12-07 18:00:10] Encrypted backup completed
[2025-12-07 18:00:10] Starting rclone-config backup...
2025/12/07 18:00:12 INFO  : rclone.conf: Copied (new)
2025/12/07 18:00:13 INFO  : .vaultwarden-config: Copied (new)
[2025-12-07 18:00:15] Rclone-config backup completed
```

### 수동 백업 실행
```bash
# 즉시 백업 실행 (컨테이너 내부에서)
docker exec vaultwarden-backup \
  rclone sync /data gdrive-crypt:vaultwarden-backups/vaultwarden-data -v

# Rclone 설정 백업
docker exec vaultwarden-backup \
  rclone sync /config/rclone gdrive:vaultwarden-backups/rclone-config -v
```

### 백업 확인
```bash
# 암호화된 백업 목록
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone ls gdrive-crypt:vaultwarden-backups/vaultwarden-data

# Rclone 설정 백업 확인
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone ls gdrive:vaultwarden-backups/rclone-config
```

### 백업 주기 변경
```bash
# docker-compose.yml 수정
nano docker-compose.yml
```

**수정:**
```yaml
# 12시간으로 변경
sleep 43200;    # 기존: 86400 (24시간)
```

**적용:**
```bash
docker compose restart vaultwarden-backup
```

---

## 🔄 재해 복구

### 시나리오: 서버 완전 손실

#### 1단계: 복구 스크립트 실행
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/restore-vaultwarden.sh | bash
```

#### 2단계: 작업 디렉토리 확인
```
현재 디렉토리: /home/user/vaultwarden
기존 Vaultwarden 관련 파일이 존재합니다.
덮어쓰시겠습니까? (y/N): y
```
- 기존 파일은 `backup-YYYYMMDD_HHMMSS/` 폴더에 백업됨

#### 3단계: Google Drive 인증
```bash
# Rclone 설정 화면
n/s/q> n
name> gdrive
Storage> drive
# ... (설치와 동일한 과정)
```

#### 4단계: 백업 복원
```
Google Drive 백업 루트 폴더명을 입력하세요:
> vaultwarden-backups
```

스크립트가 자동으로:
1. Rclone 설정 파일 복원
2. `.vaultwarden-config` 파일 로드
3. 설정 정보 자동 적용

#### 5단계: Admin 토큰 설정
```
Admin 토큰을 설정하는 방법을 선택하세요:
  1) 새 Admin 비밀번호로 토큰 생성
  2) 기존 Admin 토큰 직접 입력
선택 (1/2): 1

Admin 비밀번호: ****************
```

#### 6단계: 데이터 복원 및 시작
```
지금 서비스를 시작하시겠습니까? (y/N): y
```

#### 7단계: 복원 확인
```bash
# 컨테이너 확인
docker compose ps

# 웹 접속 테스트
curl -I https://vault.yourdomain.com
```

---

## 🛠️ 유용한 명령어

### 컨테이너 관리
```bash
# 모든 로그 확인
docker compose logs -f

# Vaultwarden 로그만
docker compose logs -f vaultwarden

# 백업 컨테이너 로그
docker compose logs -f vaultwarden-backup

# 컨테이너 상태
docker compose ps

# 서비스 시작
docker compose up -d

# 서비스 중지
docker compose down

# 서비스 재시작
docker compose restart

# 특정 컨테이너 재시작
docker compose restart vaultwarden
```

### 백업 관리
```bash
# 백업 로그 실시간 확인
tail -f backup-logs/backup-$(date +%Y).log

# 최근 백업 상태
docker compose logs vaultwarden-backup --tail 20

# 수동 백업 실행
docker exec vaultwarden-backup \
  rclone sync /data gdrive-crypt:vaultwarden-backups/vaultwarden-data -v

# 백업 파일 목록
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone ls gdrive-crypt:vaultwarden-backups/vaultwarden-data

# 백업 크기 확인
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone size gdrive-crypt:vaultwarden-backups/vaultwarden-data
```

### 데이터베이스 관리
```bash
# 데이터베이스 백업 (로컬)
docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup '/data/db-backup.sqlite3'"

# 데이터베이스 크기 확인
docker exec vaultwarden ls -lh /data/db.sqlite3

# 데이터베이스 무결성 검사
docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"
```

### Rclone 관리
```bash
# 리모트 목록
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone listremotes

# Rclone 설정 보기
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone config show

# 대역폭 테스트
docker run --rm -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone test speed gdrive-crypt:vaultwarden-backups/vaultwarden-data
```

### 네트워크 관리
```bash
# 네트워크 목록
docker network ls

# 네트워크 상세 정보
docker network inspect main

# 네트워크에 연결된 컨테이너
docker network inspect main | grep -A 5 Containers
```

---

## 🔍 문제 해결

### 1. 컨테이너가 시작되지 않음

#### 증상
```bash
docker compose ps
# Status: Exited (1)
```

#### 해결
```bash
# 로그 확인
docker compose logs vaultwarden

# 일반적인 원인:
# 1. Admin 토큰 형식 오류
# 2. 볼륨 권한 문제
# 3. 네트워크 미존재

# 볼륨 권한 확인
ls -la vaultwarden-data/

# 권한 수정
sudo chown -R 1000:1000 vaultwarden-data/

# 네트워크 확인
docker network ls | grep main

# 재시작
docker compose up -d
```

### 2. 백업이 실행되지 않음

#### 증상
```bash
# 백업 로그가 업데이트되지 않음
tail backup-logs/backup-$(date +%Y).log
```

#### 해결
```bash
# 백업 컨테이너 로그 확인
docker compose logs vaultwarden-backup

# Rclone 설정 확인
docker exec vaultwarden-backup cat /config/rclone/rclone.conf

# 리모트 테스트
docker exec vaultwarden-backup \
  rclone lsd gdrive-crypt:vaultwarden-backups/

# 컨테이너 재시작
docker compose restart vaultwarden-backup
```

### 3. Google Drive 인증 오류

#### 증상
```
Failed to create file system for "gdrive:": 
couldn't find root directory ID: Get "https://www.googleapis.com/drive/v3/files/...": 
oauth2: cannot fetch token: ... invalid_grant
```

#### 해결
```bash
# Rclone 설정 재설정
docker run --rm -it -v $(pwd)/rclone-config:/config/rclone \
  rclone/rclone config

# gdrive 리모트 삭제 후 재생성
# d) Delete remote
# n) New remote
```

### 4. 암호화 비밀번호 분실

#### 증상
```
Failed to decrypt: cipher: message authentication failed
```

#### 해결
⚠️ **암호화 비밀번호를 잃어버린 경우 복구 불가능**

**예방 조치:**
1. 비밀번호를 안전한 곳에 보관
2. 비밀번호 관리자에 저장
3. 오프라인 백업 (종이에 적기)
4. 정기적인 복원 테스트

### 5. 웹 접속 불가

#### 증상
```bash
curl https://vault.yourdomain.com
# curl: (7) Failed to connect
```

#### 해결
```bash
# 1. 컨테이너 상태 확인
docker compose ps

# 2. Nginx Proxy Manager 설정 확인
# - Domain 이름 일치 여부
# - Forward host: vaultwarden:80
# - SSL 활성화

# 3. 네트워크 확인
docker network inspect main | grep vaultwarden

# 4. 로그 확인
docker compose logs vaultwarden
docker logs nginx-proxy-manager

# 5. 방화벽 확인
sudo ufw status
sudo ufw allow 443/tcp
```

### 6. Admin 패널 접속 불가

#### 증상
```
Invalid admin token
```

#### 해결
```bash
# Admin 토큰 재생성
docker run --rm -i vaultwarden/server:latest /vaultwarden hash
# 비밀번호 입력

# docker-compose.yml 수정
nano docker-compose.yml
# ADMIN_TOKEN= 새 토큰으로 변경

# 재시작
docker compose restart vaultwarden
```

### 7. 데이터베이스 손상

#### 증상
```
Error: database disk image is malformed
```

#### 해결
```bash
# 1. 서비스 중지
docker compose down

# 2. 백업에서 복원
docker run --rm \
  -v $(pwd)/rclone-config:/config/rclone \
  -v $(pwd)/vaultwarden-data:/data \
  rclone/rclone sync gdrive-crypt:vaultwarden-backups/vaultwarden-data /data -v

# 3. 서비스 시작
docker compose up -d
```

---

## 🔒 보안 권장사항

### 초기 설정
1. ✅ 강력한 Master Password 사용 (20자 이상)
2. ✅ 초기 계정 생성 후 회원가입 즉시 비활성화
3. ✅ Admin 비밀번호는 Master Password와 다르게
4. ✅ HTTPS 반드시 사용 (Let's Encrypt)

### 사용자 관리
1. ✅ 모든 사용자 2FA 활성화 강제
2. ✅ 비밀번호 힌트 비활성화 (기본 설정)
3. ✅ 정기적인 비밀번호 변경
4. ✅ 복구 코드 오프라인 보관

### 백업 보안
1. ✅ Rclone 암호화 비밀번호 안전하게 보관
2. ✅ `.admin-token` 파일 권한 600 유지
3. ✅ 정기적인 백업 복원 테스트 (월 1회)
4. ✅ 백업 로그 주기적 확인

### 서버 보안
1. ✅ 방화벽 설정 (필요한 포트만 개방)
2. ✅ SSH 키 인증 사용
3. ✅ Docker 데몬 보안 설정
4. ✅ 정기적인 시스템 업데이트

### 모니터링
1. ✅ 백업 로그 확인 (일 1회)
2. ✅ Admin 패널에서 활동 로그 확인
3. ✅ 디스크 용량 모니터링
4. ✅ 컨테이너 상태 확인

### 업데이트
```bash
# Vaultwarden 업데이트
docker compose pull
docker compose up -d

# 업데이트 후 확인
docker compose ps
docker compose logs vaultwarden --tail 50
```

## 📄 라이선스 및 참고

### 오픈소스 프로젝트
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden) - GPL-3.0
- [Rclone](https://rclone.org/) - MIT
- [Bitwarden](https://bitwarden.com/) - GPL-3.0

### 참고 문서
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Rclone Documentation](https://rclone.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
