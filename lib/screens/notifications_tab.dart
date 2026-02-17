import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/local_db_service.dart';
import '../services/connectivity_service.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
  print('📱 Loading notifications...');
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final online = await ConnectivityService.instance.checkOnline();
    print('🌐 Online: $online');
    
    if (online) {
      // Load from Firestore - GET BARANGAY NOTIFICATIONS
      print('☁️ Loading barangay notifications from Firestore...');
      final notifications = await FirestoreService().getBarangayNotifications();
      print('✅ Loaded ${notifications.length} notifications from Firestore');
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      // Load from local database
      print('💾 Loading from local database...');
      await LocalDbService.instance.init();
      final localRecords = await LocalDbService.instance.getAllRecords();
      print('✅ Loaded ${localRecords.length} records from local DB');
      
      // Convert local records to notification format
      final notifications = localRecords.map((record) {
        final data = record['data'] as Map<String, dynamic>;
        return {
          'id': record['id'],
          'type': 'new_patient',
          'patientName': '${data['demographic']?['firstName'] ?? ''} ${data['demographic']?['lastName'] ?? ''}',
          'patientAge': data['demographic']?['age'] ?? '',
          'patientSex': data['demographic']?['sex'] ?? '',
          'createdAt': record['timestamp'],
          'read': record['synced'] ?? false,
        };
      }).toList();
      
      // Sort by timestamp descending
      notifications.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime is String && bTime is String) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  } catch (e, stackTrace) {
    print('❌ Error loading notifications: $e');
    print('Stack trace: $stackTrace');
    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });
  }
}

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp == null) {
        return 'Unknown time';
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown time';
    }
  }

  Color _getAvatarColor(String sex) {
    if (sex.toLowerCase() == 'male' || sex.toLowerCase() == 'm') {
      return const Color(0xFF5CAA7F);
    } else if (sex.toLowerCase() == 'female' || sex.toLowerCase() == 'f') {
      return const Color(0xFFF5A962);
    }
    return const Color(0xFF8BC88A);
  }

  IconData _getAvatarIcon(String sex) {
    if (sex.toLowerCase() == 'male' || sex.toLowerCase() == 'm') {
      return Icons.boy;
    } else if (sex.toLowerCase() == 'female' || sex.toLowerCase() == 'f') {
      return Icons.girl;
    }
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E8B7B),
            Color(0xFF5CAA7F),
            Color(0xFF8BC88A),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Recent patient assessments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error loading notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New patient assessments will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadNotifications,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2E8B7B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFF2E8B7B),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

 Widget _buildNotificationCard(Map<String, dynamic> notification) {
  final type = notification['type'] ?? 'new_patient';
  final patientName = notification['patientName'] ?? '';
  final patientAge = notification['patientAge'] ?? '';
  final patientSex = notification['patientSex'] ?? '';
  final createdBy = notification['createdByName'] ?? 'Unknown';
  final timestamp = notification['createdAt'];
  final isRead = notification['read'] ?? false;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isRead ? Colors.transparent : const Color(0xFF2E8B7B),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Mark as read
          final notifId = notification['id'];
          if (notifId != null && !isRead) {
            await FirestoreService().markNotificationAsRead(notifId);
            _loadNotifications(); // Refresh
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View details for $patientName'),
              backgroundColor: const Color(0xFF2E8B7B),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAvatarColor(patientSex),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAvatarIcon(patientSex),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'New Assessment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isRead ? Colors.grey : const Color(0xFF2E8B7B),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E8B7B),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added by $createdBy',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.cake,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patientAge.isNotEmpty ? '$patientAge years old' : 'Age not specified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _getAvatarIcon(patientSex),
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patientSex.isNotEmpty ? patientSex : 'Not specified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}