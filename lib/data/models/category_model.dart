class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final String? parentId;
  final CategoryModel? parent;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.parentId,
    this.parent,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: (json['iconUrl'] ?? json['icon_url'])?.toString(),
      parentId: (json['parentId'] ?? json['parent_id'])?.toString(),
      parent: json['parent'] != null
          ? CategoryModel.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    if (iconUrl != null) 'iconUrl': iconUrl,
    if (parentId != null) 'parentId': parentId,
  };

  /// Display label — shows full hierarchy: "Electronics › Phones"
  String get breadcrumb {
    if (parent != null) return '${parent!.name} › $name';
    return name;
  }

  @override
  String toString() => name;
}
