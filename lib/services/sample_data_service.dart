import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class SampleDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed sample products to Firestore
  Future<void> seedSampleProducts() async {
    try {
      final sampleProducts = _getSampleProducts();
      
      final batch = _firestore.batch();
      
      for (final product in sampleProducts) {
        final docRef = _firestore.collection('products').doc(product.id);
        batch.set(docRef, product.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed sample products: $e');
    }
  }

  // Check if products collection exists and has data
  Future<bool> hasProducts() async {
    try {
      final snapshot = await _firestore.collection('products').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get sample products data
  List<ProductModel> _getSampleProducts() {
    return [
      ProductModel(
        id: 'prod_001',
        name: 'Premium Car Floor Mats',
        description: 'High-quality rubber floor mats with anti-slip design. Perfect fit for most car models. Waterproof and easy to clean.',
        price: 45000, // TZS
        originalPrice: 55000,
        stock: 25,
        category: 'Interior',
        brand: 'AutoPro',
        sku: 'AP-FM-001',
        compatibility: ['Toyota Corolla', 'Honda Civic', 'Nissan Sentra'],
        sellerId: 'seller_001',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.5,
        totalReviews: 23,
        specifications: {
          'Material': 'Premium Rubber',
          'Color': 'Black',
          'Set': '4 pieces',
          'Warranty': '2 years',
        },
        tags: ['floor mats', 'interior', 'rubber', 'waterproof'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 156,
      ),
      
      ProductModel(
        id: 'prod_002',
        name: 'LED Headlight Bulbs H4',
        description: 'Super bright LED headlight bulbs with 6000K white light. Easy installation and long-lasting performance.',
        price: 85000, // TZS
        stock: 15,
        category: 'Lighting',
        brand: 'BrightLite',
        sku: 'BL-LED-H4',
        compatibility: ['Toyota Vitz', 'Suzuki Swift', 'Mazda Demio'],
        sellerId: 'seller_002',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.8,
        totalReviews: 45,
        specifications: {
          'Type': 'H4 LED',
          'Power': '60W',
          'Color Temperature': '6000K',
          'Lifespan': '50,000 hours',
        },
        tags: ['headlight', 'LED', 'bright', 'H4'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 234,
      ),

      ProductModel(
        id: 'prod_003',
        name: 'Car Phone Holder Dashboard',
        description: 'Adjustable phone holder for dashboard mounting. Compatible with all smartphone sizes. Strong suction cup base.',
        price: 25000, // TZS
        originalPrice: 35000,
        stock: 40,
        category: 'Electronics',
        brand: 'MobileMount',
        sku: 'MM-PH-001',
        compatibility: ['Universal'],
        sellerId: 'seller_001',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.2,
        totalReviews: 67,
        specifications: {
          'Mount Type': 'Dashboard',
          'Compatibility': 'Universal',
          'Rotation': '360 degrees',
          'Material': 'ABS Plastic',
        },
        tags: ['phone holder', 'dashboard', 'universal', 'mount'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 189,
      ),

      ProductModel(
        id: 'prod_004',
        name: 'Engine Oil Filter',
        description: 'High-performance oil filter for optimal engine protection. OEM quality replacement part.',
        price: 15000, // TZS
        stock: 60,
        category: 'Engine',
        brand: 'FilterPro',
        sku: 'FP-OF-001',
        compatibility: ['Toyota Corolla', 'Toyota Vitz', 'Toyota Platz'],
        sellerId: 'seller_003',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.6,
        totalReviews: 34,
        specifications: {
          'Type': 'Spin-on',
          'Thread': 'M20 x 1.5',
          'Height': '65mm',
          'Diameter': '76mm',
        },
        tags: ['oil filter', 'engine', 'maintenance', 'toyota'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 98,
      ),

      ProductModel(
        id: 'prod_005',
        name: 'Car Seat Covers Set',
        description: 'Premium leather-look seat covers. Full set for front and rear seats. Easy installation with elastic straps.',
        price: 120000, // TZS
        originalPrice: 150000,
        stock: 12,
        category: 'Interior',
        brand: 'ComfortSeats',
        sku: 'CS-SC-001',
        compatibility: ['Universal'],
        sellerId: 'seller_002',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.4,
        totalReviews: 28,
        specifications: {
          'Material': 'PU Leather',
          'Color': 'Black',
          'Set': 'Front + Rear',
          'Installation': 'Elastic straps',
        },
        tags: ['seat covers', 'leather', 'interior', 'universal'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 145,
      ),

      ProductModel(
        id: 'prod_006',
        name: 'Brake Pads Front Set',
        description: 'High-quality ceramic brake pads for superior stopping power. Low dust formula for cleaner wheels.',
        price: 95000, // TZS
        stock: 20,
        category: 'Brakes',
        brand: 'StopSafe',
        sku: 'SS-BP-F001',
        compatibility: ['Honda Civic', 'Honda Accord', 'Honda CRV'],
        sellerId: 'seller_003',
        images: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        ],
        averageRating: 4.7,
        totalReviews: 19,
        specifications: {
          'Type': 'Ceramic',
          'Position': 'Front',
          'Pieces': '4 pads',
          'Warranty': '1 year',
        },
        tags: ['brake pads', 'ceramic', 'front', 'honda'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 76,
      ),
    ];
  }

  // Create sample sellers
  Future<void> seedSampleSellers() async {
    try {
      final sampleSellers = [
        {
          'id': 'seller_001',
          'name': 'AutoParts Tanzania',
          'email': 'info@autoparts.tz',
          'phone': '+255 123 456 789',
          'role': 'seller',
          'businessName': 'AutoParts Tanzania Ltd',
          'businessAddress': 'Kariakoo, Dar es Salaam',
          'verified': true,
          'rating': 4.6,
          'totalSales': 156,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'seller_002',
          'name': 'Car Accessories Hub',
          'email': 'sales@carhub.tz',
          'phone': '+255 987 654 321',
          'role': 'seller',
          'businessName': 'Car Accessories Hub',
          'businessAddress': 'Mwenge, Dar es Salaam',
          'verified': true,
          'rating': 4.8,
          'totalSales': 203,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'seller_003',
          'name': 'Engine Parts Pro',
          'email': 'contact@enginepro.tz',
          'phone': '+255 456 789 123',
          'role': 'seller',
          'businessName': 'Engine Parts Pro Ltd',
          'businessAddress': 'Ubungo, Dar es Salaam',
          'verified': true,
          'rating': 4.5,
          'totalSales': 89,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      
      for (final seller in sampleSellers) {
        final docRef = _firestore.collection('users').doc(seller['id'] as String);
        batch.set(docRef, seller);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed sample sellers: $e');
    }
  }

  Future<void> createSampleProducts() async {
    try {
      final sampleProducts = [
        {
          'name': 'Car Phone Mount',
          'description': 'Universal car phone holder with suction cup mount',
          'price': 15000.0,
          'originalPrice': 20000.0,
          'stock': 50,
          'category': 'Electronics',
          'brand': 'CarTech',
          'model': 'Universal',
          'sku': 'CT-PM001',
          'compatibility': ['Toyota', 'Honda', 'Ford', 'BMW'],
          'sellerId': 'sample_seller_1',
          'images': [
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
          ],
          'rating': 4.5,
          'averageRating': 4.5,
          'totalReviews': 25,
          'isActive': true,
          'viewCount': 150,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'LED Interior Lights',
          'description': 'Ambient LED lighting kit for car interior',
          'price': 25000.0,
          'originalPrice': 30000.0,
          'stock': 30,
          'category': 'Lighting',
          'brand': 'LightPro',
          'model': 'Universal',
          'sku': 'LP-LED001',
          'compatibility': ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes'],
          'sellerId': 'sample_seller_1',
          'images': [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
          ],
          'rating': 4.2,
          'averageRating': 4.2,
          'totalReviews': 18,
          'isActive': true,
          'viewCount': 120,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Car Floor Mats',
          'description': 'Premium all-weather car floor mats',
          'price': 35000.0,
          'originalPrice': 40000.0,
          'stock': 40,
          'category': 'Interior',
          'brand': 'MatMaster',
          'model': 'Universal',
          'sku': 'MM-FM001',
          'compatibility': ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes', 'Audi'],
          'sellerId': 'sample_seller_2',
          'images': [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
          ],
          'rating': 4.7,
          'averageRating': 4.7,
          'totalReviews': 32,
          'isActive': true,
          'viewCount': 200,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Car Air Freshener',
          'description': 'Long-lasting car air freshener with natural scent',
          'price': 5000.0,
          'originalPrice': 7000.0,
          'stock': 100,
          'category': 'Interior',
          'brand': 'FreshAir',
          'model': 'Universal',
          'sku': 'FA-AF001',
          'compatibility': ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes', 'Audi', 'Nissan'],
          'sellerId': 'sample_seller_2',
          'images': [
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
          ],
          'rating': 4.0,
          'averageRating': 4.0,
          'totalReviews': 45,
          'isActive': true,
          'viewCount': 180,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Car Wash Kit',
          'description': 'Complete car washing and detailing kit',
          'price': 45000.0,
          'originalPrice': 55000.0,
          'stock': 25,
          'category': 'Maintenance',
          'brand': 'CleanPro',
          'model': 'Universal',
          'sku': 'CP-CW001',
          'compatibility': ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes', 'Audi', 'Nissan', 'Hyundai'],
          'sellerId': 'sample_seller_3',
          'images': [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
          ],
          'rating': 4.8,
          'averageRating': 4.8,
          'totalReviews': 28,
          'isActive': true,
          'viewCount': 160,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var productData in sampleProducts) {
        final docRef = _firestore.collection('products').doc();
        await docRef.set(productData);
        print('Created sample product: ${productData['name']} with ID: ${docRef.id}');
      }

      print('Successfully created ${sampleProducts.length} sample products');
    } catch (e) {
      print('Error creating sample products: $e');
      throw Exception('Failed to create sample products: $e');
    }
  }

  Future<void> clearSampleProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', whereIn: ['sample_seller_1', 'sample_seller_2', 'sample_seller_3'])
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('Deleted sample product: ${doc.id}');
      }

      print('Successfully cleared ${snapshot.docs.length} sample products');
    } catch (e) {
      print('Error clearing sample products: $e');
      throw Exception('Failed to clear sample products: $e');
    }
  }
}
