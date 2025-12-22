#!/bin/bash

################################################################################
# Vaultwarden + Rclone 백업 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Admin 토큰 생성
# 4. Rclone Google Drive 연동 및 암호화 설정
# 5. docker-compose.yml 파일 자동 생성
# 6. Vaultwarden + 자동 암호화 백업 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/install-vaultwarden.sh | bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/install-vaultwarden.sh
#      chmod +x install-vaultwarden.sh
#      ./install-vaultwarden.sh
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ $1${NC}"; }

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

get_user_input() {
    print_header "Vaultwarden 설정 정보 입력"
    
    echo -e "${CYAN}Vaultwarden 컨테이너 이름을 입력하세요 (기본값: vaultwarden):${NC}"
    read -p "> " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-vaultwarden}
    BACKUP_CONTAINER_NAME="${CONTAINER_NAME}-backup"
    print_success "Vaultwarden 컨테이너: $CONTAINER_NAME"
    
    echo ""
    echo -e "${CYAN}Vaultwarden 도메인을 입력하세요 (예: vault.example.com):${NC}"
    read -p "> " DOMAIN
    while [ -z "$DOMAIN" ]; do
        print_warning "도메인은 필수입니다."
        read -p "> " DOMAIN
    done
    DOMAIN_URL="https://$DOMAIN"
    print_success "도메인: $DOMAIN_URL"
    
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크: $NETWORK_NAME"
    
    echo ""
    print_info "백업 주기를 선택하세요:"
    echo "  1) 1시간"
    echo "  2) 6시간"
    echo "  3) 12시간"
    echo "  4) 24시간 [권장]"
    echo "  5) 사용자 정의"
    read -p "> " BACKUP_CHOICE
    
    case $BACKUP_CHOICE in
        1) BACKUP_INTERVAL=3600 ;;
        2) BACKUP_INTERVAL=21600 ;;
        3) BACKUP_INTERVAL=43200 ;;
        4) BACKUP_INTERVAL=86400 ;;
        5) 
            echo -e "${CYAN}백업 주기를 초 단위로 입력하세요:${NC}"
            read -p "> " BACKUP_INTERVAL
            ;;
        *) BACKUP_INTERVAL=86400 ;;
    esac
    print_success "백업 주기: ${BACKUP_INTERVAL}초 ($((BACKUP_INTERVAL/3600))시간)"
    
    echo ""
    echo -e "${CYAN}Google Drive 백업 루트 폴더명을 입력하세요 (기본값: vaultwarden-backups):${NC}"
    read -p "> " RCLONE_ROOT
    RCLONE_ROOT=${RCLONE_ROOT:-vaultwarden-backups}
    print_success "백업 폴더: $RCLONE_ROOT"
    
    echo ""
    print_info "Admin 패널 접속용 비밀번호를 설정합니다."
    print_warning "최소 12자 이상의 강력한 비밀번호를 사용하세요."
    echo ""
    
    while true; do
        read -sp "Admin 비밀번호: " ADMIN_PASSWORD
        echo ""
        if [ -z "$ADMIN_PASSWORD" ]; then
            print_error "비밀번호를 입력해주세요."
            continue
        fi
        
        read -sp "Admin 비밀번호 확인: " ADMIN_PASSWORD_CONFIRM
        echo ""
        if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
            print_error "비밀번호가 일치하지 않습니다."
            continue
        fi
        break
    done
    print_success "Admin 비밀번호 설정 완료"
    
    echo ""
    print_header "입력한 설정 확인"
    echo "Vaultwarden 컨테이너: $CONTAINER_NAME"
    echo "백업 컨테이너       : $BACKUP_CONTAINER_NAME"
    echo "도메인             : $DOMAIN_URL"
    echo "네트워크           : $NETWORK_NAME"
    echo "백업 주기          : ${BACKUP_INTERVAL}초 ($((BACKUP_INTERVAL/3600))시간)"
    echo "백업 루트 폴더     : $RCLONE_ROOT"
    echo ""
    
    read -p "이 설정으로 진행하시겠습니까? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_warning "설정을 취소했습니다."
        exit 0
    fi
}

create_directories() {
    print_header "디렉토리 구조 생성"
    mkdir -p vaultwarden-data rclone-config backup-logs
    print_success "디렉토리 생성 완료"
}

generate_admin_token() {
    print_header "Admin 토큰 생성"
    print_info "Admin 토큰을 생성하고 있습니다..."

    # htpasswd 존재 여부 확인
    if ! command -v htpasswd >/dev/null 2>&1; then
        print_warning "apache2-utils가 설치되어 있지 않습니다."
        print_info "apache2-utils 설치를 진행합니다..."

        # sudo 권한 확인
        if ! command -v sudo >/dev/null 2>&1; then
            print_error "sudo 명령을 찾을 수 없습니다. 수동으로 apache2-utils를 설치해주세요."
            print_info "  apt install apache2-utils"
            exit 1
        fi

        # 비대화형 설치
        sudo apt-get update -y
        sudo apt-get install -y apache2-utils

        # 재확인
        if ! command -v htpasswd >/dev/null 2>&1; then
            print_error "apache2-utils 설치에 실패했습니다."
            exit 1
        fi

        print_success "apache2-utils 설치 완료"
    else
        print_success "apache2-utils 설치 확인 완료"
    fi

    # bcrypt Admin Token 생성
    ADMIN_TOKEN=$(htpasswd -bnBC 10 "" "$ADMIN_PASSWORD" | tr -d ':\n')

    if [ -z "$ADMIN_TOKEN" ]; then
        print_error "Admin 토큰 생성에 실패했습니다."
        exit 1
    fi

    # 토큰 저장
    echo "$ADMIN_TOKEN" > .admin-token
    chmod 600 .admin-token

    print_success "Admin 토큰 생성 완료"
}

check_and_create_network() {
    print_header "Docker 네트워크 확인"
    if docker network ls | grep -q "\s${NETWORK_NAME}\s"; then
        print_success "'$NETWORK_NAME' 네트워크가 이미 존재합니다."
    else
        print_warning "'$NETWORK_NAME' 네트워크가 존재하지 않습니다."
        read -p "'$NETWORK_NAME' 네트워크를 생성하시겠습니까? (y/N): " CREATE_NETWORK
        if [ "$CREATE_NETWORK" = "y" ] || [ "$CREATE_NETWORK" = "Y" ]; then
            docker network create --driver=bridge $NETWORK_NAME
            print_success "'$NETWORK_NAME' 네트워크가 생성되었습니다."
        else
            print_error "네트워크가 없으면 서비스를 시작할 수 없습니다."
            exit 1
        fi
    fi
}

configure_rclone() {
    print_header "Rclone 설정"
    echo ""
    print_info "Google Drive 백업을 위해 두 개의 리모트를 설정해야 합니다:"
    echo "  1. gdrive       - Google Drive 기본 리모트"
    echo "  2. gdrive-crypt - 암호화된 백업용 리모트"
    echo ""
    print_warning "설정 과정에서 Google 계정 인증이 필요합니다."
    echo ""
    
    read -p "Rclone 설정을 시작하시겠습니까? (y/N): " START_RCLONE
    if [ "$START_RCLONE" != "y" ] && [ "$START_RCLONE" != "Y" ]; then
        print_warning "Rclone 설정을 건너뜁니다."
        return
    fi
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Step 1: Google Drive 기본 리모트 설정 (gdrive)"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "계속하려면 엔터를 누르세요..."
    docker run --rm -it -v $(pwd)/rclone-config:/config/rclone rclone/rclone config
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Step 2: 암호화 리모트 설정 (gdrive-crypt)"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_warning "⚠️  매우 중요: 암호화 비밀번호를 안전하게 보관하세요!"
    echo ""
    read -p "계속하려면 엔터를 누르세요..."
    docker run --rm -it -v $(pwd)/rclone-config:/config/rclone rclone/rclone config
    
    print_success "Rclone 리모트 설정 완료!"
}

generate_docker_compose() {
    print_header "docker-compose.yml 파일 생성"
    if [ -f "docker-compose.yml" ]; then
        mv docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    cat > docker-compose.yml << EOF
################################################################################
# Vaultwarden + Rclone 백업
################################################################################

services:
  ${CONTAINER_NAME}:
    image: vaultwarden/server:latest
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    environment:
      - DOMAIN=${DOMAIN_URL}
      - SIGNUPS_ALLOWED=true
      - INVITATIONS_ALLOWED=true
      - SHOW_PASSWORD_HINT=false
      - WEB_VAULT_ENABLED=true
      - ADMIN_TOKEN=${ADMIN_TOKEN}
    volumes:
      - ./vaultwarden-data:/data
    networks:
      - ${NETWORK_NAME}

  ${BACKUP_CONTAINER_NAME}:
    image: rclone/rclone:latest
    container_name: ${BACKUP_CONTAINER_NAME}
    restart: unless-stopped
    entrypoint: /bin/sh
    environment:
      - TZ=Asia/Seoul
      - RCLONE_CONFIG=/config/rclone/rclone.conf
    volumes:
      - ./vaultwarden-data:/data:ro
      - ./rclone-config:/config/rclone
      - ./backup-logs:/logs
    command: >
      -c "
      while true; do
        YEAR=\\\$\\\$(date +%Y);
        LOGFILE=\"/logs/backup-\\\$\\\$YEAR.log\";
        echo \"[\\\$(date)] Starting encrypted backup...\" | tee -a \\\$\\\$LOGFILE;
        rclone sync /data gdrive-crypt:${RCLONE_ROOT}/vaultwarden-data --log-file=\\\$\\\$LOGFILE --log-level INFO;
        echo \"[\\\$(date)] Encrypted backup completed\" | tee -a \\\$\\\$LOGFILE;
        echo \"[\\\$(date)] Starting rclone-config backup...\" | tee -a \\\$\\\$LOGFILE;
        rclone sync /config/rclone gdrive:${RCLONE_ROOT}/rclone-config --log-file=\\\$\\\$LOGFILE --log-level INFO;
        echo \"[\\\$(date)] Rclone-config backup completed\" | tee -a \\\$\\\$LOGFILE;
        sleep ${BACKUP_INTERVAL};
      done
      "
    depends_on:
      - ${CONTAINER_NAME}
    networks:
      - ${NETWORK_NAME}

networks:
  ${NETWORK_NAME}:
    external: true
EOF
    print_success "docker-compose.yml 파일 생성 완료"
}

save_configuration() {
    print_header "설정 정보 저장"
    cat > rclone-config/.vaultwarden-config << EOF
CONTAINER_NAME=$CONTAINER_NAME
BACKUP_CONTAINER_NAME=$BACKUP_CONTAINER_NAME
DOMAIN=$DOMAIN
DOMAIN_URL=$DOMAIN_URL
NETWORK_NAME=$NETWORK_NAME
BACKUP_INTERVAL=$BACKUP_INTERVAL
RCLONE_ROOT=$RCLONE_ROOT
EOF
    ln -sf rclone-config/.vaultwarden-config .vaultwarden-config
    chmod 600 rclone-config/.vaultwarden-config
    print_success "설정 정보가 저장되었습니다."
}

start_service() {
    print_header "서비스 시작"
    print_info "Vaultwarden + 자동 백업 서비스를 시작합니다..."
    if docker compose up -d; then
        print_success "서비스가 성공적으로 시작되었습니다!"
    else
        print_error "서비스 시작에 실패했습니다."
        exit 1
    fi
}

final_summary() {
    print_header "설치 완료!"
    echo ""
    print_success "Vaultwarden + 자동 암호화 백업 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 서비스 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  도메인: ${DOMAIN_URL}"
    echo "  Admin: ${DOMAIN_URL}/admin"
    echo "  백업: Google Drive/${RCLONE_ROOT}/"
    echo "  주기: $((BACKUP_INTERVAL/3600))시간"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 다음 단계"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. Nginx Proxy Manager 프록시 호스트 설정"
    echo "  2. ${DOMAIN_URL} 접속하여 초기 계정 생성"
    echo "  3. SIGNUPS_ALLOWED=false 로 변경 (docker-compose.yml)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  중요: 안전하게 백업하세요!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Admin 비밀번호"
    echo "  • Rclone 암호화 비밀번호"
    echo "  • .admin-token 파일"
    echo ""
    print_success "설치 완료!"
}

main() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     Vaultwarden + Rclone 암호화 백업 자동 설치 스크립트       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_docker
    get_user_input
    create_directories
    generate_admin_token
    check_and_create_network
    configure_rclone
    generate_docker_compose
    save_configuration
    start_service
    final_summary
}

main
