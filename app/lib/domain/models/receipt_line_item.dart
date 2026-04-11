import 'package:equatable/equatable.dart';

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
