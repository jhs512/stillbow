# Stillbow — Geometry Trials

[학생용 제작 과정과 핵심 프롬프트](https://jhs512.github.io/stillbow/) · [GitHub 소스](https://github.com/jhs512/stillbow)

Godot 4.5.1 궁수 게임 시제품. 로그인 없이 바로 전투가 시작됩니다. 플레이어와 아레나는 생성한 PNG 이미지를 사용하고, 적·투사체·UI는 도형 렌더링으로 표현합니다. 플레이어는 희미한 투명 여백을 제외해 높이 76픽셀로 표시하며 조준 방향에 따라 부드럽게 회전합니다. 밉맵으로 축소 품질을 보정하고, 바닥은 비율을 유지해 잘라 배치합니다. 기존 전투 판정은 유지하며 이동 경계는 커진 이미지가 벽에 잘리지 않도록 안쪽으로 조정했습니다.

## 플레이

`powershell -ExecutionPolicy Bypass -File .\play.ps1`로 실행하거나 Godot에서 `project.godot`을 가져온 뒤 F6으로 실행합니다. 이 컴퓨터의 독립 실행 엔진은 `%LOCALAPPDATA%\CodexGameTools`에 있습니다.

- WASD / 방향키: 이동, 회피
- 화면 드래그: 마우스 또는 터치 가상 조이스틱
- 정지: 가장 가까운 적에게 자동 사격
- P / Esc / 오른쪽 위 II: 일시 정지
- 웨이브 클리어: 카드 클릭 또는 1/2/3으로 강화 선택
- R / 종료 화면 PLAY AGAIN: 재시작

붉은 마름모는 추격하고 노란 사각형은 좌우로 움직입니다. 둘 다 조준 투사체를 발사하며 발사 직전 테두리가 표시됩니다. 최대 체력 6, 피격 후 1초 무적, 총 5웨이브입니다. 이동 중에는 사격하지 않습니다.

## 레퍼런스와 범위

참고: [Habby Archero 공식 Google Play](https://play.google.com/store/apps/details?id=com.habby.archero). 공식 설명의 웨이브, 강화 조합, 사망 후 재시작 구조를 작은 독립 시제품으로 구성했습니다. 정지 자동 사격은 요청된 핵심 조작 방식입니다. 원작 이미지나 이름을 게임 자산에 사용하지 않았습니다.

Android를 고려한 540×900 세로 화면과 터치 입력을 구현했습니다. Android APK 내보내기는 CI에서 수행하며 실제 Android 기기 플레이 검증은 아직 진행하지 않았습니다. 상점, 계정, 광고, 저장 진행도는 포함하지 않습니다.

## 자동 빌드

`main`에 푸시할 때마다 `.github/workflows/build.yml`이 Godot 4.5.1과 같은 버전의 내보내기 템플릿으로 Android와 Windows를 빌드합니다. Actions 탭의 **Build Android and Windows**에서 **Run workflow**로 수동 실행할 수도 있습니다. 각 작업은 리소스 가져오기와 기존 전투 동작 검사를 먼저 수행합니다.

[최신 테스트 Release](https://github.com/jhs512/stillbow/releases/tag/main-build)의 **Assets**에서 APK와 Windows ZIP을 바로 받으세요. main 빌드 두 개가 모두 성공하면 이 Release가 자동 갱신됩니다. Actions Artifacts에도 14일 동안 보관합니다.

- **Stillbow-windows-x86_64**: 아티팩트 ZIP 안의 게임 ZIP을 풀고 `Stillbow.exe`를 실행합니다. 게임 데이터가 EXE에 포함되어 별도 PCK가 필요 없습니다.
- **Stillbow-android-debug**: ZIP을 풀고 `Stillbow-debug.apk`를 Android에 설치합니다. ARMv7/ARM64용이며 테스트 목적의 디버그 서명입니다. Play Store 제출용 AAB 또는 배포 서명은 만들지 않습니다.

디버그 키는 실행 중 임시 생성되어 저장소·아티팩트에 포함되지 않습니다. 실행마다 키가 달라지므로 다른 실행의 APK로 업데이트할 때 기존 앱을 먼저 제거해야 할 수 있습니다. 배포용 서명키는 사용자가 별도로 관리해야 합니다.

빌드 결과, 엔진 캐시와 서명키는 `.gitignore`에서 제외하고 실제 게임 이미지와 이미지 가져오기 설정은 버전 관리합니다.

설정 참고: [Godot Android 내보내기](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html), [Godot 명령줄 내보내기](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html), [GitHub 빌드 아티팩트](https://docs.github.com/en/actions/tutorials/store-and-share-data).

## 검증

Godot headless import로 스크립트 구문을 검사하고 `--headless --path . --script tests/smoke.gd`로 이동 시 사격 억제, 정지 사격, 적 피격, 무적, 강화, 승리/사망, 재시작, 드래그, 경계를 검사합니다.

`--path . -- --capture`로 실제 렌더링 실행 시 100프레임 후 `artifacts/gameplay-art-v1.png`를 저장합니다. 캡처는 플레이 중인 Godot 뷰포트 이미지입니다. 최초 도형 버전 화면은 `artifacts/gameplay.png`에 보존되어 있습니다.

