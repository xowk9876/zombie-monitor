#!/bin/bash

# Rocky Linux Zombie Process Monitor v1.1
# 실시간 좀비 프로세스 모니터링 및 자동 정리
# 작성자: Tae-system, 업데이트: 2025-01-27

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 설정 변수
LOG_FILE="/var/log/zombie_monitor.log"
LOCK_FILE="/tmp/zombie_monitor.lock"
CONFIG_FILE="/etc/zombie_monitor.conf"

# 기본 설정
VERSION="1.1"
REFRESH_INTERVAL=2
AUTO_CLEANUP=true
VERBOSE=false
MAX_ZOMBIES=5
CLEANUP_DELAY=1
DAEMON_MODE=false
LOG_ROTATION_SIZE=10485760  # 10MB

# 통계 변수
TOTAL_DETECTED=0
TOTAL_CLEANED=0
TOTAL_FAILED=0
SESSION_START=$(date '+%Y-%m-%d %H:%M:%S')
START_TIME=$(date +%s)

# 로그 함수
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 로그 파일 크기 체크 및 로테이션
    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $LOG_ROTATION_SIZE ]; then
        rotate_log
    fi
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 로그 로테이션 함수
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE" 2>/dev/null
        log_message "INFO" "Log rotated - file size exceeded ${LOG_ROTATION_SIZE} bytes"
    fi
}

# 색상 출력 함수
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 락 파일 관리
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            print_color $RED "❌ 모니터가 이미 실행 중입니다. (PID: $pid)"
            exit 1
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

cleanup_lock() {
    stty echo icanon 2>/dev/null
    rm -f "$LOCK_FILE"
}

# 좀비 프로세스 감지 (최적화된 버전)
detect_zombies() {
    # ps 명령어 최적화 - 필요한 컬럼만 출력
    ps -eo pid,ppid,stat,comm --no-headers 2>/dev/null | awk '$3 ~ /^Z/ { print $1, $2, $4 }'
}

# 좀비 프로세스 개수 (최적화된 버전)
count_zombies() {
    # 더 빠른 카운팅 방법
    ps -eo stat --no-headers 2>/dev/null | grep -c '^Z' || echo 0
}

# 좀비 프로세스 정리
cleanup_zombie() {
    local pid=$1
    local ppid=$2
    local cmd=$3
    
    if [ -z "$pid" ] || [ "$pid" = "PID" ]; then
        return
    fi
    
    print_color $YELLOW "🧹 좀비 프로세스 정리: PID $pid (부모: $ppid)"
    log_message "CLEANUP" "Cleaning zombie PID $pid (PPID: $ppid, CMD: $cmd)"
    
    # PPID가 0.0인 경우 특별 처리
    if [ "$ppid" = "0.0" ] || [ "$ppid" = "0" ]; then
        print_color $BLUE "🔥 시스템 레벨 좀비 감지 - 초강력 정리 시작"
        
        # 1단계: 안정적인 정리 시도
        print_color $BLUE "  → 1단계: 안정적인 정리 시도"
        kill -CHLD 1 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 안정적 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with stable method"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 2단계: 강력한 정리 시도
        print_color $BLUE "  → 2단계: 강력한 정리 시도"
        kill -HUP 1 2>/dev/null
        kill -USR1 1 2>/dev/null
        kill -USR2 1 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 강력한 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with powerful method"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 3단계: 시스템 레벨 정리
        print_color $BLUE "  → 3단계: 시스템 레벨 정리"
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 시스템 레벨 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with system method"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 4단계: 프로세스 트리 정리
        print_color $BLUE "  → 4단계: 프로세스 트리 정리"
        pkill -TERM -P "$pid" 2>/dev/null
        pkill -KILL -P "$pid" 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 프로세스 트리 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with process tree"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 5단계: 최종 강제 정리
        print_color $RED "  → 5단계: 최종 강제 정리"
        kill -9 "$pid" 2>/dev/null
        kill -9 -"$pid" 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 최종 강제 정리 완료"
            log_message "SUCCESS" "Zombie $pid force cleaned"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 6단계: 커널 레벨 정리 (매우 위험)
        print_color $RED "  → 6단계: 커널 레벨 정리 (위험)"
        echo 1 > /proc/sysrq-trigger 2>/dev/null
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 커널 레벨 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with kernel method"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 7단계: 절대 강제 정리
        print_color $RED "  → 7단계: 절대 강제 정리"
        kill -9 "$pid" 2>/dev/null
        kill -9 -"$pid" 2>/dev/null
        pkill -9 -f "$pid" 2>/dev/null
        sleep 1
        
        # 최종 확인
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 절대 강제 정리 완료"
            log_message "SUCCESS" "Zombie $pid absolutely force cleaned"
            ((TOTAL_CLEANED++))
            return
        fi
        
        # 실패 시 무시하고 계속 진행
        print_color $YELLOW "⚠️ 좀비 $pid 정리 실패 - 무시하고 계속 진행"
        log_message "WARNING" "Zombie $pid cleanup failed, continuing"
        ((TOTAL_FAILED++))
        return
    fi
    
    # 일반 좀비 프로세스 정리
    # 1단계: SIGCHLD 신호 전송
    if [ "$ppid" != "0" ] && [ "$ppid" != "0.0" ]; then
        if kill -CHLD "$ppid" 2>/dev/null; then
            sleep 0.5
            if ! kill -0 "$pid" 2>/dev/null; then
                print_color $GREEN "✅ SIGCHLD로 정리 완료"
                log_message "SUCCESS" "Zombie $pid cleaned with SIGCHLD"
                ((TOTAL_CLEANED++))
                return
            fi
        fi
    fi
    
    # 2단계: 부모 프로세스에 SIGCHLD
    if [ "$ppid" != "1" ] && [ "$ppid" != "0" ] && [ "$ppid" != "0.0" ]; then
        kill -CHLD "$ppid" 2>/dev/null
        sleep 0.5
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ 부모 프로세스 SIGCHLD로 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with parent SIGCHLD"
            ((TOTAL_CLEANED++))
            return
        fi
    fi
    
    # 3단계: init 프로세스에 SIGCHLD
    kill -CHLD 1 2>/dev/null
    sleep 0.5
    if ! kill -0 "$pid" 2>/dev/null; then
        print_color $GREEN "✅ init SIGCHLD로 정리 완료"
        log_message "SUCCESS" "Zombie $pid cleaned with init SIGCHLD"
        ((TOTAL_CLEANED++))
        return
    fi
    
    # 4단계: 강제 종료 시도
    if kill -TERM "$pid" 2>/dev/null; then
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ TERM 신호로 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with TERM"
            ((TOTAL_CLEANED++))
            return
        fi
    fi
    
    # 5단계: KILL 신호
    if kill -KILL "$pid" 2>/dev/null; then
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
            print_color $GREEN "✅ KILL 신호로 정리 완료"
            log_message "SUCCESS" "Zombie $pid cleaned with KILL"
            ((TOTAL_CLEANED++))
            return
        fi
    fi
    
    # 6단계: 최종 강제 정리
    print_color $RED "🔥 최종 강제 정리 시도"
    kill -9 "$pid" 2>/dev/null
    sleep 1
    
    if ! kill -0 "$pid" 2>/dev/null; then
        print_color $GREEN "✅ 강제 정리 완료"
        log_message "SUCCESS" "Zombie $pid force cleaned"
        ((TOTAL_CLEANED++))
        return
    fi
    
    print_color $RED "❌ 좀비 프로세스 $pid 정리 실패"
    log_message "ERROR" "Failed to clean zombie $pid"
    ((TOTAL_FAILED++))
}

# 화면 클리어 및 헤더
show_header() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                🧟 ZOMBIE PROCESS MONITOR                    ║"
    print_color $CYAN "║                    실시간 모니터링                          ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
    print_color $YELLOW "💡 단축키: [A]자동정리 [M]수동정리 [S]통계 [Q]종료 [H]도움말"
    echo
}

# 상태 표시
show_status() {
    local zombie_count=$(count_zombies)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local memory_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    
    print_color $BLUE "📊 현재 상태 ($timestamp)"
    print_color $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 좀비 프로세스 상태
    if [ $zombie_count -eq 0 ]; then
        print_color $GREEN "✅ Zombie 프로세스: 0개 (정상)"
    elif [ $zombie_count -le 3 ]; then
        print_color $YELLOW "⚠️  Zombie 프로세스: $zombie_count개 (주의)"
    else
        print_color $RED "🚨 Zombie 프로세스: $zombie_count개 (위험)"
    fi
    
    # 시스템 정보
    print_color $BLUE "💻 시스템 정보:"
    print_color $BLUE "  로드 평균: $load_avg"
    print_color $BLUE "  메모리 사용률: ${memory_usage}%"
    
    print_color $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 좀비 프로세스 목록
    if [ $zombie_count -gt 0 ]; then
        print_color $YELLOW "📋 Zombie 프로세스 목록:"
        ps aux | awk '$8 ~ /^Z/ { 
            printf "  PID: %s, PPID: %s, CMD: %s\n", $2, $3, $11 
        }'
        echo
    fi
    
    # 설정 정보
    print_color $BLUE "⚙️  설정:"
    print_color $BLUE "  자동 정리: $([ "$AUTO_CLEANUP" = true ] && echo "활성화" || echo "비활성화")"
    print_color $BLUE "  새로고침 간격: ${REFRESH_INTERVAL}초"
    print_color $BLUE "  경고 임계값: ${MAX_ZOMBIES}개"
    echo
    
    # 통계 정보
    print_color $BLUE "📈 세션 통계:"
    print_color $BLUE "  감지된 좀비: $TOTAL_DETECTED개"
    print_color $BLUE "  정리된 좀비: $TOTAL_CLEANED개"
    print_color $BLUE "  정리 실패: $TOTAL_FAILED개"
    if [ $TOTAL_DETECTED -gt 0 ]; then
        local success_rate=$((TOTAL_CLEANED * 100 / TOTAL_DETECTED))
        print_color $BLUE "  정리 성공률: ${success_rate}%"
    fi
    
    # 세션 시간 계산
    local current_time=$(date +%s)
    local session_duration=$((current_time - START_TIME))
    local hours=$((session_duration / 3600))
    local minutes=$(((session_duration % 3600) / 60))
    local seconds=$((session_duration % 60))
    print_color $BLUE "  세션 시간: ${hours}시간 ${minutes}분 ${seconds}초"
    print_color $BLUE "  세션 시작: $SESSION_START"
    echo
    
    print_color $CYAN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color $GREEN "실시간 모니터링 중... (${REFRESH_INTERVAL}초마다 새로고침)"
    echo
}

# 통계 표시
show_statistics() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                    📈 통계 정보                            ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    print_color $BLUE "📊 현재 세션 통계:"
    print_color $BLUE "  세션 시작: $SESSION_START"
    print_color $BLUE "  현재 시간: $(date '+%Y-%m-%d %H:%M:%S')"
    print_color $BLUE "  감지된 좀비: $TOTAL_DETECTED개"
    print_color $BLUE "  정리된 좀비: $TOTAL_CLEANED개"
    print_color $BLUE "  정리 실패: $TOTAL_FAILED개"
    
    # 세션 시간 계산
    local current_time=$(date +%s)
    local session_duration=$((current_time - START_TIME))
    local hours=$((session_duration / 3600))
    local minutes=$(((session_duration % 3600) / 60))
    local seconds=$((session_duration % 60))
    print_color $BLUE "  세션 시간: ${hours}시간 ${minutes}분 ${seconds}초"
    
    if [ $TOTAL_DETECTED -gt 0 ]; then
        local success_rate=$((TOTAL_CLEANED * 100 / TOTAL_DETECTED))
        print_color $BLUE "  정리 성공률: ${success_rate}%"
    fi
    
    echo
    print_color $BLUE "📋 최근 로그 (마지막 10줄):"
    if [ -f "$LOG_FILE" ]; then
        tail -10 "$LOG_FILE" | while read line; do
            print_color $YELLOW "  $line"
        done
    else
        print_color $YELLOW "  로그 파일이 없습니다."
    fi
    
    echo
    print_color $CYAN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color $GREEN "아무 키나 누르면 모니터링으로 돌아갑니다..."
    read -n 1
}

# 도움말 표시
show_help() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                    📖 도움말                               ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    print_color $YELLOW "🎮 단축키:"
    print_color $YELLOW "  [A] - 자동 정리 토글 (ON/OFF)"
    print_color $YELLOW "  [M] - 수동 정리 실행"
    print_color $YELLOW "  [S] - 통계 정보 표시"
    print_color $YELLOW "  [Q] - 모니터링 종료"
    print_color $YELLOW "  [H] - 도움말 표시"
    print_color $YELLOW "  [Ctrl+C] - 강제 종료"
    
    echo
    print_color $BLUE "🔧 기능 설명:"
    print_color $BLUE "  자동 정리: 좀비 프로세스 감지 시 자동으로 정리"
    print_color $BLUE "  수동 정리: 사용자가 원할 때 수동으로 정리"
    print_color $BLUE "  통계 정보: 현재 세션의 통계 및 로그 확인"
    
    echo
    print_color $CYAN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color $GREEN "아무 키나 누르면 모니터링으로 돌아갑니다..."
    read -n 1
}

# 키 입력 처리
handle_key_input() {
    local key=$1
    
    case $key in
        [Aa])
            if [ "$AUTO_CLEANUP" = true ]; then
                AUTO_CLEANUP=false
                print_color $YELLOW "자동 정리 비활성화"
                log_message "INFO" "Auto cleanup disabled"
            else
                AUTO_CLEANUP=true
                print_color $GREEN "자동 정리 활성화"
                log_message "INFO" "Auto cleanup enabled"
            fi
            ;;
        [Mm])
            print_color $CYAN "🧹 수동 정리 실행..."
            local zombie_count=$(count_zombies)
            if [ $zombie_count -gt 0 ]; then
                ((TOTAL_DETECTED += zombie_count))
                print_color $YELLOW "🎯 $zombie_count개 좀비 프로세스 발견 - 정리 시작!"
                log_message "MANUAL" "Manual cleanup started for $zombie_count zombies"
                
                # 서브셸 문제 해결을 위해 배열 사용
                local zombies=()
                while read pid ppid cmd; do
                    zombies+=("$pid:$ppid:$cmd")
                done < <(detect_zombies)
                
                for zombie_info in "${zombies[@]}"; do
                    IFS=':' read -r pid ppid cmd <<< "$zombie_info"
                    cleanup_zombie "$pid" "$ppid" "$cmd"
                done
                
                print_color $GREEN "✅ 수동 정리 완료"
            else
                print_color $GREEN "정리할 좀비 프로세스가 없습니다."
            fi
            ;;
        [Ss])
            show_statistics
            ;;
        [Qq])
            print_color $GREEN "모니터링을 종료합니다."
            log_message "INFO" "Monitor session ended"
            cleanup_lock
            exit 0
            ;;
        [Hh])
            show_help
            ;;
    esac
}

# 설정 파일 로드
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # CRLF 문제 해결을 위해 설정 파일을 임시로 변환
        local temp_config=$(mktemp)
        tr -d '\r' < "$CONFIG_FILE" > "$temp_config"
        source "$temp_config"
        rm -f "$temp_config"
        log_message "INFO" "Configuration loaded from $CONFIG_FILE"
    else
        log_message "INFO" "Using default configuration"
    fi
}

# 사용법 출력
usage() {
    echo "🧟 Rocky Linux Zombie Process Monitor v$VERSION"
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     도움말 표시"
    echo "  -v, --verbose  상세 출력"
    echo "  -i, --interval 간격 설정 (초, 기본값: 2)"
    echo "  -a, --auto     자동 정리 활성화 (기본값)"
    echo "  -m, --manual   자동 정리 비활성화"
    echo "  -d, --daemon   백그라운드 데몬 모드"
    echo "  --version      버전 정보 표시"
    echo ""
    echo "예시:"
    echo "  $0                    # 기본 모드"
    echo "  $0 -i 5              # 5초 간격"
    echo "  $0 -m                # 수동 모드"
    echo "  $0 -v -i 3           # 상세 출력, 3초 간격"
    echo "  $0 -d                # 백그라운드 데몬 모드"
}

# 메인 함수
main() {
    # 명령행 인수 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                echo "🧟 Rocky Linux Zombie Process Monitor v$VERSION"
                echo "작성자: Tae-system"
                echo "업데이트: 2025-01-27"
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -i|--interval)
                REFRESH_INTERVAL="$2"
                shift 2
                ;;
            -a|--auto)
                AUTO_CLEANUP=true
                shift
                ;;
            -m|--manual)
                AUTO_CLEANUP=false
                shift
                ;;
            -d|--daemon)
                DAEMON_MODE=true
                shift
                ;;
            *)
                print_color $RED "알 수 없는 옵션: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # 설정 파일 로드
    load_config
    
    # 락 파일 확인
    check_lock
    
    # 신호 처리 설정
    trap cleanup_lock EXIT INT TERM
    
    # 터미널 설정
    stty -echo -icanon time 0 min 0 2>/dev/null
    
    # 시작 로그
    log_message "INFO" "Zombie monitor v$VERSION started (PID: $$, Interval: ${REFRESH_INTERVAL}s, Auto: $AUTO_CLEANUP, Daemon: $DAEMON_MODE)"
    
    if [ "$DAEMON_MODE" = true ]; then
        print_color $GREEN "🚀 Zombie Process Monitor v$VERSION 데몬 모드 시작"
        print_color $YELLOW "백그라운드에서 실행 중... (PID: $$)"
        log_message "INFO" "Running in daemon mode"
    else
        print_color $GREEN "🚀 Zombie Process Monitor v$VERSION 시작"
        print_color $YELLOW "Ctrl+C로 종료하거나 Q키를 눌러주세요."
        sleep 2
    fi
    
    # 메인 루프
    while true; do
        if [ "$DAEMON_MODE" != true ]; then
            show_header
            show_status
        fi
        
        # 자동 정리 실행
        if [ "$AUTO_CLEANUP" = true ]; then
            local zombie_count=$(count_zombies)
            if [ $zombie_count -gt 0 ]; then
                ((TOTAL_DETECTED += zombie_count))
                print_color $YELLOW "🤖 자동 정리 실행 중... ($zombie_count개 감지)"
                log_message "AUTO" "Auto cleanup triggered for $zombie_count zombies"
                
                # 서브셸 문제 해결을 위해 배열 사용
                local zombies=()
                while read pid ppid cmd; do
                    zombies+=("$pid:$ppid:$cmd")
                done < <(detect_zombies)
                
                for zombie_info in "${zombies[@]}"; do
                    IFS=':' read -r pid ppid cmd <<< "$zombie_info"
                    cleanup_zombie "$pid" "$ppid" "$cmd"
                    sleep "$CLEANUP_DELAY"
                done
            fi
        fi
        
        # 키 입력 확인 (논블로킹) - 데몬 모드가 아닐 때만
        if [ "$DAEMON_MODE" != true ]; then
            key=$(dd bs=1 count=1 2>/dev/null)
            if [ -n "$key" ]; then
                handle_key_input "$key"
            fi
        fi
        
        sleep "$REFRESH_INTERVAL"
    done
}

# 스크립트 실행
main "$@"
