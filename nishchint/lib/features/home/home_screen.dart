import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../data/models/adherence_log_model.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../medicines/add_medicine_screen.dart';
import '../medicines/medicines_list_screen.dart';
import '../patients/add_patient_screen.dart';
import '../patients/patient_profile_screen.dart';
import '../family/family_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/weekly_chart_widget.dart';
import '../../core/utils/language_helper.dart';
import '../../core/constants/strings.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Set<int> _processingIds = {};

  String getGreeting() {
    final hour = DateTime.now().hour;
    // Check if current locale is Hindi (using our helper)
    final bool isHi = LanguageProvider.isHindi(context);
    
    if (hour < 12) return isHi ? 'सुप्रभात' : 'Good Morning';
    if (hour < 17) return isHi ? 'नमस्ते' : 'Good Afternoon';
    return isHi ? 'शुभ संध्या' : 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().fetchPatients();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientData = context.watch<PatientProvider>();
    
    final List<Widget> pages = [
      _buildDashboard(context, patientData),
      const MedicinesListScreen(),
      const FamilyScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Text('Nishchint'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          )
        ],
      ) : null,
      body: patientData.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : patientData.patients.isEmpty
              ? _buildEmptyState(context)
              : pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Medicines'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      floatingActionButton: (patientData.patients.isEmpty || _selectedIndex != 0) 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicineScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Medicine"),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 24),
            Text(
              "Welcome to Nishchint!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "To start setting up Medicine schedules and offline alarms, please create your first Patient Profile.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientScreen(isFirstPatient: true)));
              },
              icon: const Icon(Icons.person_add),
              label: const Text("Set Up Profile"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, PatientProvider patientData) {
    final selectedPatient = patientData.selectedPatient;
    final logs = patientData.adherenceLogs;

    return RefreshIndicator(
      onRefresh: () => patientData.fetchTodayAdherence(selectedPatient!.id),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section — tap to open profile
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: selectedPatient?.photoUrl != null
                        ? NetworkImage(selectedPatient!.photoUrl!)
                        : null,
                    child: selectedPatient?.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${getGreeting()}, ${selectedPatient?.name ?? 'User'}!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text('${logs.length} doses scheduled for today'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weekly adherence chart
            if (selectedPatient != null)
              WeeklyChartWidget(patientId: selectedPatient.id),
            const SizedBox(height: 20),
            
            Text(
              t(AppStrings.todaysMedicinesEn, AppStrings.todaysMedicinesHi),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (logs.isEmpty)
               Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No medications scheduled for today", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
               )
            else
              ...logs.map((log) => _buildAdherenceCard(context, log, patientData)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context, AdherenceLogModel log, PatientProvider provider) {
    Color statusColor;
    IconData statusIcon;
    String statusText = log.status.toUpperCase();

    switch (log.status) {
      case 'taken':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'skipped':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'snoozed':
        statusColor = Colors.orange;
        statusIcon = Icons.snooze;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.radio_button_unchecked;
        statusText = "PENDING";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: log.isCritical ? Colors.red.shade200 : Colors.transparent, 
          width: 2
        )
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.medicineName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(
                        '${log.timeSlot.substring(0, 5)} • ${log.dose} • ${AppStrings.getFoodTiming(log.foodTiming)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (log.status == 'pending') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _processingIds.contains(log.scheduleId)
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () {
                          _markAsTakenAsync(context, log, provider);
                        },
                        icon: const Icon(Icons.done, size: 18),
                        label: Text(t(AppStrings.markTakenEn, AppStrings.markTakenHi).toUpperCase()),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _markAsTakenAsync(BuildContext context, AdherenceLogModel log, PatientProvider provider) async {
     if (_processingIds.contains(log.scheduleId)) return;
     
     setState(() => _processingIds.add(log.scheduleId));
     
     try {
        final ApiService api = ApiService();
        await api.post(ApiConstants.logUpdate, {
          'schedule_id': log.scheduleId,
          'patient_id': provider.selectedPatient!.id,
          'status': 'taken',
          'scheduled_datetime': '${log.scheduledDate} ${log.timeSlot}',
        });

        // Auto-decrement stock
        try {
          await api.post(ApiConstants.medicineDecrementStock, {
            'medicine_id': log.medicineId,
          });
        } catch (e) {
          debugPrint("Error decrementing stock: $e");
          // Non-blocking error for user
        }

        // Notify family
        try {
          await api.post(ApiConstants.familyNotifyTaken, {
            'patient_id': provider.selectedPatient!.id,
            'medicine_name': log.medicineName,
            'schedule_id': log.scheduleId, // Fixed as per BUG-19
            'message': '✅ ${log.medicineName} has been taken!',
          });
        } catch (e) {
          debugPrint("Error notifying family: $e");
        }
        
        // Refresh local state
        await provider.fetchTodayAdherence(provider.selectedPatient!.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Medication marked as taken ✅")),
          );
        }
     } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
     } finally {
        if (mounted) {
          setState(() => _processingIds.remove(log.scheduleId));
        }
     }
  }
}
