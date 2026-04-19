class ShopModel {
  final int id;
  final String shopName;
  final String ownerName;
  final String shopType;
  final String pinCode;
  final String shopAddress;
  final String location;
  final String contactNumber;
  final String photoUrl;
  final int userId;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>>? workingHours;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.shopType,
    required this.pinCode,
    required this.shopAddress,
    required this.location,
    required this.contactNumber,
    required this.photoUrl,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.workingHours,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? workingHours;
    if (json['working_hours'] != null) {
      workingHours = List<Map<String, dynamic>>.from(
        json['working_hours'].map((item) => Map<String, dynamic>.from(item)),
      );
    }

    return ShopModel(
      id: json['id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      shopType: json['shop_type'] ?? '',
      pinCode: json['pin_code'] ?? '',
      shopAddress: json['shop_address'] ?? '',
      location: json['location'] ?? '',
      contactNumber: json['number'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      workingHours: workingHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'owner_name': ownerName,
      'shop_type': shopType,
      'pin_code': pinCode,
      'shop_address': shopAddress,
      'location': location,
      'number': contactNumber,
      'photo_url': photoUrl,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'working_hours': workingHours,
    };
  }

  // Helper method to get shop type display text
  String get shopTypeDisplayText {
    switch (shopType.toLowerCase()) {
      case 'grocery store':
        return 'Grocery Store';
      case 'electronics':
        return 'Electronics';
      case 'clothing':
        return 'Clothing';
      case 'restaurant':
        return 'Restaurant';
      case 'pharmacy':
        return 'Pharmacy';
      case 'hardware store':
        return 'Hardware Store';
      case 'beauty & cosmetics':
        return 'Beauty & Cosmetics';
      case 'book store':
        return 'Book Store';
      default:
        return shopType;
    }
  }
}
