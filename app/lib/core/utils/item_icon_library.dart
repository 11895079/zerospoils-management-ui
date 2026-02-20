library;

import 'package:flutter/material.dart';
import '../../domain/models/item_model.dart';

/// Well-curated icon library for common grocery and food items
/// Maps item names to Material Design Icons for consistent display
/// across inventory list, detail, and edit screens
class ItemIconLibrary {
  // Prevent instantiation
  ItemIconLibrary._();

  /// Generic fallback icon for unknown items
  static const IconData genericIcon = Icons.shopping_basket_outlined;

  /// Icon for items with no specific match
  static const IconData unknownIcon = Icons.help_outline;

  /// Comprehensive mapping of item names (lowercase) to icons
  /// Organized by category for maintainability
  static final Map<String, IconData> _itemIconMap = {
    // ===== PRODUCE - Fruits =====
    'apple': Icons.apple,
    'apples': Icons.apple,
    'banana': Icons.set_meal,
    'bananas': Icons.set_meal,
    'blueberry': Icons.grain,
    'blueberries': Icons.grain,
    'strawberry': Icons.grain,
    'strawberries': Icons.grain,
    'raspberry': Icons.grain,
    'raspberries': Icons.grain,
    'orange': Icons.circle,
    'oranges': Icons.circle,
    'lemon': Icons.circle,
    'lemons': Icons.circle,
    'lime': Icons.circle,
    'limes': Icons.circle,
    'grape': Icons.grain,
    'grapes': Icons.grain,
    'mango': Icons.set_meal,
    'mangoes': Icons.set_meal,
    'pineapple': Icons.set_meal,
    'pineapples': Icons.set_meal,
    'watermelon': Icons.set_meal,
    'watermelons': Icons.set_meal,
    'cantaloupe': Icons.set_meal,
    'melon': Icons.set_meal,
    'melons': Icons.set_meal,
    'peach': Icons.set_meal,
    'peaches': Icons.set_meal,
    'pear': Icons.set_meal,
    'pears': Icons.set_meal,
    'avocado': Icons.eco,
    'avocados': Icons.eco,
    'coconut': Icons.circle,
    'coconuts': Icons.circle,
    'kiwi': Icons.circle,
    'kiwis': Icons.circle,
    'papaya': Icons.set_meal,
    'papayas': Icons.set_meal,
    'guava': Icons.set_meal,
    'guavas': Icons.set_meal,
    'dragonfruit': Icons.set_meal,

    // ===== PRODUCE - Vegetables =====
    'broccoli': Icons.eco,
    'carrot': Icons.eco,
    'carrots': Icons.eco,
    'spinach': Icons.eco,
    'lettuce': Icons.eco,
    'kale': Icons.eco,
    'cabbage': Icons.eco,
    'tomato': Icons.circle,
    'tomatoes': Icons.circle,
    'cucumber': Icons.eco,
    'cucumbers': Icons.eco,
    'zucchini': Icons.eco,
    'zucchinis': Icons.eco,
    'bell pepper': Icons.circle,
    'bell peppers': Icons.circle,
    'pepper': Icons.circle,
    'peppers': Icons.circle,
    'onion': Icons.circle,
    'onions': Icons.circle,
    'garlic': Icons.circle,
    'celery': Icons.eco,
    'cauliflower': Icons.eco,
    'mushroom': Icons.eco,
    'mushrooms': Icons.eco,
    'potato': Icons.circle,
    'potatoes': Icons.circle,
    'sweet potato': Icons.circle,
    'sweet potatoes': Icons.circle,
    'yam': Icons.circle,
    'yams': Icons.circle,
    'artichoke': Icons.eco,
    'artichokes': Icons.eco,
    'asparagus': Icons.eco,
    'green bean': Icons.eco,
    'green beans': Icons.eco,
    'pea': Icons.grain,
    'peas': Icons.grain,
    'corn': Icons.grain,
    'corns': Icons.grain,
    'eggplant': Icons.eco,
    'eggplants': Icons.eco,
    'squash': Icons.eco,
    'pumpkin': Icons.eco,
    'radish': Icons.eco,
    'radishes': Icons.eco,
    'beet': Icons.circle,
    'beets': Icons.circle,
    'caraway': Icons.eco,

    // ===== DAIRY & ALTERNATIVES =====
    'milk': Icons.local_drink,
    'whole milk': Icons.local_drink,
    'skim milk': Icons.local_drink,
    '2% milk': Icons.local_drink,
    'almond milk': Icons.local_drink,
    'oat milk': Icons.local_drink,
    'soy milk': Icons.local_drink,
    'coconut milk': Icons.local_drink,
    'cheese': Icons.cake,
    'cheddar': Icons.cake,
    'mozzarella': Icons.cake,
    'parmesan': Icons.cake,
    'cream cheese': Icons.cake,
    'feta': Icons.cake,
    'yogurt': Icons.icecream,
    'greek yogurt': Icons.icecream,
    'butter': Icons.cake,
    'butter spread': Icons.cake,
    'ghee': Icons.local_drink,
    'cream': Icons.local_drink,
    'sour cream': Icons.icecream,
    'cottage cheese': Icons.icecream,
    'ricotta': Icons.icecream,
    'egg': Icons.egg,
    'eggs': Icons.egg,
    'egg white': Icons.egg,
    'egg yolk': Icons.egg,

    // ===== MEAT & PROTEIN =====
    'chicken': Icons.set_meal,
    'chicken breast': Icons.set_meal,
    'chicken thigh': Icons.set_meal,
    'chicken wing': Icons.set_meal,
    'ground chicken': Icons.set_meal,
    'beef': Icons.set_meal,
    'steak': Icons.set_meal,
    'ground beef': Icons.set_meal,
    'beef roast': Icons.set_meal,
    'ribs': Icons.set_meal,
    'pork': Icons.set_meal,
    'pork chop': Icons.set_meal,
    'ground pork': Icons.set_meal,
    'pork belly': Icons.set_meal,
    'bacon': Icons.set_meal,
    'sausage': Icons.set_meal,
    'ham': Icons.set_meal,
    'turkey': Icons.set_meal,
    'duck': Icons.set_meal,
    'lamb': Icons.set_meal,
    'veal': Icons.set_meal,
    'venison': Icons.set_meal,
    'fish': Icons.set_meal,
    'salmon': Icons.set_meal,
    'tuna': Icons.set_meal,
    'cod': Icons.set_meal,
    'tilapia': Icons.set_meal,
    'shrimp': Icons.set_meal,
    'prawns': Icons.set_meal,
    'crab': Icons.set_meal,
    'lobster': Icons.set_meal,
    'oyster': Icons.set_meal,
    'clam': Icons.set_meal,
    'mussel': Icons.set_meal,
    'scallop': Icons.set_meal,
    'squid': Icons.set_meal,
    'tofu': Icons.grain,
    'tempeh': Icons.grain,
    'seitan': Icons.grain,

    // ===== GRAINS & STARCHES =====
    'rice': Icons.grain,
    'white rice': Icons.grain,
    'brown rice': Icons.grain,
    'jasmine rice': Icons.grain,
    'basmati rice': Icons.grain,
    'wild rice': Icons.grain,
    'wheat': Icons.grain,
    'barley': Icons.grain,
    'oat': Icons.grain,
    'oats': Icons.grain,
    'quinoa': Icons.grain,
    'flour': Icons.kitchen,
    'bread': Icons.bakery_dining,
    'white bread': Icons.bakery_dining,
    'whole wheat bread': Icons.bakery_dining,
    'sourdough': Icons.bakery_dining,
    'bagel': Icons.bakery_dining,
    'bagels': Icons.bakery_dining,
    'pasta': Icons.ramen_dining,
    'spaghetti': Icons.ramen_dining,
    'noodle': Icons.ramen_dining,
    'noodles': Icons.ramen_dining,
    'ramen': Icons.ramen_dining,
    'couscous': Icons.grain,
    'millet': Icons.grain,
    'polenta': Icons.grain,
    'cornmeal': Icons.grain,
    'lentil': Icons.grain,
    'lentils': Icons.grain,
    'bean': Icons.grain,
    'beans': Icons.grain,
    'chickpea': Icons.grain,
    'chickpeas': Icons.grain,
    'black bean': Icons.grain,
    'black beans': Icons.grain,
    'kidney bean': Icons.grain,
    'kidney beans': Icons.grain,
    'pinto bean': Icons.grain,
    'pinto beans': Icons.grain,
    'split pea': Icons.grain,
    'split peas': Icons.grain,

    // ===== PANTRY STAPLES =====
    'oil': Icons.local_drink,
    'olive oil': Icons.local_drink,
    'vegetable oil': Icons.local_drink,
    'coconut oil': Icons.local_drink,
    'canola oil': Icons.local_drink,
    'sesame oil': Icons.local_drink,
    'peanut oil': Icons.local_drink,
    'salt': Icons.kitchen,
    'sugar': Icons.kitchen,
    'honey': Icons.kitchen,
    'syrup': Icons.local_drink,
    'maple syrup': Icons.local_drink,
    'vinegar': Icons.local_drink,
    'soy sauce': Icons.local_drink,
    'worcestershire sauce': Icons.local_drink,
    'hot sauce': Icons.local_drink,
    'sauce': Icons.restaurant,
    'peanut butter': Icons.cake,
    'almond butter': Icons.cake,
    'jam': Icons.cake,
    'jelly': Icons.cake,
    'marmalade': Icons.cake,
    'spice': Icons.kitchen,
    'spices': Icons.kitchen,
    'cinnamon': Icons.kitchen,
    'vanilla': Icons.kitchen,
    'paprika': Icons.kitchen,
    'cumin': Icons.kitchen,
    'turmeric': Icons.kitchen,
    'black pepper': Icons.kitchen,
    'cayenne': Icons.kitchen,
    'chili powder': Icons.kitchen,
    'mustard': Icons.restaurant,
    'ketchup': Icons.restaurant,
    'mayonnaise': Icons.restaurant,
    'pesto': Icons.restaurant,
    'salsa': Icons.restaurant,
    'baking powder': Icons.kitchen,
    'baking soda': Icons.kitchen,
    'yeast': Icons.kitchen,
    'gelatin': Icons.kitchen,
    'cornstarch': Icons.kitchen,
    'chocolate': Icons.cake,
    'cocoa powder': Icons.kitchen,
    'coffee': Icons.local_cafe,
    'tea': Icons.local_drink,
    'cereal': Icons.grain,

    // ===== BEVERAGES =====
    'juice': Icons.local_drink,
    'orange juice': Icons.local_drink,
    'apple juice': Icons.local_drink,
    'cranberry juice': Icons.local_drink,
    'lemonade': Icons.local_drink,
    'smoothie': Icons.restaurant,
    'soda': Icons.local_drink,
    'cola': Icons.local_drink,
    'sprite': Icons.local_drink,
    'beer': Icons.local_bar,
    'wine': Icons.local_bar,
    'red wine': Icons.local_bar,
    'white wine': Icons.local_bar,
    'champagne': Icons.local_bar,
    'vodka': Icons.local_bar,
    'rum': Icons.local_bar,
    'whiskey': Icons.local_bar,
    'gin': Icons.local_bar,
    'tequila': Icons.local_bar,
    'water': Icons.local_drink,
    'sparkling water': Icons.local_drink,
    'coconut water': Icons.local_drink,

    // ===== FROZEN FOODS =====
    'frozen pizza': Icons.fastfood,
    'frozen dinner': Icons.fastfood,
    'frozen vegetable': Icons.eco,
    'frozen vegetables': Icons.eco,
    'frozen fruit': Icons.grain,
    'frozen fruits': Icons.grain,
    'ice cream': Icons.ac_unit,
    'frozen yogurt': Icons.ac_unit,
    'frozen dessert': Icons.ac_unit,
    'frozen entrée': Icons.fastfood,

    // ===== PREPARED/COOKED FOODS =====
    'amala': Icons.ramen_dining,
    'fufu': Icons.ramen_dining,
    'jollof rice': Icons.ramen_dining,
    'couscous salad': Icons.ramen_dining,
    'dhal': Icons.ramen_dining,
    'dal': Icons.ramen_dining,
    'curry': Icons.ramen_dining,
    'stew': Icons.ramen_dining,
    'soup': Icons.ramen_dining,
    'broth': Icons.ramen_dining,
    'stock': Icons.restaurant,
    'dressing': Icons.restaurant,
    'hummus': Icons.cake,
    'baba ganoush': Icons.cake,
    'tzatziki': Icons.restaurant,
    'guacamole': Icons.cake,
    'pate': Icons.set_meal,
    'terrine': Icons.set_meal,
    'prepared meal': Icons.ramen_dining,
    'leftovers': Icons.ramen_dining,
    'takeout': Icons.fastfood,
    'pizza': Icons.fastfood,
    'sandwich': Icons.fastfood,
    'burger': Icons.fastfood,
    'sushi': Icons.ramen_dining,
    'sashimi': Icons.set_meal,
    'dim sum': Icons.ramen_dining,
    'dumpling': Icons.ramen_dining,
    'dumplings': Icons.ramen_dining,
    'pasta salad': Icons.ramen_dining,
    'grain salad': Icons.restaurant,
    'salad': Icons.restaurant,
    'coleslaw': Icons.restaurant,

    // ===== SNACKS & DESSERTS =====
    'chip': Icons.grain,
    'chips': Icons.grain,
    'cracker': Icons.grain,
    'crackers': Icons.grain,
    'cookie': Icons.cake,
    'cookies': Icons.cake,
    'candy': Icons.cake,
    'brownie': Icons.cake,
    'cake': Icons.cake,
    'cupcake': Icons.cake,
    'pie': Icons.cake,
    'tart': Icons.cake,
    'donut': Icons.cake,
    'pastry': Icons.cake,
    'croissant': Icons.bakery_dining,
    'muffin': Icons.bakery_dining,
    'scone': Icons.bakery_dining,
    'granola': Icons.grain,
    'granola bar': Icons.grain,
    'protein bar': Icons.grain,
    'cereal bar': Icons.grain,
    'trail mix': Icons.grain,
    'nut': Icons.grain,
    'nuts': Icons.grain,
    'seed': Icons.grain,
    'seeds': Icons.grain,
    'sunflower seed': Icons.grain,
    'pumpkin seed': Icons.grain,
    'popcorn': Icons.grain,
    'pretzel': Icons.grain,

    // ===== CONDIMENTS & SAUCES =====
    'mayo': Icons.restaurant,
    'bbq sauce': Icons.restaurant,
    'sriracha': Icons.restaurant,
    'teriyaki sauce': Icons.local_drink,
    'fish sauce': Icons.local_drink,
    'oyster sauce': Icons.local_drink,
    'tabasco': Icons.restaurant,
    'vinaigrette': Icons.restaurant,
    'ranch dressing': Icons.restaurant,
    'caesar dressing': Icons.restaurant,
    'italian dressing': Icons.restaurant,

    // ===== SPECIALTY/INTERNATIONAL =====
    'miso': Icons.kitchen,
    'miso paste': Icons.kitchen,
    'soy bean paste': Icons.kitchen,
    'pho broth': Icons.ramen_dining,
    'pad thai': Icons.ramen_dining,
    'curry paste': Icons.kitchen,
    'garam masala': Icons.kitchen,
    'ginger': Icons.circle,
    'turmeric root': Icons.circle,
    'wasabi': Icons.kitchen,
    'matcha': Icons.local_cafe,
    'kimchi': Icons.eco,
    'miso soup': Icons.ramen_dining,
    'kombucha': Icons.local_drink,
  };

  /// Get icon for an item based on its name
  /// Falls back to category icon, then generic icon
  static IconData getIconForItem(String itemName, {ItemCategory? category}) {
    // Try exact name match (case-insensitive)
    final normalized = itemName.toLowerCase().trim();
    if (_itemIconMap.containsKey(normalized)) {
      return _itemIconMap[normalized]!;
    }

    // Try substring match (e.g., "cherry tomatoes" matches "tomato")
    for (final MapEntry(:key, :value) in _itemIconMap.entries) {
      if (normalized.contains(key) || key.contains(normalized)) {
        return value;
      }
    }

    // Fall back to category icon
    if (category != null) {
      return _getCategoryIcon(category);
    }

    // Final fallback: generic icon
    return genericIcon;
  }

  /// Get icon for a category
  static IconData getCategoryIcon(ItemCategory category) {
    return _getCategoryIcon(category);
  }

  static IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.produce:
        return Icons.eco;
      case ItemCategory.dairy:
        return Icons.local_drink;
      case ItemCategory.meat:
        return Icons.set_meal;
      case ItemCategory.grains:
        return Icons.grain;
      case ItemCategory.pantry:
        return Icons.kitchen;
      case ItemCategory.other:
        return genericIcon;
    }
  }

  /// Get a set of all mapped item names for debugging/testing
  static Set<String> get mappedItems => _itemIconMap.keys.toSet();

  /// Get total number of items in the library
  static int get librarySize => _itemIconMap.length;
}
