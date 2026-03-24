import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/asistencia.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final Map<int, EstadoAsistencia> _attendance = {};
  bool _classStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grupo = ModalRoute.of(context)!.settings.arguments as Grupo;
      context.read<DataProvider>().loadAlumnos(grupo.id);
    });
  }

  Future<void> _startSession(Grupo grupo) async {
    final maestroId = context.read<AuthProvider>().maestro!.id;
    final success = await context.read<DataProvider>().startClassSession(grupo.id, maestroId);
    
    if (success) {
      if (mounted) {
        setState(() => _classStarted = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión iniciada')));
      }
    }
  }

  Future<void> _saveAttendance(Grupo grupo) async {
    final data = context.read<DataProvider>();
    final List<Asistencia> asistencias = [];
    final today = DateTime.now().toIso8601String().split('T')[0];

    for (var alumno in data.alumnos) {
      asistencias.add(Asistencia(
        grupoId: grupo.id,
        alumnoId: alumno.id,
        fecha: today,
        estado: _attendance[alumno.id] ?? EstadoAsistencia.asistencia,
      ));
    }

    final success = await data.saveAttendance(asistencias);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asistencia guardada')));
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
                child: ElevatedButton.icon(
                  onPressed: () => _startSession(grupo),
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
                  child: const Text('GUARDAR ASISTENCIA'),
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
      child: Row(
        children: [
          Expanded(child: Text(alumno.nombre)),
          SegmentedButton<EstadoAsistencia>(
            segments: const [
              ButtonSegment(value: EstadoAsistencia.asistencia, label: Text('A')),
              ButtonSegment(value: EstadoAsistencia.falta, label: Text('F')),
              ButtonSegment(value: EstadoAsistencia.retardo, label: Text('R')),
            ],
            selected: {currentStatus},
            onSelectionChanged: (Set<EstadoAsistencia> selection) {
              setState(() => _attendance[alumno.id] = selection.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
