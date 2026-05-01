class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // Role add kiya
  final String? profilePic;
  final Map<String, dynamic>? preferences;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role, // Required field
    this.profilePic,
    this.preferences,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? 'No Name',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user', // Default 'user'
      profilePic: map['profilePic'],
      preferences: map['preferences'],
    );
  }
}
