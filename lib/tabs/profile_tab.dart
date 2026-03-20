import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthylife/screens/login_screen.dart';
 

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  // FUNCIÓN NUEVA: Cerrar Sesión
  Future<void> _cerrarSesion(BuildContext context) async {
    // Le preguntamos al usuario si está seguro
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No salir
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Sí salir
            child: const Text('Sí, salir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Si dijo que sí, cerramos sesión y lo mandamos al Login
    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Borra el historial para que no pueda volver atrás con la flecha
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("No hay sesión"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar perfil.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              
              // Correo
              Text(userData['email'] ?? 'Sin correo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Chips de Objetivo y Nivel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(userData['objetivo'] ?? 'Mantenerse', style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(userData['nivel'] ?? 'Principiante', style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                ],
              ),
              const Divider(height: 48, thickness: 1),

              // Datos Físicos
              const Align(alignment: Alignment.centerLeft, child: Text('Tus Datos Físicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.cake, 'Edad', '${userData['edad'] ?? '--'} años'),
                      const Divider(),
                      _buildProfileRow(Icons.monitor_weight, 'Peso', '${userData['peso'] ?? '--'} kg'),
                      const Divider(),
                      _buildProfileRow(Icons.height, 'Altura', '${userData['altura'] ?? '--'} cm'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN DE CERRAR SESIÓN ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cerrarSesion(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fila reutilizable para los datos físicos
  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}