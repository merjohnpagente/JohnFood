// Offline fallback menu + admin "Import sample menu" source.
// Plain text only. Images point to bundled assets in assets/images/.
class SampleCategory {
  final String id;
  final String name;
  final String icon;
  final int order;
  const SampleCategory(this.id, this.name, this.icon, this.order);
}

class SampleFood {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String image;
  final String category;
  final String deliveryTime;
  const SampleFood({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.image,
    required this.category,
    required this.deliveryTime,
  });
}

const sampleCategories = <SampleCategory>[
  SampleCategory('burgers', 'Burgers', 'lunch_dining', 1),
  SampleCategory('pizza', 'Pizza', 'local_pizza', 2),
  SampleCategory('chicken', 'Chicken', 'dinner_dining', 3),
  SampleCategory('rice', 'Rice Meals', 'rice_bowl', 4),
  SampleCategory('pasta', 'Pasta', 'ramen_dining', 5),
  SampleCategory('drinks', 'Drinks', 'local_drink', 6),
  SampleCategory('desserts', 'Desserts', 'icecream', 7),
  SampleCategory('snacks', 'Snacks', 'fastfood', 8),
];

const sampleFoods = <SampleFood>[
  SampleFood(id: 'b1', name: 'Classic Beef Burger', description: 'Grilled beef patty with lettuce, tomato and house sauce.', price: 120, rating: 4.6, image: 'assets/images/b1.jpg', category: 'burgers', deliveryTime: '20 min'),
  SampleFood(id: 'b2', name: 'Cheese Burger', description: 'Beef patty with melted cheese and pickles.', price: 135, rating: 4.7, image: 'assets/images/b2.jpg', category: 'burgers', deliveryTime: '20 min'),
  SampleFood(id: 'b3', name: 'Double Patty Burger', description: 'Two patties, double cheese, extra sauce.', price: 185, rating: 4.8, image: 'assets/images/b3.jpg', category: 'burgers', deliveryTime: '25 min'),
  SampleFood(id: 'b4', name: 'Chicken Burger', description: 'Crispy chicken fillet with mayo and slaw.', price: 110, rating: 4.5, image: 'assets/images/b4.jpg', category: 'burgers', deliveryTime: '20 min'),
  SampleFood(id: 'b5', name: 'Mushroom Burger', description: 'Grilled mushrooms with garlic sauce, meat-free.', price: 125, rating: 4.4, image: 'assets/images/b5.jpg', category: 'burgers', deliveryTime: '22 min'),
  SampleFood(id: 'p1', name: 'Pepperoni Pizza', description: 'Loaded pepperoni with mozzarella on thin crust.', price: 299, rating: 4.7, image: 'assets/images/p1.jpg', category: 'pizza', deliveryTime: '30 min'),
  SampleFood(id: 'p2', name: 'Cheese Pizza', description: 'Classic three-cheese blend, kid favorite.', price: 249, rating: 4.5, image: 'assets/images/p2.jpg', category: 'pizza', deliveryTime: '30 min'),
  SampleFood(id: 'p3', name: 'Hawaiian Pizza', description: 'Ham and pineapple with extra cheese.', price: 279, rating: 4.4, image: 'assets/images/p3.jpg', category: 'pizza', deliveryTime: '30 min'),
  SampleFood(id: 'p4', name: 'Veggie Pizza', description: 'Peppers, onions, mushrooms and olives.', price: 259, rating: 4.3, image: 'assets/images/p4.jpg', category: 'pizza', deliveryTime: '28 min'),
  SampleFood(id: 'p5', name: 'BBQ Chicken Pizza', description: 'Smoky BBQ chicken with red onions.', price: 319, rating: 4.8, image: 'assets/images/p5.jpg', category: 'pizza', deliveryTime: '32 min'),
  SampleFood(id: 'c1', name: 'Fried Chicken 2pc', description: 'Crispy fried chicken with gravy and rice.', price: 149, rating: 4.7, image: 'assets/images/c1.jpg', category: 'chicken', deliveryTime: '25 min'),
  SampleFood(id: 'c2', name: 'Chicken Tenders', description: 'Golden tenders with dip trio.', price: 139, rating: 4.5, image: 'assets/images/c2.jpg', category: 'chicken', deliveryTime: '22 min'),
  SampleFood(id: 'c3', name: 'Grilled Chicken', description: 'Herb grilled quarter chicken, lighter option.', price: 159, rating: 4.6, image: 'assets/images/c3.jpg', category: 'chicken', deliveryTime: '25 min'),
  SampleFood(id: 'c4', name: 'Chicken Wings', description: 'Tossed in your choice of glaze.', price: 169, rating: 4.6, image: 'assets/images/c4.jpg', category: 'chicken', deliveryTime: '25 min'),
  SampleFood(id: 'c5', name: 'Chicken Popcorn', description: 'Bite-size crispy chicken for sharing.', price: 99, rating: 4.4, image: 'assets/images/c5.jpg', category: 'chicken', deliveryTime: '18 min'),
  SampleFood(id: 'r1', name: 'Chicken Adobo Meal', description: 'Classic adobo with garlic rice and egg.', price: 120, rating: 4.8, image: 'assets/images/r1.jpg', category: 'rice', deliveryTime: '20 min'),
  SampleFood(id: 'r2', name: 'Beef Tapa Meal', description: 'Sweet beef tapa with vinegar dip.', price: 130, rating: 4.7, image: 'assets/images/r2.jpg', category: 'rice', deliveryTime: '20 min'),
  SampleFood(id: 'r3', name: 'Pork Sisig Meal', description: 'Sizzling sisig on garlic rice.', price: 135, rating: 4.7, image: 'assets/images/r3.jpg', category: 'rice', deliveryTime: '22 min'),
  SampleFood(id: 'r4', name: 'Bangus Meal', description: 'Fried milkfish with tomato and rice.', price: 125, rating: 4.5, image: 'assets/images/r4.jpg', category: 'rice', deliveryTime: '20 min'),
  SampleFood(id: 'r5', name: 'Tocino Meal', description: 'Sweet pork tocino with egg and rice.', price: 115, rating: 4.6, image: 'assets/images/r5.jpg', category: 'rice', deliveryTime: '18 min'),
  SampleFood(id: 'pa1', name: 'Spaghetti', description: 'Sweet-style spaghetti with hotdog slices.', price: 110, rating: 4.5, image: 'assets/images/pa1.jpg', category: 'pasta', deliveryTime: '20 min'),
  SampleFood(id: 'pa2', name: 'Carbonara', description: 'Creamy carbonara with bacon bits.', price: 130, rating: 4.6, image: 'assets/images/pa2.jpg', category: 'pasta', deliveryTime: '22 min'),
  SampleFood(id: 'pa3', name: 'Pesto Pasta', description: 'Basil pesto with parmesan.', price: 140, rating: 4.4, image: 'assets/images/pa3.jpg', category: 'pasta', deliveryTime: '22 min'),
  SampleFood(id: 'pa4', name: 'Baked Mac', description: 'Cheesy baked macaroni, single serve.', price: 135, rating: 4.6, image: 'assets/images/pa4.jpg', category: 'pasta', deliveryTime: '25 min'),
  SampleFood(id: 'pa5', name: 'Palabok', description: 'Rice noodles with shrimp sauce and chicharon.', price: 120, rating: 4.7, image: 'assets/images/pa5.jpg', category: 'pasta', deliveryTime: '20 min'),
  SampleFood(id: 'd1', name: 'Iced Coffee', description: 'Chilled brewed coffee with milk.', price: 85, rating: 4.5, image: 'assets/images/d1.jpg', category: 'drinks', deliveryTime: '10 min'),
  SampleFood(id: 'd2', name: 'Mango Shake', description: 'Fresh mango blended with ice and milk.', price: 95, rating: 4.7, image: 'assets/images/d2.jpg', category: 'drinks', deliveryTime: '10 min'),
  SampleFood(id: 'd3', name: 'Lemonade', description: 'Fresh calamansi lemonade.', price: 65, rating: 4.4, image: 'assets/images/d3.jpg', category: 'drinks', deliveryTime: '8 min'),
  SampleFood(id: 'd4', name: 'Milk Tea', description: 'Classic milk tea with pearls.', price: 99, rating: 4.6, image: 'assets/images/d4.jpg', category: 'drinks', deliveryTime: '12 min'),
  SampleFood(id: 'd5', name: 'Bottled Water', description: 'Chilled purified water 500ml.', price: 30, rating: 4.2, image: 'assets/images/d5.jpg', category: 'drinks', deliveryTime: '5 min'),
  SampleFood(id: 'de1', name: 'Halo Halo', description: 'Mixed dessert with leche flan and ube.', price: 110, rating: 4.8, image: 'assets/images/de1.jpg', category: 'desserts', deliveryTime: '15 min'),
  SampleFood(id: 'de2', name: 'Chocolate Cake', description: 'Moist chocolate slice.', price: 95, rating: 4.7, image: 'assets/images/de2.jpg', category: 'desserts', deliveryTime: '12 min'),
  SampleFood(id: 'de3', name: 'Leche Flan', description: 'Creamy caramel custard cup.', price: 80, rating: 4.6, image: 'assets/images/de3.jpg', category: 'desserts', deliveryTime: '12 min'),
  SampleFood(id: 'de4', name: 'Ice Cream Cup', description: 'Two scoops, assorted flavors.', price: 75, rating: 4.5, image: 'assets/images/de4.jpg', category: 'desserts', deliveryTime: '10 min'),
  SampleFood(id: 'de5', name: 'Banana Cue', description: 'Caramelized banana skewers.', price: 45, rating: 4.4, image: 'assets/images/de5.jpg', category: 'desserts', deliveryTime: '10 min'),
  SampleFood(id: 's1', name: 'French Fries', description: 'Crispy fries with cheese powder.', price: 75, rating: 4.5, image: 'assets/images/s1.jpg', category: 'snacks', deliveryTime: '12 min'),
  SampleFood(id: 's2', name: 'Nachos', description: 'Cheesy nachos with salsa.', price: 110, rating: 4.5, image: 'assets/images/s2.jpg', category: 'snacks', deliveryTime: '15 min'),
  SampleFood(id: 's3', name: 'Lumpia', description: 'Fried spring rolls, 5 pieces.', price: 85, rating: 4.6, image: 'assets/images/s3.jpg', category: 'snacks', deliveryTime: '15 min'),
  SampleFood(id: 's4', name: 'Fish Balls', description: 'Street-style fish balls with sauces.', price: 55, rating: 4.3, image: 'assets/images/s4.jpg', category: 'snacks', deliveryTime: '10 min'),
  SampleFood(id: 's5', name: 'Garlic Bread', description: 'Toasted garlic bread sticks.', price: 65, rating: 4.4, image: 'assets/images/s5.jpg', category: 'snacks', deliveryTime: '10 min'),
  SampleFood(id: 'b6', name: 'Bacon Cheeseburger', description: 'Beef patty with crispy bacon and cheddar.', price: 165, rating: 4.7, image: 'assets/images/b6.jpg', category: 'burgers', deliveryTime: '22 min'),
  SampleFood(id: 'b7', name: 'BBQ Burger', description: 'Smoky BBQ sauce with crispy onions.', price: 150, rating: 4.6, image: 'assets/images/b7.jpg', category: 'burgers', deliveryTime: '22 min'),
  SampleFood(id: 'p6', name: 'Four Cheese Pizza', description: 'Mozzarella, cheddar, parmesan and blue cheese.', price: 329, rating: 4.7, image: 'assets/images/p6.jpg', category: 'pizza', deliveryTime: '32 min'),
  SampleFood(id: 'p7', name: 'Meat Lovers Pizza', description: 'Pepperoni, ham, beef and sausage.', price: 339, rating: 4.8, image: 'assets/images/p7.jpg', category: 'pizza', deliveryTime: '32 min'),
  SampleFood(id: 'p8', name: 'Burger Pizza', description: 'Beef patty crumbles, cheddar, pickles and burger sauce on pizza crust.', price: 349, rating: 4.9, image: 'assets/images/p8.jpg', category: 'pizza', deliveryTime: '35 min'),
  SampleFood(id: 'c6', name: 'Spicy Chicken', description: 'Fiery glazed fried chicken, extra crispy.', price: 155, rating: 4.6, image: 'assets/images/c6.jpg', category: 'chicken', deliveryTime: '25 min'),
  SampleFood(id: 'c7', name: 'Chicken Fillet', description: 'Golden breaded fillet with lemon and herbs.', price: 145, rating: 4.5, image: 'assets/images/c7.jpg', category: 'chicken', deliveryTime: '22 min'),
  SampleFood(id: 'r6', name: 'Beef Steak Meal', description: 'Savory beef steak with garlic rice.', price: 140, rating: 4.7, image: 'assets/images/r6.jpg', category: 'rice', deliveryTime: '22 min'),
  SampleFood(id: 'r7', name: 'Fried Rice Meal', description: 'Wok-tossed fried rice with veggies.', price: 125, rating: 4.6, image: 'assets/images/r7.jpg', category: 'rice', deliveryTime: '20 min'),
  SampleFood(id: 'pa6', name: 'Shrimp Pasta', description: 'Garlic butter shrimp over linguine.', price: 155, rating: 4.7, image: 'assets/images/pa6.jpg', category: 'pasta', deliveryTime: '25 min'),
  SampleFood(id: 'pa7', name: 'Tomato Basil Pasta', description: 'Fresh tomatoes and basil in olive oil.', price: 125, rating: 4.5, image: 'assets/images/pa7.jpg', category: 'pasta', deliveryTime: '20 min'),
  SampleFood(id: 'd6', name: 'Strawberry Shake', description: 'Fresh strawberries blended with milk.', price: 105, rating: 4.6, image: 'assets/images/d6.jpg', category: 'drinks', deliveryTime: '10 min'),
  SampleFood(id: 'd7', name: 'Iced Tea', description: 'Chilled black tea with lemon.', price: 60, rating: 4.3, image: 'assets/images/d7.jpg', category: 'drinks', deliveryTime: '8 min'),
  SampleFood(id: 'de6', name: 'Ice Cream Cone', description: 'Crunchy cone with a big scoop.', price: 55, rating: 4.5, image: 'assets/images/de6.jpg', category: 'desserts', deliveryTime: '8 min'),
  SampleFood(id: 'de7', name: 'Brownie Sundae', description: 'Warm brownie with ice cream and syrup.', price: 95, rating: 4.7, image: 'assets/images/de7.jpg', category: 'desserts', deliveryTime: '12 min'),
  SampleFood(id: 's6', name: 'Loaded Fries', description: 'Fries piled with cheese and sauce.', price: 95, rating: 4.6, image: 'assets/images/s6.jpg', category: 'snacks', deliveryTime: '14 min'),
  SampleFood(id: 's7', name: 'Onion Rings', description: 'Crispy battered onion rings.', price: 80, rating: 4.5, image: 'assets/images/s7.jpg', category: 'snacks', deliveryTime: '12 min'),
];
