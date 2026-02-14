import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// DEBUG WIDGET - Add this to your home page temporarily
// ============================================================================

class DebugUserButton extends StatelessWidget {
  const DebugUserButton({super.key});

  Future<void> _debugUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        _showDialog(context, '❌ ERROR', 'No user logged in');
        return;
      }

      print('\n═══════════════════════════════════════');
      print('🔍 DEBUG USER INFO');
      print('═══════════════════════════════════════');
      print('User UID: ${user.uid}');
      print('User Email: ${user.email}');
      
      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showDialog(context, '❌ ERROR', 'User document does not exist!\n\nUID: ${user.uid}');
        return;
      }

      final userData = userDoc.data()!;
      print('\n📄 User Document Fields:');
      userData.forEach((key, value) {
        print('  $key: $value');
      });

      // Check critical fields
      final hasBarangayId = userData.containsKey('barangayId');
      final barangayId = userData['barangayId'];
      
      print('\n🔍 Critical Checks:');
      print('  Has barangayId field: $hasBarangayId');
      print('  barangayId value: $barangayId');
      print('  barangayId is null: ${barangayId == null}');
      print('  barangayId is empty: ${barangayId == ""}');

      String status = '';
      String message = '';

      if (!hasBarangayId) {
        status = '❌ PROBLEM FOUND';
        message = 'User document is MISSING the "barangayId" field!\n\n'
                  'Solution: Add barangayId field to your user document in Firebase Console.';
      } else if (barangayId == null || barangayId == '') {
        status = '❌ PROBLEM FOUND';
        message = 'barangayId field is NULL or EMPTY!\n\n'
                  'Current value: ${barangayId == null ? "null" : "empty string"}\n\n'
                  'Solution: Set a proper barangayId value in Firebase Console.';
      } else {
        status = '✅ User Document OK';
        message = 'User has valid barangayId: $barangayId\n\n';
        
        // Check if barangay document exists
        print('\n🔍 Checking barangay document...');
        final barangayDoc = await FirebaseFirestore.instance
            .collection('barangays')
            .doc(barangayId)
            .get();

        if (!barangayDoc.exists) {
          status = '⚠️ BARANGAY MISSING';
          message += 'BUT: Barangay document does NOT exist!\n\n'
                     'barangays/$barangayId does not exist.\n\n'
                     'Solution: Create the barangay document in Firebase Console.';
        } else {
          message += 'Barangay document exists: ✅\n\n';
          
          // Try to read patients
          print('\n🔍 Testing patient access...');
          try {
            final patientsSnapshot = await FirebaseFirestore.instance
                .collection('barangays')
                .doc(barangayId)
                .collection('patients')
                .limit(1)
                .get();

            status = '✅ ALL CHECKS PASSED';
            message += 'Can read patients: ✅\n'
                       'Found ${patientsSnapshot.docs.length} patients\n\n'
                       'Everything looks good!';
          } catch (e) {
            status = '❌ PERMISSION DENIED';
            message += 'CANNOT read patients!\n\n'
                       'Error: $e\n\n'
                       'This means Firestore rules are blocking access.\n\n'
                       'Solution: Update your Firestore rules.';
          }
        }
      }

      print('\n═══════════════════════════════════════');
      print('Result: $status');
      print('═══════════════════════════════════════\n');

      _showDialog(context, status, message);

    } catch (e) {
      print('❌ Debug error: $e');
      _showDialog(context, '❌ ERROR', 'Debug failed:\n\n$e');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _debugUser(context),
      icon: const Icon(Icons.bug_report),
      label: const Text('🔍 Debug User'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

// ============================================================================
// HOW TO USE:
// ============================================================================
//
// 1. Add this widget to your home page or settings page:
//
//    const DebugUserButton(),
//
// 2. Click the "Debug User" button
//
// 3. Read the popup message - it will tell you EXACTLY what's wrong
//
// 4. Check your console logs for detailed info
//
// 5. Follow the solution in the message
//
// ============================================================================