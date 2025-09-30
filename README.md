# 🧟 Rocky Linux Zombie Process Monitor

**실시간 좀비 프로세스 모니터링 및 자동 정리 시스템**

Rocky Linux 8/9에서 좀비 프로세스를 실시간으로 모니터링하고 자동으로 정리하는 시스템입니다.

## 주요 특징
- 🎯 **7단계 체계적 정리**: 체계적인 좀비 프로세스 정리 과정
- 🔄 **실시간 모니터링**: 2초마다 자동 새로고침
- 🤖 **완전 자동화**: 수동 개입 없이 자동 정리
- 📊 **상세한 로깅**: 모든 활동 추적 및 통계 제공
- 🛡️ **안전한 설계**: 시스템 안정성 고려

---

## 📋 목차

- [✨ 주요 기능](#-주요-기능)
- [🚀 Quick Start](#-quick-start)
- [📋 사용법](#-사용법)
- [🔧 자동화 설정](#-자동화-설정)
- [📈 모니터링 및 로깅](#-모니터링-및-로깅)
- [🗑️ 완전 제거](#️-완전-제거)
- [🛠️ 문제 해결](#️-문제-해결)
- [📁 파일 구조](#-파일-구조)
- [🤝 기여하기](#-기여하기)
- [🆘 지원](#-지원)


## 설치 및 실행

### 사전 준비 (Rocky Linux 8/9)

```bash
# 필수 패키지 설치
sudo yum update -y
sudo yum install -y git dos2unix

# 파일 권한 설정
sudo chmod +x *.sh
sudo chown root:root *.sh *.conf

# CRLF 문제 해결 (필요시)
dos2unix *.sh *.conf
```

### 설치 및 실행

```bash
# 설치
sudo ./setup_zombie_monitor.sh

# 실시간 모니터링 시작
sudo /opt/zombie_monitor/zombie_monitor.sh

# 제거 (필요시)
sudo ./uninstall_zombie_monitor.sh
```

## 주요 기능

### 🎯 실시간 모니터링
- 2초 간격 자동 새로고침으로 지속적인 시스템 감시
- 직관적인 상태 정보 제공
- 시스템 정보 표시 (로드 평균, 메모리 사용률 등)
- 논블로킹 키보드 처리

### 🤖 자동 정리
- 좀비 프로세스 발견 시 즉시 처리
- 7단계 체계적인 정리 프로세스
- 시스템 레벨 처리 (PPID 0.0 좀비도 처리 가능)
- 안전하고 효율적인 정리

### 📊 통계 및 로깅
- 감지/정리된 좀비 수 추적
- 실시간 성공률 계산
- 모든 활동을 로그로 기록
- 자동 로그 파일 관리

### 🎮 인터랙티브 제어
- 단축키 지원 ([A]자동정리, [M]수동정리, [S]통계, [Q]종료)
- 모니터링 중에도 키 입력 가능
- 내장 도움말 시스템
- 안전한 종료 및 재시작

### 🔥 7단계 정리 과정

```mermaid
graph TD
    A[좀비 프로세스 감지] --> B[1단계: 안정적 정리]
    B --> C{성공?}
    C -->|Yes| D[✅ 정리 완료]
    C -->|No| E[2단계: 강력한 정리]
    E --> F{성공?}
    F -->|Yes| D
    F -->|No| G[3단계: 시스템 레벨 정리]
    G --> H{성공?}
    H -->|Yes| D
    H -->|No| I[4단계: 프로세스 트리 정리]
    I --> J{성공?}
    J -->|Yes| D
    J -->|No| K[5단계: 최종 강제 정리]
    K --> L{성공?}
    L -->|Yes| D
    L -->|No| M[6단계: 커널 레벨 정리]
    M --> N{성공?}
    N -->|Yes| D
    N -->|No| O[7단계: 절대 강제 정리]
    O --> P{성공?}
    P -->|Yes| D
    P -->|No| Q[⚠️ 정리 실패 - 통계 기록]
```

### v1.1 신기능

- 향상된 통계 (정리 실패 수, 세션 시간 추가)
- 자동 로그 로테이션 (10MB 초과 시 자동 로그 순환)
- 성능 최적화 (ps 명령어 호출 최적화)
- 데몬 모드 (백그라운드 실행 지원)
- 버전 관리 (버전 정보 및 업데이트 날짜 추가)

## 📋 사용법

### 기본 사용법

```bash
# 실시간 모니터링 (기본 모드, 2초 간격)
sudo /opt/zombie_monitor/zombie_monitor.sh

# 수동 모드 (자동 정리 비활성화)
sudo /opt/zombie_monitor/zombie_monitor.sh -m

# 5초 간격으로 모니터링
sudo /opt/zombie_monitor/zombie_monitor.sh -i 5

# 상세 출력 모드
sudo /opt/zombie_monitor/zombie_monitor.sh -v

# 백그라운드 데몬 모드 (신기능!)
sudo /opt/zombie_monitor/zombie_monitor.sh -d

# 버전 정보 확인
sudo /opt/zombie_monitor/zombie_monitor.sh --version

# 도움말 표시
sudo /opt/zombie_monitor/zombie_monitor.sh -h
```

### 고급 옵션

```bash
# 데몬 모드로 백그라운드 실행 (v1.1 신기능!)
sudo /opt/zombie_monitor/zombie_monitor.sh -d

# 기존 방식 백그라운드 실행
nohup sudo /opt/zombie_monitor/zombie_monitor.sh > /dev/null 2>&1 &

# 서비스로 실행
sudo systemctl start zombie-monitor

# 서비스 상태 확인
sudo systemctl status zombie-monitor

# 서비스 중지
sudo systemctl stop zombie-monitor

# 서비스 재시작
sudo systemctl restart zombie-monitor

# 데몬 모드 + 자동 정리 비활성화
sudo /opt/zombie_monitor/zombie_monitor.sh -d -m

# 데몬 모드 + 5초 간격 + 상세 출력
sudo /opt/zombie_monitor/zombie_monitor.sh -d -i 5 -v
```

### 🎮 실시간 모니터링 단축키

| 단축키 | 기능 | 설명 |
|--------|------|------|
| **[A]** | 자동 정리 토글 | 활성화/비활성화 전환 |
| **[M]** | 수동 정리 실행 | 7단계 정리 과정 실행 |
| **[S]** | 통계 정보 표시 | 세션 통계 + 최근 로그 |
| **[Q]** | 모니터링 종료 | 안전한 종료 |
| **[H]** | 도움말 표시 | 내장 도움말 |
| **Ctrl+C** | 강제 종료 | 터미널 설정 자동 복원 |

### 📊 실시간 모니터링 화면 예시

```
╔══════════════════════════════════════════════════════════════╗
║                🧟 ZOMBIE PROCESS MONITOR                    ║
║                    실시간 모니터링                          ║
╚══════════════════════════════════════════════════════════════╝

💡 단축키: [A]자동정리 [M]수동정리 [S]통계 [Q]종료 [H]도움말

📊 현재 상태 (2025-09-27 18:42:31)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Zombie 프로세스: 0개 (정상)
💻 시스템 정보:
  로드 평균: 0.27
  메모리 사용률: 4.8%

⚙️  설정:
  자동 정리: 활성화
  새로고침 간격: 2초
  경고 임계값: 5개

📈 세션 통계:
  감지된 좀비: 5개
  정리된 좀비: 3개
  정리 실패: 1개
  정리 성공률: 75%
  세션 시간: 0시간 2분 15초
  세션 시작: 2025-09-30 18:40:30

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
실시간 모니터링 중... (2초마다 새로고침)
```

## 🔧 자동화 설정

### 크론잡 설정
```bash
# 5분마다 실행
*/5 * * * * /opt/zombie_monitor/zombie_monitor.sh

# 매일 새벽 2시에 정리
0 2 * * * /opt/zombie_monitor/zombie_monitor.sh -v
```

### Systemd 서비스
```bash
# 서비스 상태 확인
sudo systemctl status zombie-monitor

# 서비스 시작/중지
sudo systemctl start zombie-monitor
sudo systemctl stop zombie-monitor

# 서비스 재시작
sudo systemctl restart zombie-monitor

# 서비스 활성화/비활성화
sudo systemctl enable zombie-monitor
sudo systemctl disable zombie-monitor
```

> **⚠️ 주의**: 서비스는 자동 시작되지 않습니다. 수동으로 시작하세요:
> ```bash
> sudo systemctl start zombie-monitor
> ```

## 📈 모니터링 및 로깅

### 로그 파일
```bash
# 실시간 로그 모니터링
tail -f /var/log/zombie_monitor.log

# 특정 시간대 로그 확인
grep "2025-09-27 14:" /var/log/zombie_monitor.log

# 에러 로그 확인
grep -i "error" /var/log/zombie_monitor.log
```

### 로그 분석
```bash
# 좀비 프로세스 관련 로그만 필터링
grep "Zombie" /var/log/zombie_monitor.log

# 정리 성공 로그 확인
grep "SUCCESS" /var/log/zombie_monitor.log

# 에러 로그 확인
grep "ERROR" /var/log/zombie_monitor.log

# 7단계 정리 과정 로그 확인
grep "단계" /var/log/zombie_monitor.log
```

## 🗑️ 완전 제거

설치된 zombie monitor 시스템을 완전히 제거하려면:

```bash
# 확인 후 제거 (권장)
sudo ./uninstall_zombie_monitor.sh

# 강제 제거 (확인 없이)
sudo ./uninstall_zombie_monitor.sh -f

# 제거 확인
ls -la /opt/ | grep zombie
systemctl status zombie-monitor

# 언인스톨 도움말
sudo ./uninstall_zombie_monitor.sh -h
```

### 제거되는 항목
- **📁 스크립트 파일**: `/opt/zombie_monitor/`
- **📄 설정 파일**: `/etc/zombie_monitor.conf`
- **📄 로그 파일**: `/var/log/zombie_monitor.log`
- **⚙️ 크론잡 설정**: 모든 zombie 관련 크론잡
- **⚙️ systemd 서비스**: `zombie-monitor.service`
- **⚙️ 로그 로테이션 설정**: `/etc/logrotate.d/zombie-monitor`
- **🔒 락 파일**: `/tmp/zombie_monitor.lock`

## 🛠️ 문제 해결

### 일반적인 문제

#### 1. CRLF 문제
```bash
# 오류: $'\r': command not found
# 해결: dos2unix 설치 및 변환
sudo yum install dos2unix
dos2unix *.sh *.conf

# 또는 sed 명령어 사용
sed -i 's/\r$//' *.sh *.conf
```

#### 2. 권한 오류
```bash
# 스크립트 실행 권한 확인
ls -la zombie_monitor.sh

# 권한 수정
sudo chmod +x zombie_monitor.sh
sudo chown root:root zombie_monitor.sh
```

#### 3. 설정 파일 문제
```bash
# 설정 파일 확인
cat /etc/zombie_monitor.conf

# 설정 파일 권한 수정
sudo chmod 644 /etc/zombie_monitor.conf
sudo chown root:root /etc/zombie_monitor.conf
```

#### 4. 실시간 모니터링 문제
```bash
# 모니터링 스크립트 실행 권한 확인
chmod +x zombie_monitor.sh

# 모니터링 스크립트 테스트
./zombie_monitor.sh -h

# 로그 파일 확인
tail -f /var/log/zombie_monitor.log
```

#### 5. 좀비 프로세스 정리 실패 문제
```bash
# PPID 0.0인 시스템 레벨 좀비 확인
ps aux | awk '$8 ~ /^Z/ { print $2, $3, $11 }'

# 7단계 정리 시스템으로 수동 정리
sudo /opt/zombie_monitor/zombie_monitor.sh
# [M] 키를 눌러 수동 정리 실행

# 부모 프로세스 강제 종료 (위험)
sudo kill -9 [부모_PID]

# 시스템 재부팅 (최후의 수단)
sudo reboot
```

#### 6. 로그 파일 문제
```bash
# 로그 파일 권한 확인
ls -la /var/log/zombie_*.log

# 로그 파일 권한 수정
sudo chmod 644 /var/log/zombie_*.log
sudo chown root:root /var/log/zombie_*.log

# 로그 디렉토리 확인
sudo mkdir -p /var/log
```

### 디버깅 명령어

```bash
# 상세 로그 확인
tail -f /var/log/zombie_monitor.log

# 시스템 로그 확인
journalctl -u zombie-monitor -f

# 프로세스 상태 확인
ps aux | grep zombie

# 서비스 상태 확인
systemctl status zombie-monitor

```

## 📁 파일 구조

```
zombie-monitor/
├── 📄 README.md                   # 📖 프로젝트 문서
├── 🧟 zombie_monitor.sh           # 실시간 모니터링 스크립트
├── ⚙️ zombie_monitor.conf         # 설정 파일
├── 🚀 setup_zombie_monitor.sh     # 설치 스크립트
└── 🗑️ uninstall_zombie_monitor.sh # 제거 스크립트
```

### 📋 각 파일의 역할

| 파일 | 역할 | 설명 |
|------|------|------|
| **`zombie_monitor.sh`** | 🧟 메인 스크립트 | 7단계 정리 시스템을 갖춘 실시간 좀비 프로세스 모니터링 |
| **`zombie_monitor.conf`** | ⚙️ 설정 파일 | 모니터링 설정 (CRLF 문제 해결) |
| **`setup_zombie_monitor.sh`** | 🚀 설치 스크립트 | 시스템에 자동 설치 및 설정 (자동 시작 비활성화) |
| **`uninstall_zombie_monitor.sh`** | 🗑️ 제거 스크립트 | 타임아웃 기능이 있는 완전 제거 스크립트 |
| **`README.md`** | 📖 문서 | 최적화된 기능 설명, 사용법, 문제 해결 가이드 |

## 📄 라이선스

이 프로젝트는 **MIT License** 하에 배포됩니다.

### 라이선스 요약
- ✅ **자유로운 사용**: 개인 및 상업적 용도로 자유롭게 사용 가능
- ✅ **수정 허용**: 코드 수정 및 개선 가능  
- ✅ **배포 허용**: 수정된 버전 배포 가능
- ✅ **사유 소프트웨어**: 사유 소프트웨어에 포함 가능
- ⚠️ **저작권 표시**: 원본 저작권 표시 필요
- ⚠️ **면책 조항**: 소프트웨어는 "있는 그대로" 제공되며 보증 없음

자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 지원

**작성자**: Tae-system  
**버전**: 1.1  
**최종 업데이트**: 2025-01-27

### 📱 소셜 미디어

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Tae-system)
[![Instagram](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://instagram.com/tae_system)

</div>


