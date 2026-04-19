class TicketModel {
  final int id;
  final String email;
  final String fullName;
  final String mobileNumber;
  final String category;
  final String description;
  final String status;
  final int userId;
  final String? createdAt;
  final String? updatedAt;

  TicketModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.mobileNumber,
    required this.category,
    required this.description,
    required this.status,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'category': category,
      'description': description,
      'status': status,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper method to get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'in_progress':
        return '#2196F3'; // Blue
      case 'resolved':
        return '#4CAF50'; // Green
      case 'closed':
        return '#9E9E9E'; // Grey
      default:
        return '#FFA500'; // Default to orange
    }
  }

  // Helper method to get status display text
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Pending';
    }
  }
}
