# Nginx Proxy Manager 자동 설치 스크립트

Nginx Proxy Manager를 간편하게 설치하고 설정하는 자동화 스크립트입니다.

## 🚀 Nginx Proxy Manager란?

Nginx Proxy Manager는 웹 기반 리버스 프록시 관리 도구입니다. 복잡한 Nginx 설정 없이 간편하게 도메인과 SSL 인증서를 관리할 수 있습니다.

### 주요 기능
- ✅ **리버스 프록시 관리**: 웹 UI에서 간편하게 프록시 호스트 설정
- ✅ **무료 SSL 인증서**: Let's Encrypt 자동 발급 및 갱신
- ✅ **사용자 관리**: 다중 사용자 및 권한 관리
- ✅ **Access List**: IP 기반 접근 제어
- ✅ **스트림 프록시**: TCP/UDP 프록시 지원

## 📋 요구사항

- **운영체제**: Ubuntu, Debian, CentOS, RHEL 등 Linux 배포판
- **Docker**: 20.10 이상
- **Docker Compose**: V2 권장
- **포트**: 
  - `80` (HTTP)
  - `443` (HTTPS)
  - `7081` (관리 페이지 기본값, 사용자 지정 가능)
- **권한**: root (sudo) 권한 필요

## 📥 설치 방법

### ⚡ 빠른 설치 (원라인 명령어)

```bash
# curl 사용
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/npm/install-npm.sh | sudo bash
```

```bash
# wget 사용
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/npm/install-npm.sh | sudo bash
```

### 📝 단계별 설치

```bash
# 1. 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/npm/install-npm.sh

# 2. 실행 권한 부여
chmod +x install-npm.sh

# 3. 스크립트 실행
sudo ./install-npm.sh
```

## 🎯 설치 과정

스크립트는 다음과 같은 정보를 입력받습니다:

### 1. 컨테이너 이름
```
컨테이너 이름을 입력하세요 (기본값: npmjc):
> [Enter 또는 원하는 이름 입력]
```
- **기본값**: `npmjc`
- **용도**: Docker 컨테이너 식별자
- **예시**: `npm`, `proxy-manager`, `nginx-pm`

### 2. 네트워크 이름
```
Docker 네트워크 이름을 입력하세요 (기본값: main):
> [Enter 또는 원하는 이름 입력]
```
- **기본값**: `main`
- **용도**: 다른 컨테이너와 통신을 위한 네트워크
- **예시**: `app`, `web`, `proxy-net`

### 3. 관리 페이지 포트
```
관리 페이지 포트를 입력하세요 (기본값: 7081):
> [Enter 또는 원하는 포트 입력]
```
- **기본값**: `7081`
- **범위**: 1-65535
- **용도**: Nginx Proxy Manager 웹 관리 페이지 접속 포트
- **추천 포트**: `7081`, `8081`, `9081`
- **주의**: 이미 사용 중인 포트는 피하세요

#### 포트 충돌 시 처리
만약 입력한 포트가 이미 사용 중이라면:
```
⚠ 포트 7081 가 이미 사용 중입니다.
다른 포트를 사용하시겠습니까? (y/N): y
새로운 포트를 입력하세요:
> 8081
✓ 관리 페이지 포트: 8081
```

### 설정 확인
```
입력한 설정 확인
컨테이너 이름  : npmjc
네트워크 이름  : main
관리 페이지 포트: 7081

이 설정으로 진행하시겠습니까? (y/N): y
```

## 📁 생성되는 파일 구조

설치 후 다음과 같은 파일과 디렉토리가 생성됩니다:

```
현재 디렉토리/
├── docker-compose.yml          # Docker Compose 설정 파일
├── .npm-config                 # 설치 설정 정보 백업
│                               # (컨테이너명, 네트워크명, 포트 정보)
├── data/                       # Nginx Proxy Manager 데이터
│   ├── nginx/                  # Nginx 설정 파일
│   ├── logs/                   # 로그 파일
│   └── database.sqlite         # SQLite 데이터베이스
└── letsencrypt/                # Let's Encrypt SSL 인증서
    ├── accounts/               # Let's Encrypt 계정
    ├── archive/                # 인증서 아카이브
    └── live/                   # 현재 사용 중인 인증서
```

### .npm-config 파일 내용
```bash
# Nginx Proxy Manager 설정 정보
# 생성일: 2025-12-07 15:30:00

CONTAINER_NAME=npmjc
NETWORK_NAME=main
ADMIN_PORT=7081

# 관리 페이지 접속: http://YOUR_SERVER_IP:7081
```

## 🌐 최초 접속 및 설정

### 1. 관리 페이지 접속

설치 완료 후 브라우저에서 접속:

```
http://YOUR_SERVER_IP:YOUR_ADMIN_PORT
```

예시:
- 기본 포트 사용: `http://192.168.1.100:7081`
- 사용자 지정 포트: `http://192.168.1.100:8081`

> 💡 **팁**: 설치 시 입력한 관리 페이지 포트를 사용하세요. 기본값은 7081입니다.

### 2. 기본 로그인 정보

```
이메일: admin@example.com
비밀번호: changeme
```

### 3. 🔴 필수 보안 설정

최초 로그인 후 **반드시** 다음 작업을 수행하세요:

1. **비밀번호 변경**
   - 우측 상단 프로필 아이콘 클릭
   - "Edit Details" 선택
   - 새 비밀번호 입력

2. **이메일 주소 변경**
   - 실제 사용하는 이메일로 변경
   - Let's Encrypt 인증서 발급 시 필요

3. **관리자 계정 이름 변경** (선택사항)
   - 보안 강화를 위해 권장

## 🛠️ 사용 방법

### Proxy Host 추가

1. **왼쪽 메뉴에서 "Hosts" → "Proxy Hosts" 선택**

2. **"Add Proxy Host" 클릭**

3. **Details 탭 설정**
   ```
   Domain Names: your-domain.com
   Scheme: http
   Forward Hostname/IP: container_name (예: vaultwarden)
   Forward Port: 80 (또는 서비스 포트)
   Cache Assets: ✓
   Block Common Exploits: ✓
   Websockets Support: ✓ (필요시)
   ```

4. **SSL 탭 설정**
   ```
   SSL Certificate: Request a new SSL Certificate
   Force SSL: ✓
   HTTP/2 Support: ✓
   HSTS Enabled: ✓
   Email Address: your-email@example.com
   ✓ I Agree to the Let's Encrypt Terms of Service
   ```

5. **"Save" 클릭**


## 💡 유용한 명령어

### Docker Compose 기본 명령어

```bash
# 서비스 시작
docker compose up -d

# 서비스 중지
docker compose down

# 서비스 재시작
docker compose restart

# 로그 확인 (실시간)
docker compose logs -f

# 컨테이너 상태 확인
docker compose ps

# 특정 컨테이너 로그만 확인
docker compose logs -f npmjc
```

### 백업 및 복원

```bash
# 데이터 백업
tar -czf npm-backup-$(date +%Y%m%d).tar.gz data/ letsencrypt/

# 데이터 복원
tar -xzf npm-backup-YYYYMMDD.tar.gz
```

### 컨테이너 내부 접속

```bash
# Bash 쉘 접속
docker exec -it npmjc bash

# Nginx 설정 확인
docker exec npmjc cat /data/nginx/custom/default.conf
```

## 🔧 트러블슈팅

### 문제 1: 포트 충돌 오류

**증상**: `Error: Port 80 is already in use`

**원인**: 다른 웹 서버가 80 포트를 사용 중

**해결**:
```bash
# 포트 사용 확인
sudo netstat -tlnp | grep :80

# Apache2가 실행 중이라면
sudo systemctl stop apache2
sudo systemctl disable apache2

# Nginx가 실행 중이라면
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### 문제 2: SSL 인증서 발급 실패

**원인**:
- 도메인의 DNS가 서버 IP를 가리키지 않음
- 80, 443 포트가 방화벽에 막혀있음
- 이메일 주소가 유효하지 않음

**해결**:
1. DNS 설정 확인
   ```bash
   nslookup your-domain.com
   ```

2. 방화벽 확인
   ```bash
   # UFW 사용 시
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   
   # Firewalld 사용 시
   sudo firewall-cmd --permanent --add-port=80/tcp
   sudo firewall-cmd --permanent --add-port=443/tcp
   sudo firewall-cmd --reload
   ```

### 문제 3: 관리 페이지 접속 불가

**증상**: `http://SERVER_IP:YOUR_PORT` 접속 안됨

**원인**: 관리 페이지 포트가 방화벽에 막혀있음

**해결**:
```bash
# 방화벽에서 포트 열기 (기본 포트 7081 예시)
sudo ufw allow 7081/tcp

# 사용자 지정 포트 사용 시 (예: 8081)
sudo ufw allow 8081/tcp

# 또는 보안을 위해 특정 IP만 허용
sudo ufw allow from YOUR_IP to any port 7081

# 포트 열림 확인
sudo ufw status
```

**포트 확인**:
```bash
# 컨테이너 포트 매핑 확인
docker ps | grep npmjc

# 예시 출력:
# 0.0.0.0:7081->81/tcp  # 7081 포트로 접속 가능
# 0.0.0.0:8081->81/tcp  # 8081 포트로 접속 가능
```

### 문제 4: 컨테이너 간 통신 실패

**증상**: 프록시 설정했지만 서비스 연결 안됨

**원인**: 네트워크가 다름

**해결**:
```bash
# 네트워크 확인
docker network inspect main

# 다른 컨테이너가 같은 네트워크를 사용하는지 확인
docker inspect container_name | grep NetworkMode
```

## 📊 성능 최적화

### 1. 캐시 설정 강화

Proxy Host 설정에서:
- Cache Assets: ✓
- Cache Duration: 24시간

### 2. 로그 로테이션

```bash
# 로그 정리 (1주일 이상 된 로그 삭제)
find ./data/logs -name "*.log" -mtime +7 -delete
```

### 3. 데이터베이스 최적화

```bash
# SQLite 데이터베이스 최적화
docker exec npmjc sqlite3 /data/database.sqlite "VACUUM;"
```

## 🔒 보안 권장사항

### 1. 관리 페이지 접근 제한

방화벽에서 관리 페이지 포트를 특정 IP만 접근하도록 설정:

```bash
# UFW 예시 (기본 포트 7081)
sudo ufw deny 7081/tcp
sudo ufw allow from YOUR_IP to any port 7081

# 사용자 지정 포트 사용 시 (예: 8081)
sudo ufw deny 8081/tcp
sudo ufw allow from YOUR_IP to any port 8081

# 여러 IP 허용
sudo ufw allow from 192.168.1.0/24 to any port 7081
```

**권장 설정**:
- 관리자 IP만 접근 허용
- VPN 사용 시 VPN 네트워크에서만 접근 허용
- 공용 네트워크에서는 관리 페이지 접근 차단

### 2. Access List 사용

Nginx Proxy Manager에서:
- Access Lists 메뉴
- IP 기반 접근 제어 설정
- 중요한 서비스는 화이트리스트 방식 사용

### 3. 정기적인 업데이트

```bash
# 이미지 업데이트
docker compose pull
docker compose up -d
```

## 📚 참고 자료

- [공식 문서](https://nginxproxymanager.com/guide/)
- [GitHub 저장소](https://github.com/NginxProxyManager/nginx-proxy-manager)
- [Docker Hub](https://hub.docker.com/r/jc21/nginx-proxy-manager)
- [커뮤니티 포럼](https://reddit.com/r/nginxproxymanager)
