import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_card.dart';
import '../providers/attendance_provider.dart';

class AttendanceCard extends ConsumerWidget {
  const AttendanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(currentAttendanceProvider);
    final controllerState = ref.watch(attendanceControllerProvider);

    return PremiumCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative Corner
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
             Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: AppTheme.emeraldLight,
                                 borderRadius: BorderRadius.circular(10),
                               ),
                               child: const Icon(Icons.watch_later_outlined, color: AppTheme.emeraldGreen, size: 20),
                             ),
                           const SizedBox(width: 12),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 "ATTENDANCE", 
                                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                   color: Colors.grey, 
                                   letterSpacing: 1.5,
                                   fontWeight: FontWeight.bold
                                 )
                               ),
                               const Text("تسجيل الحضور", style: TextStyle(fontFamily: 'Arial', fontSize: 12, color: AppTheme.emeraldGreen)),
                             ],
                           ),
                        ],
                      ),
                      // Live Clock or Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  attendanceAsync.when(
                    data: (session) {
                      final isCheckedIn = session != null;
                      return Column(
                        children: [
                          // Status Display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isCheckedIn ? AppTheme.emeraldGreen.withValues(alpha: 0.05) : const Color(0xFFFFF7ED), // Orange tint for warning
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCheckedIn ? AppTheme.emeraldGreen.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCheckedIn ? Icons.check_circle_outline : Icons.info_outline,
                                  color: isCheckedIn ? AppTheme.emeraldGreen : Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCheckedIn ? 'Currently on Duty' : 'Not Checked In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCheckedIn ? AppTheme.emeraldGreen : Colors.orange.shade800,
                                        ),
                                      ),
                                      if (isCheckedIn)
                                        Text(
                                          'Since ${DateFormat('hh:mm a').format(DateTime.parse(session['check_in_time']).toLocal())}',
                                          style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen.withValues(alpha: 0.8)),
                                        )
                                      else
                                        Text(
                                          'Please check in to start work',
                                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: controllerState.isLoading 
                                ? null 
                                : () {
                                    if (isCheckedIn) {
                                      ref.read(attendanceControllerProvider.notifier).checkOut(session['id']);
                                    } else {
                                      ref.read(attendanceControllerProvider.notifier).checkIn();
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn ? AppTheme.errorRed : AppTheme.emeraldGreen,
                                elevation: isCheckedIn ? 0 : 4,
                                shadowColor: AppTheme.emeraldGreen.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: controllerState.isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isCheckedIn ? Icons.logout : Icons.login),
                                      const SizedBox(width: 8),
                                      Text(
                                        isCheckedIn ? 'CHECK OUT / انصراف' : 'CHECK IN / حضور',
                                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                    error: (err, stack) => Text('Error: $err'),
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
