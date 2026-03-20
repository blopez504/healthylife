import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DietTab extends StatelessWidget {
  const DietTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos al usuario que inició sesión
    final user = FirebaseAuth.instance.currentUser;

    // Si por alguna razón no hay usuario, mostramos un mensaje
    if (user == null) {
      return const Center(child: Text("No hay sesión iniciada"));
    }

    return FutureBuilder<DocumentSnapshot>(
      // 2. Buscamos los datos de este usuario específico en la colección 'users' de Firestore
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        
        // Mientras espera la respuesta de internet
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        
        // Si hay un error de conexión o no encuentra el documento
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar tu plan de dieta.'));
        }

        // 3. Extraemos los datos del usuario
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        // Buscamos qué objetivo guardó al registrarse (si no hay, por defecto es 'Mantenerse')
        String objetivo = userData['objetivo'] ?? 'Mantenerse';

        // Variables vacías que llenaremos dependiendo del objetivo
        String tituloDieta = "";
        String descripcion = "";
        List<Map<String, String>> planComidas = [];

        // 4. LÓGICA INTELIGENTE: Asignamos la dieta según su objetivo
        if (objetivo == 'Perder peso') {
          tituloDieta = "Déficit Calórico (Perder Peso)";
          descripcion = "Plan enfocado en consumir menos calorías para quemar grasa conservando energía.";
          planComidas = [
            {"comida": "Desayuno", "desc": "2 huevos revueltos con espinaca y una taza de té verde o café sin azúcar."},
            {"comida": "Almuerzo", "desc": "Pechuga de pollo a la plancha (150g) con ensalada mixta y vinagreta ligera."},
            {"comida": "Cena", "desc": "Lata de atún en agua con rodajas de pepino y tomate."}
          ];
        } else if (objetivo == 'Ganar masa muscular') {
          tituloDieta = "Superávit Calórico (Volumen)";
          descripcion = "Plan alto en proteínas y carbohidratos complejos para construir músculo.";
          planComidas = [
            {"comida": "Desayuno", "desc": "Tazón de avena con leche, 1 plátano, crema de maní y un scoop de proteína."},
            {"comida": "Almuerzo", "desc": "Filete de res magro (200g) con doble porción de arroz y brócoli al vapor."},
            {"comida": "Cena", "desc": "Pasta integral con carne molida magra y salsa de tomate natural."}
          ];
        } else {
          // Opción por defecto: Mantenerse
          tituloDieta = "Mantenimiento Saludable";
          descripcion = "Plan balanceado para mantener tu peso actual y mejorar tu salud general.";
          planComidas = [
            {"comida": "Desayuno", "desc": "Yogur griego sin azúcar con un puñado de fresas y almendras."},
            {"comida": "Almuerzo", "desc": "Filete de pescado al horno con porción moderada de arroz y vegetales."},
            {"comida": "Cena", "desc": "Ensalada César con trozos de pollo a la plancha (aderezo ligero)."}
          ];
        }

        // 5. Construimos la interfaz visual de la pestaña
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Tarjeta principal verde con el título
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tu Plan Personalizado', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
            
            // Generamos las tarjetas de comida usando el ciclo map
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
            )).toList() // Convertimos el map de vuelta a una lista para que Flutter lo dibuje
          ],
        );
      },
    );
  }
}