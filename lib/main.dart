import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Any async initialization (Hive, etc.) is done inside AppBootstrap.
  runApp(
    const ProviderScope(
      child: AppBootstrap(),
    ),
  );
}

