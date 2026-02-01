import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications / الإشعارات'),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today Section
            _buildSectionHeader('TODAY / اليوم'),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.task_alt,
              color: AppTheme.emeraldGreen,
              title: 'Task Completed',
              message: 'You have successfully completed "Visa Renewal" for Client Ahmed.',
              time: '2 mins ago',
              isUnread: true,
            ),
            _buildNotificationItem(
              icon: Icons.assignment_add,
              color: AppTheme.darkBlue,
              title: 'New Task Assigned',
              message: 'You have a new task: "Document Pickup" at Olaya District.',
              time: '1 hour ago',
              isUnread: true,
            ),
            
            const SizedBox(height: 24),
            
            // Yesterday Section
            _buildSectionHeader('YESTERDAY / الأمس'),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.info_outline,
              color: AppTheme.accentGold,
              title: 'System Update',
              message: 'The app has been updated to version 1.2.0. Check out the new features.',
              time: 'Yesterday, 9:00 AM',
              isUnread: false,
            ),
            _buildNotificationItem(
              icon: Icons.warning_amber_rounded,
              color: AppTheme.errorRed,
              title: 'Urgent Reminder',
              message: 'Pending report submission for "TechCorp" is overdue.',
              time: 'Yesterday, 8:30 AM',
              isUnread: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread ? Border.all(color: AppTheme.emeraldGreen.withOpacity(0.2), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isUnread ? AppTheme.darkBlue : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
