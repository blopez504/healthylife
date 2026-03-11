import 'package:flutter/material.dart';

class ExerciseTab extends StatelessWidget {
  const ExerciseTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Tus Rutinas - Nivel Principiante', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Ejercicios seleccionados para tu condición física.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        
        // Lista de ejercicios
        _buildExerciseCard('Cardio Suave', '20 minutos • Quema grasa inicial', Icons.directions_walk_rounded, Colors.blue),
        _buildExerciseCard('Fuerza con Peso Corporal', '30 minutos • Piernas y abdomen', Icons.fitness_center_rounded, Colors.orange),
        _buildExerciseCard('Yoga y Estiramiento', '15 minutos • Flexibilidad', Icons.self_improvement_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildExerciseCard(String title, String desc, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Lógica al tocar el ejercicio
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 35),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: Color(0xFF2E7D32), size: 40),
            ],
          ),
        ),
      ),
    );
  }
}