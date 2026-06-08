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

    return Column(
      children: [
        if (_tabController.index != 2) _buildDatePicker(context),
        // Summary stats row
        if (_tabController.index != 2)
          dailyAttendanceAsync.when(
            data: (records) {
              final totalStaff = profilesAsync.value?.length ?? 0;
              final present = records.length;
              final absent = (totalStaff - present).clamp(0, totalStaff);
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill(isArabic ? 'حاضر' : 'Present', present, Colors.green),
                    Container(width: 1, height: 30, color: Colors.grey.shade200),
                    _statPill(isArabic ? 'غائب' : 'Absent', absent, AppTheme.errorRed),
                    Container(width: 1, height: 30, color: Colors.grey.shade200),
                    _statPill(isArabic ? 'الإجمالي' : 'Total', totalStaff, AppTheme.emeraldGreen),
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
          labelColor: AppTheme.emeraldGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.emeraldGreen,
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
              _buildAttendanceList(dailyAttendanceAsync, isArabic),
              _buildMissingAttendanceList(dailyAttendanceAsync, profilesAsync, isArabic),
              _buildHistoryList(isArabic),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
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
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.emeraldGreen),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _selectedDate.day == DateTime.now().day && 
                       _selectedDate.month == DateTime.now().month && 
                       _selectedDate.year == DateTime.now().year
                ? null 
                : () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AsyncValue<List<Map<String, dynamic>>> attendanceAsync, bool isArabic) {
    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(child: Text(isArabic ? 'لا توجد سجلات لهذا اليوم' : 'No records for this day'));
        }
        return RefreshIndicator(
          color: const Color(0xFF0D1B2E),
          onRefresh: () async {
            ref.invalidate(dailyAttendanceProvider(_selectedDate));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final profile = record['profiles'];
              final checkInTime = DateTime.parse(record['check_in_time']);
              final checkOutTime = record['check_out_time'] != null ? DateTime.parse(record['check_out_time']) : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.emeraldLight,
                    child: Text(profile['name']?[0].toUpperCase() ?? '?', style: const TextStyle(color: AppTheme.emeraldGreen)),
                  ),
                  title: Text(profile['name'] ?? 'Unknown Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile['role'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.login, size: 14, color: AppTheme.emeraldGreen),
                          const SizedBox(width: 4),
                          Text(DateFormat('hh:mm a').format(checkInTime), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.logout, size: 14, color: AppTheme.errorRed),
                          const SizedBox(width: 4),
                          Text(
                            checkOutTime != null ? DateFormat('hh:mm a').format(checkOutTime) : (isArabic ? 'نشط' : 'Active'),
                            style: TextStyle(fontSize: 12, color: checkOutTime == null ? AppTheme.emeraldGreen : null),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: record['location_gps'] != null 
                    ? IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.blue),
                        onPressed: () {
                          // In a real app, open map with GPS
                        },
                      )
                    : null,
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

  Widget _buildMissingAttendanceList(AsyncValue<List<Map<String, dynamic>>> attendanceAsync, AsyncValue<List<Map<String, dynamic>>> profilesAsync, bool isArabic) {
    return attendanceAsync.when(
      data: (records) {
        return profilesAsync.when(
          data: (profiles) {
            final checkedInUserIds = records.map((r) => r['user_id']).toSet();
            final missingStaff = profiles.where((p) => !checkedInUserIds.contains(p['id']) && p['role'] == 'staff').toList();

            if (missingStaff.isEmpty) {
              return Center(child: Text(isArabic ? 'الكل حاضر اليوم' : 'Everyone is present today'));
            }

            return RefreshIndicator(
              color: const Color(0xFF0D1B2E),
              onRefresh: () async {
                ref.invalidate(dailyAttendanceProvider(_selectedDate));
                ref.invalidate(staffProfilesProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: missingStaff.length,
                itemBuilder: (context, index) {
                  final staff = missingStaff[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(staff['name']?[0].toUpperCase() ?? '?', style: const TextStyle(color: Colors.grey)),
                      ),
                      title: Text(staff['name'] ?? 'Unknown Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(staff['offices']?['name'] ?? (isArabic ? 'لم يتم تعيين مكتب' : 'No office assigned')),
                      trailing: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
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

  Widget _buildHistoryList(bool isArabic) {
    final historyAsync = ref.watch(attendanceHistoryProvider((userId: null, start: null, end: null)));

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(child: Text(isArabic ? 'لا توجد سجلات تاريخية' : 'No history records'));
        }
        return RefreshIndicator(
          color: const Color(0xFF0D1B2E),
          onRefresh: () async {
            ref.invalidate(attendanceHistoryProvider((userId: null, start: null, end: null)));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final profile = record['profiles'];
              final checkInTime = DateTime.parse(record['check_in_time']);
              final checkOutTime = record['check_out_time'] != null ? DateTime.parse(record['check_out_time']) : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.emeraldLight,
                    child: Text(profile['name']?[0].toUpperCase() ?? '?', style: const TextStyle(color: AppTheme.emeraldGreen)),
                  ),
                  title: Text(profile['name'] ?? 'Unknown Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM d, yyyy').format(checkInTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.login, size: 14, color: AppTheme.emeraldGreen),
                          const SizedBox(width: 4),
                          Text(DateFormat('hh:mm a').format(checkInTime), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.logout, size: 14, color: AppTheme.errorRed),
                          const SizedBox(width: 4),
                          Text(
                            checkOutTime != null ? DateFormat('hh:mm a').format(checkOutTime) : (isArabic ? 'نشط' : 'Active'),
                            style: TextStyle(fontSize: 12, color: checkOutTime == null ? AppTheme.emeraldGreen : null),
                          ),
                        ],
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

  Widget _statPill(String label, int count, Color color) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}
