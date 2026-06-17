import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/attendance_provider.dart';

class AttendanceMonitor extends ConsumerStatefulWidget {
  const AttendanceMonitor({super.key});

  @override
  ConsumerState<AttendanceMonitor> createState() => _AttendanceMonitorState();
}

class _AttendanceMonitorState extends ConsumerState<AttendanceMonitor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyAttendanceAsync = ref.watch(dailyAttendanceProvider(_selectedDate));
    final profilesAsync = ref.watch(staffProfilesProvider);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.surfaceWhite;
    final dividerColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);

    return Column(
      children: [
        if (_tabController.index != 2) _buildDatePicker(context, accent),
        // Summary stats row
        if (_tabController.index != 2)
          dailyAttendanceAsync.when(
            data: (records) {
              final staffIds = (profilesAsync.value ?? [])
                  .map((p) => p['id'] as String? ?? '')
                  .toSet();
              final totalStaff = staffIds.length;
              final present = records
                  .where((r) => staffIds.contains(r['user_id'] as String? ?? ''))
                  .length;
              final absent = (totalStaff - present).clamp(0, totalStaff);
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill(context, isArabic ? 'حاضر' : 'Present', present, AppTheme.mintGreen, isDark),
                    Container(width: 1, height: 30, color: dividerColor),
                    _statPill(context, isArabic ? 'غائب' : 'Absent', absent, AppTheme.errorRed, isDark),
                    Container(width: 1, height: 30, color: dividerColor),
                    _statPill(context, isArabic ? 'الإجمالي' : 'Total', totalStaff, accent, isDark),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 4),
            error: (_, __) => const SizedBox(height: 4),
          ),
        TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          labelColor: accent,
          unselectedLabelColor: isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8),
          indicatorColor: accent,
          dividerColor: dividerColor,
          tabs: [
            Tab(text: isArabic ? 'السجلات' : 'Records'),
            Tab(text: isArabic ? 'لم يحضروا' : 'Not Checked In'),
            Tab(text: isArabic ? 'السجل' : 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttendanceList(context, dailyAttendanceAsync, isArabic, isDark),
              _buildMissingAttendanceList(context, dailyAttendanceAsync, profilesAsync, isArabic, isDark),
              _buildHistoryList(context, isArabic, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(
                () => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
            icon: Icon(Icons.chevron_left, color: textColor),
          ),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                Icon(Icons.calendar_today, size: 15, color: accent),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14),
                ),
              ]),
            ),
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () => setState(
                    () => _selectedDate = _selectedDate.add(const Duration(days: 1))),
            icon: Icon(Icons.chevron_right,
                color: isToday ? (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)) : textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> attendanceAsync,
    bool isArabic,
    bool isDark,
  ) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final accent = AppTheme.primaryAccent(isDark);

    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_available, size: 56, color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'لا توجد سجلات لهذا اليوم' : 'No records for this day',
                style: TextStyle(color: metaColor, fontSize: 15),
              ),
            ]),
          );
        }
        return RefreshIndicator(
          color: accent,
          onRefresh: () async => ref.invalidate(dailyAttendanceProvider(_selectedDate)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final profile = record['profiles'];
              final checkInTime = DateTime.parse(record['check_in_time']);
              final checkOutTime = record['check_out_time'] != null
                  ? DateTime.parse(record['check_out_time'])
                  : null;
              final isCheckedOut = checkOutTime != null;
              final activeColor = isCheckedOut
                  ? (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1))
                  : accent;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Container(width: 3, height: 76, color: activeColor),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: accent.withValues(alpha: 0.10),
                        child: Text(
                          (profile['name']?[0] ?? '?').toUpperCase(),
                          style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              profile['name'] ?? 'Unknown Staff',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (profile['role'] ?? '').toString(),
                              style: TextStyle(fontSize: 11, color: metaColor),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              _timeChip(Icons.login_rounded, DateFormat('hh:mm a').format(checkInTime), accent),
                              const SizedBox(width: 8),
                              _timeChip(
                                Icons.logout_rounded,
                                isCheckedOut
                                    ? DateFormat('hh:mm a').format(checkOutTime)
                                    : (isArabic ? 'نشط' : 'Active'),
                                isCheckedOut ? metaColor : AppTheme.mutedAmber,
                              ),
                            ]),
                          ]),
                        ),
                      ),
                      if (record['location_gps'] != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.electricBlue.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppTheme.electricBlue, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMissingAttendanceList(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> attendanceAsync,
    AsyncValue<List<Map<String, dynamic>>> profilesAsync,
    bool isArabic,
    bool isDark,
  ) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final avatarBg = isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9);

    return attendanceAsync.when(
      data: (records) {
        return profilesAsync.when(
          data: (profiles) {
            final checkedInUserIds = records.map((r) => r['user_id']).toSet();
            final missingStaff = profiles
                .where((p) => !checkedInUserIds.contains(p['id']) && p['role'] == 'staff')
                .toList();

            if (missingStaff.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, size: 56, color: AppTheme.mintGreen),
                  const SizedBox(height: 12),
                  Text(
                    isArabic ? 'الكل حاضر اليوم' : 'Everyone is present today',
                    style: const TextStyle(color: AppTheme.mintGreen, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ]),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryAccent(isDark),
              onRefresh: () async {
                ref.invalidate(dailyAttendanceProvider(_selectedDate));
                ref.invalidate(staffProfilesProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: missingStaff.length,
                itemBuilder: (context, index) {
                  final staff = missingStaff[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Row(children: [
                        Container(width: 3, height: 68, color: AppTheme.errorRed),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: avatarBg,
                          child: Text(
                            (staff['name']?[0] ?? '?').toUpperCase(),
                            style: TextStyle(color: metaColor, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                staff['name'] ?? 'Unknown Staff',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                staff['offices']?['name'] ??
                                    (isArabic ? 'لم يتم تعيين مكتب' : 'No office assigned'),
                                style: TextStyle(fontSize: 12, color: metaColor),
                              ),
                            ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.mutedAmber.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.mutedAmber, size: 16),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isArabic, bool isDark) {
    final historyAsync =
        ref.watch(attendanceHistoryProvider((userId: null, start: null, end: null)));
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final accent = AppTheme.primaryAccent(isDark);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history, size: 56, color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'لا توجد سجلات تاريخية' : 'No history records',
                style: TextStyle(color: metaColor, fontSize: 15),
              ),
            ]),
          );
        }
        return RefreshIndicator(
          color: accent,
          onRefresh: () async =>
              ref.invalidate(attendanceHistoryProvider((userId: null, start: null, end: null))),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final profile = record['profiles'];
              final checkInTime = DateTime.parse(record['check_in_time']);
              final checkOutTime = record['check_out_time'] != null
                  ? DateTime.parse(record['check_out_time'])
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withValues(alpha: 0.10),
                      child: Text(
                        (profile['name']?[0] ?? '?').toUpperCase(),
                        style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          profile['name'] ?? 'Unknown Staff',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, yyyy').format(checkInTime),
                          style: TextStyle(fontSize: 11, color: metaColor),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          _timeChip(Icons.login_rounded, DateFormat('hh:mm a').format(checkInTime), accent),
                          const SizedBox(width: 8),
                          _timeChip(
                            Icons.logout_rounded,
                            checkOutTime != null
                                ? DateFormat('hh:mm a').format(checkOutTime)
                                : (isArabic ? 'نشط' : 'Active'),
                            checkOutTime == null ? AppTheme.mutedAmber : metaColor,
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }

  Widget _timeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statPill(BuildContext context, String label, int count, Color color, bool isDark) {
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    return Column(children: [
      Text(
        '$count',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: metaColor, fontWeight: FontWeight.w500)),
    ]);
  }
}
