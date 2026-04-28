import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/examen_programado.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.maestro != null) {
        context.read<DataProvider>().loadExamenes(auth.maestro!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final maestroId = auth.maestro?.id ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Mis Exámenes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (auth.maestro != null) data.loadExamenes(auth.maestro!.id);
            },
          ),
        ],
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : data.examenes.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: data.examenes.length,
                  itemBuilder: (ctx, i) => _ExamenCard(
                    examen: data.examenes[i],
                    maestroId: maestroId,
                    maestroClave: auth.maestro?.clave ?? '',
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No tienes exámenes programados',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ============================================================
// Card de Examen
// ============================================================
class _ExamenCard extends StatefulWidget {
  final ExamenProgramado examen;
  final int maestroId;
  final String maestroClave;

  const _ExamenCard({required this.examen, required this.maestroId, required this.maestroClave});

  @override
  State<_ExamenCard> createState() => _ExamenCardState();
}

class _ExamenCardState extends State<_ExamenCard> {
  int _sesionesCount = 0;
  bool _loaded = false;
  bool _esMaestroBase = false;

  @override
  void initState() {
    super.initState();
    _esMaestroBase = widget.examen.maestroBaseId == widget.maestroId;
    _cargarSesiones();
  }

  Future<void> _cargarSesiones() async {
    if (widget.examen.grupoId == null) {
      setState(() => _loaded = true);
      return;
    }
    final count = await context.read<DataProvider>().contarSesionesGrupo(widget.examen.grupoId!);
    if (mounted) setState(() { _sesionesCount = count; _loaded = true; });
  }

  bool get _puedeIniciar => _sesionesCount >= 24;

  Color get _cardColor {
    if (!_puedeIniciar) return Colors.white;
    if (_esMaestroBase) return const Color(0xFFe8f5e9);
    return const Color(0xFFfff8e1);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.examen;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ex.claveExamen,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                _buildEstadoBadge(),
              ],
            ),
            const SizedBox(height: 8),
            if (ex.grupoNombre != null)
              _infoRow(Icons.group, 'Grupo', ex.grupoNombre!),
            if (ex.curso != null)
              _infoRow(Icons.book, 'Curso', ex.curso!),
            if (ex.tipo != null)
              _infoRow(Icons.category, 'Tipo', ex.tipo!),
            if (ex.fecha != null)
              _infoRow(Icons.calendar_today, 'Fecha', ex.fecha!),
            if (ex.hora != null)
              _infoRow(Icons.access_time, 'Hora', ex.hora!),
            if (ex.salon != null)
              _infoRow(Icons.room, 'Salón', ex.salon!),
            const SizedBox(height: 4),
            if (!_loaded)
              const LinearProgressIndicator()
            else
              Text(
                'Clases completadas: $_sesionesCount / 24',
                style: TextStyle(
                  fontSize: 12,
                  color: _puedeIniciar ? Colors.green.shade700 : Colors.grey.shade600,
                  fontWeight: _puedeIniciar ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(height: 12),
            // Botones
            if (_puedeIniciar) ...[
              if (_esMaestroBase) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _verClaveYIniciar(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('INICIAR EXAMEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _supervisarExamen(context),
                  icon: const Icon(Icons.supervisor_account),
                  label: const Text('SUPERVISAR EXAMEN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge() {
    String label;
    Color color;
    if (!_loaded) { label = '...'; color = Colors.grey; }
    else if (!_puedeIniciar) { label = 'Pendiente ($_sesionesCount/24)'; color = Colors.orange; }
    else if (_esMaestroBase) { label = 'LISTO'; color = Colors.green; }
    else { label = 'Supervisar'; color = Colors.amber.shade700; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // Maestro base: muestra clave y abre examen
  Future<void> _verClaveYIniciar(BuildContext context) async {
    final data = context.read<DataProvider>();
    final clave = await data.obtenerClaveAcceso(widget.examen.claveExamen, widget.maestroId);

    if (!mounted) return;
    if (clave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la clave de acceso'), backgroundColor: Colors.red));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔑 Tu Clave de Acceso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
              child: Text(clave, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 12),
            const Text('Esta clave es confidencial. Compártela solo si no puedes dar el examen.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Continuar al Examen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushNamed(context, '/exam-session', arguments: {
        'examen': widget.examen,
        'maestroId': widget.maestroId,
        'maestroClave': widget.maestroClave,
      });
    }
  }

  // Examinador: pide clave del maestro base
  Future<void> _supervisarExamen(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔑 Supervisar Examen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa la clave de acceso del maestro base para supervisar el examen.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Clave de acceso', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            child: const Text('Verificar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final data = context.read<DataProvider>();
    final valida = await data.verificarClaveAcceso(widget.examen.claveExamen, controller.text.trim().toUpperCase());
    if (!mounted) return;

    if (!valida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Clave incorrecta'), backgroundColor: Colors.red));
      return;
    }

    Navigator.pushNamed(context, '/exam-session', arguments: {
      'examen': widget.examen,
      'maestroId': widget.maestroId,
      'maestroClave': widget.maestroClave,
    });
  }
}

// ============================================================
// Pantalla de sesión de examen (calificación con cronómetro)
// ============================================================
class ExamSessionScreen extends StatefulWidget {
  const ExamSessionScreen({super.key});

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _secondsLeft = 2 * 60 * 60; // 2 horas
  List<Map<String, dynamic>> _alumnos = [];
  final Map<int, ResultadoExamen> _resultados = {};
  final Map<int, bool> _yaCalificado = {};
  bool _loading = true;
  bool _guardando = false;
  bool _hayCambios = false;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarAlumnos());
  }

  bool _isNotificationsInitialized = false;

  void _initNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const settings = InitializationSettings(android: androidSettings);
      await flutterLocalNotificationsPlugin.initialize(settings);
      _isNotificationsInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isNotificationsInitialized) {
      try {
        flutterLocalNotificationsPlugin.cancelAll();
      } catch (e) {
        debugPrint('Error al cancelar notificaciones: $e');
      }
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isFinished) return;
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Mostrar notificacion
      _showNotification();
    } else if (state == AppLifecycleState.resumed) {
      // Cancelar notificacion y recalcular timer
      try {
        flutterLocalNotificationsPlugin.cancelAll();
      } catch (e) {
        debugPrint('Error al cancelar notificaciones: $e');
      }
      _syncTimer();
    }
  }

  void _showNotification() async {
    if (_secondsLeft <= 0) return;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    
    final endTimeMillis = DateTime.now().millisecondsSinceEpoch + (_secondsLeft * 1000);
    
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'exam_timer_channel',
      'Temporizador de Examen',
      channelDescription: 'Muestra el tiempo restante del examen activo',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      usesChronometer: true,
      chronometerCountDown: true,
      when: endTimeMillis,
    );
    
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'Examen en curso',
      body: 'Clave: ${examen.claveExamen}',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> _syncTimer() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    final prefs = await SharedPreferences.getInstance();
    final endTimeStr = prefs.getString('exam_end_${examen.claveExamen}');
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      final diff = endTime.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        if (mounted) setState(() => _secondsLeft = diff);
      } else {
        if (mounted) setState(() => _secondsLeft = 0);
      }
    }
  }

  Future<void> _cargarAlumnos() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    if (examen.grupoNombre == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    
    final dp = context.read<DataProvider>();
    final alumnos = await dp.getAlumnosGrupoExamen(examen.grupoNombre!);
    final resultadosViejos = await dp.getResultadosExamen(examen.claveExamen);
    
    if (!mounted) return;
    
    setState(() {
      _alumnos = alumnos;
      
      final Map<int, Map<String, dynamic>> resMap = {
        for (var e in resultadosViejos) e['alumno_id'] as int: e
      };
      
      for (final a in alumnos) {
        final id = a['id'] as int;
        
        // Revisar si ya tiene calificación guardada y SI PRESENTÓ
        final rv = resMap[id];
        if (rv != null) {
          // Bloquear solo si el alumno sí presentó o tiene una calificación previamente asentada > 0
          bool presentoExamen = rv['presento'] == true || (rv['calificacion'] != null && rv['calificacion'] > 0);
          _yaCalificado[id] = presentoExamen;
          
          _resultados[id] = ResultadoExamen(
            alumnoId: id,
            credencial: a['credencial']?.toString(),
            nombreAlumno: a['nombre']?.toString(),
            presento: rv['presento'] ?? false,
            calificacion: (rv['calificacion'] as num?)?.toDouble(),
            nota: rv['nota'],
          );
        } else {
          _yaCalificado[id] = false;
          _resultados[id] = ResultadoExamen(
            alumnoId: id,
            credencial: a['credencial']?.toString(),
            nombreAlumno: a['nombre']?.toString(),
          );
        }
      }
      _isFinished = _alumnos.isNotEmpty && _alumnos.every((a) => _yaCalificado[a['id']] == true);
      _loading = false;
    });
    
    if (!_isFinished) {
      await _syncTimer(); // Sincroniza o inicializa
      _startTimer();
    }
  }

  Future<void> _startTimer() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('exam_end_${examen.claveExamen}')) {
      final endTime = DateTime.now().add(Duration(seconds: _secondsLeft));
      await prefs.setString('exam_end_${examen.claveExamen}', endTime.toIso8601String());
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _onTimerEnd();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onTimerEnd() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏰ Tiempo terminado. Guarda las calificaciones.'), backgroundColor: Colors.red, duration: Duration(seconds: 5)));
  }

  String get _timerDisplay {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 3600) return Colors.green.shade700;
    if (_secondsLeft > 1800) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _guardarResultados() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    final maestroId = args['maestroId'] as int;
    final maestroClave = args['maestroClave'] as String;

    setState(() => _guardando = true);
    _timer?.cancel();

    final resultadosList = _resultados.values.where((r) => _yaCalificado[r.alumnoId!] != true).toList();
    if (resultadosList.isEmpty) {
      if (mounted) setState(() => _guardando = false);
      if (mounted) Navigator.pop(context);
      return;
    }

    final res = await context.read<DataProvider>().guardarResultadosExamen(
      claveExamen: examen.claveExamen,
      maestroCalificadorId: maestroId,
      credencialMaestro: maestroClave,
      resultados: resultadosList,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (res == 'OK') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Calificaciones guardadas correctamente'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $res'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final examen = args['examen'] as ExamenProgramado;
    final todosCalificados = _alumnos.isNotEmpty && _alumnos.every((a) => _yaCalificado[a['id']] == true);

    return PopScope(
      canPop: !_hayCambios,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: Text(examen.claveExamen),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Cronómetro
                if (!todosCalificados)
                  Container(
                    width: double.infinity,
                    color: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text('TIEMPO RESTANTE',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text(_timerDisplay,
                            style: TextStyle(color: _timerColor, fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                // Info examen
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    elevation: 0,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: Text('Grupo: ${examen.grupoNombre ?? "—"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Tipo: ${examen.tipo ?? "—"}')),
                          Expanded(child: Text('Hora: ${examen.hora ?? "—"}')),
                        ],
                      ),
                    ),
                  ),
                ),
                // Lista alumnos
                Expanded(
                  child: _alumnos.isEmpty
                      ? const Center(child: Text('No hay alumnos en este grupo'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _alumnos.length,
                          itemBuilder: (ctx, i) {
                            final alumno = _alumnos[i];
                            final id = alumno['id'] as int;
                            final resultado = _resultados[id]!;
                            final yaCalificado = _yaCalificado[id] ?? false;
                            return _buildAlumnoTile(alumno, resultado, yaCalificado);
                          },
                        ),
                ),
                // Botón guardar
                if (todosCalificados)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 8),
                          Text('EXAMEN FINALIZADO', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarResultados,
                        icon: _guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                        label: Text(_guardando ? 'Terminando...' : 'TERMINAR EXAMEN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  Widget _buildAlumnoTile(Map<String, dynamic> alumno, ResultadoExamen resultado, bool yaCalificado) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: yaCalificado ? Colors.grey.shade300 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(alumno['credencial']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: yaCalificado ? Colors.grey.shade600 : Colors.blue.shade900)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(alumno['nombre']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: yaCalificado ? Colors.grey.shade600 : Colors.black))),
                if (yaCalificado) Icon(Icons.lock, size: 16, color: Colors.grey.shade500),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _checkItem('Presentó', resultado.presento, yaCalificado ? null : (v) => setState(() {
                  resultado.presento = v;
                  _hayCambios = true;
                })),
                const SizedBox(width: 8),
                _readOnlyBadge('Aprobó', resultado.aprobo),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: resultado.calificacion?.toInt().toString() ?? '')..selection = TextSelection.collapsed(offset: (resultado.calificacion?.toInt().toString() ?? '').length),
                    enabled: !yaCalificado,
                    decoration: InputDecoration(
                      labelText: 'Calificación (0-100)',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      counterText: '',
                      fillColor: yaCalificado ? Colors.grey.shade200 : null,
                      filled: yaCalificado,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    inputFormatters: [_ScoreInputFormatter()],
                    onChanged: (v) {
                      setState(() {
                        _hayCambios = true;
                        if (v.isEmpty) {
                          resultado.setCalificacion(null);
                        } else {
                          resultado.setCalificacion(int.parse(v).toDouble());
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkItem(String label, bool value, ValueChanged<bool>? onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged(v ?? false)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _readOnlyBadge(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
          )),
        ],
      ),
    );
  }
}

class _ScoreInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null || val < 0 || val > 100) return oldValue;
    return newValue;
  }
}
