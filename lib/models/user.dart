class User {
  final String uid;
  final String phoneNumber;
  final String? profileUrl;
  final String displayName;
  final DateTime lastSeen;
  final String? statusContent;

  User({
    required this.uid,
    required this.phoneNumber,
    this.profileUrl,
    required this.displayName,
    required this.lastSeen,
    this.statusContent,
  });

  // Convert the User object to a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'displayName': displayName,
      'lastSeen': lastSeen.toIso8601String(), // Convert DateTime to String
      'statusContent': statusContent,
    };
  }

  // Create a User object from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      phoneNumber: map['phoneNumber'],
      profileUrl: map['profileUrl'],
      displayName: map['displayName'],
      lastSeen: DateTime.parse(map['lastSeen']), // Convert String to DateTime
      statusContent: map['statusContent'],
    );
  }
}