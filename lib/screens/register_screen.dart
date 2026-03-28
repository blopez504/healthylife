import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthylife/tabs/home_tab.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  
  String _objetivoSeleccionado = 'Mantenerse';
  String _nivelSeleccionado = 'Principiante';
  bool _isLoading = false;

  final List<String> _objetivos = ['Perder peso', 'Ganar masa muscular', 'Mantenerse'];
  final List<String> _niveles = ['Principiante', 'Intermedio', 'Avanzado'];

  Future<void> _registrarUsuario() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || 
        _pesoController.text.isEmpty || _alturaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Crear el usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Guardar sus datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'edad': int.tryParse(_edadController.text) ?? 0,
        'peso': double.tryParse(_pesoController.text) ?? 0.0, // Ahora el usuario sabe que debe poner libras
        'altura': double.tryParse(_alturaController.text) ?? 0.0,
        'objetivo': _objetivoSeleccionado,
        'nivel': _nivelSeleccionado,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      // 3. Ir a la pantalla principal
      if (mounted) {
        // NOTA: Cambia 'HomeTab()' por el nombre del Widget que contiene tu BottomNavigationBar (Ej: MainScreen() o HomeScreen())
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeTab()), 
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar';
      if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil (Mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') mensaje = 'Este correo ya está registrado.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add, size: 80, color: Color(0xFF2E7D32)),
              const SizedBox(height: 24),
              const Text(
                '¡Comienza tu cambio hoy!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 32),

              // --- DATOS DE LA CUENTA ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña (Mín. 6 caracteres)',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Divider(height: 48, thickness: 1),

              // --- DATOS FÍSICOS ---
              const Text('Tus Datos Físicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _edadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        prefixIcon: const Icon(Icons.cake),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _alturaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Altura (cm)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ¡AQUÍ ESTÁ LA CORRECCIÓN! (Libras en lugar de Kilos)
              TextField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (lbs)',
                  hintText: 'Ej. 150',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // --- METAS Y NIVEL ---
              DropdownButtonFormField<String>(
                initialValue: _objetivoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tu Objetivo Principal',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _objetivos.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _objetivoSeleccionado = newValue!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _nivelSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tu Nivel de Experiencia',
                  prefixIcon: const Icon(Icons.fitness_center),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _niveles.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _nivelSeleccionado = newValue!),
              ),
              
              const SizedBox(height: 40),

              // --- BOTÓN DE REGISTRO ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _registrarUsuario,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear mi cuenta', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}