import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/trip_service.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({Key? key}) : super(key: key);

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _tripService = TripService();
  
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de fin es anterior a la de inicio, resetearla
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona las fechas del viaje')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? budget;
      if (_budgetController.text.isNotEmpty) {
        final budgetValue = double.tryParse(_budgetController.text);
        if (budgetValue != null) {
          budget = (budgetValue * 100).round(); // Convertir a centavos
        }
      }

      await _tripService.createTrip(
        name: _nameController.text,
        destination: _destinationController.text.isEmpty ? null : _destinationController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        budget: budget,
      );

      if (mounted) {
        Navigator.pop(context, true); // true indica que se creó el viaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje creado exitosamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear viaje: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Viaje'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del viaje *',
                hintText: 'Ej: Viaje a Madrid',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre del viaje';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destino',
                hintText: 'Ej: Madrid, España',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha inicio *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startDate != null
                            ? dateFormat.format(_startDate!)
                            : 'Seleccionar',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha fin *',
                        prefixIcon: Icon(Icons.event),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endDate != null
                            ? dateFormat.format(_endDate!)
                            : 'Seleccionar',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Presupuesto',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Notas adicionales del viaje',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear Viaje', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
