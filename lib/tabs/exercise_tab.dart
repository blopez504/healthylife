import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha
import '../../widgets/pulse_loader.dart';

class ExerciseTab extends StatefulWidget {
  const ExerciseTab({super.key});

  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  late Future<Map<String, dynamic>> _routineFuture;
  List<bool> _ejerciciosCompletados = []; // Estado local de los checkboxes
  String _nivelActual = "";

  @override
  void initState() {
    super.initState();
    _routineFuture = _loadRoutineData();
  }

  /// Devuelve la fecha actual en formato 'YYYY-MM-DD' para usarla como ID de documento.
  String _getTodayDateId() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Carga los datos del usuario y su rutina correspondiente en una sola operación.
  Future<Map<String, dynamic>> _loadRoutineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay sesión iniciada.');
    }

    // Paso 1: Buscamos el objetivo y nivel del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Error al cargar datos del usuario.');
    }
    final userData = userDoc.data() ?? {};
    final String objetivoUsuario = userData['objetivo'] ?? 'Mantenerse';
    final String nivelUsuario = userData['nivel'] ?? 'Principiante';
    
    _nivelActual = nivelUsuario; // Guardamos el nivel para mostrarlo en la interfaz

    // Paso 2: Buscamos la rutina que coincida con el objetivo AND el nivel
    final routineQuery = await FirebaseFirestore.instance.collection('rutinas')
        .where('objetivo', isEqualTo: objetivoUsuario)
        .where('nivel', isEqualTo: nivelUsuario)
        .get();

    if (routineQuery.docs.isEmpty) {
      throw _RoutineNotFoundException(objetivoUsuario, nivelUsuario);
    }

    // Paso 3: Extraemos los datos
    final routineData = routineQuery.docs.first.data();
    
    // Paso 4: Inicializamos las casillas de verificación
    List<dynamic> ejerciciosRaw = routineData['ejercicios'] ?? [];
    int totalEjercicios = ejerciciosRaw.length;

    // Paso 5: Cargamos el progreso guardado para el día de hoy
    final todayId = _getTodayDateId();
    final progressDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('progreso_diario')
        .doc(todayId)
        .get();

    List<bool> initialProgress = List<bool>.filled(totalEjercicios, false);
    if (progressDoc.exists && progressDoc.data()!.containsKey('ejerciciosCompletados')) {
      List<dynamic> savedProgress = progressDoc.data()!['ejerciciosCompletados'];
      // Aseguramos que la lista de progreso tenga el mismo tamaño que la lista de ejercicios
      for (int i = 0; i < totalEjercicios && i < savedProgress.length; i++) {
        initialProgress[i] = savedProgress[i] as bool;
      }
    }

    // Usamos 'WidgetsBinding.instance.addPostFrameCallback' para asegurar que el widget esté construido
    // antes de llamar a setState. Esto evita errores comunes en Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _ejerciciosCompletados = initialProgress;
        });
      }
    });

    return routineData;
  }

  // --- NUEVA FUNCIÓN: Guarda el progreso en Firebase ---
  Future<void> _updateExerciseProgress(int index, bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Actualiza el estado local inmediatamente para que la UI responda al instante
    setState(() {
      _ejerciciosCompletados[index] = isCompleted;
    });

    // Guarda la lista completa en Firebase
    final todayId = _getTodayDateId();
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('progreso_diario').doc(todayId).set({
        'ejerciciosCompletados': _ejerciciosCompletados,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // 'merge: true' es crucial para no sobreescribir el progreso de comidas
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar progreso: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _routineFuture,
      builder: (context, snapshot) {
        
        // Caso 1: Cargando datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PulseLoader(
            icon: Icons.fitness_center,
            color: Color(0xFF1976D2),
            text: 'Descargando tu rutina...',
          );
        }

        // Caso 2: Ocurrió un error (Ej. No existe esa rutina en la nube)
        if (snapshot.hasError) {
          if (snapshot.error is _RoutineNotFoundException) {
            final error = snapshot.error as _RoutineNotFoundException;
            return _buildRoutineNotFoundUI(error.objective, error.level);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Caso 3: Datos cargados correctamente
        if (snapshot.hasData) {
          final rutinaData = snapshot.data!;
          String tituloRutina = rutinaData['titulo'] ?? 'Sin Título';
          String enfoque = rutinaData['enfoque'] ?? 'Sin enfoque específico';
          List<dynamic> ejerciciosRaw = rutinaData['ejercicios'] ?? [];

          // Convertimos a lista fuertemente tipada para Flutter
          List<Map<String, String>> rutina = ejerciciosRaw.map((item) {
            return {
              "ejercicio": item["ejercicio"]?.toString() ?? "Ejercicio",
              "series": item["series"]?.toString() ?? "Series no especificadas"
            };
          }).toList();

          // Si _ejerciciosCompletados está vacío (primera carga), lo inicializamos
          if (_ejerciciosCompletados.isEmpty && rutina.isNotEmpty) {
            _ejerciciosCompletados = List<bool>.filled(rutina.length, false);
          }

          // Cálculos para la barra de progreso
          int marcadas = _ejerciciosCompletados.where((element) => element == true).length;
          double progreso = rutina.isEmpty ? 0 : marcadas / rutina.length;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- TARJETA PRINCIPAL (Datos de Firebase) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.blue.withAlpha(77), blurRadius: 8, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Text('Rutina: $_nivelActual', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.cloud_done, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('Sincronizado', style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(tituloRutina, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(enfoque, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progreso de Hoy:', style: TextStyle(color: Colors.white70)),
                        Text('$marcadas/${rutina.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progreso,
                      backgroundColor: Colors.white.withAlpha(77),
                      color: Colors.greenAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Ejercicios de Hoy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // --- LISTA DE CHECKBOX (Generada dinámicamente desde Firebase) ---
              if (rutina.isEmpty)
                const Center(child: Text('No hay ejercicios detallados en esta rutina.'))
              else
                for (int i = 0; i < rutina.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: _ejerciciosCompletados[i] ? Colors.green.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _ejerciciosCompletados[i] ? Colors.green : Colors.transparent, width: 1)
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.all(12),
                      activeColor: const Color(0xFF2E7D32),
                      title: Text(
                        rutina[i]['ejercicio']!, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          decoration: _ejerciciosCompletados[i] ? TextDecoration.lineThrough : TextDecoration.none,
                          color: _ejerciciosCompletados[i] ? Colors.grey : Colors.black,
                        )
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(rutina[i]['series']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      ),
                      value: _ejerciciosCompletados[i],
                      onChanged: (bool? newValue) {
                        _updateExerciseProgress(i, newValue ?? false);
                      },
                    ),
                  ),
                
                // Mensaje de felicitaciones al llenar la barra
                if (progreso == 1.0 && rutina.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.orange, size: 32),
                        SizedBox(width: 12),
                        Text('¡Felicidades! Terminaste por hoy.', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
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

  /// Widget amigable que se muestra cuando la rutina no existe en la BD
  Widget _buildRoutineNotFoundUI(String objetivoUsuario, String nivelUsuario) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aún no hay una rutina en la nube para:\n"$objetivoUsuario" - Nivel: "$nivelUsuario".',
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

/// Excepción personalizada
class _RoutineNotFoundException implements Exception {
  final String objective;
  final String level;
  _RoutineNotFoundException(this.objective, this.level);
}