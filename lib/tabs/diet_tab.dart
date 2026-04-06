import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha
import '../../widgets/pulse_loader.dart';

class DietTab extends StatefulWidget {
  const DietTab({super.key});

  @override
  State<DietTab> createState() => _DietTabState();
}

class _DietTabState extends State<DietTab> {
  late Future<Map<String, dynamic>> _dietFuture;
  
  List<bool> _comidasCompletadas = []; // Estado local de los checkboxes

  @override
  void initState() {
    super.initState();
    _dietFuture = _loadDietData();
  }

  /// Devuelve la fecha actual en formato 'YYYY-MM-DD' para usarla como ID de documento.
  String _getTodayDateId() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Carga los datos del usuario y su dieta correspondiente en una sola operación.
  Future<Map<String, dynamic>> _loadDietData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay sesión iniciada.');
    }

    // Paso 1: Buscamos el objetivo del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Error al cargar datos del usuario.');
    }
    final userData = userDoc.data() ?? {};
    final String objetivoUsuario = userData['objetivo'] ?? 'Mantenerse';

    // Paso 2: Buscamos la dieta que coincida con el objetivo
    final dietQuery = await FirebaseFirestore.instance.collection('dietas').where('objetivo', isEqualTo: objetivoUsuario).get();

    if (dietQuery.docs.isEmpty) {
      throw _DietNotFoundException(objetivoUsuario);
    }

    final dietaData = dietQuery.docs.first.data();

    // Paso 3: Inicializamos las casillas de verificación
    List<dynamic> planComidasRaw = dietaData['comidas'] ?? [];
    int totalComidas = planComidasRaw.length;

    // Paso 4: Cargamos el progreso guardado para el día de hoy
    final todayId = _getTodayDateId();
    final progressDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('progreso_diario')
        .doc(todayId)
        .get();

    List<bool> initialProgress = List<bool>.filled(totalComidas, false);
    if (progressDoc.exists && progressDoc.data()!.containsKey('comidasCompletadas')) {
      List<dynamic> savedProgress = progressDoc.data()!['comidasCompletadas'];
      // Aseguramos que la lista de progreso tenga el mismo tamaño que la lista de comidas
      for (int i = 0; i < totalComidas && i < savedProgress.length; i++) {
        initialProgress[i] = savedProgress[i] as bool;
      }
    }

    // Usamos 'WidgetsBinding.instance.addPostFrameCallback' para asegurar que el widget esté construido
    // antes de llamar a setState. Esto evita errores comunes en Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _comidasCompletadas = initialProgress;
        });
      }
    });

    return dietaData;
  }

  // --- NUEVA FUNCIÓN: Guarda el progreso en Firebase ---
  Future<void> _updateMealProgress(int index, bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Actualiza el estado local inmediatamente para que la UI responda al instante
    setState(() {
      _comidasCompletadas[index] = isCompleted;
    });

    // Guarda la lista completa en Firebase
    final todayId = _getTodayDateId();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progreso_diario')
          .doc(todayId)
          .set({
            'comidasCompletadas': _comidasCompletadas,
            'lastUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // 'merge: true' es crucial para no sobreescribir el progreso de ejercicios
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar progreso: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
          if (snapshot.error is _DietNotFoundException) {
            final error = snapshot.error as _DietNotFoundException;
            return _buildDietNotFoundUI(error.objective);
          }
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

          // Si _comidasCompletadas está vacío (primera carga), lo inicializamos
          if (_comidasCompletadas.isEmpty && planComidas.isNotEmpty) {
            _comidasCompletadas = List<bool>.filled(planComidas.length, false);
          }

          // Cálculos para la barra de progreso
          int marcadas = _comidasCompletadas.where((element) => element == true).length;
          double progreso = planComidas.isEmpty ? 0 : marcadas / planComidas.length;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- TARJETA PRINCIPAL ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tu Plan Personalizado', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Row(
                          children: [
                            Icon(Icons.cloud_done, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('Sincronizado', style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tituloDieta, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(descripcion, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    
                    const SizedBox(height: 24),
                    // --- BARRA DE PROGRESO DE COMIDAS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Comidas registradas hoy:', style: TextStyle(color: Colors.white70)),
                        Text('$marcadas/${planComidas.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progreso,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      color: Colors.orangeAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('Registro Diario (Menú)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- LISTA DE COMIDAS INTERACTIVA (Checkboxes) ---
              if (planComidas.isEmpty)
                const Center(child: Text('No hay comidas detalladas en este plan.'))
              else
                for (int i = 0; i < planComidas.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: _comidasCompletadas[i] ? Colors.green.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _comidasCompletadas[i] ? Colors.green : Colors.transparent, width: 1)
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.all(12),
                      activeColor: const Color(0xFF2E7D32),
                      secondary: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _comidasCompletadas[i] ? Colors.green.shade100 : Colors.green.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.restaurant_menu, color: _comidasCompletadas[i] ? Colors.green : const Color(0xFF2E7D32)),
                      ),
                      title: Text(
                        planComidas[i]['comida']!, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          decoration: _comidasCompletadas[i] ? TextDecoration.lineThrough : TextDecoration.none,
                          color: _comidasCompletadas[i] ? Colors.grey : Colors.black,
                        )
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(planComidas[i]['desc']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      ),
                      value: _comidasCompletadas[i],
                      onChanged: (bool? newValue) {
                        _updateMealProgress(i, newValue ?? false);
                      },
                    ),
                  ),

                // --- MENSAJE DE FELICITACIONES ---
                if (progreso == 1.0 && planComidas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.thumb_up, color: Colors.orange, size: 32),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text('¡Excelente! Has cumplido con todas tus comidas de hoy.', 
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                        ),
                      ],
                    ),
                  )
            ],
          );
        }

        // Caso 4: Estado inesperado
        return const Center(child: Text('Ha ocurrido algo inesperado.'));
      },
    );
  }

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
            const Text('Dile al administrador que la agregue en Firebase.', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _DietNotFoundException implements Exception {
  final String objective;
  _DietNotFoundException(this.objective);
}