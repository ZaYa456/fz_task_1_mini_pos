import 'package:hive_flutter/hive_flutter.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/items/data/models/item_model.dart';
import '../../features/checkout/data/models/checkout_model.dart';
import '../../features/checkout/data/models/checkout_items_model.dart';

// ===============================
// Box Name Constants
// ===============================

const String kUserBox = 'user_box';
const String kItemBox = 'item_box';
const String kCheckoutBox = 'checkout_box';
const String kSessionBox = 'session_box';
const String kPreferencesBox = 'preferences';

// ===============================
// Session Keys
// ===============================

const String kIsLoggedInKey = 'is_logged_in';
const String kCurrentUserKey = 'current_user';
const String kGracefulShutdownKey =
    'graceful_shutdown'; // Flag to indicate if the app was closed gracefully (used for session restoration)

// ===============================
// Hive Setup
// ===============================

Future<void> setupHive() async {
  // Initialize Hive for Flutter (Windows supported)
  await Hive.initFlutter();

  // Register Generated Adapters (MODEL adapters, not domain entities)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ItemModelAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CheckoutModelAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(CheckoutItemModelAdapter());
  }

  // Open Boxes (Store MODELS only)
  await Hive.openBox<UserModel>(kUserBox);

  await Hive.openBox<ItemModel>(kItemBox);
  await Hive.openBox<CheckoutModel>(kCheckoutBox);

  // Session box (non-typed)
  await Hive.openBox(kSessionBox);
  await Hive.openBox(kPreferencesBox);

  // ===============================
  // SESSION RECOVERY LOGIC
  // ===============================

  final sessionBox = Hive.box(kSessionBox);
  final checkoutBox = Hive.box<CheckoutModel>(kCheckoutBox);

  final wasGraceful = sessionBox.get(kGracefulShutdownKey, defaultValue: null);

  // If null → first app launch ever → do nothing
  if (wasGraceful == true) {
    // Previous session closed normally
    // Convert all OPEN checkouts → HELD
    for (final checkout in checkoutBox.values) {
      if (checkout.status == 'open') {
        checkout.status = 'held';
        await checkout.save();
      }
    }
  }

  // Mark this session as NOT gracefully closed yet
  await sessionBox.put(kGracefulShutdownKey, false);
}
