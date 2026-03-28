import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/pulse_loader.dart';

class DietTab extends StatefulWidget {
  const DietTab({super.key});

  @override
  State<DietTab> createState() => _DietTabState();
}

class _DietTabState extends State<DietTab> {
  late Future<Map<String, dynamic>> _dietFuture;

  @override
  void initState() {
    super.initState();
    _dietFuture = _loadDietData();
  }

  /// Carga los datos del usuario y su dieta correspondiente en una sola operación.
  Future<Map<String, dynamic>> _loadDietData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay sesión iniciada.');
    }

    // 1. Buscamos el objetivo del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Error al cargar datos del usuario.');
    }
    final userData = userDoc.data() ?? {};
    final String objetivoUsuario = userData['objetivo'] ?? 'Mantenerse';

    // 2. Buscamos la dieta que coincida con el objetivo
    final dietQuery = await FirebaseFirestore.instance.collection('dietas').where('objetivo', isEqualTo: objetivoUsuario).get();

    if (dietQuery.docs.isEmpty) {
      // Usamos una excepción personalizada para manejar este caso específico en el builder.
      throw _DietNotFoundException(objetivoUsuario);
    }

    // Si encontramos la dieta, devolvemos sus datos.
    return dietQuery.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dietFuture,
      builder: (context, snapshot) {
        // Caso 1: Cargando datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PulseLoader(
            icon: Icons.menu_book,
            color: Color(0xFF2E7D32),
            text: 'Descargando tu plan...',
          );
        }

        // Caso 2: Ocurrió un error
        if (snapshot.hasError) {
          // Si el error es que no se encontró la dieta, mostramos un mensaje amigable.
          if (snapshot.error is _DietNotFoundException) {
            final error = snapshot.error as _DietNotFoundException;
            return _buildDietNotFoundUI(error.objective);
          }
          // Para cualquier otro error, mostramos un mensaje genérico.
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Caso 3: Datos cargados correctamente
        if (snapshot.hasData) {
          final dietaData = snapshot.data!;
          String tituloDieta = dietaData['titulo'] ?? 'Sin Título';
          String descripcion = dietaData['descripcion'] ?? 'Sin descripción';
          List<dynamic> planComidasRaw = dietaData['comidas'] ?? [];

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
                          Text(
                            'Sincronizado desde la nube',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
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
                      ))
                      
              ],
            );
        }

        // Caso 4: Estado inesperado (no debería ocurrir)
        return const Center(child: Text('Ha ocurrido algo inesperado.'));
      },
    );
  }

  /// Widget que se muestra cuando no se encuentra una dieta para el objetivo del usuario.
  Widget _buildDietNotFoundUI(String objetivoUsuario) {
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
            const Text(
              'Dile al administrador que la agregue en Firebase.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

/// Excepción personalizada para indicar que no se encontró una dieta.
class _DietNotFoundException implements Exception {
  final String objective;
  _DietNotFoundException(this.objective);
}