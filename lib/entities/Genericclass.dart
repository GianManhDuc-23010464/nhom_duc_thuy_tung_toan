// lib/entities/Genericclass.dart
// ignore_for_file: file_names

/// Lớp Generic cơ sở chứa các đặc điểm chung: id, name, description
/// và các phương thức chung getter / setter tương ứng theo bài giảng Generics.
class Genericclass<T> {
  T id;
  T name;
  T description;

  Genericclass({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Lấy id
  T getId() {
    return id;
  }

  /// Lấy name
  T getName() {
    return name;
  }

  /// Lấy description
  T getDescription() {
    return description;
  }

  /// Cập nhật id
  T setId(T newId) {
    id = newId;
    return id;
  }

  /// Cập nhật name
  T setName(T newName) {
    name = newName;
    return name;
  }

  /// Cập nhật description
  T setDescription(T newDescription) {
    description = newDescription;
    return description;
  }

  @override
  String toString() {
    return 'Genericclass<$T>(id: $id, name: $name, description: $description)';
  }
}
