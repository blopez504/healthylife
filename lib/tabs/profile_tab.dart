import 'package:flutter/material.dart';
import '../login_screen.dart'; // Importa la pantalla de login para poder cerrar sesión

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        const Center(child: Text('Usuario Demo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        const Center(child: Text('usuario@healthylife.com', style: TextStyle(fontSize: 14, color: Colors.grey))),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
            child: const Text('Objetivo: Perder peso', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit_note, color: Colors.black87),
          title: const Text('Editar Perfil (Edad, Peso, Altura)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none, color: Colors.black87),
          title: const Text('Configurar Recordatorios'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.security, color: Colors.black87),
          title: const Text('Privacidad y Seguridad'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () {
            // Regresa al login borrando el historial
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ],
    );
  }
}