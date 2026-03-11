import 'package:flutter/material.dart';

class DietTab extends StatelessWidget {
  const DietTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Aviso de personalización
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green),
              SizedBox(width: 10),
              Expanded(child: Text('Dieta personalizada para tu objetivo de "Perder peso".', style: TextStyle(color: Colors.green))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Plan de Comidas (Hoy)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Lista de comidas
        _buildMealCard('Desayuno', 'Avena con manzana y almendras', '350 kcal', Icons.wb_sunny_rounded, Colors.orange),
        _buildMealCard('Almuerzo', 'Pechuga a la plancha con ensalada verde', '450 kcal', Icons.local_dining_rounded, Colors.green),
        _buildMealCard('Snack', 'Yogur griego con frutos rojos', '150 kcal', Icons.apple_rounded, Colors.redAccent),
        _buildMealCard('Cena', 'Salmón al horno con espárragos', '400 kcal', Icons.nights_stay_rounded, Colors.indigo),
      ],
    );
  }

  Widget _buildMealCard(String title, String desc, String kcal, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), radius: 25, child: Icon(icon, color: color, size: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(desc),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(kcal, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}