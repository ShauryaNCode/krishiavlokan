// lib/features/diagnosis/steps/step2_location_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  String? _selectedState;
  String? _selectedDistrict;
  double _lat = 0.0;
  double _lon = 0.0;
  bool _loadingGps = false;

  List<String> get _districts => _selectedState != null
      ? AppLocations.statesDistricts[_selectedState!] ?? []
      : [];

  /// Resolves coordinates when a district is selected from the dropdown.
  void _onDistrictSelected(String district) {
    final (lat, lon) = AppLocations.coordsFor(district);
    setState(() {
      _selectedDistrict = district;
      _lat = lat;
      _lon = lon;
    });
  }

  ///Real GPS Extraction
  void _selectGps() async {
  setState(() => _loadingGps = true);

  try {
    // 1. Permission & Service Check
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Attempt Real Location Fetch with 5s Timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    // 3. Attempt Reverse Geocoding
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String? detectedState = place.administrativeArea;
      String? detectedDistrict = place.subAdministrativeArea;

      setState(() {
        _loadingGps = false;
        _lat = position.latitude;
        _lon = position.longitude;

        // --- NEW SAFETY LOGIC ---
        
        // Check if our Map recognizes this State
        if (AppLocations.statesDistricts.containsKey(detectedState)) {
          _selectedState = detectedState;

          // Check if District exists in our list for this State
          if (AppLocations.statesDistricts[_selectedState]!.contains(detectedDistrict)) {
            _selectedDistrict = detectedDistrict;
          } else {
            // FALLBACK: State is right, but District name is missing/different
            // We use the first district in the list (index 0)
            _selectedDistrict = AppLocations.statesDistricts[_selectedState]![0];
            debugPrint("District unrecognized. Falling back to index 0.");
          }
        } else {
          // State not in our list (e.g. user is in Kerala)
          _applyMockFallback();
        }
      });
    } else {
      _applyMockFallback();
    }
  } catch (e) {
    debugPrint("GPS failed, using fallback: $e");
    _applyMockFallback();
  }
}

// Your helper to reset to Pune defaults
void _applyMockFallback() {
  setState(() {
    _loadingGps = false;
    _selectedState = 'Maharashtra';
    _selectedDistrict = 'Pune';
    _lat = 18.5204;
    _lon = 73.8567;
  });
}



  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();
    final canProceed = _selectedState != null && _selectedDistrict != null;

    return DiagnosisStepScaffold(
      step: 2,
      title: 'Location',
      showOfflineBanner: provider.offlineMode,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text('Where are you located?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Select state and district, or use GPS.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          VoiceButton(),
          const SizedBox(height: 24),

          // State dropdown
          _DropdownCard(
            label: 'State',
            hint: 'Select state...',
            value: _selectedState,
            items: AppLocations.statesDistricts.keys.toList(),
            onChanged: (val) => setState(() {
              _selectedState = val;
              _selectedDistrict = null;
              _lat = 0.0;
              _lon = 0.0;
            }),
          ),
          const SizedBox(height: 12),

          // District dropdown
          _DropdownCard(
            label: 'District',
            hint: _selectedState == null
                ? 'Select state first...'
                : 'Select district...',
            value: _selectedDistrict,
            items: _districts,
            onChanged: _selectedState == null
                ? null
                : (val) {
                    if (val != null) _onDistrictSelected(val);
                  },
          ),

          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Divider(color: AppColors.lightGrey)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.midGrey)),
            ),
            Expanded(child: Divider(color: AppColors.lightGrey)),
          ]),
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
                        strokeWidth: 2, color: AppColors.deepGreen))
                : const Icon(Icons.my_location_rounded,
                    color: AppColors.deepGreen),
            label: Text(
              _loadingGps ? 'Finding location...' : 'Use GPS Location',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.deepGreen, size: 20),
                    const SizedBox(width: 10),
                    Text('$_selectedDistrict, $_selectedState',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.deepGreen,
                              fontWeight: FontWeight.bold,
                            )),
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.successGreen),
                  ]),
                  if (_lat != 0.0) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(
                        'Lat: ${_lat.toStringAsFixed(4)}, '
                        'Lon: ${_lon.toStringAsFixed(4)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.midGrey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      bottomBar: KaNextButton(
        isEnabled: canProceed,
        onPressed: () {
          provider.setLocation(
            _selectedState!,
            _selectedDistrict!,
            lat: _lat,
            lon: _lon,
          );
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
