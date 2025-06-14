import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balebale_cabs/config/router.dart';
import 'package:balebale_cabs/config/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://telmnjpsbhixquklbkuf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlbG1uanBzYmhpeHF1a2xia3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MTY1NjYsImV4cCI6MjA2NTQ5MjU2Nn0.LA-Inu3W1VYdhTMOKq5SgJCTaM847RvOZNIJPoDkVJs',
  );
  
  runApp(
    const ProviderScope(
      child: BalebaleCabs(),
    ),
  );
}

class BalebaleCabs extends ConsumerWidget {
  const BalebaleCabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Balebale Cabs',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
} 