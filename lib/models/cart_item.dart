import 'food.dart';

class CartItem {
  final Food food;
  int qty;
  final String selectedOption;

  CartItem({required this.food, this.qty = 1, this.selectedOption = ''});

  double get lineTotal => food.price * qty;
  String get key => '${food.id}::$selectedOption';
}
