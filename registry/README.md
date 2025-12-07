# Docker Registry 자동 설치 스크립트

Docker를 이용하여 Private Docker Registry를 자동으로 설치하고 설정하는 Bash 스크립트입니다.

## 📋 목차

- [Docker Registry란?](#docker-registry란)
- [주요 기능](#주요-기능)
- [시스템 요구사항](#시스템-요구사항)
- [설치 방법](#설치-방법)
- [사용 방법](#사용-방법)
- [생성되는 파일](#생성되는-파일)
- [Registry 사용법](#registry-사용법)
- [Insecure Registry 설정](#insecure-registry-설정)
- [HTTPS 설정](#https-설정)
- [유용한 명령어](#유용한-명령어)
- [백업 및 복원](#백업-및-복원)
- [문제 해결](#문제-해결)
- [라이선스](#라이선스)

## 📦 Docker Registry란?

Docker Registry는 Docker 이미지를 저장하고 배포하기 위한 저장소입니다.

### Docker Hub vs Private Registry

| 특징 | Docker Hub | Private Registry |
|------|-----------|------------------|
| **호스팅** | Docker 공식 클라우드 | 자체 서버 |
| **비용** | 무료(제한)/유료 | 인프라 비용만 |
| **프라이버시** | 제한적 | 완전한 제어 |
| **속도** | 인터넷 속도 의존 | 로컬 네트워크 속도 |
| **용량** | 제한적 | 무제한 (디스크 용량만큼) |
| **접근 제어** | 제한적 | 완전한 제어 |

### 사용 사례

- **내부 개발**: 사내 Docker 이미지 관리
- **CI/CD**: 빌드된 이미지 저장 및 배포
- **에어갭 환경**: 인터넷이 차단된 환경
- **속도 개선**: 로컬 네트워크에서 빠른 이미지 전송
- **보안**: 민감한 이미지의 안전한 저장

## 🚀 주요 기능

- ✅ **자동화된 설치**: 모든 설정을 자동으로 구성
- ✅ **Basic Auth 인증**: htpasswd 기반 인증 지원
- ✅ **버전 선택**: Docker Registry 버전 자유 선택
- ✅ **스토리지 삭제**: 이미지 삭제 기능 활성화 옵션
- ✅ **데이터 영속성**: Docker 볼륨을 통한 데이터 보존
- ✅ **즉시 사용 가능**: 설치 후 바로 사용 가능

## 📦 시스템 요구사항

### 최소 요구사항
- **운영체제**: Linux (Ubuntu, Debian, CentOS 등)
- **Docker**: 20.10 이상
- **Docker Compose**: 1.29 이상
- **메모리**: 최소 512MB (권장 1GB 이상)
- **디스크**: 최소 10GB 여유 공간 (이미지 크기에 따라)
- **Apache2 Utils**: htpasswd (자동 설치)

### 권장 사양
- **메모리**: 2GB 이상
- **디스크**: 100GB 이상 (많은 이미지 저장 시)
- **CPU**: 2 Core 이상

## 📥 설치 방법

### 방법 1: 원라인 설치 (추천)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/registry/install-registry.sh | sudo bash
```

### 방법 2: 수동 다운로드 후 실행

```bash
# 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/registry/install-registry.sh

# 실행 권한 부여
chmod +x install-registry.sh

# 실행
sudo ./install-registry.sh
```

## 🎯 사용 방법

### 1. 스크립트 실행

```bash
sudo ./install-registry.sh
```

### 2. 대화형 설정

스크립트가 다음 정보를 순차적으로 요청합니다:

#### 컨테이너 설정
- **Registry 컨테이너 이름** (기본값: `registry`)
- **Docker 네트워크 이름** (기본값: `main`)

#### 버전 설정
- **Docker Registry 버전** (기본값: `2`)
  - 예시: `2`, `2.8`, `latest`

#### 포트 설정
- **Registry 포트** (기본값: `5000`)

#### 인증 설정
- **Basic Auth 사용 여부** (기본값: Y)
  - 사용자 이름 (기본값: `admin`)
  - 비밀번호 입력 및 확인

#### 기능 설정
- **스토리지 삭제 기능 활성화** (기본값: Y)
  - 이미지 삭제 허용 여부

### 3. 설정 확인 및 설치

입력한 설정을 확인하고 `y`를 입력하여 설치를 진행합니다.

## 📁 생성되는 파일

설치 후 다음 파일과 디렉토리가 생성됩니다:

```
./
├── docker-compose.yml        # Docker Compose 설정 파일
├── .registry-config          # 설정 정보 (비밀번호 제외)
├── registry-data/            # Registry 데이터 저장 디렉토리
│   └── (Docker 이미지 레이어들)
├── registry-auth/            # 인증 파일 디렉토리
│   └── htpasswd              # Basic Auth 인증 파일
└── registry-certs/           # SSL 인증서 디렉토리 (선택사항)
    ├── domain.crt
    └── domain.key
```

### 파일 상세 설명

#### `docker-compose.yml`
- Docker Registry 컨테이너 정의
- 네트워크 및 볼륨 설정
- 환경 변수 구성

#### `.registry-config`
- 컨테이너 이름, 네트워크 정보
- 버전 정보
- 포트 설정
- **비밀번호는 포함되지 않음** (보안)

#### `registry-data/`
- Docker 이미지 레이어 저장
- Docker 볼륨으로 마운트
- 컨테이너 삭제 시에도 데이터 보존

#### `registry-auth/htpasswd`
- Basic Auth 인증 정보
- bcrypt로 암호화된 비밀번호
- 파일 권한: 600 (소유자만 읽기/쓰기)

#### `registry-certs/`
- SSL/TLS 인증서 저장 (HTTPS 사용 시)
- 선택사항

## 🐳 Registry 사용법

### 1. Docker 로그인 (인증 활성화된 경우)

```bash
docker login YOUR_SERVER_IP:5000
```

**예시:**
```bash
docker login 192.168.1.100:5000
# Username: admin
# Password: ********
```

### 2. 이미지 태그

```bash
docker tag LOCAL_IMAGE:TAG REGISTRY_URL/IMAGE:TAG
```

**예시:**
```bash
docker tag myapp:latest 192.168.1.100:5000/myapp:latest
```

### 3. 이미지 Push

```bash
docker push REGISTRY_URL/IMAGE:TAG
```

**예시:**
```bash
docker push 192.168.1.100:5000/myapp:latest
```

### 4. 이미지 Pull

```bash
docker pull REGISTRY_URL/IMAGE:TAG
```

**예시:**
```bash
docker pull 192.168.1.100:5000/myapp:latest
```

### 5. Registry 카탈로그 확인

**인증 있는 경우:**
```bash
curl -u admin:PASSWORD http://192.168.1.100:5000/v2/_catalog
```

**인증 없는 경우:**
```bash
curl http://192.168.1.100:5000/v2/_catalog
```

**응답 예시:**
```json
{
  "repositories": [
    "myapp",
    "nginx",
    "postgres"
  ]
}
```

### 6. 특정 이미지의 태그 목록 확인

**인증 있는 경우:**
```bash
curl -u admin:PASSWORD http://192.168.1.100:5000/v2/myapp/tags/list
```

**인증 없는 경우:**
```bash
curl http://192.168.1.100:5000/v2/myapp/tags/list
```

**응답 예시:**
```json
{
  "name": "myapp",
  "tags": [
    "latest",
    "v1.0",
    "v1.1"
  ]
}
```

## ⚙️ Insecure Registry 설정

HTTP를 사용하는 경우 (HTTPS 미설정), Docker 클라이언트에서 다음 설정이 필요합니다.

### Linux

**1. daemon.json 파일 생성/수정:**

```bash
sudo nano /etc/docker/daemon.json
```

**2. 다음 내용 추가:**

```json
{
  "insecure-registries": ["192.168.1.100:5000"]
}
```

**3. Docker 재시작:**

```bash
sudo systemctl restart docker
```

### macOS (Docker Desktop)

1. Docker Desktop 아이콘 클릭
2. **Preferences** → **Docker Engine**
3. JSON 설정에 추가:
   ```json
   {
     "insecure-registries": ["192.168.1.100:5000"]
   }
   ```
4. **Apply & Restart**

### Windows (Docker Desktop)

1. Docker Desktop 아이콘 클릭
2. **Settings** → **Docker Engine**
3. JSON 설정에 추가:
   ```json
   {
     "insecure-registries": ["192.168.1.100:5000"]
   }
   ```
4. **Apply & Restart**

⚠️ **중요**: 프로덕션 환경에서는 반드시 HTTPS를 사용하세요!

## 🔒 HTTPS 설정

프로덕션 환경에서는 반드시 HTTPS를 설정해야 합니다.

### 방법 1: 자체 서명 인증서 (테스트용)

#### 1. 인증서 생성

```bash
# 인증서 생성
openssl req -newkey rsa:4096 -nodes -sha256 -keyout registry-certs/domain.key -x509 -days 365 -out registry-certs/domain.crt

# Common Name에 서버 IP 또는 도메인 입력
# 예: 192.168.1.100 또는 registry.example.com
```

#### 2. docker-compose.yml 수정

```yaml
services:
  registry:
    environment:
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
      REGISTRY_HTTP_TLS_KEY: /certs/domain.key
    volumes:
      - ./registry-certs:/certs
```

#### 3. 클라이언트에 인증서 추가

**Linux:**
```bash
sudo mkdir -p /etc/docker/certs.d/192.168.1.100:5000
sudo cp registry-certs/domain.crt /etc/docker/certs.d/192.168.1.100:5000/ca.crt
sudo systemctl restart docker
```

### 방법 2: Let's Encrypt (프로덕션 권장)

#### Caddy를 이용한 자동 HTTPS

**Caddyfile:**
```
registry.example.com {
    reverse_proxy registry:5000
}
```

**docker-compose.yml에 Caddy 추가:**
```yaml
services:
  caddy:
    image: caddy:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy-data:/data
      - caddy-config:/config
    networks:
      - main
    depends_on:
      - registry

volumes:
  caddy-data:
  caddy-config:
```

### 방법 3: Nginx 리버스 프록시

**nginx.conf:**
```nginx
server {
    listen 443 ssl http2;
    server_name registry.example.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    client_max_body_size 0;
    chunked_transfer_encoding on;

    location / {
        proxy_pass http://registry:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 900;
    }
}
```

## 🛠️ 유용한 명령어

### 컨테이너 관리

```bash
# 로그 확인
docker compose logs -f

# Registry 로그만 확인
docker compose logs -f registry

# 컨테이너 상태 확인
docker compose ps

# 서비스 재시작
docker compose restart

# 서비스 중지
docker compose stop

# 서비스 시작
docker compose start

# 서비스 완전 삭제 (데이터 보존)
docker compose down

# 서비스 완전 삭제 (볼륨도 삭제, 데이터 삭제됨)
docker compose down -v
```

### Registry API 사용

```bash
# Registry 버전 확인
curl http://192.168.1.100:5000/v2/

# 저장된 이미지 목록
curl -u admin:PASSWORD http://192.168.1.100:5000/v2/_catalog

# 특정 이미지의 태그 목록
curl -u admin:PASSWORD http://192.168.1.100:5000/v2/IMAGE_NAME/tags/list

# 이미지 매니페스트 확인
curl -u admin:PASSWORD http://192.168.1.100:5000/v2/IMAGE_NAME/manifests/TAG

# 이미지 삭제 (스토리지 삭제 활성화된 경우)
# 1. 매니페스트 digest 확인
curl -I -u admin:PASSWORD \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  http://192.168.1.100:5000/v2/IMAGE_NAME/manifests/TAG

# 2. digest를 이용한 삭제
curl -X DELETE -u admin:PASSWORD \
  http://192.168.1.100:5000/v2/IMAGE_NAME/manifests/DIGEST
```

### 이미지 관리

```bash
# 로컬 이미지 확인
docker images

# Registry에서 이미지 Pull
docker pull 192.168.1.100:5000/myapp:latest

# 이미지 실행
docker run -d 192.168.1.100:5000/myapp:latest

# 이미지 삭제 (로컬)
docker rmi 192.168.1.100:5000/myapp:latest
```

### 디스크 정리

```bash
# Registry에서 사용하지 않는 레이어 정리
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml

# 더 공격적인 정리 (삭제 표시된 레이어 제거)
docker exec registry bin/registry garbage-collect -m /etc/docker/registry/config.yml

# 디스크 사용량 확인
du -sh registry-data/
```

## 💾 백업 및 복원

### Registry 데이터 백업

#### 방법 1: 데이터 디렉토리 백업

```bash
# 서비스 중지
docker compose stop

# 데이터 백업
tar -czf registry_backup_$(date +%Y%m%d).tar.gz registry-data/ registry-auth/

# 서비스 시작
docker compose start
```

#### 방법 2: 온라인 백업 (서비스 중단 없음)

```bash
# rsync를 이용한 백업
rsync -av registry-data/ /backup/registry-data-$(date +%Y%m%d)/
rsync -av registry-auth/ /backup/registry-auth-$(date +%Y%m%d)/
```

### 백업 복원

```bash
# 서비스 중지 및 삭제
docker compose down

# 기존 데이터 제거
rm -rf registry-data/ registry-auth/

# 백업 복원
tar -xzf registry_backup_20241207.tar.gz

# 서비스 시작
docker compose up -d
```

### 자동 백업 스크립트

```bash
#!/bin/bash
# registry-backup.sh

BACKUP_DIR="/backup/registry"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Registry 데이터 백업
tar -czf $BACKUP_DIR/registry_${DATE}.tar.gz registry-data/ registry-auth/

# 30일 이상 된 백업 파일 삭제
find $BACKUP_DIR -name "registry_*.tar.gz" -mtime +30 -delete

echo "Backup completed: registry_${DATE}.tar.gz"
```

**Cron 설정 (매일 새벽 3시 백업):**
```bash
crontab -e

# 다음 줄 추가
0 3 * * * /path/to/registry-backup.sh >> /var/log/registry-backup.log 2>&1
```

## 🔍 문제 해결

### Registry가 시작되지 않는 경우

1. **로그 확인:**
   ```bash
   docker compose logs registry
   ```

2. **포트 충돌 확인:**
   ```bash
   sudo netstat -tulpn | grep 5000
   ```

3. **권한 문제:**
   ```bash
   sudo chown -R 1000:1000 registry-data/
   ```

### 이미지 Push 실패

**오류:** `http: server gave HTTP response to HTTPS client`

**원인:** Insecure Registry 설정이 안 됨

**해결방법:**
1. `/etc/docker/daemon.json` 설정 확인
2. Docker 재시작
   ```bash
   sudo systemctl restart docker
   ```

### 인증 실패

**오류:** `unauthorized: authentication required`

**해결방법:**
1. 로그인 확인:
   ```bash
   docker login 192.168.1.100:5000
   ```

2. htpasswd 파일 확인:
   ```bash
   cat registry-auth/htpasswd
   ```

3. 비밀번호 재설정:
   ```bash
   htpasswd -B registry-auth/htpasswd admin
   docker compose restart
   ```

### 디스크 공간 부족

```bash
# 디스크 사용량 확인
df -h
du -sh registry-data/

# Garbage Collection 실행
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml

# Docker 시스템 정리
docker system prune -a
```

### 이미지 삭제가 안 되는 경우

**원인:** 스토리지 삭제 기능이 비활성화됨

**해결방법:**

docker-compose.yml에 추가:
```yaml
environment:
  REGISTRY_STORAGE_DELETE_ENABLED: "true"
```

재시작:
```bash
docker compose restart
```

## ⚙️ 고급 설정

### 스토리지 드라이버 변경

#### S3 스토리지 사용

```yaml
environment:
  REGISTRY_STORAGE: s3
  REGISTRY_STORAGE_S3_ACCESSKEY: YOUR_ACCESS_KEY
  REGISTRY_STORAGE_S3_SECRETKEY: YOUR_SECRET_KEY
  REGISTRY_STORAGE_S3_REGION: ap-northeast-2
  REGISTRY_STORAGE_S3_BUCKET: my-registry-bucket
```

#### Azure Blob Storage 사용

```yaml
environment:
  REGISTRY_STORAGE: azure
  REGISTRY_STORAGE_AZURE_ACCOUNTNAME: YOUR_ACCOUNT
  REGISTRY_STORAGE_AZURE_ACCOUNTKEY: YOUR_KEY
  REGISTRY_STORAGE_AZURE_CONTAINER: registry
```

### 이미지 캐시 설정

```yaml
environment:
  REGISTRY_PROXY_REMOTEURL: https://registry-1.docker.io
```

### 로깅 설정

```yaml
environment:
  REGISTRY_LOG_LEVEL: info
  REGISTRY_LOG_FORMATTER: json
```

### 웹훅 설정

```yaml
environment:
  REGISTRY_NOTIFICATIONS_ENDPOINTS: |
    - name: webhook
      url: https://example.com/webhook
      timeout: 1s
      threshold: 5
      backoff: 1s
```

## 📊 모니터링

### Prometheus 메트릭

Registry는 `/metrics` 엔드포인트를 제공합니다.

**docker-compose.yml 수정:**
```yaml
environment:
  REGISTRY_HTTP_DEBUG_ADDR: :5001
  REGISTRY_HTTP_DEBUG_PROMETHEUS_ENABLED: "true"
```

**메트릭 확인:**
```bash
curl http://192.168.1.100:5001/metrics
```

### 디스크 사용량 모니터링

```bash
# 전체 디스크 사용량
du -sh registry-data/

# 레포지토리별 크기
du -sh registry-data/docker/registry/v2/repositories/*

# 레이어 크기
du -sh registry-data/docker/registry/v2/blobs/
```

## 🔐 보안 권장사항

1. **반드시 HTTPS 사용** (프로덕션 필수)

2. **Strong Basic Auth**
   ```bash
   htpasswd -B registry-auth/htpasswd username
   ```

3. **방화벽 설정**
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 5000
   sudo ufw enable
   ```

4. **정기적인 백업**

5. **디스크 공간 모니터링**

6. **로그 확인**
   ```bash
   docker compose logs -f registry
   ```

7. **정기적인 업데이트**
   ```bash
   docker compose pull
   docker compose up -d
   ```

8. **TLS 버전 제한**
   ```yaml
   environment:
     REGISTRY_HTTP_TLS_MINIMUMTLS: tls1.2
   ```

## 📚 참고 문서

- [Docker Registry 공식 문서](https://docs.docker.com/registry/)
- [Docker Registry API](https://docs.docker.com/registry/spec/api/)
- [Registry 설정 참조](https://docs.docker.com/registry/configuration/)
- [Docker Registry GitHub](https://github.com/distribution/distribution)
