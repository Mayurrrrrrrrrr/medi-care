import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/family_provider.dart';
import '../../shared/providers/patient_provider.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'member';

  @override
  void initState() {
    super.initState();
    _fetchFamily();
  }

  void _fetchFamily() {
    final patientId = context.read<PatientProvider>().selectedPatient?.id;
    if (patientId != null) {
      context.read<FamilyProvider>().fetchFamilyMembers(patientId);
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invite Family Member"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "e.g. 9876543210",
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: "Role"),
              items: const [
                DropdownMenuItem(value: 'member', child: Text("Member")),
                DropdownMenuItem(value: 'primary', child: Text("Primary (Admin)")),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final patientId = context.read<PatientProvider>().selectedPatient?.id;
              if (patientId == null) return;

              final success = await context.read<FamilyProvider>().inviteMember(
                patientId,
                _phoneController.text,
                _selectedRole,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? "Invitation sent!" : "Failed to invite. Make sure the user is registered.")),
                );
                _phoneController.clear();
              }
            },
            child: const Text("Invite"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Members"),
        actions: [
          IconButton(onPressed: _fetchFamily, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, family, child) {
          if (family.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (family.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No family members found yet."),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Invite First Member"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: family.members.length,
            itemBuilder: (context, index) {
              final member = family.members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: member.role == 'primary' ? Colors.blue.shade100 : Colors.grey.shade100,
                    child: Icon(
                      member.role == 'primary' ? Icons.admin_panel_settings : Icons.person,
                      color: member.role == 'primary' ? Colors.blue : Colors.grey,
                    ),
                  ),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member.phone),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: member.role == 'primary' ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: member.role == 'primary' ? Colors.blue : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
