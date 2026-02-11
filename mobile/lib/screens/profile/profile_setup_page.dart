import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/premium_dropdown.dart';
import '../../widgets/premium_loader.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _bioCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _tribeCtrl = TextEditingController();

  // Dropdown Values
  String _gender = 'Male';
  String _country = 'Nigeria';
  String _genotype = 'AA';
  String _relationshipStatus = 'Single';

  // Selections
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _genotypes = ['AA', 'AS', 'SS', 'AC'];
  final List<String> _countries = ['Nigeria', 'Ghana', 'Kenya', 'USA', 'UK'];
  final List<String> _statuses = ['Single', 'Divorced', 'Widowed'];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfileProvider>().updateProfile({
        'bio': _bioCtrl.text,
        'gender': _gender,
        'country': _country,
        'state': _stateCtrl.text,
        'tribe': _tribeCtrl.text,
        'genotype': _genotype,
        'relationshipStatus': _relationshipStatus,
        'firstName':
            'User', // In updates, these might be optional if already set on register
      });

      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<ProfileProvider>().error ?? 'Failed to save profile',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: isLoading
          ? const Center(child: PremiumLoader())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Tell us about yourself',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  PremiumDropdown(
                    label: 'Gender',
                    value: _gender,
                    items: _genders,
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                  const SizedBox(height: 16),

                  PremiumDropdown(
                    label: 'Country',
                    value: _country,
                    items: _countries,
                    onChanged: (v) => setState(() => _country = v!),
                  ),

                  if (_country == 'Nigeria') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State of Origin',
                      ),
                    ),
                    TextFormField(
                      controller: _tribeCtrl,
                      decoration: const InputDecoration(labelText: 'Tribe'),
                    ),
                  ],

                  const SizedBox(height: 16),

                  PremiumDropdown(
                    label: 'Genotype',
                    value: _genotype,
                    items: _genotypes,
                    onChanged: (v) => setState(() => _genotype = v!),
                  ),
                  const SizedBox(height: 16),

                  PremiumDropdown(
                    label: 'Relationship Status',
                    value: _relationshipStatus,
                    items: _statuses,
                    onChanged: (v) => setState(() => _relationshipStatus = v!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bio (Short description)',
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
