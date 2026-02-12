import 'package:equatable/equatable.dart';

class ReceiptLineItem extends Equatable {
  final String name;
  final double price;

  const ReceiptLineItem({required this.name, required this.price});

  @override
  List<Object?> get props => [name, price];
}
