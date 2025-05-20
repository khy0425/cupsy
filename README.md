# Cupsy - 감정 음료 시각화 앱

<p align="center">
  <img src="assets/images/app_icon.png" width="150" alt="Cupsy 로고">
</p>

<p align="center">
  <b>당신의 감정을 음료로 표현해보세요</b><br>
  <i>Express your emotions as a beverage</i>
</p>

## 📱 소개 (Introduction)

Cupsy는 사용자의 감정과 상황을 선택하면, 그에 맞는 색상, 점도, 패턴을 기반으로 감정을 음료 형태로 시각화해주는 앱입니다. 하루에 한 번, 자신의 감정을 아름다운 시각적 표현으로 기록하고 공유할 수 있습니다.

*Cupsy is an app that visualizes emotions as beverages based on colors, viscosity, and patterns that match the user's selected emotion and situation. Once a day, you can record and share your emotions as beautiful visual expressions.*

## ✨ 주요 기능 (Key Features)

- **감정 시각화**: 8가지 감정을 다양한 컬러와 패턴으로 표현
  - *Emotion Visualization: Express 8 different emotions with various colors and patterns*
  
- **상황 맞춤형**: 다양한 상황에 따른 감정 표현 가능
  - *Situation-specific: Customize emotions based on different situations*
  
- **하루 한 잔**: 매일 한 번씩 감정을 기록하고 SNS에 공유
  - *Once a day: Record your emotions once a day and share them on SNS*
  
- **미니멀한 UX**: 간결하고 직관적인 사용자 경험
  - *Minimal UX: Simple and intuitive user experience*

## 🛠️ 기술 스택 (Tech Stack)

- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Riverpod**: 상태 관리
- **CustomPainter**: 감정 음료 시각화
- **Google AdMob**: 광고 통합
- **Share Plus**: SNS 공유 기능

## 📸 스크린샷 (Screenshots)

<p align="center">
  <img src="screenshots/home_screen.png" width="200" alt="홈 화면">
  <img src="screenshots/emotion_screen.png" width="200" alt="감정 선택 화면">
  <img src="screenshots/situation_screen.png" width="200" alt="상황 선택 화면">
  <img src="screenshots/result_screen.png" width="200" alt="결과 화면">
</p>

## 🚀 시작하기 (Getting Started)

### 사전 요구사항 (Prerequisites)

- Flutter 3.7.2 이상
- Dart SDK 2.19.0 이상

### 설치 및 실행 (Installation and Run)

```bash
# 저장소 클론
git clone https://github.com/khy0425/cupsy.git

# 디렉토리 이동
cd cupsy

# 종속성 설치
flutter pub get

# 앱 실행
flutter run
```

## 🧩 아키텍처 (Architecture)

- **모델 (Model)**: 감정, 상황, 감정 컵 데이터 모델
- **화면 (Screens)**: 홈, 감정 선택, 상황 선택, 결과 화면
- **위젯 (Widgets)**: 재사용 가능한 UI 컴포넌트
- **공급자 (Providers)**: Riverpod 기반 상태 관리
- **유틸리티 (Utils)**: 공통 기능 및 서비스

## 📝 라이센스 (License)

MIT 라이센스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 👨‍💻 기여하기 (Contributing)

기여는 언제나 환영합니다! [CONTRIBUTING.md](CONTRIBUTING.md) 파일을 참조하세요.

## 📧 문의하기 (Contact)

프로젝트 관련 문의사항은 이메일 [osu355@gmail.com](mailto:osu355@gmail.com)로 보내주세요.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/khy0425">khy0425</a>
</p>
