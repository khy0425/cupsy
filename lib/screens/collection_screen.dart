import 'package:flutter/material.dart';
import 'package:cupsy/models/cup_collection_model.dart';
import 'package:flutter/services.dart';

// 필터 옵션
enum FilterOption {
  all('전체'),
  unlocked('획득한 컵만'),
  locked('미획득 컵만'),
  common('일반'),
  uncommon('고급'),
  rare('희귀'),
  epic('에픽'),
  legendary('전설');

  final String label;
  const FilterOption(this.label);
}

/// 컵 컬렉션 화면
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  // 필터 및 정렬 상태
  FilterOption _currentFilter = FilterOption.all;
  bool _isGridView = true; // true = 그리드 뷰, false = 리스트 뷰
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // 전체 컵 목록
  final List<CupDesign> _allCups = CupDesignsData.allDesigns;

  // 필터링된 컵 목록
  List<CupDesign> get _filteredCups {
    List<CupDesign> result = _allCups;

    // 필터 적용
    switch (_currentFilter) {
      case FilterOption.all:
        result = _allCups;
        break;
      case FilterOption.unlocked:
        result = _allCups.where((cup) => cup.isUnlocked).toList();
        break;
      case FilterOption.locked:
        result = _allCups.where((cup) => !cup.isUnlocked).toList();
        break;
      case FilterOption.common:
        result =
            _allCups.where((cup) => cup.rarity == CupRarity.common).toList();
        break;
      case FilterOption.uncommon:
        result =
            _allCups.where((cup) => cup.rarity == CupRarity.uncommon).toList();
        break;
      case FilterOption.rare:
        result = _allCups.where((cup) => cup.rarity == CupRarity.rare).toList();
        break;
      case FilterOption.epic:
        result = _allCups.where((cup) => cup.rarity == CupRarity.epic).toList();
        break;
      case FilterOption.legendary:
        result =
            _allCups.where((cup) => cup.rarity == CupRarity.legendary).toList();
        break;
    }

    // 검색어 적용
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result =
          result
              .where(
                (cup) =>
                    cup.name.toLowerCase().contains(query) ||
                    (cup.isUnlocked &&
                        cup.description.toLowerCase().contains(query)) ||
                    cup.tags.any((tag) => tag.toLowerCase().contains(query)),
              )
              .toList();
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // 검색어 변경 리스너
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 아이템 터치 시 햅틱 피드백
  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearchVisible
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '컵 이름, 설명 또는 태그 검색',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: const TextStyle(color: Colors.black),
                  autofocus: true,
                )
                : const Text('컵 컬렉션'),
        actions: [
          // 검색 버튼
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: _isSearchVisible ? '검색 닫기' : '컵 검색',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
          ),
          // 필터 메뉴
          PopupMenuButton<FilterOption>(
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
                // 필터 변경 시 애니메이션 재실행
                _animationController.reset();
                _animationController.forward();
              });
            },
            itemBuilder:
                (context) =>
                    FilterOption.values.map((option) {
                      return PopupMenuItem<FilterOption>(
                        value: option,
                        child: Row(
                          children: [
                            if (_currentFilter == option)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.green,
                              )
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(option.label),
                          ],
                        ),
                      );
                    }).toList(),
          ),
          // 보기 방식 전환
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? '리스트 보기' : '그리드 보기',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
                // 보기 방식 변경 시 애니메이션 재실행
                _animationController.reset();
                _animationController.forward();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '전체 컵'), Tab(text: '감정별')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 전체 컵 탭
          _buildCupCollectionView(),

          // 감정별 탭
          _buildEmotionCategoryView(),
        ],
      ),
    );
  }

  // 컵 컬렉션 뷰 (그리드 또는 리스트)
  Widget _buildCupCollectionView() {
    final cups = _filteredCups;

    // 컵이 없는 경우
    if (cups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '컵이 없습니다',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _isSearchVisible = false;
                  });
                },
                child: const Text('검색 초기화'),
              ),
            ],
          ],
        ),
      );
    }

    // 그리드 뷰
    if (_isGridView) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: cups.length,
            itemBuilder: (context, index) {
              // 아이템별 지연 애니메이션 적용
              final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index / (cups.length > 10 ? 10 : cups.length),
                    1.0,
                    curve: Curves.easeInOut,
                  ),
                ),
              );

              return FadeTransition(
                opacity: itemAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.8,
                    end: 1.0,
                  ).animate(itemAnimation),
                  child: _buildCupGridItem(cups[index]),
                ),
              );
            },
          );
        },
      );
    }
    // 리스트 뷰
    else {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cups.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              // 아이템별 지연 애니메이션 적용
              final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index / (cups.length > 10 ? 10 : cups.length),
                    1.0,
                    curve: Curves.easeInOut,
                  ),
                ),
              );

              return FadeTransition(
                opacity: itemAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0.0),
                    end: Offset.zero,
                  ).animate(itemAnimation),
                  child: _buildCupListItem(cups[index]),
                ),
              );
            },
          );
        },
      );
    }
  }

  // 컵 그리드 아이템
  Widget _buildCupGridItem(CupDesign cup) {
    return GestureDetector(
      onTap: () {
        _triggerHapticFeedback();
        _showCupDetails(cup);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              cup.isUnlocked
                  ? BorderSide(color: cup.rarity.color, width: 2)
                  : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 컵 이미지 (잠긴 상태면 흐리게)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 이미지
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        cup.isUnlocked
                            ? Hero(
                              tag: 'cup_${cup.id}',
                              child: Image.asset(
                                cup.assetPath,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_cafe,
                                    size: 80,
                                    color: cup.rarity.color,
                                  );
                                },
                              ),
                            )
                            : ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: Image.asset(
                                cup.assetPath,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_cafe,
                                    size: 80,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                  ),

                  // 잠금 아이콘
                  if (!cup.isUnlocked)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                  // 희귀도 배지
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cup.rarity.color.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cup.rarity.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 컵 이름
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    cup.isUnlocked
                        ? cup.rarity.color.withOpacity(0.1)
                        : Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                cup.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cup.isUnlocked ? cup.rarity.color : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 컵 리스트 아이템
  Widget _buildCupListItem(CupDesign cup) {
    return ListTile(
      onTap: () {
        _triggerHapticFeedback();
        _showCupDetails(cup);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 60,
        height: 60,
        child:
            cup.isUnlocked
                ? Hero(
                  tag: 'cup_${cup.id}',
                  child: Image.asset(
                    cup.assetPath,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_cafe,
                        size: 40,
                        color: cup.rarity.color,
                      );
                    },
                  ),
                )
                : ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        cup.assetPath,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.local_cafe,
                            size: 40,
                            color: Colors.grey,
                          );
                        },
                      ),
                      const Positioned.fill(
                        child: Center(
                          child: Icon(Icons.lock, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
      title: Text(
        cup.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: cup.isUnlocked ? null : Colors.grey[600],
        ),
      ),
      subtitle: Text(
        cup.isUnlocked ? cup.description : '???',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cup.isUnlocked ? null : Colors.grey),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              cup.isUnlocked
                  ? cup.rarity.color.withOpacity(0.2)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cup.isUnlocked ? cup.rarity.color : Colors.grey,
          ),
        ),
        child: Text(
          cup.rarity.name,
          style: TextStyle(
            fontSize: 12,
            color: cup.isUnlocked ? cup.rarity.color : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 감정 카테고리 뷰
  Widget _buildEmotionCategoryView() {
    // 일반적인 감정 카테고리 (추후 감정 모델과 연동)
    final emotionCategories = [
      {
        'name': '기쁨',
        'icon': Icons.sentiment_very_satisfied,
        'color': Colors.amber,
        'tag': 'joy',
      },
      {
        'name': '평온',
        'icon': Icons.sentiment_satisfied,
        'color': Colors.blue,
        'tag': 'calm',
      },
      {
        'name': '슬픔',
        'icon': Icons.sentiment_dissatisfied,
        'color': Colors.indigo,
        'tag': 'sadness',
      },
      {
        'name': '분노',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': Colors.red,
        'tag': 'anger',
      },
      {
        'name': '사랑',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'tag': 'love',
      },
      {
        'name': '불안',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'tag': 'anxiety',
      },
    ];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emotionCategories.length,
          itemBuilder: (context, index) {
            final category = emotionCategories[index];
            final tag = category['tag'] as String;
            final cupsByEmotion = CupDesignsData.filterByTag(tag);
            final unlockedCount =
                cupsByEmotion.where((c) => c.isUnlocked).length;

            // 카테고리별 지연 애니메이션 적용
            final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index / emotionCategories.length,
                  1.0,
                  curve: Curves.easeInOut,
                ),
              ),
            );

            return FadeTransition(
              opacity: itemAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(itemAnimation),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: InkWell(
                    onTap: () {
                      // 특정 감정 태그로 필터링하고 전체 탭으로 이동
                      setState(() {
                        _searchController.text = tag;
                        _searchQuery = tag;
                      });
                      _tabController.animateTo(0);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 카테고리 헤더
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withOpacity(
                              0.2,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                color: category['color'] as Color,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: (category['color'] as Color)
                                      .withOpacity(0.8),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$unlockedCount / ${cupsByEmotion.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (category['color'] as Color),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 컵 프리뷰
                        SizedBox(
                          height: 120,
                          child:
                              cupsByEmotion.isEmpty
                                  ? Center(
                                    child: Text(
                                      '이 감정과 관련된 컵이 없습니다',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: cupsByEmotion.length,
                                    itemBuilder: (context, i) {
                                      final cup = cupsByEmotion[i];
                                      return GestureDetector(
                                        onTap: () {
                                          _triggerHapticFeedback();
                                          _showCupDetails(cup);
                                        },
                                        child: Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child:
                                                    cup.isUnlocked
                                                        ? Hero(
                                                          tag:
                                                              'cup_${cup.id}_preview',
                                                          child: Image.asset(
                                                            cup.assetPath,
                                                            errorBuilder: (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Icon(
                                                                Icons
                                                                    .local_cafe,
                                                                size: 40,
                                                                color:
                                                                    cup
                                                                        .rarity
                                                                        .color,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                        : ColorFiltered(
                                                          colorFilter:
                                                              const ColorFilter.mode(
                                                                Colors.grey,
                                                                BlendMode
                                                                    .saturation,
                                                              ),
                                                          child: Stack(
                                                            fit:
                                                                StackFit.expand,
                                                            children: [
                                                              Image.asset(
                                                                cup.assetPath,
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                                errorBuilder: (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons
                                                                        .local_cafe,
                                                                    size: 40,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  );
                                                                },
                                                              ),
                                                              const Center(
                                                                child: Icon(
                                                                  Icons.lock,
                                                                  color:
                                                                      Colors
                                                                          .white70,
                                                                  size: 24,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cup.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      cup.isUnlocked
                                                          ? null
                                                          : Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 컵 상세 정보 표시
  void _showCupDetails(CupDesign cup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 희귀도 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cup.rarity.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cup.rarity.color),
                ),
                child: Text(
                  cup.rarity.name,
                  style: TextStyle(
                    color: cup.rarity.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 컵 이미지
              SizedBox(
                height: 150,
                child:
                    cup.isUnlocked
                        ? Hero(
                          tag: 'cup_${cup.id}',
                          child: Image.asset(
                            cup.assetPath,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.local_cafe,
                                size: 80,
                                color: cup.rarity.color,
                              );
                            },
                          ),
                        )
                        : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                cup.assetPath,
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_cafe,
                                    size: 80,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                              if (!cup.isUnlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        '잠금',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // 컵 이름
              Text(
                cup.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 획득 시간
              if (cup.isUnlocked && cup.obtainedAt != null)
                Text(
                  '획득: ${_formatDateTime(cup.obtainedAt!)}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 16),

              // 컵 설명
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cup.isUnlocked ? cup.description : '이 컵을 획득하면 설명을 볼 수 있습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: cup.isUnlocked ? Colors.black87 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // 태그
              if (cup.isUnlocked && cup.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children:
                      cup.tags.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            // 태그 클릭 시 해당 태그로 검색
                            Navigator.pop(context);
                            setState(() {
                              _isSearchVisible = true;
                              _searchController.text = tag;
                              _searchQuery = tag;
                            });
                          },
                          child: Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey[200],
                          ),
                        );
                      }).toList(),
                ),

              const SizedBox(height: 20),

              // 닫기 버튼
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 날짜 형식화
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }
}
