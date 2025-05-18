# Cupsy 기여 가이드라인

Cupsy 프로젝트에 기여하는 데 관심을 가져주셔서 감사합니다! 이 문서는 프로젝트에 기여하기 위한 가이드라인을 제공합니다.

## 기여 방법

1. 이 저장소를 포크(Fork)합니다.
2. 기능 브랜치를 생성합니다. (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다. (`git commit -m '멋진 기능 추가'`)
4. 브랜치에 푸시합니다. (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다.

## 개발 환경 설정

1. Flutter SDK 설치 (버전 3.7.2 이상)
2. Dart SDK 설치 (버전 2.19.0 이상)
3. 관련 에디터 설치 (VSCode 추천)
4. 프로젝트 클론
   ```bash
   git clone https://github.com/yourusername/cupsy.git
   cd cupsy
   flutter pub get
   ```

## 코드 스타일

- [Flutter 공식 스타일 가이드](https://dart.dev/guides/language/effective-dart/style)를 따릅니다.
- 모든 코드는 Dart 분석기를 통과해야 합니다.
- 주석은 한글로 작성합니다.

## 테스트

새로운 기능을 추가하거나 기존 기능을 수정할 때는 적절한 테스트도 함께 작성해주세요.
```bash
flutter test
```

## 이슈 보고

버그를 발견하거나 새로운 기능을 제안하고 싶다면, 먼저 이슈를 생성해주세요.

1. 해당 이슈가 이미 존재하는지 확인합니다.
2. 명확하고 설명적인 제목을 사용합니다.
3. 문제 상황이나 기능 요청을 상세히 설명합니다.
4. 가능하다면 스크린샷이나 코드 예제를 첨부합니다.

## Pull Request 프로세스

1. 모든 PR은 개발 브랜치(`develop`)를 대상으로 합니다.
2. PR에는 변경 사항에 대한 명확한 설명이 포함되어야 합니다.
3. PR이 승인되면 병합됩니다.

## 질문이 있으신가요?

질문이 있으시면 [이슈](https://github.com/khy0425/cupsy/issues)를 생성하거나 이메일(email@example.com)로 문의해주세요. 