enum AppRole {
  customer,
  vendor,
  admin,
}

extension AppRoleX on AppRole {
  String get apiValue {
    switch (this) {
      case AppRole.customer:
        return 'CUSTOMER';
      case AppRole.vendor:
        return 'VENDOR';
      case AppRole.admin:
        return 'ADMIN';
    }
  }

  String get label {
    switch (this) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.vendor:
        return 'Vendor';
      case AppRole.admin:
        return 'Admin';
    }
  }
}