#!/bin/bash

################################################################################
# Linux Server Setup Script
################################################################################
# 이 스크립트는 다음 작업을 수행합니다:
# 1. 서버 타임존을 Asia/Seoul로 설정
# 2. Docker 및 Docker Compose 설치
#
# 사용 방법:
#   1. 스크립트 다운로드:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh
#      또는
#      curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh
#
#   2. 실행 권한 부여:
#      chmod +x init_setup.sh
#
#   3. 스크립트 실행 (root 권한 필요):
#      sudo ./init_setup.sh
#
# 한줄 명령어: curl 사용
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh | sudo bash
#      또는
#      wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh | sudo bash
# 
# 참고:
#   - 이 스크립트는 root 권한이 필요합니다.
#   - Ubuntu, Debian, CentOS, RHEL 등 주요 Linux 배포판을 지원합니다.
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
# Root 권한 확인
################################################################################
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "이 스크립트는 root 권한이 필요합니다. 'sudo'를 사용하여 실행하세요."
        exit 1
    fi
}

################################################################################
# 타임존 확인 및 설정
################################################################################
setup_timezone() {
    print_header "타임존 설정"
    
    print_info "현재 타임존 확인 중..."
    
    current_timezone=$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Unknown")
    
    print_info "현재 타임존: $current_timezone"
    
    if [ "$current_timezone" = "Asia/Seoul" ]; then
        print_success "타임존이 이미 Asia/Seoul로 설정되어 있습니다."
    else
        print_warning "타임존을 Asia/Seoul로 변경합니다..."
        
        # timedatectl을 사용할 수 있는 경우
        if command -v timedatectl &> /dev/null; then
            timedatectl set-timezone Asia/Seoul
        else
            # 수동으로 설정
            ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
            echo "Asia/Seoul" > /etc/timezone
        fi
        
        print_success "타임존이 Asia/Seoul로 설정되었습니다."
    fi
    
    print_info "현재 시간: $(date)"
}

################################################################################
# Docker 설치 확인
################################################################################
check_docker() {
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version)
        print_success "Docker가 이미 설치되어 있습니다: $docker_version"
        return 0
    else
        print_warning "Docker가 설치되어 있지 않습니다."
        return 1
    fi
}

################################################################################
# Docker Compose 설치 확인
################################################################################
check_docker_compose() {
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version)
        print_success "Docker Compose가 이미 설치되어 있습니다: $compose_version"
        return 0
    elif command -v docker-compose &> /dev/null; then
        compose_version=$(docker-compose --version)
        print_success "Docker Compose가 이미 설치되어 있습니다: $compose_version"
        return 0
    else
        print_warning "Docker Compose가 설치되어 있지 않습니다."
        return 1
    fi
}

################################################################################
# Docker 설치
################################################################################
install_docker() {
    print_header "Docker 설치"
    
    print_info "Docker 설치를 시작합니다..."
    
    # 기존 Docker 관련 패키지 제거 (선택사항)
    print_info "기존 Docker 패키지 확인 중..."
    
    # Docker 공식 설치 스크립트 다운로드 및 실행
    print_info "https://get.docker.com/ 에서 설치 스크립트를 다운로드합니다..."
    
    if curl -fsSL https://get.docker.com -o get-docker.sh; then
        print_info "설치 스크립트 다운로드 완료. Docker 설치 중..."
        sh get-docker.sh
        rm get-docker.sh
        
        # Docker 서비스 시작 및 활성화
        print_info "Docker 서비스를 시작합니다..."
        systemctl start docker
        systemctl enable docker
        
        print_success "Docker 설치가 완료되었습니다."
        docker --version
    else
        print_error "Docker 설치 스크립트 다운로드에 실패했습니다."
        exit 1
    fi
}

################################################################################
# 현재 사용자를 docker 그룹에 추가
################################################################################
add_user_to_docker_group() {
    if [ -n "$SUDO_USER" ]; then
        print_info "사용자 '$SUDO_USER'를 docker 그룹에 추가합니다..."
        usermod -aG docker "$SUDO_USER"
        print_success "docker 그룹 추가 완료"
        print_warning "변경사항을 적용하려면 로그아웃 후 다시 로그인하세요."
    fi
}

################################################################################
# 최종 요약
################################################################################
final_summary() {
    print_header "설정 완료!"
    
    echo ""
    print_success "모든 설정이 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 완료된 작업"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ 타임존 설정: Asia/Seoul"
    echo "  ✓ Docker 설치 및 설정"
    echo "  ✓ Docker Compose 설치"
    if [ -n "$SUDO_USER" ]; then
        echo "  ✓ 사용자 '$SUDO_USER'를 docker 그룹에 추가"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 다음 단계"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. 로그아웃 후 다시 로그인 (docker 그룹 적용)"
    echo "  2. Docker 테스트: docker run hello-world"
    echo "  3. Docker Compose 테스트: docker compose version"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Docker 상태 확인: systemctl status docker"
    echo "  • Docker 버전 확인: docker --version"
    echo "  • Docker Compose 버전: docker compose version"
    echo "  • 실행 중인 컨테이너: docker ps"
    echo ""
    
    print_success "Linux 서버 설정 스크립트를 완료했습니다!"
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
    echo "║          Linux Server Setup Script                           ║"
    echo "║          타임존 설정 + Docker 설치                             ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Root 권한 확인
    check_root
    
    # 1. 타임존 설정
    setup_timezone
    
    # 2. Docker 설치 확인 및 설치
    print_header "Docker 설치 확인"
    
    if ! check_docker; then
        install_docker
        add_user_to_docker_group
    fi
    
    # 3. Docker Compose 확인 (Docker 설치 시 자동으로 포함됨)
    echo ""
    print_info "Docker Compose 확인 중..."
    check_docker_compose
    
    # 4. 최종 요약
    final_summary
}

################################################################################
# 스크립트 실행
################################################################################
main
