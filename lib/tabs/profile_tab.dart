import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthylife/screens/login_screen.dart';
import '../../widgets/pulse_loader.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<DocumentSnapshot> _profileFuture;
  final _user = FirebaseAuth.instance.currentUser;

  // --- VARIABLES PARA LOS RECORDATORIOS ---
  bool _recordatorioAgua = true; // Valor por defecto
  bool _recordatorioComidas = true; // Valor por defecto
  bool _recordatorioEjercicios = false; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<DocumentSnapshot> _loadProfileData() async {
    if (_user == null) {
      throw Exception("No hay sesión iniciada.");
    }
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
    if (!userDoc.exists) {
      throw Exception("No se encontraron datos del perfil.");
    }
    final data = userDoc.data();
    // Inicializamos el estado de los switches con los datos de Firebase
    // Esto se hace antes de que se construya el widget por primera vez.
    if (data != null && mounted) {
      setState(() {
        _recordatorioAgua = data['recordatorioAgua'] ?? true;
        _recordatorioComidas = data['recordatorioComidas'] ?? true;
        _recordatorioEjercicios = data['recordatorioEjercicios'] ?? false;
      });
    }
    return userDoc;
  }

  Future<void> _editarDatosFisicos(BuildContext context, Map<String, dynamic> userData) async {
    final pesoController = TextEditingController(text: userData['peso'].toString());
    final alturaController = TextEditingController(text: userData['altura'].toString());
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Medidas', style: TextStyle(color: Color(0xFF2E7D32))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nuevo Peso (lbs)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nueva Altura (cm)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              double nuevoPeso = double.tryParse(pesoController.text) ?? userData['peso'];
              double nuevaAltura = double.tryParse(alturaController.text) ?? userData['altura'];

              try {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'peso': nuevoPeso, 'altura': nuevaAltura});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Datos actualizados con éxito!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, salir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje), 
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      )
    );
  }

  // --- NUEVA FUNCIÓN: Guarda las preferencias en Firebase ---
  Future<void> _updateUserPreference(String key, bool value) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({key: value});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: Text("No hay sesión"));

    return FutureBuilder<DocumentSnapshot>(
      future: _profileFuture,
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PulseLoader(icon: Icons.person_search, color: Color(0xFF2E7D32), text: 'Cargando tu perfil...');
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
              CircleAvatar(radius: 50, backgroundColor: Colors.green.shade100, child: const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32))),
              const SizedBox(height: 16),
              Text(userData['email'] ?? 'Sin correo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(label: Text(userData['objetivo'] ?? 'Mantenerse', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Chip(label: Text(userData['nivel'] ?? 'Principiante', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1976D2)),
                ],
              ),
              const Divider(height: 48, thickness: 1),

              // --- SECCIÓN: DATOS FÍSICOS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tus Datos Físicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _editarDatosFisicos(context, userData),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.cake, 'Edad', '${userData['edad'] ?? '--'} años'),
                      const Divider(),
                      _buildProfileRow(Icons.monitor_weight, 'Peso', '${userData['peso'] ?? '--'} lbs'),
                      const Divider(),
                      _buildProfileRow(Icons.height, 'Altura', '${userData['altura'] ?? '--'} cm'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- NUEVA SECCIÓN: RECORDATORIOS Y NOTIFICACIONES ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Recordatorios Diarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tus preferencias se guardarán en la nube', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF2E7D32),
                      secondary: const Icon(Icons.water_drop, color: Colors.lightBlue),
                      title: const Text('Beber Agua', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Cada 2 horas', style: TextStyle(fontSize: 12)),
                      value: _recordatorioAgua,
                      onChanged: (value) {
                        setState(() => _recordatorioAgua = value); // Actualiza la UI al instante
                        _updateUserPreference('recordatorioAgua', value); // Guarda en Firebase
                        _mostrarMensaje('Preferencia de agua guardada');
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF2E7D32),
                      secondary: const Icon(Icons.restaurant, color: Colors.orange),
                      title: const Text('Plan de Comidas', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Desayuno, almuerzo y cena', style: TextStyle(fontSize: 12)),
                      value: _recordatorioComidas,
                      onChanged: (value) {
                        setState(() => _recordatorioComidas = value);
                        _updateUserPreference('recordatorioComidas', value);
                        _mostrarMensaje('Preferencia de comidas guardada');
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF2E7D32),
                      secondary: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                      title: const Text('Rutina de Ejercicios', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Hora sugerida: 6:00 PM', style: TextStyle(fontSize: 12)),
                      value: _recordatorioEjercicios,
                      onChanged: (value) {
                        setState(() => _recordatorioEjercicios = value);
                        _updateUserPreference('recordatorioEjercicios', value);
                        _mostrarMensaje('Preferencia de ejercicio guardada');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN DE CERRAR SESIÓN ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon( // ignore: prefer_const_constructors
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