import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/pulse_loader.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No hay sesión iniciada"));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // --- ANIMACIÓN DE CARGA AQUÍ ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PulseLoader(
            icon: Icons.monitor_heart, 
            color: Color(0xFF2E7D32),
            text: 'Calculando tu salud...',
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar tu resumen.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        
        double pesoLibras = (userData['peso'] ?? 0).toDouble(); 
        double alturaCm = (userData['altura'] ?? 0).toDouble();
        String nombre = userData['email']?.split('@')[0] ?? 'Usuario'; 
        
        double imc = 0;
        String estadoImc = "Calculando...";
        Color colorImc = Colors.grey;
        String consejo = "";
        IconData iconoEstado = Icons.help_outline;

        if (pesoLibras > 0 && alturaCm > 0) {
          double pesoKilos = pesoLibras / 2.20462; 
          
          double alturaMts = alturaCm;
          if (alturaCm > 3.0) {
            alturaMts = alturaCm / 100;
          }
          
          imc = pesoKilos / (alturaMts * alturaMts);
          
          if (imc < 18.5) {
            estadoImc = "Bajo Peso";
            colorImc = Colors.blue;
            iconoEstado = Icons.arrow_downward;
            consejo = "Te recomendamos un superávit calórico para ganar masa muscular.";
          } else if (imc >= 18.5 && imc < 24.9) {
            estadoImc = "Peso Saludable";
            colorImc = Colors.green;
            iconoEstado = Icons.check_circle;
            consejo = "¡Excelente trabajo! Mantén tus hábitos saludables actuales.";
          } else if (imc >= 25 && imc < 29.9) {
            estadoImc = "Sobrepeso";
            colorImc = Colors.orange;
            iconoEstado = Icons.warning_amber_rounded;
            consejo = "Un ligero déficit calórico y ejercicio regular te ayudarán.";
          } else {
            estadoImc = "Obesidad";
            colorImc = Colors.red;
            iconoEstado = Icons.report_problem;
            consejo = "Prioriza ejercicios de cardio y consulta tu dieta personalizada.";
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, $nombre!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Aquí tienes tu resumen de salud de hoy.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),

              const Text('Tu Índice de Masa Corporal (IMC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [colorImc.withOpacity(0.8), colorImc],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(iconoEstado, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        imc > 0 ? imc.toStringAsFixed(1) : '--', 
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        estadoImc.toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          consejo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildMiniCard('Objetivo', userData['objetivo'] ?? '--', Icons.flag, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniCard('Nivel', userData['nivel'] ?? '--', Icons.fitness_center, Colors.orange)),
                ],
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text('Peso registrado: $pesoLibras lbs', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}