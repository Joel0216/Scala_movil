import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/grupo.dart';
import '../models/examen_programado.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.maestro != null) {
        context.read<DataProvider>().loadGrupos(auth.maestro!.id);
        context.read<DataProvider>().loadExamenes(auth.maestro!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.maestro == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - maestro info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.brown.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Maestro: ${auth.maestro?.nombre ?? "Cargando..."}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Content
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                _GruposTab(),
                ExamenesTab(),
              ],
            ),
          ),
          // Bottom tab bar
          _BottomTabBar(
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tab: Mis Grupos
// ============================================================
class _GruposTab extends StatelessWidget {
  const _GruposTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final active = data.grupos.where((g) => !data.hiddenIds.contains('g_${g.clave}')).toList();
    final hidden = data.grupos.where((g) => data.hiddenIds.contains('g_${g.clave}')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mis Grupos',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, fontFamily: 'serif')),
              const SizedBox(height: 4),
              Text('Selecciona un grupo para iniciar la clase y tomar asistencia.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: data.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.brown))
              : data.grupos.isEmpty
                  ? const Center(child: Text('No tienes grupos asignados'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ...active.map((g) => _GrupoCard(grupo: g)),
                          if (hidden.isNotEmpty)
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Oculto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                children: hidden.map((g) => _GrupoCard(grupo: g)).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _GrupoCard extends StatelessWidget {
  final Grupo grupo;
  const _GrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Visibilidad'),
            content: const Text('¿Deseas ocultar/mostrar este grupo?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR')),
              TextButton(
                onPressed: () {
                  context.read<DataProvider>().toggleHidden('g_${grupo.clave}');
                  Navigator.pop(c);
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          ),
        );
      },
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => GroupDetailScreen(),
        settings: RouteSettings(arguments: grupo),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text('ACTIVO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                ),
                  Row(
                    children: [
                      Text(grupo.clave ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown.shade400)),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'toggle') {
                             context.read<DataProvider>().toggleHidden('g_${grupo.clave}');
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(context.read<DataProvider>().hiddenIds.contains('g_${grupo.clave}') ? 'Mostrar Grupo' : 'Ocultar Grupo'),
                          )
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(grupo.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'serif')),
            const SizedBox(height: 4),
            Text(grupo.fechaInicio ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.brown.shade300, size: 14),
              const SizedBox(width: 6),
              Text('CLIC PARA ENTRAR Y PASAR ASISTENCIA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown.shade400, letterSpacing: 0.5)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab: Exámenes — inline (no push nav needed since it's a tab)
// ============================================================
class ExamenesTab extends StatefulWidget {
  const ExamenesTab({super.key});

  @override
  State<ExamenesTab> createState() => _ExamenesTabState();
}

class _ExamenesTabState extends State<ExamenesTab> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final maestroId = auth.maestro?.id ?? '';
    
    final active = data.examenes.where((e) => !data.hiddenIds.contains('e_${e.claveExamen}')).toList();
    final hidden = data.examenes.where((e) => data.hiddenIds.contains('e_${e.claveExamen}')).toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Exámenes',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, fontFamily: 'serif')),
                  const SizedBox(height: 4),
                  Text('Selecciona el examen a calificar',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: data.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : data.examenes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 52, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No tienes exámenes programados',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              ...active.map((e) => _ExamenCard(examen: e, maestroId: maestroId, maestroClave: auth.maestro?.clave ?? '')),
                              if (hidden.isNotEmpty)
                                Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: const Text('Oculto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    children: hidden.map((e) => _ExamenCard(examen: e, maestroId: maestroId, maestroClave: auth.maestro?.clave ?? '')).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _ingresarConClave(context, maestroId, auth.maestro?.clave ?? ''),
            backgroundColor: Colors.deepOrange,
            icon: const Icon(Icons.key, color: Colors.white),
            label: const Text('Clave examen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _ingresarConClave(BuildContext ctx, String maestroId, String maestroClave) async {
    final controller = TextEditingController();
    final clave = await showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('🔑 Ingresar a un Examen'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Clave de acceso', border: OutlineInputBorder(), hintText: 'Ej. XYZ123'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim().toUpperCase()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Verificar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (clave == null || clave.isEmpty || !ctx.mounted) return;

    // Verificar si la clave existe en Supabase y obtener el examen
    final nav = Navigator.of(ctx);
    final data = ctx.read<DataProvider>();
    
    // Asumimos que podemos obtener el examen por clave_acceso
    final examen = await data.getExamenPorClaveAcceso(clave);
    
    if (!ctx.mounted) return;
    if (examen == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('❌ Clave incorrecta o examen no encontrado'), backgroundColor: Colors.red));
      return;
    }
    
    nav.pushNamed('/exam-session', arguments: {
      'examen': examen,
      'maestroId': maestroId,
      'maestroClave': maestroClave,
    });
  }
}

class _ExamenCard extends StatefulWidget {
  final ExamenProgramado examen;
  final String maestroId;
  final String maestroClave;

  const _ExamenCard({required this.examen, required this.maestroId, required this.maestroClave});

  @override
  State<_ExamenCard> createState() => _ExamenCardState();
}

class _ExamenCardState extends State<_ExamenCard> {
  bool _esMaestroBase = false;
  @override
  void initState() {
    super.initState();
    _esMaestroBase = widget.examen.maestroBaseId == widget.maestroId;
  }

  Future<void> _entrarComoBase(BuildContext ctx) async {
    final clave = widget.examen.claveAcceso;
    if (clave == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('No se encontró la clave de acceso'), backgroundColor: Colors.red));
      return;
    }
    final timeController = TextEditingController(text: '120');
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('🚀 Iniciar Examen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔑 Tu Clave de Acceso', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
              child: Text(clave, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 20),
            const Text('⏱️ Duración del Examen', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Compártela clave únicamente si no puedes aplicar el examen.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Entrar al Examen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      final mins = int.tryParse(timeController.text) ?? 120;
      _navigateToExamen(ctx, mins);
    }
  }

  void _navigateToExamen(BuildContext ctx, int duracion) {
    Navigator.pushNamed(ctx, '/exam-session', arguments: {
      'examen': widget.examen,
      'maestroId': widget.maestroId,
      'maestroClave': widget.maestroClave,
      'duracionMinutos': duracion,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.examen;
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Visibilidad'),
            content: const Text('¿Deseas ocultar/mostrar este examen?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR')),
              TextButton(
                onPressed: () {
                   context.read<DataProvider>().toggleHidden('e_${widget.examen.claveExamen}');
                   Navigator.pop(c);
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
        children: [
          // Card body — tap to enter (base) or tap orange for examinador
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: _esMaestroBase ? () => _entrarComoBase(context) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Activo', style: TextStyle(fontSize: 11)),
                      ),
                      Row(
                        children: [
                          Text(ex.claveExamen,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'toggle') {
                                context.read<DataProvider>().toggleHidden('e_${ex.claveExamen}');
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(context.read<DataProvider>().hiddenIds.contains('e_${ex.claveExamen}') ? 'Mostrar Examen' : 'Ocultar Examen'),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ex.curso != null)
                    Text(ex.curso!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'serif')),
                  if (ex.grupoNombre != null)
                    Text('Grupo: ${ex.grupoNombre}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (ex.fecha != null)
                    Text(ex.fecha!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  if (_esMaestroBase)
                    Row(children: [
                      Icon(Icons.touch_app, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text('Click para entrar a calificar examen',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                    ])
                  else
                    Text('Supervisar con clave del maestro base',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// ============================================================
// Custom bottom tab bar
// ============================================================
class _BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(child: _TabButton(label: 'Mis Grupos', selected: currentIndex == 0, onTap: () => onTap(0))),
          Expanded(child: _TabButton(label: 'Examenes', selected: currentIndex == 1, onTap: () => onTap(1))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE040FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
