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
        
        // Calculo del IMC
        double imc = 0;
        String estadoImc = "Calculando...";
        Color colorImc = Colors.grey;
        String consejo = "";
        IconData iconoEstado = Icons.help_outline;

        if (pesoLibras > 0 && alturaCm > 0) {
          double pesoKilos = pesoLibras / 2.20462; 
          double alturaMts = alturaCm > 3.0 ? alturaCm / 100 : alturaCm;
          
          imc = pesoKilos / (alturaMts * alturaMts);
          
          if (imc < 18.5) {
            estadoImc = "Bajo Peso"; colorImc = Colors.blue; iconoEstado = Icons.arrow_downward;
            consejo = "Te recomendamos un superávit calórico para ganar masa muscular.";
          } else if (imc >= 18.5 && imc < 24.9) {
            estadoImc = "Peso Saludable"; colorImc = Colors.green; iconoEstado = Icons.check_circle;
            consejo = "¡Excelente trabajo! Mantén tus hábitos saludables actuales.";
          } else if (imc >= 25 && imc < 29.9) {
            estadoImc = "Sobrepeso"; colorImc = Colors.orange; iconoEstado = Icons.warning_amber_rounded;
            consejo = "Un ligero déficit calórico y ejercicio regular te ayudarán.";
          } else {
            estadoImc = "Obesidad"; colorImc = Colors.red; iconoEstado = Icons.report_problem;
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
              
              // --- TARJETA DE IMC ---
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
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(consejo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- MINI TARJETAS DE OBJETIVO Y NIVEL ---
              Row(
                children: [
                  Expanded(child: _buildMiniCard('Objetivo', userData['objetivo'] ?? '--', Icons.flag, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniCard('Nivel', userData['nivel'] ?? '--', Icons.fitness_center, Colors.orange)),
                ],
              ),
              
              const SizedBox(height: 24),

              // --- NUEVA SECCIÓN: CONTROL DE AGUA ---
              const Text('Registro de Hidratación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Llamamos a nuestro nuevo widget interactivo
              WaterTracker(userId: user.uid, vasosTomados: userData['vasosAgua'] ?? 0),

              const SizedBox(height: 24),
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

// =====================================================================
// NUEVO WIDGET: CONTROL DE AGUA (WATER TRACKER)
// =====================================================================
class WaterTracker extends StatefulWidget {
  final String userId;
  final int vasosTomados;
  final int metaVasos;

  const WaterTracker({
    super.key,
    required this.userId,
    required this.vasosTomados,
    this.metaVasos = 8, // Meta recomendada de 8 vasos (Aprox 2 Litros)
  });

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  late int _vasosActuales;

  @override
  void initState() {
    super.initState();
    _vasosActuales = widget.vasosTomados;
  }

  // Función que se ejecuta al tocar un vaso
  Future<void> _actualizarAgua(int index) async {
    // Si tocan el vaso 3, queremos que se llenen los vasos 1, 2 y 3.
    // Si tocan el mismo vaso que ya está lleno (el último), se vacía.
    int nuevosVasos = index + 1;
    if (_vasosActuales == nuevosVasos) {
      nuevosVasos--; // Quitar un vaso
    }

    setState(() {
      _vasosActuales = nuevosVasos;
    });

    // Guardamos en Firebase para que no se pierda al cambiar de pestaña
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'vasosAgua': nuevosVasos
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error al guardar agua: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progreso = _vasosActuales / widget.metaVasos;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.lightBlue),
                    SizedBox(width: 8),
                    Text('Agua consumida', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text('$_vasosActuales / ${widget.metaVasos} vasos', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _vasosActuales >= widget.metaVasos ? Colors.green : Colors.lightBlue
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fila de vasos interactivos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(widget.metaVasos, (index) {
                bool estaLleno = index < _vasosActuales;
                return GestureDetector(
                  onTap: () => _actualizarAgua(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: estaLleno ? Colors.lightBlue.shade100 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: estaLleno ? Colors.lightBlue : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      estaLleno ? Icons.local_drink : Icons.local_drink_outlined,
                      color: estaLleno ? Colors.lightBlue : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            // Mensaje motivacional
            Center(
              child: Text(
                _vasosActuales == 0 
                    ? '¡No olvides hidratarte hoy!' 
                    : _vasosActuales >= widget.metaVasos 
                        ? '¡Meta alcanzada! Excelente hidratación.' 
                        : '¡Sigue así! Estás a ${widget.metaVasos - _vasosActuales} vasos de tu meta.',
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}