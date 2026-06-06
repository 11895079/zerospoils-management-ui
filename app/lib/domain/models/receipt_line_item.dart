import 'package:equatable/equatable.dart';

enum ReceiptRowClassification {
  saleItem,
  tax,
  total,
  loyalty,
  payment,
  savings,
  department,
  storeInfo,
  unknown,
}

class ReceiptOcrBox extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const ReceiptOcrBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  ReceiptOcrBox union(ReceiptOcrBox other) {
    return ReceiptOcrBox(
      left: left < other.left ? left : other.left,
      top: top < other.top ? top : other.top,
      right: right > other.right ? right : other.right,
      bottom: bottom > other.bottom ? bottom : other.bottom,
    );
  }

  @override
  List<Object?> get props => [left, top, right, bottom];
}

class ReceiptOcrLine extends Equatable {
  final String text;
  final int photoIndex;
  final ReceiptOcrBox? box;

  const ReceiptOcrLine({required this.text, this.photoIndex = 0, this.box});

  @override
  List<Object?> get props => [text, photoIndex, box];
}

class ReceiptLineItem extends Equatable {
  final String name;
  final double price;
  final int photoIndex;
  final ReceiptOcrBox? ocrBox;

  const ReceiptLineItem({
    required this.name,
    required this.price,
    this.photoIndex = 0,
    this.ocrBox,
  });

  @override
  List<Object?> get props => [name, price, photoIndex, ocrBox];
}

class ReceiptClassifiedRow extends Equatable {
  final String text;
  final int photoIndex;
  final ReceiptOcrBox? box;
  final ReceiptRowClassification classification;
  final String? extractedName;
  final double? extractedPrice;

  const ReceiptClassifiedRow({
    required this.text,
    required this.photoIndex,
    required this.box,
    required this.classification,
    this.extractedName,
    this.extractedPrice,
  });

  bool get isAccepted => classification == ReceiptRowClassification.saleItem;

  @override
  List<Object?> get props => [
    text,
    photoIndex,
    box,
    classification,
    extractedName,
    extractedPrice,
  ];
}

class ReceiptParseResult extends Equatable {
  final List<ReceiptLineItem> items;
  final List<ReceiptClassifiedRow> rows;
  final double? taxAmount;
  final double? totalAmount;
  final double? savingsAmount;

  const ReceiptParseResult({
    required this.items,
    required this.rows,
    this.taxAmount,
    this.totalAmount,
    this.savingsAmount,
  });

  List<ReceiptClassifiedRow> get acceptedRows =>
      rows.where((row) => row.isAccepted).toList(growable: false);

  List<ReceiptClassifiedRow> get rejectedRows =>
      rows.where((row) => !row.isAccepted).toList(growable: false);

  @override
  List<Object?> get props => [
    items,
    rows,
    taxAmount,
    totalAmount,
    savingsAmount,
  ];
}
