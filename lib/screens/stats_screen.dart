import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cupsy/models/emotion_model.dart';
import 'package:cupsy/models/situation.dart';
import 'package:cupsy/services/emotion_stats_service.dart';
import 'package:cupsy/services/analytics_service.dart';
import 'package:cupsy/services/error_handling_service.dart';
import 'package:cupsy/theme/app_theme.dart';
import 'package:cupsy/widgets/app_scaffold.dart';

/// 감정 통계 화면
class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final EmotionStatsService _statsService = EmotionStatsService();

  // 탭 컨트롤러
  late TabController _tabController;

  // 상태 변수
  bool _isLoading = true;
  String _selectedPeriod = '전체';
  final List<String> _periods = ['오늘', '이번 주', '이번 달', '전체'];

  // 데이터
  List<EmotionStat> _emotionStats = [];
  List<SituationStat> _situationStats = [];
  List<TimeOfDayStat> _timeStats = [];
  List<DayOfWeekStat> _dayStats = [];
  Map<String, int> _monthlyStats = {};
  int _totalRecords = 0;
  EmotionStat? _mostFrequentEmotion;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 탭 컨트롤러 초기화
    _tabController = TabController(length: 4, vsync: this);

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // 데이터 로드
    _loadStats();

    // 분석 기록
    AnalyticsService.instance.logScreenView(screenName: 'Stats');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 통계 데이터 로드
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 통계 서비스 초기화
      await _statsService.initialize();

      // 감정별 통계
      _emotionStats = await _statsService.getEmotionStats();

      // 상황별 통계
      _situationStats = await _statsService.getSituationStats();

      // 시간대별 통계
      _timeStats = await _statsService.getTimeOfDayStats();

      // 요일별 통계
      _dayStats = await _statsService.getDayOfWeekStats();

      // 월별 통계
      _monthlyStats = await _statsService.getMonthlyRecordCounts();

      // 가장 많이 기록한 감정
      _mostFrequentEmotion = await _statsService.getMostFrequentEmotion();

      // 전체 기록 수
      final allRecords = await _statsService.getAllRecords();
      _totalRecords = allRecords.length;

      // 애니메이션 시작
      _animationController.forward();
    } catch (e, stackTrace) {
      ErrorHandlingService.logError(
        '통계 데이터 로드 실패',
        error: e,
        stackTrace: stackTrace,
      );

      _showErrorSnackBar();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 기간 선택에 따라 데이터 필터링
  Future<void> _filterByPeriod(String period) async {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });

    try {
      // TODO: 실제로는 선택한 기간에 맞게 통계 서비스에서 데이터를 필터링해야 합니다.
      // 현재는 기간 변경을 위한 UI만 구현된 상태입니다.

      // 데이터 새로고침을 위한 지연
      await Future.delayed(const Duration(milliseconds: 500));

      // 애니메이션 재시작
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      _showErrorSnackBar();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 오류 스낵바 표시
  void _showErrorSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('통계 데이터를 불러오는 중 오류가 발생했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '감정 통계',

      // 앱바 액션
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadStats,
          tooltip: '통계 새로고침',
        ),
      ],

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 요약 정보 카드
                  _buildSummaryCard(),

                  // 기간 선택 필터
                  _buildPeriodFilter(),

                  // 탭바
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: '감정별'),
                      Tab(text: '상황별'),
                      Tab(text: '시간대별'),
                      Tab(text: '추세'),
                    ],
                  ),

                  // 탭 콘텐츠
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 감정별 통계
                          _buildEmotionStatsTab(),

                          // 상황별 통계
                          _buildSituationStatsTab(),

                          // 시간대별 통계
                          _buildTimeStatsTab(),

                          // 추세 통계
                          _buildTrendStatsTab(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  /// 요약 정보 카드 위젯
  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 총 기록 수
          Expanded(
            child: Column(
              children: [
                const Text(
                  '총 기록',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalRecords회',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // 구분선
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),

          // 가장 많은 감정
          Expanded(
            child: Column(
              children: [
                const Text(
                  '가장 많은 감정',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_mostFrequentEmotion != null) ...[
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _mostFrequentEmotion!.emotion.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mostFrequentEmotion!.emotion.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      const Text(
                        '기록 없음',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 기간 선택 필터 위젯
  Widget _buildPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _periods.map((period) {
                final isSelected = period == _selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _filterByPeriod(period);
                      }
                    },
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  /// 감정별 통계 탭 위젯
  Widget _buildEmotionStatsTab() {
    if (_emotionStats.isEmpty) {
      return const Center(
        child: Text(
          '감정 기록이 없습니다.\n감정을 기록하면 통계를 볼 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 16),

        // 감정 파이 차트
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sections:
                  _emotionStats
                      .take(5) // 상위 5개만
                      .map(
                        (stat) => PieChartSectionData(
                          value: stat.count.toDouble(),
                          color: stat.emotion.color,
                          title: '${stat.percentage.toStringAsFixed(1)}%',
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                      .toList(),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              startDegreeOffset: 180,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 범례
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children:
                _emotionStats
                    .map(
                      (stat) => _buildLegendItem(
                        color: stat.emotion.color,
                        title: stat.emotion.name,
                        value:
                            '${stat.count}회 (${stat.percentage.toStringAsFixed(1)}%)',
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  /// 상황별 통계 탭 위젯
  Widget _buildSituationStatsTab() {
    if (_situationStats.isEmpty) {
      return const Center(
        child: Text(
          '감정 기록이 없습니다.\n감정을 기록하면 통계를 볼 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 24),

        // 상황별 막대 차트
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  _situationStats
                      .map((s) => s.count.toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                  1.2,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _situationStats.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _situationStats[value.toInt()].situation.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                _situationStats.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: _situationStats[index].count.toDouble(),
                      color: AppTheme.primaryColor,
                      width: 40,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 상황별 세부 정보
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상황별 세부 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                _situationStats.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _situationStats[index].situation.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '${_situationStats[index].count}회',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시간대별 통계 탭 위젯
  Widget _buildTimeStatsTab() {
    if (_timeStats.isEmpty || _dayStats.isEmpty) {
      return const Center(
        child: Text(
          '감정 기록이 없습니다.\n감정을 기록하면 통계를 볼 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),

        // 시간대별 섹션
        const Text(
          '시간대별 감정 기록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 시간대 차트
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _timeStats.map((stat) {
                  final maxCount = _timeStats
                      .map((s) => s.count)
                      .reduce((a, b) => a > b ? a : b);
                  final percentage = maxCount > 0 ? stat.count / maxCount : 0;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${stat.count}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          height: percentage * 120,
                          width: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stat.timeSlot.split(' ')[0],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // 요일별 섹션
        const Text(
          '요일별 감정 기록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 요일별 현황
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children:
                _dayStats.map((stat) {
                  final maxCount = _dayStats
                      .map((s) => s.count)
                      .reduce((a, b) => a > b ? a : b);
                  final percentage = maxCount > 0 ? stat.count / maxCount : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                stat.dayName.substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                    height: 8,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.6 *
                                        percentage,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${stat.count}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// 추세 통계 탭 위젯
  Widget _buildTrendStatsTab() {
    if (_monthlyStats.isEmpty) {
      return const Center(
        child: Text(
          '감정 기록이 없습니다.\n감정을 기록하면 통계를 볼 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // 월별 데이터 변환 (최근 6개월)
    final monthlyData =
        _monthlyStats.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final last6Months =
        monthlyData.length > 6
            ? monthlyData.sublist(monthlyData.length - 6)
            : monthlyData;

    // x축 라벨 생성
    final xLabels =
        last6Months.map((entry) {
          final parts = entry.key.split('.');
          final month = int.parse(parts[1]);
          return DateFormat('M월').format(DateTime(2023, month, 1));
        }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),

        // 추세 설명
        const Text(
          '월별 감정 기록 추세',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 추세 차트
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    last6Months.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      last6Months[index].value.toDouble(),
                    ),
                  ),
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= xLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          xLabels[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 월별 세부 정보
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '월별 감정 기록 횟수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...List.generate(last6Months.length, (index) {
                final entry = last6Months[index];
                final parts = entry.key.split('.');
                final year = parts[0];
                final month = int.parse(parts[1]);
                final monthName = DateFormat(
                  'yyyy년 M월',
                ).format(DateTime(int.parse(year), month, 1));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          monthName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${entry.value}회',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// 범례 아이템 위젯
  Widget _buildLegendItem({
    required Color color,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
