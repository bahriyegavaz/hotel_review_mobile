/// Rapordaki roller (bölüm 6): Admin, Manager, DepartmentUser, MobileUser
enum UserRole {
  admin,
  manager,
  departmentUser,
  mobileUser,
  unknown;

  /// Backend'den string olarak gelen rolü enum'a çevirir.
  /// Backend "Admin" / "admin" / "ADMIN" hangisini dönerse dönsün çalışsın diye
  /// küçük harfe indirip karşılaştırıyoruz.
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'departmentuser':
        return UserRole.departmentUser;
      case 'mobileuser':
        return UserRole.mobileUser;
      default:
        return UserRole.unknown;
    }
  }
}

/// Uygulama içinde kullanılan kullanıcı modeli.
/// Bu sınıf JSON bilmez, HTTP bilmez - sadece "kullanıcı nedir" onu tarif eder.
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.departmentId,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? departmentId;

  /// Saha personeli (DepartmentUser/MobileUser) mobilde sadece kendi
  /// departmanının aksiyonlarını görür.
  bool get isDepartmentScoped =>
      role == UserRole.departmentUser || role == UserRole.mobileUser;

  /// Admin/Manager tüm departmanların görevlerini görebilir.
  bool get canViewAllDepartments =>
      role == UserRole.admin || role == UserRole.manager;
}
