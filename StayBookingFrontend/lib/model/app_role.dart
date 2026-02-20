enum AppRole {
  customer,
  vendor,
}

extension AppRoleX on AppRole {
  String get apiValue {
    switch (this) {
      case AppRole.customer:
        return 'CUSTOMER';
      case AppRole.vendor:
        return 'VENDOR';
    }
  }

  String get label {
    switch (this) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.vendor:
        return 'Vendor';
    }
  }
}
