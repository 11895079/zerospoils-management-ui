library;

/// Domain models for ZeroSpoils inventory system
/// Based on planning/docs/data-model.md
import 'package:equatable/equatable.dart';

/// Item categories enum
enum ItemCategory {
  produce('Produce'),
  dairy('Dairy'),
  meat('Meat'),
  grains('Grains'),
  pantry('Pantry'),
  other('Other');

  final String displayName;
  const ItemCategory(this.displayName);

  static ItemCategory fromString(String value) {
    return ItemCategory.values.firstWhere(
      (cat) => cat.name == value,
      orElse: () => ItemCategory.other,
    );
  }
}

/// Storage location enum
enum StorageLocation {
  fridge('Fridge'),
  pantry('Pantry'),
  freezer('Freezer'),
  other('Other');

  final String displayName;
  const StorageLocation(this.displayName);

  static StorageLocation fromString(String value) {
    return StorageLocation.values.firstWhere(
      (loc) => loc.name == value,
      orElse: () => StorageLocation.other,
    );
  }
}

/// Item status enum
enum ItemStatus {
  available('Available'),
  consumed('Consumed'),
  wasted('Wasted');

  final String displayName;
  const ItemStatus(this.displayName);

  static ItemStatus fromString(String value) {
    return ItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ItemStatus.available,
    );
  }
}

/// Waste reason enum
enum WasteReason {
  spoiled('Spoiled'),
  forgotten('Forgotten'),
  expired('Expired'),
  damaged('Damaged'),
  other('Other');

  final String displayName;
  const WasteReason(this.displayName);

  static WasteReason fromString(String value) {
    return WasteReason.values.firstWhere(
      (reason) => reason.name == value,
      orElse: () => WasteReason.other,
    );
  }
}

/// Item type enum (raw vs prepared)
enum ItemType {
  raw('Raw'),
  prepared('Prepared');

  final String displayName;
  const ItemType(this.displayName);

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ItemType.raw,
    );
  }
}

/// Unit of measurement enum
enum Unit {
  count('Count'),
  liter('Liter'),
  kg('Kg'),
  g('g'),
  lb('lb'),
  oz('oz');

  final String displayName;
  const Unit(this.displayName);

  static Unit fromString(String value) {
    return Unit.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => Unit.count,
    );
  }
}

/// Item model for inventory
class Item extends Equatable {
  final String id;
  final String name;
  final ItemCategory category;
  final ItemType type;
  final DateTime? preparedDate;
  final StorageLocation location;
  final int quantity;
  final Unit unit;
  final DateTime? expiryDate;
  final double? purchasePrice;
  final ItemStatus status;
  final WasteReason? wasteReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.name,
    required this.category,
    this.type = ItemType.raw,
    this.preparedDate,
    required this.location,
    this.quantity = 1,
    this.unit = Unit.count,
    this.expiryDate,
    this.purchasePrice,
    this.status = ItemStatus.available,
    this.wasteReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of Item with optional field overrides
  Item copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    ItemType? type,
    DateTime? preparedDate,
    StorageLocation? location,
    int? quantity,
    Unit? unit,
    DateTime? expiryDate,
    double? purchasePrice,
    ItemStatus? status,
    WasteReason? wasteReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      preparedDate: preparedDate ?? this.preparedDate,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      status: status ?? this.status,
      wasteReason: wasteReason ?? this.wasteReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if item is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final today = DateTime.now();
    final todayAtMidnight = DateTime(today.year, today.month, today.day);
    final expiryAtMidnight = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    return expiryAtMidnight.difference(todayAtMidnight).inDays;
  }

  /// Check if item is expiring soon (within 3 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days >= 0 && days <= 3;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    type,
    preparedDate,
    location,
    quantity,
    unit,
    expiryDate,
    purchasePrice,
    status,
    wasteReason,
    createdAt,
    updatedAt,
  ];
}

/// Shopping list item model
class ShoppingListItem extends Equatable {
  final String id;
  final String name;
  final ItemCategory category;
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.category,
    this.isPurchased = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with optional field overrides
  ShoppingListItem copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    bool? isPurchased,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    isPurchased,
    createdAt,
    updatedAt,
  ];
}

/// Event model for telemetry
class Event extends Equatable {
  final String id;
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? sessionId;
  final bool synced;

  const Event({
    required this.id,
    required this.name,
    required this.properties,
    required this.timestamp,
    this.sessionId,
    this.synced = false,
  });

  /// Create a copy with optional field overrides
  Event copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
    String? sessionId,
    bool? synced,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      properties: properties ?? this.properties,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    properties,
    timestamp,
    sessionId,
    synced,
  ];
}
