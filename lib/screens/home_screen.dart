import 'package:flutter/material.dart';
import '../data/runes.dart';
import '../models/rune.dart';
import '../services/rune_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final RuneService _service = RuneService();
  Rune? _todayRune;
  bool _isDrawing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadLastRune();
  }

  Future<void> _loadLastRune() async {
    await _service.init();
    final last = _service.getLastRune();
    if (last != null && mounted) {
      setState(() => _todayRune = last);
      _animationController.forward();
    }
  }

  Future<void> _drawRune() async {
    if (_service.isLimited) {
      _showLimitDialog();
      return;
    }

    setState(() => _isDrawing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final rune = await _service.drawRune();

    setState(() {
      _todayRune = rune;
      _isDrawing = false;
    });

    _animationController.reset();
    _animationController.forward();
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Руна уже вытянута'),
        content: const Text(
            'Сегодня ты уже получил свой знак. Новая руна будет доступна завтра.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'Огонь':
        return const Color(0xFFE57373);
      case 'Вода':
        return const Color(0xFF64B5F6);
      case 'Воздух':
        return const Color(0xFF4DB6AC);
      case 'Земля':
        return const Color(0xFF81C784);
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'РУНА ДНЯ',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_service.collectedCount}/${_service.totalCount}',
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.grid_view,
                      color: Color(0xFFD4A5A5),
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: collection screen
                    },
                  ),
                ],
              ),
            ),

            // Контент (скроллируется)
            Expanded(
              child: _todayRune == null ? _buildEmptyState() : _buildRuneView(),
            ),

            // Нижняя секция (фиксированная)
            if (_todayRune != null) _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuneView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Hero image with rune symbol overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    _todayRune!.imageAsset != null
                        ? Image.asset(
                            _todayRune!.imageAsset!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Center(
                              child: Text(
                                '᛭',
                                style: TextStyle(
                                  fontSize: 120,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ),
                    // Rune symbol overlay
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _todayRune!.symbol,
                            style: const TextStyle(
                              fontSize: 48,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w300,
                              shadows: [
                                Shadow(
                                  color: Colors.amber,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Элемент-бейдж
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getElementColor(_todayRune!.element).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _todayRune!.element.toUpperCase(),
                style: TextStyle(
                  color: _getElementColor(_todayRune!.element),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Название + титул
            Text(
              _todayRune!.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _todayRune!.title,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _todayRune!.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Совет дня
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFECB3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Color(0xFFFFB300),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Совет дня',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _todayRune!.advice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Hero image placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/runes/fehu.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const Center(
                    child: Text(
                      'ᚠ',
                      style: TextStyle(
                        fontSize: 80,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Доброе утро',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Потяните руну и узнайте свой знак на день',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Кнопка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDrawing ? null : _drawRune,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isDrawing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF333333),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ТЯНУТЬ РУНУ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Бесплатно
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1 руна в день — бесплатно',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Полный расклад: 3 руны о прошлом, настоящем и будущем',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Кнопка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDrawing ? null : _drawRune,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isDrawing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF333333),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ПОЛУЧИТЬ РАСКЛАД',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
