class RegisterUserRequest {
  RegisterUserRequest({
    required this.fname,
    required this.lname,
    required this.email,
    required this.password,
    required this.role,
    required this.mobileno,
    required this.gender,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  final String fname;
  final String lname;
  final String email;
  final String password;
  final String role;
  final String mobileno;
  final String gender;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  Map<String, dynamic> toJson() {
    return {
      'fname': fname,
      'lname': lname,
      'email': email,
      'password': password,
      'role': role,
      'mobileno': mobileno,
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }
}
