import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

enum TxnType { expense, income }

class TxnCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final TxnType type;

  const TxnCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class Transaction {
  final String id;
  final TxnType type;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String note;

  const Transaction({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note = '',
  });
}

enum StatsRange { weekly, monthly, yearly }

// =============================================================================
// IN-MEMORY REPOSITORY  (no backend / no database — swap for an API later)
// =============================================================================

class BudgetRepository {
  BudgetRepository._();

  // ── Student expense categories ───────────────────────────────────────
  static const expenseCategories = <TxnCategory>[
    TxnCategory(id: 'food', label: 'Food & Canteen', icon: Icons.restaurant_rounded, color: Color(0xFFF97316), type: TxnType.expense),
    TxnCategory(id: 'transport', label: 'Transport', icon: Icons.directions_bus_rounded, color: Color(0xFF3B82F6), type: TxnType.expense),
    TxnCategory(id: 'tuition', label: 'Tuition Fee', icon: Icons.school_rounded, color: Color(0xFF8B5CF6), type: TxnType.expense),
    TxnCategory(id: 'books', label: 'Books & Notes', icon: Icons.menu_book_rounded, color: Color(0xFF0EA5E9), type: TxnType.expense),
    TxnCategory(id: 'stationery', label: 'Stationery', icon: Icons.edit_rounded, color: Color(0xFF14B8A6), type: TxnType.expense),
    TxnCategory(id: 'printing', label: 'Print & Photocopy', icon: Icons.print_rounded, color: Color(0xFF64748B), type: TxnType.expense),
    TxnCategory(id: 'mobile', label: 'Mobile Recharge', icon: Icons.smartphone_rounded, color: Color(0xFFEC4899), type: TxnType.expense),
    TxnCategory(id: 'internet', label: 'Internet', icon: Icons.wifi_rounded, color: Color(0xFF6366F1), type: TxnType.expense),
    TxnCategory(id: 'hostel', label: 'Hostel / Rent', icon: Icons.apartment_rounded, color: Color(0xFFEF4444), type: TxnType.expense),
    TxnCategory(id: 'exam', label: 'Exam Fee', icon: Icons.assignment_rounded, color: Color(0xFFD946EF), type: TxnType.expense),
    TxnCategory(id: 'club', label: 'Club & Society', icon: Icons.groups_rounded, color: Color(0xFF22C55E), type: TxnType.expense),
    TxnCategory(id: 'health', label: 'Health', icon: Icons.local_hospital_rounded, color: Color(0xFFF43F5E), type: TxnType.expense),
    TxnCategory(id: 'fun', label: 'Entertainment', icon: Icons.sports_esports_rounded, color: Color(0xFFA855F7), type: TxnType.expense),
    TxnCategory(id: 'shopping', label: 'Shopping', icon: Icons.shopping_bag_rounded, color: Color(0xFFF59E0B), type: TxnType.expense),
    TxnCategory(id: 'other_exp', label: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF94A3B8), type: TxnType.expense),
  ];

  // ── Student income sources ───────────────────────────────────────────
  static const incomeCategories = <TxnCategory>[
    TxnCategory(id: 'pocket', label: 'Pocket Money', icon: Icons.family_restroom_rounded, color: Color(0xFF10B981), type: TxnType.income),
    TxnCategory(id: 'scholarship', label: 'Scholarship', icon: Icons.workspace_premium_rounded, color: Color(0xFF6366F1), type: TxnType.income),
    TxnCategory(id: 'stipend', label: 'Stipend', icon: Icons.volunteer_activism_rounded, color: Color(0xFF0EA5E9), type: TxnType.income),
    TxnCategory(id: 'tutoring', label: 'Tutoring', icon: Icons.cast_for_education_rounded, color: Color(0xFF8B5CF6), type: TxnType.income),
    TxnCategory(id: 'partime', label: 'Part-time Job', icon: Icons.work_rounded, color: Color(0xFF14B8A6), type: TxnType.income),
    TxnCategory(id: 'freelance', label: 'Freelancing', icon: Icons.laptop_mac_rounded, color: Color(0xFF3B82F6), type: TxnType.income),
    TxnCategory(id: 'internship', label: 'Internship', icon: Icons.badge_rounded, color: Color(0xFF22C55E), type: TxnType.income),
    TxnCategory(id: 'award', label: 'Prize / Award', icon: Icons.emoji_events_rounded, color: Color(0xFFF59E0B), type: TxnType.income),
    TxnCategory(id: 'gift', label: 'Gift', icon: Icons.card_giftcard_rounded, color: Color(0xFFEC4899), type: TxnType.income),
    TxnCategory(id: 'savings', label: 'Savings', icon: Icons.savings_rounded, color: Color(0xFF0D9488), type: TxnType.income),
    TxnCategory(id: 'other_inc', label: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF94A3B8), type: TxnType.income),
  ];

  static const _fallback = TxnCategory(
    id: 'other_exp', label: 'Other', icon: Icons.more_horiz_rounded,
    color: Color(0xFF94A3B8), type: TxnType.expense,
  );

  static List<TxnCategory> categoriesOf(TxnType type) =>
      type == TxnType.expense ? expenseCategories : incomeCategories;

  static TxnCategory category(String id) => [...expenseCategories, ...incomeCategories]
      .firstWhere((c) => c.id == id, orElse: () => _fallback);

  // ── Transactions ─────────────────────────────────────────────────────
  static final List<Transaction> _transactions = [];
  static int _seq = 0;
  static bool _seeded = false;

  static List<Transaction> get transactions =>
      List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));

  static void seed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();
    DateTime d(int daysAgo) => DateTime(now.year, now.month, now.day - daysAgo);

    _addAll([
      (TxnType.income, 'pocket', 6000.0, d(28), 'Monthly allowance'),
      (TxnType.income, 'tutoring', 3500.0, d(20), 'Class 9 batch'),
      (TxnType.income, 'scholarship', 4000.0, d(12), 'Merit stipend'),
      (TxnType.income, 'freelance', 2200.0, d(4), 'Logo design'),
      (TxnType.expense, 'hostel', 3500.0, d(27), 'Hostel rent'),
      (TxnType.expense, 'books', 850.0, d(21), 'Algorithms book'),
      (TxnType.expense, 'transport', 120.0, d(14), 'Bus fare'),
      (TxnType.expense, 'mobile', 300.0, d(10), 'Data pack'),
      (TxnType.expense, 'food', 180.0, d(6), 'Canteen lunch'),
      (TxnType.expense, 'printing', 90.0, d(5), 'Lab report'),
      (TxnType.expense, 'food', 220.0, d(3), 'Dinner with friends'),
      (TxnType.expense, 'fun', 400.0, d(2), 'Movie night'),
      (TxnType.expense, 'food', 150.0, d(1), 'Breakfast'),
      (TxnType.expense, 'transport', 60.0, d(0), 'Rickshaw'),
    ]);
  }

  static void _addAll(List<(TxnType, String, double, DateTime, String)> rows) {
    for (final r in rows) {
      _transactions.add(Transaction(
        id: 't${_seq++}', type: r.$1, categoryId: r.$2,
        amount: r.$3, date: r.$4, note: r.$5,
      ));
    }
  }

  static void add({
    required TxnType type,
    required String categoryId,
    required double amount,
    required DateTime date,
    String note = '',
  }) {
    _transactions.add(Transaction(
      id: 't${_seq++}', type: type, categoryId: categoryId,
      amount: amount, date: date, note: note,
    ));
  }

  static void remove(String id) => _transactions.removeWhere((t) => t.id == id);

  // ── Queries ──────────────────────────────────────────────────────────
  static List<Transaction> onDay(DateTime day) => transactions
      .where((t) => _sameDay(t.date, day))
      .toList();

  static List<Transaction> inMonth(DateTime month) => transactions
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  static List<Transaction> inRange(DateTime start, DateTime end) => transactions
      .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
      .toList();

  static double totalOf(Iterable<Transaction> txns, TxnType type) => txns
      .where((t) => t.type == type)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Category → total, sorted descending. Used by the statistics breakdown.
  static List<MapEntry<String, double>> breakdown(Iterable<Transaction> txns, TxnType type) {
    final map = <String, double>{};
    for (final t in txns.where((t) => t.type == type)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// =============================================================================
// FORMATTING HELPERS
// =============================================================================

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'];
const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _money(double v) {
  final rounded = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    if (i > 0 && (rounded.length - i) % 3 == 0) buf.write(',');
    buf.write(rounded[i]);
  }
  return '৳${buf.toString()}';
}

/// Compact form for the tight calendar cells: 1.2k, 12k, 340.
String _moneyCompact(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${k >= 10 ? k.round() : k.toStringAsFixed(1)}k';
  }
  return v.round().toString();
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// =============================================================================
// BUDGET PAGE
// =============================================================================

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  /// How many of the selected day's transactions show inline before we hand
  /// the rest to a scrollable sheet. Keeps the page a fixed height on a busy day.
  static const _previewCount = 3;

  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  StatsRange _range = StatsRange.monthly;
  TxnType _breakdownType = TxnType.expense;

  @override
  void initState() {
    super.initState();
    BudgetRepository.seed();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      // The summary card and the monthly/yearly stats follow the day you pick.
      _visibleMonth = DateTime(day.year, day.month);
    });
  }

  /// One-tap day stepping, so the common "yesterday" case needs no popup.
  void _shiftDay(int delta) =>
      _selectDay(DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day + delta));

  void _jumpToToday() {
    final now = DateTime.now();
    _selectDay(DateTime(now.year, now.month, now.day));
  }

  /// The month calendar now lives in a popup, launched from the summary card
  /// or by tapping the date in the Transactions header.
  Future<void> _openCalendarSheet() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CalendarSheet(selectedDay: _selectedDay),
    );
    if (picked != null && mounted) _selectDay(picked);
  }

  Future<void> _openTypePicker() async {
    final type = await showModalBottomSheet<TxnType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TypePickerSheet(),
    );
    if (type == null || !mounted) return;
    await _openAddSheet(type);
  }

  Future<void> _openAddSheet(TxnType type) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTransactionSheet(type: type, initialDate: _selectedDay),
    );
    if (saved != true || !mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(type == TxnType.expense ? 'Expense added' : 'Income added'),
      duration: const Duration(seconds: 2),
    ));
  }

  void _deleteTransaction(Transaction t) {
    BudgetRepository.remove(t.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted'), duration: Duration(seconds: 2)),
    );
  }

  /// Full day list — scrolls inside a sheet so a 20-transaction day never
  /// stretches the page.
  Future<void> _openDaySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayTransactionsSheet(
        day: _selectedDay,
        onDelete: (t) => BudgetRepository.remove(t.id),
      ),
    );
    if (mounted) setState(() {});
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _AddFab(onPressed: _openTypePicker),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 18),
            _buildTransactionsHeader(),
            const SizedBox(height: 10),
            _buildDayTransactions(),
            const SizedBox(height: 22),
            _sectionTitle('Statistics'),
            const SizedBox(height: 10),
            _buildStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(
          color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (trailing != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(trailing, textAlign: TextAlign.right,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
      ],
    );
  }

  // ── Summary (month income / expense / balance) ───────────────────────

  Widget _buildSummaryCard() {
    final monthTxns = BudgetRepository.inMonth(_visibleMonth);
    final income = BudgetRepository.totalOf(monthTxns, TxnType.income);
    final expense = BudgetRepository.totalOf(monthTxns, TxnType.expense);
    final balance = income - expense;
    final spentRatio = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;

    return _GlowCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance + calendar button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_months[_visibleMonth.month - 1]} ${_visibleMonth.year} · balance',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                      const SizedBox(height: 1),
                      Text(_money(balance),
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6,
                          color: balance < 0 ? const Color(0xFFDC2626) : AppColors.textPrimary,
                        )),
                    ],
                  ),
                ),
                _CalendarButton(onTap: _openCalendarSheet),
              ],
            ),
            const SizedBox(height: 12),
            // Income / expense, side by side
            Row(
              children: [
                Expanded(child: _MiniStat(
                  icon: Icons.arrow_downward_rounded, label: 'Income',
                  value: _money(income), color: const Color(0xFF10B981),
                )),
                const SizedBox(width: 8),
                Expanded(child: _MiniStat(
                  icon: Icons.arrow_upward_rounded, label: 'Expense',
                  value: _money(expense), color: const Color(0xFFEF4444),
                )),
              ],
            ),
            const SizedBox(height: 10),
            // Spend meter — the caption sits beside the bar instead of under it.
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: spentRatio.toDouble(),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(
                        spentRatio > 0.9 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  income == 0
                      ? 'No income yet'
                      : '${(spentRatio * 100).toStringAsFixed(0)}% spent',
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Transactions header: day stepper + tap-to-open calendar ──────────

  Widget _buildTransactionsHeader() {
    final isToday = _isSameDay(_selectedDay, DateTime.now());
    final label = isToday
        ? 'Today'
        : '${_weekdaysShort[_selectedDay.weekday - 1]}, ${_selectedDay.day} '
          '${_monthsShort[_selectedDay.month - 1]}';

    return Column(
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(
              color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            const Text('Transactions', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 16,
              fontWeight: FontWeight.w800, letterSpacing: -0.2)),
            const Spacer(),
            // ‹  Today  ›  — arrows step a day, the label opens the calendar.
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepArrow(icon: Icons.chevron_left_rounded, onTap: () => _shiftDay(-1)),
                  GestureDetector(
                    onTap: _openCalendarSheet,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.purple),
                          const SizedBox(width: 5),
                          Text(label, style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple)),
                        ],
                      ),
                    ),
                  ),
                  _StepArrow(icon: Icons.chevron_right_rounded, onTap: () => _shiftDay(1)),
                ],
              ),
            ),
          ],
        ),
        if (!isToday) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _jumpToToday,
              child: const Text('Back to today', style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.purple)),
            ),
          ),
        ],
      ],
    );
  }

  // ── Selected-day transaction list ────────────────────────────────────

  Widget _buildDayTransactions() {
    final txns = BudgetRepository.onDay(_selectedDay);
    if (txns.isEmpty) {
      return _EmptyCard(
        icon: Icons.receipt_long_rounded,
        message: 'Nothing logged on this day.\nTap + to add an expense or income.',
      );
    }

    final preview = txns.take(_previewCount).toList();
    final hidden = txns.length - preview.length;

    return Column(
      children: [
        ...preview.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SwipeToDelete(
            id: t.id,
            onDelete: () => _deleteTransaction(t),
            child: _TxnTile(txn: t),
          ),
        )),
        if (hidden > 0)
          GestureDetector(
            onTap: _openDaySheet,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View all ${txns.length} transactions', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purple)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.purple),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Statistics (weekly / monthly / yearly) ───────────────────────────

  /// Buckets for the selected range: bar label + income/expense totals.
  ({List<String> labels, List<double> income, List<double> expense, List<Transaction> txns, String caption})
      _statsData() {
    final now = DateTime.now();
    switch (_range) {
      case StatsRange.weekly:
        final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final end = monday.add(const Duration(days: 7));
        final txns = BudgetRepository.inRange(monday, end);
        final income = List<double>.filled(7, 0);
        final expense = List<double>.filled(7, 0);
        for (final t in txns) {
          final i = t.date.difference(monday).inDays.clamp(0, 6);
          if (t.type == TxnType.income) {
            income[i] += t.amount;
          } else {
            expense[i] += t.amount;
          }
        }
        return (
          labels: _weekdaysShort,
          income: income,
          expense: expense,
          txns: txns,
          caption: 'This week · ${monday.day} ${_monthsShort[monday.month - 1]} – '
              '${monday.add(const Duration(days: 6)).day} ${_monthsShort[monday.add(const Duration(days: 6)).month - 1]}',
        );

      case StatsRange.monthly:
        // Bucket the visible month into calendar weeks (W1…W5/6).
        final month = _visibleMonth;
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        final leading = DateTime(month.year, month.month).weekday - 1;
        final weeks = ((leading + daysInMonth) / 7).ceil();
        final txns = BudgetRepository.inMonth(month);
        final income = List<double>.filled(weeks, 0);
        final expense = List<double>.filled(weeks, 0);
        for (final t in txns) {
          final i = ((leading + t.date.day - 1) ~/ 7).clamp(0, weeks - 1);
          if (t.type == TxnType.income) {
            income[i] += t.amount;
          } else {
            expense[i] += t.amount;
          }
        }
        return (
          labels: List.generate(weeks, (i) => 'W${i + 1}'),
          income: income,
          expense: expense,
          txns: txns,
          caption: '${_months[month.month - 1]} ${month.year}',
        );

      case StatsRange.yearly:
        final year = _visibleMonth.year;
        final txns = BudgetRepository.inRange(DateTime(year), DateTime(year + 1));
        final income = List<double>.filled(12, 0);
        final expense = List<double>.filled(12, 0);
        for (final t in txns) {
          final i = t.date.month - 1;
          if (t.type == TxnType.income) {
            income[i] += t.amount;
          } else {
            expense[i] += t.amount;
          }
        }
        return (
          labels: _monthsShort,
          income: income,
          expense: expense,
          txns: txns,
          caption: 'Year $year',
        );
    }
  }

  Widget _buildStatistics() {
    final data = _statsData();
    final totalIncome = BudgetRepository.totalOf(data.txns, TxnType.income);
    final totalExpense = BudgetRepository.totalOf(data.txns, TxnType.expense);
    final breakdown = BudgetRepository.breakdown(data.txns, _breakdownType);
    final breakdownTotal = breakdown.fold<double>(0, (s, e) => s + e.value);

    return Column(
      children: [
        // Range selector
        _GlowCard(
          radius: 16, strokeWidth: 1.2,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: StatsRange.values.map((r) {
                final selected = r == _range;
                final label = switch (r) {
                  StatsRange.weekly => 'Weekly',
                  StatsRange.monthly => 'Monthly',
                  StatsRange.yearly => 'Yearly',
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _range = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(label, style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Income vs expense bars
        _GlowCard(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: AppColors.purple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Income vs Expense', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(data.caption, style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _LegendDot(color: const Color(0xFF10B981), label: 'Income ${_money(totalIncome)}'),
                    const SizedBox(width: 14),
                    _LegendDot(color: const Color(0xFFEF4444), label: 'Expense ${_money(totalExpense)}'),
                  ],
                ),
                const SizedBox(height: 14),
                _GroupedBarChart(
                  labels: data.labels,
                  income: data.income,
                  expense: data.expense,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        totalIncome - totalExpense >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color: totalIncome - totalExpense >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          totalIncome - totalExpense >= 0
                              ? 'You saved ${_money(totalIncome - totalExpense)} in this period.'
                              : 'You overspent by ${_money(totalExpense - totalIncome)} in this period.',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category breakdown
        _GlowCard(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF06B6D4), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('By Category', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    _MiniToggle(
                      selected: _breakdownType,
                      onChanged: (t) => setState(() => _breakdownType = t),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (breakdown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No ${_breakdownType == TxnType.expense ? 'expenses' : 'income'} in this period.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 104, height: 104,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            values: breakdown.map((e) => e.value).toList(),
                            colors: breakdown
                                .map((e) => BudgetRepository.category(e.key).color)
                                .toList(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_money(breakdownTotal), style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                Text(
                                  _breakdownType == TxnType.expense ? 'spent' : 'earned',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: breakdown.take(5).map((e) {
                            final cat = BudgetRepository.category(e.key);
                            final pct = breakdownTotal > 0 ? e.value / breakdownTotal : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 9, height: 9, decoration: BoxDecoration(
                                        color: cat.color, borderRadius: BorderRadius.circular(3))),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(cat.label,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5, fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                      ),
                                      Text('${(pct * 100).round()}%', style: const TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.w800,
                                        color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 4,
                                      backgroundColor: cat.color.withValues(alpha: 0.12),
                                      valueColor: AlwaysStoppedAnimation(cat.color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CALENDAR POPUP
//
// The month grid used to sit on the page and cost ~340px. It now opens on
// demand from the summary card or the Transactions date chip, and returns the
// day the student tapped.
// =============================================================================

class _CalendarSheet extends StatefulWidget {
  final DateTime selectedDay;
  const _CalendarSheet({required this.selectedDay});

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month).weekday - 1; // Monday-first
    final rows = ((leadingBlanks + daysInMonth) / 7).ceil();
    final monthTxns = BudgetRepository.inMonth(_month);
    final income = BudgetRepository.totalOf(monthTxns, TxnType.income);
    final expense = BudgetRepository.totalOf(monthTxns, TxnType.expense);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 14),
            // Month switcher
            Row(
              children: [
                _CalendarArrow(icon: Icons.chevron_left_rounded, onTap: () => _shiftMonth(-1)),
                Expanded(
                  child: Center(
                    child: Text('${_months[_month.month - 1]} ${_month.year}',
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, letterSpacing: -0.2)),
                  ),
                ),
                _CalendarArrow(icon: Icons.chevron_right_rounded, onTap: () => _shiftMonth(1)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: const Color(0xFF10B981), label: _money(income)),
                const SizedBox(width: 12),
                _LegendDot(color: const Color(0xFFEF4444), label: _money(expense)),
              ],
            ),
            const SizedBox(height: 12),
            // Weekday header
            Row(
              children: _weekdaysShort.map((d) => Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.65))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 4),
            // Day grid — tapping a day returns it and closes the popup.
            ...List.generate(rows, (row) => Row(
              children: List.generate(7, (col) {
                final dayNum = row * 7 + col - leadingBlanks + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 46));
                }
                final day = DateTime(_month.year, _month.month, dayNum);
                final txns = BudgetRepository.onDay(day);
                return Expanded(
                  child: _CalendarCell(
                    day: day,
                    income: BudgetRepository.totalOf(txns, TxnType.income),
                    expense: BudgetRepository.totalOf(txns, TxnType.expense),
                    isSelected: _isSameDay(day, widget.selectedDay),
                    isToday: _isSameDay(day, DateTime.now()),
                    onTap: () => Navigator.of(context).pop(day),
                  ),
                );
              }),
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(context).pop(DateTime(now.year, now.month, now.day));
              },
              child: const Text('Jump to today'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TRANSACTION TILE  (shared by the inline preview and the full-day sheet)
// =============================================================================

class _TxnTile extends StatelessWidget {
  final Transaction txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final cat = BudgetRepository.category(txn.categoryId);
    final isExpense = txn.type == TxnType.expense;

    return _GlowCard(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label, style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    txn.note.isEmpty ? (isExpense ? 'Expense' : 'Income source') : txn.note,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isExpense ? '−' : '+'} ${_money(txn.amount)}',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  final String id;
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToDelete({required this.id, required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
      ),
      child: child,
    );
  }
}

// =============================================================================
// FULL-DAY TRANSACTION SHEET
//
// A busy day can hold dozens of entries. They live here, in a sheet that
// scrolls on its own, so the budget page itself never grows past one screen.
// =============================================================================

class _DayTransactionsSheet extends StatefulWidget {
  final DateTime day;
  final ValueChanged<Transaction> onDelete;

  const _DayTransactionsSheet({required this.day, required this.onDelete});

  @override
  State<_DayTransactionsSheet> createState() => _DayTransactionsSheetState();
}

class _DayTransactionsSheetState extends State<_DayTransactionsSheet> {
  @override
  Widget build(BuildContext context) {
    final txns = BudgetRepository.onDay(widget.day);
    final income = BudgetRepository.totalOf(txns, TxnType.income);
    final expense = BudgetRepository.totalOf(txns, TxnType.expense);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_weekdaysShort[widget.day.weekday - 1]}, ${widget.day.day} '
                          '${_monthsShort[widget.day.month - 1]} ${widget.day.year}',
                          style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text('${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (income > 0)
                    _DayTotalChip(label: '+${_money(income)}', color: const Color(0xFF10B981)),
                  if (income > 0 && expense > 0) const SizedBox(width: 6),
                  if (expense > 0)
                    _DayTotalChip(label: '−${_money(expense)}', color: const Color(0xFFEF4444)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: txns.isEmpty
                  ? const Center(
                      child: Text('Nothing left on this day.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      itemCount: txns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = txns[i];
                        return _SwipeToDelete(
                          id: t.id,
                          onDelete: () {
                            widget.onDelete(t);
                            setState(() {});
                          },
                          child: _TxnTile(txn: t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTotalChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DayTotalChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

// =============================================================================
// ADD FLOW — type picker  →  add sheet
// =============================================================================

class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 18),
            const Text('What do you want to add?', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Track where your money goes and where it comes from.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _TypeOption(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Expense',
                  subtitle: 'Food, transport, fees…',
                  color: const Color(0xFFEF4444),
                  onTap: () => Navigator.of(context).pop(TxnType.expense),
                )),
                const SizedBox(width: 12),
                Expanded(child: _TypeOption(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Income Source',
                  subtitle: 'Pocket money, tutoring…',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.of(context).pop(TxnType.income),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon, required this.title,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final TxnType type;
  final DateTime initialDate;

  const _AddTransactionSheet({required this.type, required this.initialDate});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  String? _categoryId;
  String? _error;

  bool get _isExpense => widget.type == TxnType.expense;
  Color get _accent => _isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = _isExpense
          ? 'Pick an expense category.'
          : 'Pick an income source.');
      return;
    }
    BudgetRepository.add(
      type: widget.type,
      categoryId: _categoryId!,
      amount: amount,
      date: _date,
      note: _noteController.text.trim(),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = BudgetRepository.categoriesOf(widget.type);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(_isExpense ? 'Add Expense' : 'Add Income', style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 18),

            // Amount
            const Text('Amount', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: _accent, letterSpacing: -0.5),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '৳ ',
                prefixStyle: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: _accent.withValues(alpha: 0.6)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Category
            Text(_isExpense ? 'Expense category' : 'Income source', style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: categories.map((c) {
                final selected = c.id == _categoryId;
                return GestureDetector(
                  onTap: () => setState(() {
                    _categoryId = c.id;
                    _error = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? c.color.withValues(alpha: 0.14) : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? c.color : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 15,
                          color: selected ? c.color : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(c.label, style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? c.color : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Date
            const Text('Date', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      '${_weekdaysShort[_date.weekday - 1]}, ${_date.day} '
                      '${_monthsShort[_date.month - 1]} ${_date.year}',
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Note
            const Text('Note (optional)', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'e.g. Canteen lunch with friends'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Text(_error!, style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                ],
              ),
            ],
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: Text(_isExpense ? 'Save Expense' : 'Save Income',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL COMPONENTS
// =============================================================================

class _AddFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.purple.withValues(alpha: 0.35),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 0,
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

/// Opens the calendar popup from the summary card.
class _CalendarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CalendarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.purple, size: 18),
            SizedBox(width: 6),
            Text('Calendar', style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.purple)),
          ],
        ),
      ),
    );
  }
}

/// Small chevron used by the day stepper in the Transactions header.
class _StepArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalendarArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.purple, size: 20),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime day;
  final double income;
  final double expense;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.day, required this.income, required this.expense,
    required this.isSelected, required this.isToday, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple.withValues(alpha: 0.1)
              : isToday
                  ? AppColors.purple.withValues(alpha: 0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : isToday
                    ? AppColors.purple.withValues(alpha: 0.3)
                    : Colors.transparent,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}', style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
              color: isSelected || isToday ? AppColors.purple : AppColors.textPrimary,
            )),
            const SizedBox(height: 2),
            // One compact line: spending leads (that's what students watch),
            // with a green dot marking days that also brought money in.
            SizedBox(
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (expense > 0)
                    Flexible(
                      child: Text('-${_moneyCompact(expense)}',
                        maxLines: 1, overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                    )
                  else if (income > 0)
                    Flexible(
                      child: Text('+${_moneyCompact(income)}',
                        maxLines: 1, overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ),
                  if (expense > 0 && income > 0) ...[
                    const SizedBox(width: 2),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(
                      color: Color(0xFF10B981), shape: BoxShape.circle)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final TxnType selected;
  final ValueChanged<TxnType> onChanged;
  const _MiniToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(TxnType type, String label, Color color) {
      final isOn = selected == type;
      return GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isOn ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 11,
            fontWeight: isOn ? FontWeight.w800 : FontWeight.w600,
            color: isOn ? color : AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(TxnType.expense, 'Expense', const Color(0xFFEF4444)),
          chip(TxnType.income, 'Income', const Color(0xFF10B981)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _GroupedBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;

  const _GroupedBarChart({
    required this.labels, required this.income, required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = [...income, ...expense].fold<double>(0, (m, v) => v > m ? v : m);
    const barAreaHeight = 96.0;
    // Yearly view packs 12 groups — let it scroll instead of squeezing.
    final scrollable = labels.length > 8;

    Widget group(int i) {
      final inPct = maxV > 0 ? income[i] / maxV : 0.0;
      final exPct = maxV > 0 ? expense[i] / maxV : 0.0;
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: barAreaHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(heightFactor: inPct, maxHeight: barAreaHeight, color: const Color(0xFF10B981)),
                const SizedBox(width: 3),
                _Bar(heightFactor: exPct, maxHeight: barAreaHeight, color: const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(labels[i], style: TextStyle(
            fontSize: 9.5, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.75))),
        ],
      );
    }

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(labels.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(width: 30, child: group(i)),
          )),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(labels.length, (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: group(i),
        ),
      )),
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFactor;
  final double maxHeight;
  final Color color;

  const _Bar({required this.heightFactor, required this.maxHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: 9,
      // Keep a visible stub for zero so the grid still reads as a chart.
      height: (heightFactor * maxHeight).clamp(3.0, maxHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.45)],
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return _GlowCard(
      radius: 14, strokeWidth: 1.2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(9, 9, size.width - 18, size.height - 18);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    var start = -1.5708; // 12 o'clock
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors;
}

// Local copy of the dashboard's card chrome so this page stays self-contained.
class _GlowCard extends StatelessWidget {
  const _GlowCard({required this.child, this.radius = 16, this.strokeWidth = 1.6});

  final Widget child;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.18),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: CustomPaint(
        painter: _BorderPainter(radius: radius, strokeWidth: strokeWidth),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((radius - strokeWidth).clamp(0, radius)),
            child: ColoredBox(color: AppColors.card, child: child),
          ),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.radius, required this.strokeWidth});

  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF7DB4FF), Color(0xFF1E40AF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter old) =>
      old.radius != radius || old.strokeWidth != strokeWidth;
}
