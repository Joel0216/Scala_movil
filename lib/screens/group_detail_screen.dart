import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/asistencia.dart';
import '../models/sesion.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final Map<int, EstadoAsistencia> _attendance = {};
  final Map<int, String> _observaciones = {};
  bool _classStarted = false;
  String _sessionDate = DateTime.now().toIso8601String().split('T')[0];
  int _sesionesCount = 0;
  bool _isCheckingCount = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final grupo = ModalRoute.of(context)!.settings.arguments as Grupo;
      final provider = context.read<DataProvider>();
      
      // Lanzar la carga al mismo tiempo para optimizar tiempo
      await Future.wait([
        provider.loadAlumnos(grupo.clave ?? ''),
        provider.contarSesionesGrupo(grupo.id).then((count) {
          if (mounted) {
            setState(() {
              _sesionesCount = count;
              _isCheckingCount = false;
            });
          }
        }),
      ]);
    });
  }

  Future<void> _showStartClassDialog(Grupo grupo) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final maestroId = context.read<AuthProvider>().maestro!.id;
    final provider = context.read<DataProvider>();

    await provider.loadSalones();

    await showDialog(
      context: context,
      builder: (context) {
        bool isChecking = false;
        bool isExtra = false;
        String? razon;
        String? salonExtra = grupo.salon;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Iniciar Clase'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Fecha: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setState(() => selectedDate = d);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Hora: ${selectedTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (t != null) {
                          setState(() => selectedTime = t);
                        }
                      },
                    ),
                    if (!isExtra)
                      ElevatedButton(
                        onPressed: isChecking ? null : () async {
                          setState(() => isChecking = true);
                          final exists = await provider.checkSessionExistsThisWeek(grupo.id, selectedDate);
                          setState(() {
                            isChecking = false;
                            isExtra = exists;
                          });
                          if (!exists) {
                            _submitSession(grupo, maestroId, selectedDate, selectedTime, false, null, null);
                          }
                        },
                        child: isChecking ? const CircularProgressIndicator() : const Text('Verificar y Empezar'),
                      ),
                    
                    if (isExtra) ...[
                      const Divider(),
                      const Text('Ya hay clase esta semana. Será EXTRA.', style: TextStyle(color: Colors.red)),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Motivo/Razón'),
                        onChanged: (v) => razon = v,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Salón'),
                        value: provider.salones.contains(salonExtra) ? salonExtra : (provider.salones.isNotEmpty ? provider.salones.first : null),
                        items: provider.salones.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => salonExtra = v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isChecking ? null : () async {
                          if (razon == null || razon!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe ingresar un motivo')));
                            return;
                          }
                          setState(() => isChecking = true);
                          final horaStr = '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}:00';
                          final fechaStr = selectedDate.toIso8601String().split('T')[0];
                          
                          final hayCupo = await provider.checkSalonAvailability(salonExtra ?? '', fechaStr, horaStr);
                          setState(() => isChecking = false);
                          
                          if (!hayCupo) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El salón no tiene cupo o está ocupado.')));
                          } else {
                            _submitSession(grupo, maestroId, selectedDate, selectedTime, true, razon, salonExtra);
                          }
                        },
                        child: isChecking ? const CircularProgressIndicator() : const Text('Confirmar Clase Extra'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitSession(Grupo grupo, int maestroId, DateTime date, TimeOfDay time, bool esExtra, String? motivo, String? salon) async {
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    final sesion = Sesion(
      grupoId: grupo.id,
      maestroId: maestroId,
      fecha: combined.toIso8601String().split('T')[0],
      horaInicio: combined.toUtc().toIso8601String(),
      esExtra: esExtra,
      motivoExtra: motivo,
      salonExtra: salon,
    );
    
    final result = await context.read<DataProvider>().startClassSession(sesion);
    if (result == 'OK') {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _classStarted = true;
          _sessionDate = combined.toIso8601String().split('T')[0];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión iniciada')));
      }
    } else if (result == 'DUPLICATE_DAY') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ya tienes una clase registrada para esta fecha exacta (solo 1 por día).'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear sesión')));
      }
    }
  }

  Future<void> _saveAttendance(Grupo grupo) async {
    final data = context.read<DataProvider>();
    final List<Asistencia> asistencias = [];

    for (var alumno in data.alumnos) {
      asistencias.add(Asistencia(
        grupoId: grupo.id,
        alumnoId: alumno.id,
        fecha: _sessionDate,
        estado: _attendance[alumno.id] ?? EstadoAsistencia.asistencia,
        observaciones: _observaciones[alumno.id],
      ));
    }

    final result = await data.saveAttendance(asistencias);
    if (mounted) {
      if (result == 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clase terminada y asistencia guardada')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $result'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupo = ModalRoute.of(context)!.settings.arguments as Grupo;
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nombre),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(grupo),
            const SizedBox(height: 24),
            if (!_classStarted)
              Center(
                child: _isCheckingCount 
                  ? const CircularProgressIndicator()
                  : _sesionesCount >= 24 
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: const Text('Este grupo ha alcanzado el límite de 24 clases permitidas.', 
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.lock),
                            label: const Text('CURSO FINALIZADO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Historial de Asistencias Consolidado \n(Solo vista en versión móvil, ver detalle en escritorio)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showStartClassDialog(grupo),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('INICIAR CLASE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
              )
            else ...[
              const Text(
                'Pasar Lista',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (data.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = data.alumnos[index];
                    return _buildAttendanceTile(alumno);
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveAttendance(grupo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('TERMINAR CLASE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Grupo grupo) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.book, 'Curso', grupo.curso ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.schedule, 'Horario', grupo.horario ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.room, 'Salón', grupo.salon ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade900),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value),
      ],
    );
  }

  Widget _buildAttendanceTile(Alumno alumno) {
    final currentStatus = _attendance[alumno.id] ?? EstadoAsistencia.asistencia;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(alumno.nombre)),
              SegmentedButton<EstadoAsistencia>(
                segments: const [
                  ButtonSegment(value: EstadoAsistencia.asistencia, label: Text('A')),
                  ButtonSegment(value: EstadoAsistencia.falta, label: Text('F')),
                  ButtonSegment(value: EstadoAsistencia.retardo, label: Text('R')),
                  ButtonSegment(value: EstadoAsistencia.reposicion, label: Text('Rep')),
                ],
                selected: {currentStatus},
                onSelectionChanged: (Set<EstadoAsistencia> selection) {
                  setState(() => _attendance[alumno.id] = selection.first);
                },
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      if (currentStatus == EstadoAsistencia.reposicion) return Colors.purple;
                      if (currentStatus == EstadoAsistencia.falta) return Colors.red;
                      if (currentStatus == EstadoAsistencia.retardo) return Colors.orange;
                      return Colors.blue.shade800;
                    }
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Observaciones (opcional)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              _observaciones[alumno.id] = val;
            },
          ),
        ],
      ),
    );
  }
}
