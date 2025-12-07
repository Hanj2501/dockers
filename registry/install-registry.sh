#!/bin/bash

################################################################################
# Docker Registry 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Docker 네트워크 생성 (없는 경우)
# 4. Basic Auth 인증 설정 (htpasswd)
# 5. docker-compose.yml 파일 자동 생성
# 6. Docker Registry 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/registry/install-registry.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/registry/install-registry.sh
#      chmod +x install-registry.sh
#      sudo ./install-registry.sh
#
################################################################################

set -e  # 에러 발생 시 스크립트 중단

################################################################################
# 색상 정의
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# 출력 함수들
################################################################################
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

################################################################################
# Docker 및 Docker Compose 확인
################################################################################
check_docker() {
    print_header "시스템 요구사항 확인"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되어 있지 않습니다."
        echo ""
        print_info "Docker를 먼저 설치해주세요:"
        echo "  curl -fsSL https://get.docker.com | sudo bash"
        exit 1
    fi
    print_success "Docker 설치 확인 완료: $(docker --version)"
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose가 설치되어 있지 않습니다."
        exit 1
    fi
    print_success "Docker Compose 설치 확인 완료"
    
    # htpasswd 확인 (Apache2 Utils)
    if ! command -v htpasswd &> /dev/null; then
        print_warning "htpasswd가 설치되어 있지 않습니다. 설치를 진행합니다..."
        
        # OS별 설치
        if [ -f /etc/debian_version ]; then
            apt-get update && apt-get install -y apache2-utils
        elif [ -f /etc/redhat-release ]; then
            yum install -y httpd-tools
        else
            print_error "지원하지 않는 OS입니다. htpasswd를 수동으로 설치해주세요."
            exit 1
        fi
        
        print_success "htpasswd 설치 완료"
    else
        print_success "htpasswd 확인 완료"
    fi
}

################################################################################
# 사용자 입력 받기
################################################################################
get_user_input() {
    print_header "Docker Registry 설정 정보 입력"
    
    # Registry 컨테이너 이름
    echo -e "${CYAN}Docker Registry 컨테이너 이름을 입력하세요 (기본값: registry):${NC}"
    read -p "> " REGISTRY_CONTAINER
    REGISTRY_CONTAINER=${REGISTRY_CONTAINER:-registry}
    print_success "Registry 컨테이너 이름: $REGISTRY_CONTAINER"
    
    # 네트워크 이름
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크 이름: $NETWORK_NAME"
    
    # Registry 버전
    echo ""
    echo -e "${CYAN}Docker Registry 버전을 입력하세요 (기본값: 2):${NC}"
    print_info "예: 2, 2.8, latest"
    read -p "> " REGISTRY_VERSION
    REGISTRY_VERSION=${REGISTRY_VERSION:-2}
    print_success "Registry 버전: $REGISTRY_VERSION"
    
    # Registry 포트
    echo ""
    echo -e "${CYAN}Docker Registry 포트를 입력하세요 (기본값: 5000):${NC}"
    read -p "> " REGISTRY_PORT
    REGISTRY_PORT=${REGISTRY_PORT:-5000}
    
    # 포트 유효성 검사
    if ! [[ "$REGISTRY_PORT" =~ ^[0-9]+$ ]] || [ "$REGISTRY_PORT" -lt 1 ] || [ "$REGISTRY_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    
    print_success "Registry 포트: $REGISTRY_PORT"
    
    # 인증 설정 여부
    echo ""
    echo -e "${CYAN}Basic Auth 인증을 사용하시겠습니까? (Y/n):${NC}"
    print_info "보안을 위해 인증 사용을 강력히 권장합니다."
    read -p "> " USE_AUTH
    USE_AUTH=${USE_AUTH:-Y}
    
    if [ "$USE_AUTH" = "y" ] || [ "$USE_AUTH" = "Y" ]; then
        USE_AUTH=true
        
        # 사용자 이름
        echo ""
        echo -e "${CYAN}Registry 사용자 이름을 입력하세요 (기본값: admin):${NC}"
        read -p "> " REGISTRY_USER
        REGISTRY_USER=${REGISTRY_USER:-admin}
        print_success "Registry 사용자: $REGISTRY_USER"
        
        # 비밀번호
        echo ""
        print_info "Registry 비밀번호를 설정합니다."
        echo ""
        
        while true; do
            read -sp "Registry 비밀번호: " REGISTRY_PASSWORD
            echo ""
            
            if [ -z "$REGISTRY_PASSWORD" ]; then
                print_error "비밀번호를 입력해주세요."
                continue
            fi
            
            read -sp "Registry 비밀번호 확인: " REGISTRY_PASSWORD_CONFIRM
            echo ""
            
            if [ "$REGISTRY_PASSWORD" != "$REGISTRY_PASSWORD_CONFIRM" ]; then
                print_error "비밀번호가 일치하지 않습니다."
                continue
            fi
            
            break
        done
        
        print_success "Registry 비밀번호 설정 완료"
    else
        USE_AUTH=false
        print_warning "인증 없이 설치합니다. (프로덕션 환경에서는 권장하지 않음)"
    fi
    
    # 스토리지 제한 설정
    echo ""
    echo -e "${CYAN}스토리지 삭제 기능을 활성화하시겠습니까? (Y/n):${NC}"
    print_info "이미지 삭제를 허용합니다."
    read -p "> " ENABLE_DELETE
    ENABLE_DELETE=${ENABLE_DELETE:-Y}
    
    if [ "$ENABLE_DELETE" = "y" ] || [ "$ENABLE_DELETE" = "Y" ]; then
        ENABLE_DELETE=true
        print_success "스토리지 삭제 기능 활성화"
    else
        ENABLE_DELETE=false
        print_success "스토리지 삭제 기능 비활성화"
    fi
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "Registry 컨테이너 : $REGISTRY_CONTAINER"
    echo "네트워크 이름     : $NETWORK_NAME"
    echo "Registry 버전     : $REGISTRY_VERSION"
    echo "Registry 포트     : $REGISTRY_PORT"
    if [ "$USE_AUTH" = true ]; then
        echo "인증 사용         : 예 (사용자: $REGISTRY_USER)"
    else
        echo "인증 사용         : 아니오"
    fi
    echo "스토리지 삭제     : $ENABLE_DELETE"
    echo ""
    
    read -p "이 설정으로 진행하시겠습니까? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_warning "설정을 취소했습니다."
        exit 0
    fi
}

################################################################################
# Docker 네트워크 확인 및 생성
################################################################################
check_and_create_network() {
    print_header "Docker 네트워크 확인"
    
    # 네트워크 존재 확인
    if docker network ls | grep -q "\s${NETWORK_NAME}\s"; then
        print_success "'$NETWORK_NAME' 네트워크가 이미 존재합니다."
    else
        print_warning "'$NETWORK_NAME' 네트워크가 존재하지 않습니다."
        print_info "'$NETWORK_NAME' 네트워크를 생성합니다..."
        
        docker network create --driver=bridge $NETWORK_NAME
        print_success "'$NETWORK_NAME' 네트워크가 생성되었습니다."
    fi
}

################################################################################
# 디렉토리 생성
################################################################################
create_directories() {
    print_header "디렉토리 구조 생성"
    
    # 필요한 디렉토리 생성
    mkdir -p registry-data
    mkdir -p registry-auth
    mkdir -p registry-certs
    
    print_success "디렉토리 생성 완료"
    echo "  - registry-data/   (Registry 데이터 저장)"
    echo "  - registry-auth/   (인증 파일 저장)"
    echo "  - registry-certs/  (SSL 인증서 저장 - 선택사항)"
}

################################################################################
# Basic Auth 설정 파일 생성
################################################################################
generate_auth_file() {
    if [ "$USE_AUTH" = true ]; then
        print_header "Basic Auth 설정"
        
        print_info "htpasswd 파일을 생성합니다..."
        
        # htpasswd 파일 생성
        htpasswd -Bbn $REGISTRY_USER $REGISTRY_PASSWORD > registry-auth/htpasswd
        
        # 파일 권한 설정
        chmod 600 registry-auth/htpasswd
        
        print_success "Basic Auth 설정 완료"
        print_info "사용자: $REGISTRY_USER"
    fi
}

################################################################################
# docker-compose.yml 파일 생성
################################################################################
generate_docker_compose() {
    print_header "docker-compose.yml 파일 생성"
    
    # 기존 파일이 있으면 백업
    if [ -f "docker-compose.yml" ]; then
        print_warning "기존 docker-compose.yml 파일을 백업합니다."
        mv docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 인증 설정
    if [ "$USE_AUTH" = true ]; then
        AUTH_ENV="      # Basic Auth 인증
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd"
        AUTH_VOLUME="      # 인증 파일
      - ./registry-auth:/auth"
    else
        AUTH_ENV="      # 인증 비활성화"
        AUTH_VOLUME=""
    fi
    
    # 삭제 기능 설정
    if [ "$ENABLE_DELETE" = true ]; then
        DELETE_ENV="      # 스토리지 삭제 기능 활성화
      REGISTRY_STORAGE_DELETE_ENABLED: \"true\""
    else
        DELETE_ENV="      # 스토리지 삭제 기능 비활성화"
    fi
    
    # docker-compose.yml 파일 작성
    cat > docker-compose.yml << EOF
################################################################################
# Docker Registry
################################################################################
# Docker 이미지 저장소 (Private Registry)
#
# 접속 정보:
#   - Registry: http://YOUR_SERVER_IP:${REGISTRY_PORT}
#   - 이미지 Push: docker push YOUR_SERVER_IP:${REGISTRY_PORT}/image:tag
#   - 이미지 Pull: docker pull YOUR_SERVER_IP:${REGISTRY_PORT}/image:tag
#
################################################################################

services:
  # Docker Registry
  ${REGISTRY_CONTAINER}:
    image: registry:${REGISTRY_VERSION}
    container_name: ${REGISTRY_CONTAINER}
    restart: unless-stopped
    environment:
${AUTH_ENV}
      
${DELETE_ENV}
      
      # 타임존 설정
      TZ: Asia/Seoul
      
    ports:
      - '${REGISTRY_PORT}:5000'
      
    volumes:
      # Registry 데이터 저장 경로
      - ./registry-data:/var/lib/registry
${AUTH_VOLUME}
      
    networks:
      - ${NETWORK_NAME}

################################################################################
# 네트워크 설정
################################################################################
networks:
  ${NETWORK_NAME}:
    external: true
EOF

    print_success "docker-compose.yml 파일 생성 완료"
}

################################################################################
# 설정 정보 저장
################################################################################
save_configuration() {
    print_header "설정 정보 저장"
    
    # 설정 정보 파일 생성 (비밀번호 제외)
    cat > .registry-config << EOF
# Docker Registry 설정 정보
# 생성일: $(date)

# 컨테이너 정보
REGISTRY_CONTAINER=$REGISTRY_CONTAINER
NETWORK_NAME=$NETWORK_NAME

# 버전 정보
REGISTRY_VERSION=$REGISTRY_VERSION

# 포트 정보
REGISTRY_PORT=$REGISTRY_PORT

# 인증 정보
USE_AUTH=$USE_AUTH
REGISTRY_USER=$REGISTRY_USER

# 기능 설정
ENABLE_DELETE=$ENABLE_DELETE

# Registry 접속: http://YOUR_SERVER_IP:${REGISTRY_PORT}
# 이미지 Push: docker push YOUR_SERVER_IP:${REGISTRY_PORT}/image:tag
# 이미지 Pull: docker pull YOUR_SERVER_IP:${REGISTRY_PORT}/image:tag
EOF
    
    chmod 600 .registry-config
    
    print_success "설정 정보가 .registry-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "Docker Registry를 시작합니다..."
    echo ""
    
    # Docker Compose로 서비스 시작
    if docker compose up -d; then
        print_success "서비스가 성공적으로 시작되었습니다!"
    else
        print_error "서비스 시작에 실패했습니다."
        print_info "로그를 확인하세요: docker compose logs"
        exit 1
    fi
    
    echo ""
    print_info "Registry가 초기화되는 중입니다... (10초 대기)"
    sleep 10
    
    # 컨테이너 상태 확인
    if docker ps | grep -q $REGISTRY_CONTAINER; then
        print_success "Registry 컨테이너가 정상적으로 실행 중입니다."
    else
        print_warning "컨테이너 상태를 확인할 수 없습니다."
        print_info "다음 명령어로 확인하세요: docker compose ps"
    fi
}

################################################################################
# 서버 IP 주소 가져오기
################################################################################
get_server_ip() {
    # 공인 IP 주소 가져오기 (여러 방법 시도)
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
}

################################################################################
# Docker 로그인 가이드 생성
################################################################################
generate_login_guide() {
    print_header "Docker 로그인 설정"
    
    get_server_ip
    
    if [ "$USE_AUTH" = true ]; then
        echo "인증이 활성화되어 있습니다. 다음 명령어로 로그인하세요:"
        echo ""
        echo -e "${CYAN}docker login ${SERVER_IP}:${REGISTRY_PORT}${NC}"
        echo ""
        echo "사용자 이름: $REGISTRY_USER"
        echo "비밀번호: (설정한 비밀번호)"
    else
        echo "인증이 비활성화되어 있습니다."
        echo "로그인 없이 바로 사용할 수 있습니다."
    fi
}

################################################################################
# Insecure Registry 설정 가이드
################################################################################
show_insecure_registry_guide() {
    print_header "Insecure Registry 설정 (HTTP 사용 시)"
    
    get_server_ip
    
    echo "HTTP를 사용하는 경우 Docker 데몬 설정이 필요합니다:"
    echo ""
    echo "1. /etc/docker/daemon.json 파일 편집:"
    echo ""
    echo -e "${CYAN}sudo nano /etc/docker/daemon.json${NC}"
    echo ""
    echo "2. 다음 내용 추가:"
    echo ""
    echo "{"
    echo "  \"insecure-registries\": [\"${SERVER_IP}:${REGISTRY_PORT}\"]"
    echo "}"
    echo ""
    echo "3. Docker 재시작:"
    echo ""
    echo -e "${CYAN}sudo systemctl restart docker${NC}"
    echo ""
    print_warning "HTTPS를 사용하면 이 설정이 필요 없습니다."
}

################################################################################
# 최종 요약 및 안내
################################################################################
final_summary() {
    print_header "설치 완료!"
    
    get_server_ip
    
    echo ""
    print_success "Docker Registry 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ docker-compose.yml    (Docker Compose 설정)"
    echo "  ✓ .registry-config      (설정 정보)"
    echo "  ✓ registry-data/        (Registry 데이터 저장소)"
    if [ "$USE_AUTH" = true ]; then
        echo "  ✓ registry-auth/        (인증 파일)"
    fi
    echo "  ✓ registry-certs/       (SSL 인증서 저장소 - 선택사항)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Registry 컨테이너 : $REGISTRY_CONTAINER"
    echo "  네트워크           : $NETWORK_NAME"
    echo "  Registry 버전     : $REGISTRY_VERSION"
    echo "  Registry 포트     : $REGISTRY_PORT"
    if [ "$USE_AUTH" = true ]; then
        echo "  인증 사용         : 예 (사용자: $REGISTRY_USER)"
    else
        echo "  인증 사용         : 아니오"
    fi
    echo "  스토리지 삭제     : $ENABLE_DELETE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Registry 접속 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Registry URL: http://${SERVER_IP}:${REGISTRY_PORT}"
    echo ""
    
    if [ "$USE_AUTH" = true ]; then
        echo "  📌 로그인:"
        echo "  docker login ${SERVER_IP}:${REGISTRY_PORT}"
        echo "  사용자 이름: $REGISTRY_USER"
        echo "  비밀번호: (설정한 비밀번호)"
        echo ""
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 사용 방법"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$USE_AUTH" = true ]; then
        echo "  # 1. Docker 로그인"
        echo "  docker login ${SERVER_IP}:${REGISTRY_PORT}"
        echo ""
    fi
    
    echo "  # 이미지 태그"
    echo "  docker tag myimage:latest ${SERVER_IP}:${REGISTRY_PORT}/myimage:latest"
    echo ""
    echo "  # 이미지 Push"
    echo "  docker push ${SERVER_IP}:${REGISTRY_PORT}/myimage:latest"
    echo ""
    echo "  # 이미지 Pull"
    echo "  docker pull ${SERVER_IP}:${REGISTRY_PORT}/myimage:latest"
    echo ""
    echo "  # Registry 카탈로그 확인"
    if [ "$USE_AUTH" = true ]; then
        echo "  curl -u ${REGISTRY_USER}:PASSWORD http://${SERVER_IP}:${REGISTRY_PORT}/v2/_catalog"
    else
        echo "  curl http://${SERVER_IP}:${REGISTRY_PORT}/v2/_catalog"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️  Insecure Registry 설정 (HTTP 사용 시 필수)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  클라이언트 머신에서 다음 설정이 필요합니다:"
    echo ""
    echo "  1. /etc/docker/daemon.json 파일 생성/수정:"
    echo "  {"
    echo "    \"insecure-registries\": [\"${SERVER_IP}:${REGISTRY_PORT}\"]"
    echo "  }"
    echo ""
    echo "  2. Docker 재시작:"
    echo "  sudo systemctl restart docker"
    echo ""
    print_warning "프로덕션 환경에서는 HTTPS 사용을 강력히 권장합니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • 저장된 이미지 목록:"
    if [ "$USE_AUTH" = true ]; then
        echo "    curl -u ${REGISTRY_USER}:PASSWORD http://${SERVER_IP}:${REGISTRY_PORT}/v2/_catalog"
    else
        echo "    curl http://${SERVER_IP}:${REGISTRY_PORT}/v2/_catalog"
    fi
    echo "  • 이미지 태그 목록:"
    if [ "$USE_AUTH" = true ]; then
        echo "    curl -u ${REGISTRY_USER}:PASSWORD http://${SERVER_IP}:${REGISTRY_PORT}/v2/IMAGE_NAME/tags/list"
    else
        echo "    curl http://${SERVER_IP}:${REGISTRY_PORT}/v2/IMAGE_NAME/tags/list"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 다음 보안 작업을 수행하세요:"
    echo "    1. HTTPS 설정 (프로덕션 필수)"
    echo "    2. 방화벽 설정 (신뢰할 수 있는 IP만 접근 허용)"
    if [ "$USE_AUTH" = false ]; then
        echo "    3. Basic Auth 인증 활성화 (현재 비활성화됨)"
    fi
    echo "    4. 정기적인 백업"
    echo "    5. 디스크 공간 모니터링"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Docker Registry 문서: https://docs.docker.com/registry/"
    echo "  • Docker Registry API: https://docs.docker.com/registry/spec/api/"
    echo ""
    
    print_success "설치 스크립트를 완료했습니다!"
}

################################################################################
# 메인 함수
################################################################################
main() {
    clear
    
    # 헤더 출력
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║         Docker Registry 자동 설치 스크립트                     ║"
    echo "║         Private Docker Image Repository                       ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker                # 1. Docker 및 htpasswd 확인
    get_user_input              # 2. 사용자 입력
    check_and_create_network    # 3. 네트워크 확인 및 생성
    create_directories          # 4. 디렉토리 생성
    generate_auth_file          # 5. Basic Auth 설정 (선택)
    generate_docker_compose     # 6. docker-compose.yml 생성
    save_configuration          # 7. 설정 정보 저장
    start_service               # 8. 서비스 시작
    final_summary               # 9. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
