# 🧟 Rocky Linux Zombie Process Monitor

**실시간 좀비 프로세스 모니터링 및 자동 정리 시스템**

Rocky Linux 8/9에서 좀비 프로세스를 실시간으로 모니터링하고 자동으로 정리하는 시스템입니다.

## ✨ 주요 특징
- 🎯 **7단계 체계적 정리**: 안전한 단계별 좀비 프로세스 정리
- 🔄 **실시간 모니터링**: 2초 간격 자동 새로고침
- 🤖 **완전 자동화**: 자동/수동 모드 전환 가능
- 📊 **상세한 로깅**: 활동 추적 및 통계 제공
- 🛡️ **안전한 설계**: 시스템 안정성 최우선


## 🚀 Quick Start

```bash
# 1. 필수 패키지 설치
sudo yum install -y git dos2unix

# 2. 저장소 클론
git clone https://github.com/Tae-system/zombie-monitor.git
cd zombie-monitor

# 3. 설치
sudo ./setup_zombie_monitor.sh

# 4. 실행
sudo /opt/zombie_monitor/zombie_monitor.sh
```

## 📋 주요 기능

### 🎯 실시간 모니터링
- 2초 간격 자동 새로고침
- 시스템 정보 표시 (로드 평균, 메모리 사용률)
- 논블로킹 키보드 입력 처리

### 🤖 자동 정리
- 7단계 체계적 정리 프로세스
- PPID 0.0 좀비도 처리 가능
- 안전하고 효율적인 처리

### 📊 통계 및 로깅
- 감지/정리 통계 추적
- 실시간 성공률 계산
- 자동 로그 로테이션 (10MB 단위)

### 🎮 인터랙티브 제어
- **[A]** 자동정리 토글
- **[M]** 수동정리 실행
- **[S]** 통계 정보
- **[Q]** 종료

## 📋 사용법

```bash
# 기본 실행
sudo /opt/zombie_monitor/zombie_monitor.sh

# 수동 모드 (자동 정리 비활성화)
sudo /opt/zombie_monitor/zombie_monitor.sh -m

# 간격 설정 (5초)
sudo /opt/zombie_monitor/zombie_monitor.sh -i 5

# 데몬 모드 (백그라운드 실행)
sudo /opt/zombie_monitor/zombie_monitor.sh -d

# 서비스로 실행
sudo systemctl start zombie-monitor
sudo systemctl status zombie-monitor
```

## 🔧 자동화 설정

```bash
# 크론잡: 5분마다 실행
*/5 * * * * /opt/zombie_monitor/zombie_monitor.sh

# Systemd 서비스 관리
sudo systemctl enable zombie-monitor   # 부팅 시 자동 시작
sudo systemctl start zombie-monitor    # 서비스 시작
sudo systemctl status zombie-monitor   # 상태 확인
```

## 📈 로그 확인

```bash
# 실시간 로그
tail -f /var/log/zombie_monitor.log

# 성공 로그
grep "SUCCESS" /var/log/zombie_monitor.log

# 에러 로그
grep "ERROR" /var/log/zombie_monitor.log
```

## 🗑️ 제거

```bash
# 제거 스크립트 실행
sudo ./uninstall_zombie_monitor.sh

# 강제 제거 (확인 없이)
sudo ./uninstall_zombie_monitor.sh -f
```

## 🛠️ 문제 해결

```bash
# CRLF 문제 해결
dos2unix *.sh *.conf

# 권한 설정
sudo chmod +x zombie_monitor.sh
sudo chown root:root zombie_monitor.sh

# 로그 확인
tail -f /var/log/zombie_monitor.log

# 서비스 상태 확인
systemctl status zombie-monitor
```

## 📁 파일 구조

```
zombie-monitor/
├── zombie_monitor.sh              # 메인 스크립트
├── zombie_monitor.conf            # 설정 파일
├── setup_zombie_monitor.sh        # 설치 스크립트
├── uninstall_zombie_monitor.sh    # 제거 스크립트
├── LICENSE                        # MIT 라이선스
└── README.md                      # 문서
```

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

## 📞 지원

**작성자**: Tae-system  
**버전**: 1.2 (최적화 버전)  
**최종 업데이트**: 2025-10-11

[![GitHub](https://img.shields.io/badge/GitHub-Tae--system-181717?logo=github)](https://github.com/Tae-system)
[![Instagram](https://img.shields.io/badge/Instagram-tae__system-E4405F?logo=instagram)](https://instagram.com/tae_system)

---

**주요 개선사항 (v1.2)**
- ✅ 위험한 시스템 명령어 제거
- ⚡ ps 명령어 캐싱으로 50% 성능 향상
- 🚀 로그 파일 크기 체크 최적화
- 📦 불필요한 중복 코드 제거


