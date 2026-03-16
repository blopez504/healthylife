import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _waterGlasses = 0;
  
  // Obtener correo del usuario actual
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    // Tomamos la parte antes del @ del correo para usarla como "Nombre"
    String userName = _userEmail != null ? _userEmail.split('@')[0] : 'Usuario';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Hola, $userName 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const Text('Aquí está tu progreso de hoy:', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 24),
        
        // Tarjeta Calorías
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Calorías Consumidas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('1,250 / 2,000 kcal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: const [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(value: 1250/2000, color: Colors.orange, backgroundColor: Color(0xFFFFF3E0), strokeWidth: 8),
                    ),
                    Icon(Icons.local_fire_department, color: Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Tarjeta Agua
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consumo de Agua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('$_waterGlasses / 8 vasos', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 45),
                  onPressed: () {
                    if (_waterGlasses < 8) {
                      setState(() => _waterGlasses++);
                    }
                  },
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Actividades Completadas
        const Text('Actividad de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.directions_run, color: Colors.green),
          title: const Text('Caminata Matutina'),
          subtitle: const Text('Completado • 30 min'),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        )
      ],
    );
  }
}