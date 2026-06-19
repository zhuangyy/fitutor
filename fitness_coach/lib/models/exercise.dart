class Exercise {
  final int? id;
  final String name;
  final String category;      // '力量' 或 '计时'
  final String muscleGroup;
  final String iconCode;      // Flutter IconData codePoint
  final String? description;
  bool _isPreset;
  final String? createdAt;

  Exercise({
    this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.iconCode,
    this.description,
    bool isPreset = false,
    this.createdAt,
  }) : _isPreset = isPreset;

  bool get isPreset => _isPreset;
  set isPreset(bool value) => _isPreset = value;

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      muscleGroup: map['muscle_group'] as String,
      iconCode: map['icon_code'] as String,
      description: map['description'] as String?,
      isPreset: (map['is_preset'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'muscle_group': muscleGroup,
      'icon_code': iconCode,
      'description': description,
      'is_preset': _isPreset ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? category,
    String? muscleGroup,
    String? iconCode,
    String? description,
    bool? isPreset,
    String? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      isPreset: isPreset ?? _isPreset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => name;
}
