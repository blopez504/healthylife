import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Importamos el login para regresar al usuario allí

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedGoal = 'Perder peso';
  String _selectedLevel = 'Principiante';
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena todos los campos')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. ENVIAR CORREO DE VERIFICACIÓN
      await userCredential.user!.sendEmailVerification();

      // 3. Guardar datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'edad': int.tryParse(_ageController.text) ?? 0,
        'peso': double.tryParse(_weightController.text) ?? 0.0,
        'altura': double.tryParse(_heightController.text) ?? 0.0,
        'objetivo': _selectedGoal,
        'nivel': _selectedLevel,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      // 4. Mostrar aviso y regresar al Login
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Registro Exitoso!'),
            content: Text('Hemos enviado un enlace de confirmación a ${_emailController.text}. Por favor, revisa tu bandeja de entrada o spam para verificar tu cuenta antes de iniciar sesión.'),
            actions: [
              TextButton(
                onPressed: () {
                  // Cierra el diálogo y lo manda al login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Entendido', style: TextStyle(color: Color(0xFF2E7D32))),
              )
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
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
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Correo Electrónico Real', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
              value: _selectedGoal,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Perder peso', 'Mantenerse', 'Ganar masa muscular'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _selectedGoal = newValue!),
            ),
            const SizedBox(height: 16),
            
            const Text('Nivel Físico', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Principiante', 'Intermedio', 'Avanzado'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _selectedLevel = newValue!),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Registrarse', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}