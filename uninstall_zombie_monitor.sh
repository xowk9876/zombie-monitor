#!/bin/bash

# Rocky Linux Zombie Monitor 제거 스크립트
# 설치된 zombie monitor 시스템 완전 제거
# 작성자: Tae-system

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 이모지 정의
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
TRASH="🗑️"
GEAR="⚙️"
FILE="📄"
FOLDER="📁"
PROCESS="🔄"
STOP="🛑"

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    local title=$1
    echo
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                    $title                    ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

print_step() {
    local step=$1
    local message=$2
    print_color $BLUE "$GEAR $step: $message"
}

print_success() {
    local message=$1
    print_color $GREEN "$CHECK $message"
}

print_error() {
    local message=$1
    print_color $RED "$CROSS $message"
}

print_warning() {
    local message=$1
    print_color $YELLOW "$WARNING $message"
}

print_info() {
    local message=$1
    print_color $BLUE "$INFO $message"
}

# 확인 프롬프트
confirm_removal() {
    if [ "$1" != "-f" ]; then
        print_color $YELLOW "이 작업은 설치된 zombie monitor 시스템을 완전히 제거합니다."
        print_color $YELLOW "계속하시겠습니까? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_color $GREEN "제거 작업이 취소되었습니다."
            exit 0
        fi
    fi
}

# 서비스 중지 및 제거
remove_services() {
    print_step "1" "서비스 중지 및 제거"
    
    # 서비스 중지 (타임아웃 설정)
    print_info "서비스 중지 중..."
    timeout 10 systemctl stop zombie-monitor.service 2>/dev/null || true
    
    # 서비스 비활성화
    print_info "서비스 비활성화 중..."
    systemctl disable zombie-monitor.service 2>/dev/null || true
    
    # 서비스 파일 제거
    print_info "서비스 파일 제거 중..."
    rm -f /etc/systemd/system/zombie-monitor.service
    
    # systemd 데몬 리로드
    print_info "systemd 데몬 리로드 중..."
    systemctl daemon-reload 2>/dev/null || true
    
    print_success "systemd 서비스 제거 완료"
}

# 크론잡 제거
remove_cron() {
    print_step "2" "크론잡 제거"
    
    # 기존 크론잡에서 zombie 관련 항목 제거
    print_info "크론잡 정리 중..."
    crontab -l 2>/dev/null | grep -v "zombie" | crontab - 2>/dev/null || true
    
    print_success "크론잡 제거 완료"
}

# 파일 및 디렉토리 제거
remove_files() {
    print_step "3" "파일 및 디렉토리 제거"
    
    # 스크립트 디렉토리 제거
    print_info "스크립트 디렉토리 제거 중..."
    if [ -d "/opt/zombie_monitor" ]; then
        rm -rf /opt/zombie_monitor
        print_success "스크립트 디렉토리 제거: /opt/zombie_monitor"
    else
        print_info "스크립트 디렉토리가 없습니다: /opt/zombie_monitor"
    fi
    
    # 설정 파일 제거
    print_info "설정 파일 제거 중..."
    if [ -f "/etc/zombie_monitor.conf" ]; then
        rm -f /etc/zombie_monitor.conf
        print_success "설정 파일 제거: /etc/zombie_monitor.conf"
    else
        print_info "설정 파일이 없습니다: /etc/zombie_monitor.conf"
    fi
    
    # 로그 로테이션 설정 제거
    print_info "로그 로테이션 설정 제거 중..."
    if [ -f "/etc/logrotate.d/zombie-monitor" ]; then
        rm -f /etc/logrotate.d/zombie-monitor
        print_success "로그 로테이션 설정 제거"
    else
        print_info "로그 로테이션 설정이 없습니다"
    fi
}

# 로그 파일 제거
remove_logs() {
    print_step "4" "로그 파일 제거"
    
    # 로그 파일 제거
    rm -f /var/log/zombie_monitor.log
    rm -f /var/log/zombie_*.log
    rm -f /var/log/*zombie*.log
    
    # 남은 로그 파일 확인
    if find /var/log -name "*zombie*" -type f 2>/dev/null | grep -q .; then
        print_warning "일부 로그 파일이 남아있습니다:"
        find /var/log -name "*zombie*" -type f 2>/dev/null | while read -r file; do
            print_warning "  $file"
        done
    else
        print_success "모든 로그 파일 제거 완료"
    fi
}

# 락 파일 제거
remove_lock_files() {
    print_step "5" "락 파일 제거"
    
    # 락 파일 제거
    rm -f /tmp/zombie_monitor.lock
    rm -f /tmp/zombie_*.lock
    
    print_success "락 파일 제거 완료"
}

# 추가 정리
cleanup_remaining() {
    print_step "6" "추가 정리"
    
    # 남은 zombie 관련 파일 찾기 및 제거
    find /var/log -name "*zombie*" -type f -delete 2>/dev/null
    find /tmp -name "*zombie*" -type f -delete 2>/dev/null
    
    print_success "추가 정리 완료"
}

# 제거 확인
verify_removal() {
    print_step "7" "제거 확인"
    
    local remaining_items=0
    
    # 디렉토리 확인
    if [ -d "/opt/zombie_monitor" ]; then
        print_error "스크립트 디렉토리가 남아있습니다: /opt/zombie_monitor"
        ((remaining_items++))
    fi
    
    # 설정 파일 확인
    if [ -f "/etc/zombie_monitor.conf" ]; then
        print_error "설정 파일이 남아있습니다: /etc/zombie_monitor.conf"
        ((remaining_items++))
    fi
    
    # 서비스 파일 확인
    if [ -f "/etc/systemd/system/zombie-monitor.service" ]; then
        print_error "서비스 파일이 남아있습니다: /etc/systemd/system/zombie-monitor.service"
        ((remaining_items++))
    fi
    
    # 로그 파일 확인
    if find /var/log -name "*zombie*" -type f 2>/dev/null | grep -q .; then
        print_error "로그 파일이 남아있습니다:"
        find /var/log -name "*zombie*" -type f 2>/dev/null | while read -r file; do
            print_error "  $file"
        done
        ((remaining_items++))
    fi
    
    # 락 파일 확인
    if find /tmp -name "*zombie*" -type f 2>/dev/null | grep -q .; then
        print_error "락 파일이 남아있습니다:"
        find /tmp -name "*zombie*" -type f 2>/dev/null | while read -r file; do
            print_error "  $file"
        done
        ((remaining_items++))
    fi
    
    if [ $remaining_items -eq 0 ]; then
        print_success "모든 구성 요소가 성공적으로 제거되었습니다"
        return 0
    else
        print_warning "$remaining_items 개의 항목이 남아있습니다"
        return 1
    fi
}

# 완전 제거 실행
complete_removal() {
    print_header "🚀 완전 제거 작업 시작"
    
    # 1. 서비스 중지 및 제거
    remove_services
    echo
    
    # 2. 크론잡 제거
    remove_cron
    echo
    
    # 3. 파일 및 디렉토리 제거
    remove_files
    echo
    
    # 4. 로그 파일 제거
    remove_logs
    echo
    
    # 5. 락 파일 제거
    remove_lock_files
    echo
    
    # 6. 추가 정리
    cleanup_remaining
    echo
    
    # 7. 제거 확인
    verify_removal
    echo
    
    print_header "🎉 제거 작업 완료"
    print_color $GREEN "Zombie Monitor 시스템이 완전히 제거되었습니다."
    echo
    print_color $YELLOW "수동으로 제거해야 할 항목이 있다면:"
    print_color $BLUE "  sudo rm -rf /opt/zombie_monitor"
    print_color $BLUE "  sudo rm -f /etc/zombie_monitor.conf"
    print_color $BLUE "  sudo systemctl daemon-reload"
    echo
}

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -f, --force    확인 없이 강제 제거"
    echo "  -h, --help     도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0              # 확인 후 제거"
    echo "  $0 -f           # 강제 제거"
}

# 메인 함수
main() {
    # 루트 권한 확인
    if [ "$EUID" -ne 0 ]; then
        print_color $RED "이 스크립트는 루트 권한으로 실행해야 합니다."
        print_color $YELLOW "사용법: sudo $0"
        exit 1
    fi
    
    # 명령행 인수 처리
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            confirm_removal -f
            ;;
        "")
            confirm_removal
            ;;
        *)
            print_color $RED "알 수 없는 옵션: $1"
            usage
            exit 1
            ;;
    esac
    
    # 제거 실행
    complete_removal
}

# 스크립트 실행
main "$@"
