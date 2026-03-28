import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/pulse_loader.dart';

class DietTab extends StatelessWidget {
  const DietTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No hay sesión iniciada"));
    }

    // 1. PRIMERO: Buscamos el objetivo del usuario
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const PulseLoader(icon: Icons.restaurant, color: Colors.orange, text: 'Verificando tu objetivo...');
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('Error al cargar datos del usuario.'));
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        String objetivoUsuario = userData['objetivo'] ?? 'Mantenerse';

        // 2. SEGUNDO: Buscamos en la colección 'dietas' la que coincida con el objetivo del usuario
        return FutureBuilder<QuerySnapshot>(
          // Consulta a Firebase: "Tráeme la dieta donde el campo 'objetivo' sea igual a objetivoUsuario"
          future: FirebaseFirestore.instance.collection('dietas').where('objetivo', isEqualTo: objetivoUsuario).get(),
          builder: (context, dietSnapshot) {
            
            if (dietSnapshot.connectionState == ConnectionState.waiting) {
              return const PulseLoader(icon: Icons.menu_book, color: Color(0xFF2E7D32), text: 'Descargando dieta de la nube...');
            }

            if (dietSnapshot.hasError) {
              return const Center(child: Text('Error al conectar con la base de datos.'));
            }

            // Si Firebase no encuentra ninguna dieta con ese objetivo
            if (!dietSnapshot.hasData || dietSnapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay una dieta registrada en la nube para el objetivo: "$objetivoUsuario".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text('Dile al administrador que la agregue en Firebase.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            }

            // Extraemos los datos del primer documento que encontró
            var dietaData = dietSnapshot.data!.docs.first.data() as Map<String, dynamic>;
            
            String tituloDieta = dietaData['titulo'] ?? 'Sin Título';
            String descripcion = dietaData['descripcion'] ?? 'Sin descripción';
            // Obtenemos la lista de comidas. Si no existe o no es lista, devolvemos una vacía []
            List<dynamic> planComidasRaw = dietaData['comidas'] ?? [];
            
            // Convertimos la lista de Firebase a un formato que Flutter entienda fácil
            List<Map<String, String>> planComidas = planComidasRaw.map((item) {
              return {
                "comida": item["comida"]?.toString() ?? "Comida",
                "desc": item["desc"]?.toString() ?? "Descripción no disponible"
              };
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- TARJETA PRINCIPAL (Datos de Firebase) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text('Sincronizado desde la nube', style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Tu Plan Personalizado', style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(tituloDieta, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(descripcion, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('Menú del Día', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // --- LISTA DE COMIDAS (Desde Firebase) ---
                if (planComidas.isEmpty)
                  const Center(child: Text('No hay comidas detalladas en este plan.'))
                else
                  ...planComidas.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.restaurant_menu, color: Color(0xFF2E7D32)),
                      ),
                      title: Text(item['comida']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(item['desc']!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ),
                    ),
                  )).toList()
              ],
            );
          },
        );
      },
    );
  }
}