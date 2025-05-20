/// 앱 내의 모든 라우팅 경로를 정의하는 클래스입니다.
/// 하드코딩된 문자열 대신 이 상수들을 사용하여 일관성과 유지보수성을 높입니다.
class AppRoutes {
  // 기본 화면
  static const String home = '/';
  static const String emotionSelection = '/emotion';
  static const String situationSelection = '/situation';
  static const String result = '/result';

  // 향후 추가될 화면
  static const String settings = '/settings';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String collection = '/collection';
  static const String stats = '/stats';

  // 딥 링크 처리를 위한 경로
  static const String share = '/share';

  // 로그인/가입 관련 경로 (향후 구현)
  static const String login = '/login';
  static const String register = '/register';

  // 파라미터가 필요한 경로 패턴
  static String emotionDetail(String emotionId) => '/emotion/$emotionId';
  static String situationDetail(String situationId) =>
      '/situation/$situationId';
  static String sharedResult(String resultId) => '/share/$resultId';
  static String collectionDetail(String itemId) => '/collection/$itemId';
}
