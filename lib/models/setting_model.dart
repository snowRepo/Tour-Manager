class SettingModel {
  final String key;
  final String value;

  const SettingModel({required this.key, required this.value});

  Map<String, dynamic> toMap() => {'key': key, 'value': value};

  factory SettingModel.fromMap(Map<String, dynamic> map) => SettingModel(
        key: map['key'] as String,
        value: map['value'] as String,
      );
}
