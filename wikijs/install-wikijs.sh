#!/bin/bash

################################################################################
# Wiki.js + PostgreSQL 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Docker 네트워크 생성 (없는 경우)
# 4. docker-compose.yml 파일 자동 생성
# 5. Wiki.js + PostgreSQL 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/wikijs/install-wikijs.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/wikijs/install-wikijs.sh
#      chmod +x install-wikijs.sh
#      sudo ./install-wikijs.sh
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
}

################################################################################
# 사용자 입력 받기
################################################################################
get_user_input() {
    print_header "Wiki.js + PostgreSQL 설정 정보 입력"
    
    # Wiki.js 컨테이너 이름
    echo -e "${CYAN}Wiki.js 컨테이너 이름을 입력하세요 (기본값: wikijs):${NC}"
    read -p "> " WIKIJS_CONTAINER
    WIKIJS_CONTAINER=${WIKIJS_CONTAINER:-wikijs}
    print_success "Wiki.js 컨테이너 이름: $WIKIJS_CONTAINER"
    
    # PostgreSQL 컨테이너 이름
    echo ""
    echo -e "${CYAN}PostgreSQL 컨테이너 이름을 입력하세요 (기본값: postgres):${NC}"
    read -p "> " POSTGRES_CONTAINER
    POSTGRES_CONTAINER=${POSTGRES_CONTAINER:-postgres}
    print_success "PostgreSQL 컨테이너 이름: $POSTGRES_CONTAINER"
    
    # 네트워크 이름
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크 이름: $NETWORK_NAME"
    
    # Wiki.js 버전
    echo ""
    echo -e "${CYAN}Wiki.js 버전을 입력하세요 (기본값: latest):${NC}"
    print_info "예: 2, 2.5, latest"
    read -p "> " WIKIJS_VERSION
    WIKIJS_VERSION=${WIKIJS_VERSION:-latest}
    print_success "Wiki.js 버전: $WIKIJS_VERSION"
    
    # PostgreSQL 버전
    echo ""
    echo -e "${CYAN}PostgreSQL 버전을 입력하세요 (기본값: 15-alpine):${NC}"
    print_info "예: 15-alpine, 14-alpine, 13-alpine, latest"
    read -p "> " POSTGRES_VERSION
    POSTGRES_VERSION=${POSTGRES_VERSION:-15-alpine}
    print_success "PostgreSQL 버전: $POSTGRES_VERSION"
    
    # PostgreSQL 데이터베이스 이름
    echo ""
    echo -e "${CYAN}PostgreSQL 데이터베이스 이름을 입력하세요 (기본값: wiki):${NC}"
    read -p "> " POSTGRES_DB
    POSTGRES_DB=${POSTGRES_DB:-wiki}
    print_success "데이터베이스: $POSTGRES_DB"
    
    # PostgreSQL 사용자 이름
    echo ""
    echo -e "${CYAN}PostgreSQL 사용자 이름을 입력하세요 (기본값: wikijs):${NC}"
    read -p "> " POSTGRES_USER
    POSTGRES_USER=${POSTGRES_USER:-wikijs}
    print_success "PostgreSQL 사용자: $POSTGRES_USER"
    
    # PostgreSQL 비밀번호
    echo ""
    print_info "PostgreSQL 비밀번호를 설정합니다."
    echo ""
    
    while true; do
        read -sp "PostgreSQL 비밀번호: " POSTGRES_PASSWORD
        echo ""
        
        if [ -z "$POSTGRES_PASSWORD" ]; then
            print_error "비밀번호를 입력해주세요."
            continue
        fi
        
        read -sp "PostgreSQL 비밀번호 확인: " POSTGRES_PASSWORD_CONFIRM
        echo ""
        
        if [ "$POSTGRES_PASSWORD" != "$POSTGRES_PASSWORD_CONFIRM" ]; then
            print_error "비밀번호가 일치하지 않습니다."
            continue
        fi
        
        break
    done
    
    print_success "PostgreSQL 비밀번호 설정 완료"
    
    # Wiki.js 포트
    echo ""
    echo -e "${CYAN}Wiki.js 웹 포트를 입력하세요 (기본값: 3000):${NC}"
    read -p "> " WIKIJS_PORT
    WIKIJS_PORT=${WIKIJS_PORT:-3000}
    
    # 포트 유효성 검사
    if ! [[ "$WIKIJS_PORT" =~ ^[0-9]+$ ]] || [ "$WIKIJS_PORT" -lt 1 ] || [ "$WIKIJS_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    
    print_success "Wiki.js 포트: $WIKIJS_PORT"
    
    # PostgreSQL 포트 (선택사항)
    echo ""
    echo -e "${CYAN}PostgreSQL 포트를 외부에 노출하시겠습니까? (y/N):${NC}"
    print_info "대부분의 경우 내부 접속만으로 충분합니다."
    read -p "> " EXPOSE_POSTGRES
    
    if [ "$EXPOSE_POSTGRES" = "y" ] || [ "$EXPOSE_POSTGRES" = "Y" ]; then
        echo -e "${CYAN}PostgreSQL 포트를 입력하세요 (기본값: 5432):${NC}"
        read -p "> " POSTGRES_PORT
        POSTGRES_PORT=${POSTGRES_PORT:-5432}
        print_success "PostgreSQL 포트: $POSTGRES_PORT (외부 노출)"
    else
        POSTGRES_PORT=""
        print_success "PostgreSQL은 내부 네트워크에서만 접속 가능합니다."
    fi
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "Wiki.js 컨테이너     : $WIKIJS_CONTAINER"
    echo "PostgreSQL 컨테이너 : $POSTGRES_CONTAINER"
    echo "네트워크 이름        : $NETWORK_NAME"
    echo "Wiki.js 버전         : $WIKIJS_VERSION"
    echo "PostgreSQL 버전      : $POSTGRES_VERSION"
    echo "Wiki.js 포트         : $WIKIJS_PORT"
    if [ -n "$POSTGRES_PORT" ]; then
        echo "PostgreSQL 포트      : $POSTGRES_PORT (외부 노출)"
    else
        echo "PostgreSQL 포트      : 내부 전용"
    fi
    echo "데이터베이스         : $POSTGRES_DB"
    echo "PostgreSQL 사용자    : $POSTGRES_USER"
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
    mkdir -p postgres-data
    mkdir -p wikijs-data
    
    print_success "디렉토리 생성 완료"
    echo "  - postgres-data/   (PostgreSQL 데이터 저장)"
    echo "  - wikijs-data/     (Wiki.js 데이터 저장)"
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
    
    # PostgreSQL 포트 설정
    if [ -n "$POSTGRES_PORT" ]; then
        POSTGRES_PORTS="    ports:
      - '${POSTGRES_PORT}:5432'"
    else
        POSTGRES_PORTS="    # 포트는 내부 네트워크에서만 접근 가능"
    fi
    
    # docker-compose.yml 파일 작성
    cat > docker-compose.yml << EOF
################################################################################
# Wiki.js + PostgreSQL
################################################################################
# Wiki.js 위키 시스템 + PostgreSQL 데이터베이스
#
# 접속 정보:
#   - Wiki.js: http://YOUR_SERVER_IP:${WIKIJS_PORT}
#   - 초기 설정은 웹 인터페이스에서 진행
#
################################################################################

services:
  # PostgreSQL 데이터베이스
  ${POSTGRES_CONTAINER}:
    image: postgres:${POSTGRES_VERSION}
    container_name: ${POSTGRES_CONTAINER}
    restart: unless-stopped
    environment:
      # PostgreSQL 설정
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      
      # 타임존 설정
      TZ: Asia/Seoul
      
${POSTGRES_PORTS}
      
    volumes:
      # PostgreSQL 데이터 저장 경로
      - ./postgres-data:/var/lib/postgresql/data
      
    networks:
      - ${NETWORK_NAME}
      
    command:
      - "postgres"
      - "-c"
      - "max_connections=100"
      
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Wiki.js 위키 시스템
  ${WIKIJS_CONTAINER}:
    image: ghcr.io/requarks/wiki:${WIKIJS_VERSION}
    container_name: ${WIKIJS_CONTAINER}
    restart: unless-stopped
    environment:
      # 데이터베이스 연결 설정
      DB_TYPE: postgres
      DB_HOST: ${POSTGRES_CONTAINER}
      DB_PORT: 5432
      DB_USER: ${POSTGRES_USER}
      DB_PASS: ${POSTGRES_PASSWORD}
      DB_NAME: ${POSTGRES_DB}
      
      # Wiki.js 설정
      # 초기 설정 후 자동으로 생성됩니다
      
      # 타임존 설정
      TZ: Asia/Seoul
      
    ports:
      - '${WIKIJS_PORT}:3000'
      
    volumes:
      # Wiki.js 데이터 저장 경로 (선택사항)
      - ./wikijs-data:/data
      
    networks:
      - ${NETWORK_NAME}
      
    depends_on:
      ${POSTGRES_CONTAINER}:
        condition: service_healthy

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
    cat > .wikijs-config << EOF
# Wiki.js + PostgreSQL 설정 정보
# 생성일: $(date)

# 컨테이너 정보
WIKIJS_CONTAINER=$WIKIJS_CONTAINER
POSTGRES_CONTAINER=$POSTGRES_CONTAINER
NETWORK_NAME=$NETWORK_NAME

# 버전 정보
WIKIJS_VERSION=$WIKIJS_VERSION
POSTGRES_VERSION=$POSTGRES_VERSION

# 포트 정보
WIKIJS_PORT=$WIKIJS_PORT
POSTGRES_PORT=$POSTGRES_PORT

# 데이터베이스 정보
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER

# Wiki.js 접속: http://YOUR_SERVER_IP:${WIKIJS_PORT}
# 초기 설정은 웹 인터페이스에서 관리자 계정을 생성합니다.
EOF
    
    chmod 600 .wikijs-config
    
    print_success "설정 정보가 .wikijs-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "Wiki.js + PostgreSQL을 시작합니다..."
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
    print_info "PostgreSQL과 Wiki.js가 초기화되는 중입니다... (30초 대기)"
    sleep 30
    
    # 컨테이너 상태 확인
    if docker ps | grep -q $WIKIJS_CONTAINER && docker ps | grep -q $POSTGRES_CONTAINER; then
        print_success "모든 컨테이너가 정상적으로 실행 중입니다."
    else
        print_warning "일부 컨테이너 상태를 확인할 수 없습니다."
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
# 최종 요약 및 안내
################################################################################
final_summary() {
    print_header "설치 완료!"
    
    get_server_ip
    
    echo ""
    print_success "Wiki.js + PostgreSQL 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ docker-compose.yml    (Docker Compose 설정)"
    echo "  ✓ .wikijs-config        (설정 정보)"
    echo "  ✓ postgres-data/        (PostgreSQL 데이터 저장소)"
    echo "  ✓ wikijs-data/          (Wiki.js 데이터 저장소)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Wiki.js 컨테이너     : $WIKIJS_CONTAINER"
    echo "  PostgreSQL 컨테이너 : $POSTGRES_CONTAINER"
    echo "  네트워크             : $NETWORK_NAME"
    echo "  Wiki.js 버전         : $WIKIJS_VERSION"
    echo "  PostgreSQL 버전      : $POSTGRES_VERSION"
    echo "  Wiki.js 포트         : $WIKIJS_PORT"
    if [ -n "$POSTGRES_PORT" ]; then
        echo "  PostgreSQL 포트      : $POSTGRES_PORT (외부 노출)"
    else
        echo "  PostgreSQL 포트      : 내부 전용"
    fi
    echo "  데이터베이스         : $POSTGRES_DB"
    echo "  PostgreSQL 사용자    : $POSTGRES_USER"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Wiki.js 접속"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Wiki.js: http://${SERVER_IP}:${WIKIJS_PORT}"
    echo ""
    echo "  📌 초기 설정 방법:"
    echo "    1. 위 URL로 웹 브라우저에서 접속"
    echo "    2. 관리자 계정 생성 (이메일, 비밀번호, 이름)"
    echo "    3. 사이트 URL 설정"
    echo "    4. 위키 설정 완료"
    echo ""
    echo "  ⚠️  주의: 초기 설정은 반드시 첫 접속 시 완료해야 합니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗄️  PostgreSQL 접속 (선택사항)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -n "$POSTGRES_PORT" ]; then
        echo "  # 호스트에서 접속"
        echo "  psql -h localhost -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    else
        echo "  # PostgreSQL은 내부 네트워크 전용입니다"
    fi
    echo ""
    echo "  # 컨테이너 내부에서 접속"
    echo "  docker exec -it ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    echo ""
    echo "  # 다른 컨테이너에서 접속"
    echo "  psql -h ${POSTGRES_CONTAINER} -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • Wiki.js 로그: docker compose logs -f ${WIKIJS_CONTAINER}"
    echo "  • PostgreSQL 로그: docker compose logs -f ${POSTGRES_CONTAINER}"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • PostgreSQL 쉘: docker exec -it ${POSTGRES_CONTAINER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    echo "  • 백업: docker exec ${POSTGRES_CONTAINER} pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > backup.sql"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 다음 보안 작업을 수행하세요:"
    echo "    1. 방화벽 설정 (필요한 IP만 접근 허용)"
    echo "    2. 강력한 관리자 비밀번호 설정"
    echo "    3. 정기적인 백업 수행"
    echo "    4. HTTPS 설정 (Nginx/Caddy 리버스 프록시 권장)"
    echo "    5. 초기 설정 완료 후 즉시 관리자 계정 보안 확인"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 Wiki.js 기능"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Markdown 편집기"
    echo "  • 버전 관리 (Git 연동 가능)"
    echo "  • 검색 기능"
    echo "  • 다국어 지원"
    echo "  • 권한 관리"
    echo "  • 테마 커스터마이징"
    echo "  • 외부 인증 (LDAP, OAuth, SAML 등)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📖 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Wiki.js 공식 문서: https://docs.requarks.io/"
    echo "  • Wiki.js GitHub: https://github.com/requarks/wiki"
    echo "  • PostgreSQL 문서: https://www.postgresql.org/docs/"
    echo ""
    
    print_success "설치 스크립트를 완료했습니다!"
    echo ""
    print_info "이제 http://${SERVER_IP}:${WIKIJS_PORT} 에 접속하여 Wiki.js를 설정하세요!"
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
    echo "║         Wiki.js + PostgreSQL 자동 설치 스크립트                ║"
    echo "║         강력한 오픈소스 위키 시스템                            ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker                # 1. Docker 확인
    get_user_input              # 2. 사용자 입력
    check_and_create_network    # 3. 네트워크 확인 및 생성
    create_directories          # 4. 디렉토리 생성
    generate_docker_compose     # 5. docker-compose.yml 생성
    save_configuration          # 6. 설정 정보 저장
    start_service               # 7. 서비스 시작
    final_summary               # 8. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
