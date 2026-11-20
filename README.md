# PandaToggle

판다VPN-Fast Connect의 연결 상태를 macOS 메뉴 막대에 판다 아이콘으로 표시하고, 클릭 한 번으로 켜고 끄는 작은 앱입니다.

- 왼쪽 클릭: VPN 켜기/끄기
- 오른쪽 클릭: 현재 서버 이름, 켜기/끄기, 판다 앱 열기, 종료
- 초록 판다 + ON: 연결됨 / 회색 판다 + OFF: 끊김 / 주황 판다 + …: 연결하거나 끊는 중

macOS VPN 설정 중 종류가 `com.panda.fastconnect`인 항목을 찾아 `scutil --nc start/stop`으로 제어합니다. 서버를 바꿔 설정 이름이 달라져도 그대로 동작합니다.

## 빌드와 설치

```bash
./build.sh          # build/PandaToggle.app만 만든다
./build.sh install  # /Applications에 설치하고 로그인 항목에 등록한 뒤 실행한다
```
