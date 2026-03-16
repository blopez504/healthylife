import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthylife/screens/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Obtener el usuario actual
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay usuario logueado por alguna razón
    if (user == null) {
      return const Center(child: Text("No hay sesión iniciada"));
    }

    return FutureBuilder<DocumentSnapshot>(
      // Buscar el documento del usuario en Firestore
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        // Mientras carga los datos de internet
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        // Si hay un error
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar perfil'));
        }

        // Si cargó exitosamente, extraer los datos
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        String email = userData['email'] ?? user!.email ?? 'Sin correo';
        String objetivo = userData['objetivo'] ?? 'Sin objetivo';
        String nivel = userData['nivel'] ?? 'Sin nivel';
        double peso = (userData['peso'] ?? 0).toDouble();
        double altura = (userData['altura'] ?? 0).toDouble();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text(email.split('@')[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Center(child: Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey))),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                child: Text('Objetivo: $objetivo', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Fila con Peso y Altura Reales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoStat('Peso', '$peso kg'),
                _buildInfoStat('Altura', '$altura cm'),
                _buildInfoStat('Nivel', nivel),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _signOut,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoStat(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}