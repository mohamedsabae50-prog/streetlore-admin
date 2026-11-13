import 'governorates_config.dart';

class AdminGovernorate {
  static const List<GovernorateConfig> all = GovernorateConfig.all;

  static String normalizeId(String governorateId) =>
      normalizeGovernorateId(governorateId);

  static GovernorateConfig? byId(String governorateId) =>
      governoratesConfig[normalizeId(governorateId)];
}
