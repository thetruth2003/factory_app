/// Stable codes keep reports comparable when the interface language changes.
abstract final class CallReasons {
  static const byKind = {
    'fault': ['machine_stopped', 'material_jam', 'machine_alarm'],
    'quality': ['shape_size', 'baking_colour', 'packaging_seal'],
    'material': ['material_empty', 'packaging_empty'],
    'support': ['operator_help', 'technical_check'],
  };
  static bool valid(String kind, String? code) =>
      code == null || (byKind[kind]?.contains(code) ?? false);
}
