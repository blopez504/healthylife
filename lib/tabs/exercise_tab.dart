import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseTab extends StatefulWidget {
  const ExerciseTab({Key? key}) : super(key: key);

  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  // --- NUEVO: LISTA PARA LLEVAR EL CONTROL DE LAS CASILLAS MARCADAS ---
  // Guardamos si la tarea 0, 1, 2 o 3 está completada
  final List<bool> _tareasCompletadas = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("No hay sesión iniciada"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar tu rutina.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String objetivo = userData['objetivo'] ?? 'Mantenerse';
        String nivel = userData['nivel'] ?? 'Principiante';

        String tituloRutina = "";
        String enfoque = "";
        List<Map<String, String>> rutina = [];

        // LÓGICA INTELIGENTE (La que ya teníamos)
        if (objetivo == 'Perder peso') {
          tituloRutina = "Quema de Grasa (Cardio/HIIT)";
          enfoque = "Ejercicios de alta intensidad para acelerar el metabolismo. Nivel: $nivel.";
          rutina = [
            {"ejercicio": "Saltos de tijera (Jumping Jacks)", "series": "3 series de 45 segundos"},
            {"ejercicio": "Burpees", "series": nivel == 'Principiante' ? "3 series de 8 reps" : "4 series de 15 reps"},
            {"ejercicio": "Escaladoras (Mountain Climbers)", "series": "4 series de 30 segundos"},
            {"ejercicio": "Trote en el mismo sitio", "series": "5 minutos a buen ritmo"}
          ];
        } else if (objetivo == 'Ganar masa muscular') {
          tituloRutina = "Fuerza y Volumen";
          enfoque = "Enfocado en hipertrofia y resistencia muscular. Nivel: $nivel.";
          rutina = [
            {"ejercicio": "Flexiones de pecho (Push-ups)", "series": nivel == 'Principiante' ? "3 series de 8 reps (apoyo en rodillas)" : "4 series al fallo"},
            {"ejercicio": "Sentadillas con peso libre", "series": "4 series de 12 repeticiones"},
            {"ejercicio": "Dominadas o Remo con mancuernas", "series": "4 series de 10 repeticiones"},
            {"ejercicio": "Plancha abdominal (Plank)", "series": "3 series de 45 segundos"}
          ];
        } else {
          tituloRutina = "Acondicionamiento Físico";
          enfoque = "Mantenimiento general, flexibilidad y salud cardiovascular. Nivel: $nivel.";
          rutina = [
            {"ejercicio": "Caminata rápida o Trote ligero", "series": "20 - 30 minutos"},
            {"ejercicio": "Sentadillas clásicas", "series": "3 series de 15 repeticiones"},
            {"ejercicio": "Estiramiento de cuerpo completo", "series": "10 minutos"},
            {"ejercicio": "Elevación de pelvis (Puente)", "series": "3 series de 15 repeticiones"}
          ];
        }

        // Calculamos el progreso visual (cuántas están marcadas)
        int marcadas = _tareasCompletadas.where((element) => element == true).length;
        double progreso = marcadas / rutina.length;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- TARJETA PRINCIPAL CON BARRA DE PROGRESO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text('Rutina: $nivel', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(tituloRutina, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(enfoque, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  
                  // La nueva barra de progreso visual
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progreso de Hoy:', style: const TextStyle(color: Colors.white70)),
                      Text('$marcadas/${rutina.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progreso,
                    backgroundColor: Colors.white.withOpacity(0.3),
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
            
            // --- NUEVO: LISTA CON CHECKBOX INTERACTIVOS ---
            // Usamos un bucle for tradicional en lugar de .map para saber el "índice" de cada ejercicio
            for (int i = 0; i < rutina.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                // Si la tarea está completada, ponemos el fondo verdecito claro
                color: _tareasCompletadas[i] ? Colors.green.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _tareasCompletadas[i] ? Colors.green : Colors.transparent,
                    width: 1
                  )
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.all(12),
                  activeColor: const Color(0xFF2E7D32),
                  title: Text(
                    rutina[i]['ejercicio']!, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      // Tachamos el texto si ya lo completó
                      decoration: _tareasCompletadas[i] ? TextDecoration.lineThrough : TextDecoration.none,
                      color: _tareasCompletadas[i] ? Colors.grey : Colors.black,
                    )
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(rutina[i]['series']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ),
                  value: _tareasCompletadas[i],
                  onChanged: (bool? newValue) {
                    // Refrescamos la pantalla cuando marca la casilla
                    setState(() {
                      _tareasCompletadas[i] = newValue!;
                    });
                  },
                ),
              ),
              
              // Si completó todos, mostramos un mensaje de felicitaciones
              if (progreso == 1.0)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
      },
    );
  }
}