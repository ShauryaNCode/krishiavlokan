const Map<String, String> kAdviceImageAssetMap = {
  'start_protective_irrigation':
      'assets/advice/start_protective_irrigation.webp',
  'reduce_soil_moisture_loss':
      'assets/advice/reduce_soil_moisture_loss.webp',
  'check_field_cracks': 'assets/advice/check_field_cracks.webp',
  'open_drainage_channels': 'assets/advice/open_drainage_channels.webp',
  'avoid_more_irrigation': 'assets/advice/avoid_more_irrigation.webp',
  'watch_root_health': 'assets/advice/watch_root_health.webp',
  'scout_the_underside_of_leaves':
      'assets/advice/scout_the_underside_of_leaves.webp',
  'use_traps_or_manual_removal':
      'assets/advice/use_traps_or_manual_removal.webp',
  'escalate_only_if_threshold_is_crossed':
      'assets/advice/escalate_only_if_threshold_is_crossed.webp',
  'improve_air_movement': 'assets/advice/improve_air_movement.webp',
  'remove_infected_leaves': 'assets/advice/remove_infected_leaves.webp',
  'confirm_before_spraying': 'assets/advice/confirm_before_spraying.webp',
  'irrigate_before_peak_heat': 'assets/advice/irrigate_before_peak_heat.webp',
  'protect_flowering_stage': 'assets/advice/protect_flowering_stage.webp',
  'use_temporary_shade_where_practical':
      'assets/advice/use_temporary_shade_where_practical.webp',
  'check_nutrient_pattern': 'assets/advice/check_nutrient_pattern.webp',
  'apply_balanced_nutrition': 'assets/advice/apply_balanced_nutrition.webp',
  'maintain_root_zone_moisture':
      'assets/advice/maintain_root_zone_moisture.webp',
  'keep_monitoring_the_crop': 'assets/advice/keep_monitoring_the_crop.webp',
  'verify_with_local_advisory':
      'assets/advice/verify_with_local_advisory.webp',
  'confirm_diagnosis_locally': 'assets/advice/confirm_diagnosis_locally.webp',
};

String? adviceImageAssetForKey(String adviceKey) {
  return kAdviceImageAssetMap[adviceKey];
}
