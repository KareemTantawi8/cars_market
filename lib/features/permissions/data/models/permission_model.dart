/// Permission model for list/detail from API (id, name, slug, description, roles_count?)
class PermissionModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int? rolesCount;

  const PermissionModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.rolesCount,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      rolesCount: json['roles_count'] != null ? (json['roles_count'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (rolesCount != null) 'roles_count': rolesCount,
    };
  }
}
