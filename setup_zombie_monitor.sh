#!/bin/bash

# Rocky Linux Zombie Monitor 설치 스크립트
# 작성자: Tae-system
# 용도: 실시간 좀비 프로세스 모니터링 시스템 설치

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 설정 변수
SCRIPT_DIR="/opt/zombie_monitor"
SCRIPT_NAME="zombie_monitor.sh"
CONFIG_FILE="/etc/zombie_monitor.conf"
LOG_FILE="/var/log/zombie_monitor.log"

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                🚀 ZOMBIE MONITOR 설치                      ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# 디렉토리 및 파일 설정
setup_directories() {
    print_color $BLUE "=== 디렉토리 및 파일 설정 ==="
    
    # 스크립트 디렉토리 생성
    if [ ! -d "$SCRIPT_DIR" ]; then
        sudo mkdir -p "$SCRIPT_DIR"
        print_color $GREEN "디렉토리 생성: $SCRIPT_DIR"
    else
        print_color $YELLOW "디렉토리 이미 존재: $SCRIPT_DIR"
    fi
    
    # 스크립트 복사
    if [ -f "./zombie_monitor.sh" ]; then
        sudo cp ./zombie_monitor.sh "$SCRIPT_DIR/$SCRIPT_NAME"
        sudo chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
        print_color $GREEN "스크립트 설치 완료: $SCRIPT_DIR/$SCRIPT_NAME"
    else
        print_color $RED "오류: zombie_monitor.sh 파일을 찾을 수 없습니다."
        exit 1
    fi
    
    # 설정 파일 복사
    if [ -f "./zombie_monitor.conf" ]; then
        sudo cp ./zombie_monitor.conf "$CONFIG_FILE"
        sudo chmod 644 "$CONFIG_FILE"
        print_color $GREEN "설정 파일 설치 완료: $CONFIG_FILE"
    else
        print_color $YELLOW "경고: 설정 파일이 없습니다. 기본 설정을 사용합니다."
    fi
    
    # 로그 파일 권한 설정
    sudo touch "$LOG_FILE" 2>/dev/null
    sudo chmod 644 "$LOG_FILE" 2>/dev/null
    sudo chown root:root "$LOG_FILE" 2>/dev/null
    print_color $GREEN "로그 파일 권한 설정 완료"
}

# systemd 서비스 설정
setup_systemd() {
    print_color $BLUE "=== systemd 서비스 설정 ==="
    
    # 서비스 파일 생성
    sudo tee /etc/systemd/system/zombie-monitor.service > /dev/null << EOF
[Unit]
Description=Zombie Process Monitor
After=network.target

[Service]
Type=simple
User=root
ExecStart=$SCRIPT_DIR/$SCRIPT_NAME
Restart=no
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # 서비스 활성화 (자동 시작 비활성화)
    sudo systemctl daemon-reload
    sudo systemctl enable zombie-monitor.service
    print_color $GREEN "systemd 서비스 설정 완료 (자동 시작 비활성화)"
}

# 크론잡 설정
setup_cron() {
    print_color $BLUE "=== 크론잡 설정 ==="
    
    # 기존 크론잡 백업
    crontab -l > /tmp/crontab_backup 2>/dev/null
    
    # 새로운 크론잡 추가
    (crontab -l 2>/dev/null; echo "# Zombie Monitor - 5분마다 실행") | crontab -
    (crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_DIR/$SCRIPT_NAME >/dev/null 2>&1") | crontab -
    
    print_color $GREEN "크론잡 설정 완료 (5분마다 실행)"
}

# 로그 로테이션 설정
setup_logrotate() {
    print_color $BLUE "=== 로그 로테이션 설정 ==="
    
    sudo tee /etc/logrotate.d/zombie-monitor > /dev/null << EOF
$LOG_FILE {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload zombie-monitor.service > /dev/null 2>&1 || true
    endscript
}
EOF

    print_color $GREEN "로그 로테이션 설정 완료"
}

# 사용법 표시
show_usage() {
    print_color $CYAN "=== 사용법 ==="
    echo
    print_color $YELLOW "실시간 모니터링:"
    print_color $GREEN "  sudo $SCRIPT_DIR/$SCRIPT_NAME"
    echo
    print_color $YELLOW "백그라운드 실행:"
    print_color $GREEN "  sudo $SCRIPT_DIR/$SCRIPT_NAME &"
    echo
    print_color $YELLOW "서비스 관리:"
    print_color $GREEN "  sudo systemctl start zombie-monitor"
    print_color $GREEN "  sudo systemctl stop zombie-monitor"
    print_color $GREEN "  sudo systemctl status zombie-monitor"
    echo
    print_color $YELLOW "옵션:"
    print_color $GREEN "  -h, --help     도움말"
    print_color $GREEN "  -v, --verbose  상세 출력"
    print_color $GREEN "  -i, --interval 간격 설정 (초)"
    print_color $GREEN "  -a, --auto     자동 정리 활성화"
    print_color $GREEN "  -m, --manual   수동 모드"
    echo
    print_color $CYAN "=== 주의사항 ==="
    print_color $YELLOW "서비스는 자동 시작되지 않습니다. 수동으로 시작하세요:"
    print_color $GREEN "  sudo systemctl start zombie-monitor"
    echo
}

# 설치 완료 메시지
show_completion() {
    print_color $GREEN "✅ 설치 완료!"
    echo
    print_color $CYAN "설치된 구성 요소:"
    print_color $GREEN "  📁 스크립트: $SCRIPT_DIR/$SCRIPT_NAME"
    print_color $GREEN "  📄 설정 파일: $CONFIG_FILE"
    print_color $GREEN "  📄 로그 파일: $LOG_FILE"
    print_color $GREEN "  ⚙️  systemd 서비스: zombie-monitor.service"
    print_color $GREEN "  ⏰ 크론잡: 5분마다 실행"
    print_color $GREEN "  📋 로그 로테이션: 7일 보관"
    echo
    print_color $YELLOW "즉시 시작하려면:"
    print_color $GREEN "  sudo $SCRIPT_DIR/$SCRIPT_NAME"
    echo
    print_color $CYAN "또는 서비스로 시작:"
    print_color $GREEN "  sudo systemctl start zombie-monitor"
    echo
}

# 메인 함수
main() {
    print_header
    
    # 루트 권한 확인
    if [ "$EUID" -ne 0 ]; then
        print_color $RED "이 스크립트는 루트 권한으로 실행해야 합니다."
        print_color $YELLOW "사용법: sudo $0"
        exit 1
    fi
    
    # 설치 과정
    setup_directories
    setup_systemd
    setup_cron
    setup_logrotate
    
    # 완료 메시지
    show_completion
    show_usage
}

# 스크립트 실행
main "$@"
