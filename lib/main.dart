import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importación de Firebase
import 'firebase_options.dart'; // Archivo generado por FlutterFire
import 'screens/login_screen.dart'; // Importación de tu pantalla de login

// Convertimos el main a 'async' porque la inicialización de Firebase toma un momento
void main() async {
  // 1. Asegurarnos de que los widgets de Flutter estén listos antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializar Firebase con las opciones de tu proyecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arrancar la aplicación
  runApp(const HealthyLifeApp());
}

class HealthyLifeApp extends StatelessWidget {
  const HealthyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32), // Verde bosque (Salud)
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF2E7D32),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      // La primera pantalla que verá el usuario es el Login
      home: const LoginScreen(),
    );
  }
}