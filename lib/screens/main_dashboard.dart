import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/diet_tab.dart';
import 'tabs/exercise_tab.dart';
import 'tabs/profile_tab.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  // Lista de las 4 pantallas principales
  final List<Widget> _screens = [
    const HomeTab(),
    const DietTab(),
    const ExerciseTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthyLife'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recordatorio: ¡Hora de beber un vaso de agua! 💧')),
              );
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Dieta'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Rutinas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}