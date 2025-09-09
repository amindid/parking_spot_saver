class ParkingSpot {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? photoPath;
  final String? notes;
  final String name;

  const ParkingSpot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.photoPath,
    this.notes,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'photoPath': photoPath,
      'notes': notes,
      'name': name,
    };
  }

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      photoPath: json['photoPath'] as String?,
      notes: json['notes'] as String?,
      name: json['name'] as String,
    );
  }

  String getFormattedCoordinates() {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  String getFormattedTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}