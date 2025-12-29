class AppConfig {
  // Cambiar a tu dominio de producción cuando esté listo
  static const String baseUrl = 
      const bool.fromEnvironment('dart.vm.product')
          ? 'https://tu-dominio.com/api'  // Producción
          : 'http://10.0.2.2:8000/api';   // Desarrollo
  
  static const String appName = 'Control de Gastos';
  static const String version = '1.0.0';
}
