import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para capturar lo que el usuario escribe
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedGoal = 'Perder peso';
  String _selectedLevel = 'Principiante';
  bool _isLoading = false; // Para mostrar ruedita de carga

  // Función mágica para registrar en Firebase
  Future<void> _registerUser() async {
    // 1. Validar que no haya campos vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena todos los campos')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Crear usuario en Firebase Authentication (El acceso)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Guardar el perfil de salud en Firestore Database (Los datos)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'edad': int.tryParse(_ageController.text) ?? 0,
        'peso': double.tryParse(_weightController.text) ?? 0.0,
        'altura': double.tryParse(_heightController.text) ?? 0.0,
        'objetivo': _selectedGoal,
        'nivel': _selectedLevel,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      // 4. Si todo sale bien, ir al Dashboard
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboard()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Si hay error (ej. correo ya existe)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Crea tu cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // --- NUEVO: Correo y Contraseña ---
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Contraseña (mínimo 6 letras)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const Divider(height: 48),

            const Text('Perfil Físico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Edad', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            
            const Text('Objetivo Principal', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedGoal,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Perder peso', 'Mantenerse', 'Ganar masa muscular'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _selectedGoal = newValue!),
            ),
            const SizedBox(height: 16),
            
            const Text('Nivel Físico', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Principiante', 'Intermedio', 'Avanzado'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _selectedLevel = newValue!),
            ),
            const SizedBox(height: 32),
            
            // Botón de Registrar
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser, // Si está cargando, se bloquea
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Registrarse y Comenzar', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}