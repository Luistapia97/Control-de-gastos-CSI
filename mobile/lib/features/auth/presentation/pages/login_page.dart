import 'package:flutter/material.dart';

/// Login Page - Placeholder
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const Icon(
                Icons.receipt_long,
                size: 80,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Expense Control',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Control de Gastos Inteligente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Email field
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              // Login button
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement login
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Register link
              TextButton(
                onPressed: () {
                  // TODO: Navigate to register
                },
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
