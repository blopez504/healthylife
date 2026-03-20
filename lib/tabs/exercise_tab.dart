import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseTab extends StatelessWidget {
  const ExerciseTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos al usuario que inició sesión
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No hay sesión iniciada"));
    }

    return FutureBuilder<DocumentSnapshot>(
      // 2. Buscamos los datos del usuario en Firebase
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar tu rutina.'));
        }

        // 3. Extraemos el objetivo y el nivel del usuario
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String objetivo = userData['objetivo'] ?? 'Mantenerse';
        String nivel = userData['nivel'] ?? 'Principiante';

        // Variables para la rutina
        String tituloRutina = "";
        String enfoque = "";
        List<Map<String, String>> rutina = [];

        // 4. LÓGICA INTELIGENTE: Asignamos la rutina según objetivo y nivel
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

        // 5. Construimos la interfaz visual
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Tarjeta principal con el título
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2), // Color azul para diferenciarlo de la dieta (verde)
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
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
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Ejercicios de Hoy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Generamos las tarjetas de ejercicios
            ...rutina.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_run, color: Color(0xFF1976D2)),
                ),
                title: Text(item['ejercicio']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(item['series']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                ),
                trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
              ),
            )).toList()
          ],
        );
      },
    );
  }
}