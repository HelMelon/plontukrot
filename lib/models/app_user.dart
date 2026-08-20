class AppUser {
  final String uid;
  final String? photoUrl;
  final String? email;
  final String? name;

  const AppUser({
    required this.uid,
    this.photoUrl,
    this.email,
    this.name,
  });
}
