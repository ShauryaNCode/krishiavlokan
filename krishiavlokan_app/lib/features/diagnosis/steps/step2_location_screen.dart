// lib/features/diagnosis/steps/step2_location_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  String? _selectedState;
  String? _selectedDistrict;
  bool _loadingGps = false;

  List<String> get _districts =>
      _selectedState != null
          ? AppLocations.statesDistricts[_selectedState!] ?? []
          : [];

  void _selectGps() async {
    setState(() => _loadingGps = true);
    // Simulate GPS lookup delay
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _loadingGps = false;
      _selectedState    = 'Maharashtra';
      _selectedDistrict = 'Nagpur';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();
    final canProceed =
        _selectedState != null && _selectedDistrict != null;

    return DiagnosisStepScaffold(
      step: 2,
      title: 'Location Chuniye',
      showOfflineBanner: provider.offlineMode,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Aap kahan ke hain?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Where are you located?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          VoiceButton(),
          const SizedBox(height: 24),

          // State dropdown
          _DropdownCard(
            label: 'Rajya / State',
            hint: 'Chuniye...',
            value: _selectedState,
            items: AppLocations.statesDistricts.keys.toList(),
            onChanged: (val) => setState(() {
              _selectedState    = val;
              _selectedDistrict = null;
            }),
          ),
          const SizedBox(height: 12),

          // District dropdown
          _DropdownCard(
            label: 'Zila / District',
            hint: _selectedState == null
                ? 'Pehle Rajya chuniye...'
                : 'Chuniye...',
            value: _selectedDistrict,
            items: _districts,
            onChanged: _selectedState == null
                ? null
                : (val) => setState(() => _selectedDistrict = val),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider(color: AppColors.lightGrey)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'YA / OR',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.midGrey),
                ),
              ),
              Expanded(child: Divider(color: AppColors.lightGrey)),
            ],
          ),
          const SizedBox(height: 20),

          // GPS button
          OutlinedButton.icon(
            onPressed: _loadingGps ? null : _selectGps,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.deepGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _loadingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.deepGreen),
                  )
                : const Icon(Icons.my_location_rounded,
                    color: AppColors.deepGreen),
            label: Text(
              _loadingGps ? 'GPS Dhoondh raha hai...' : 'GPS se Location Lo',
              style: const TextStyle(color: AppColors.deepGreen),
            ),
          ),

          if (_selectedState != null && _selectedDistrict != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.deepGreen, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '$_selectedDistrict, $_selectedState',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.successGreen),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomBar: KaNextButton(
        isEnabled: canProceed,
        onPressed: () {
          provider.setLocation(_selectedState!, _selectedDistrict!);
          context.go(AppRoutes.step3);
        },
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _DropdownCard({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? AppColors.deepGreen : AppColors.lightGrey,
          width: value != null ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.deepGreen),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
