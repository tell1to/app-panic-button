import 'package:flutter/material.dart';
import 'dart:io';
import '../services/offline_sync_service.dart';

/// Widget de testing para sincronización offline
/// Permite simular conectividad y ver estado de alertas
class SyncTestingWidget extends StatefulWidget {
  const SyncTestingWidget({super.key});

  @override
  State<SyncTestingWidget> createState() => _SyncTestingWidgetState();
}

class _SyncTestingWidgetState extends State<SyncTestingWidget> {
  bool _isSimulatingOffline = false;
  bool _isOnline = true;
  Map<String, dynamic> _syncStats = {};
  List<Map<String, dynamic>> _alertFiles = [];
  
  late OfflineSyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = OfflineSyncService.instance;
    _loadStats();
    _loadAlertFiles();
    
    // Registrar listener para cambios de conectividad
    _syncService.addOnlineStatusListener((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _loadStats();
        });
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _syncService.getSyncStats();
      if (mounted) {
        setState(() {
          _syncStats = stats;
        });
      }
    } catch (e) {
      print('[SyncTestingWidget] Error cargando stats: $e');
    }
  }

  Future<void> _loadAlertFiles() async {
    try {
      final unsyncedAlerts = await _syncService.getUnsyncedAlerts();
      
      if (mounted) {
        setState(() {
          _alertFiles = unsyncedAlerts
              .map((a) => a.toJson(encryptSensitiveData: true))
              .toList();
        });
      }
    } catch (e) {
      print('[SyncTestingWidget] Error cargando alertas: $e');
    }
  }

  Future<void> _forceSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronización iniciada...')),
    );
    
    await _syncService.forceSyncNow();
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      _loadStats();
      _loadAlertFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronización completada')),
      );
    }
  }

  Future<void> _simulateOffline() async {
    // Nota: Esta es una simulación local - en un app real necesitarías
    // usar Mock de connectivity_plus o desactivar WiFi/mobile del device
    setState(() {
      _isSimulatingOffline = !_isSimulatingOffline;
      if (_isSimulatingOffline) {
        _isOnline = false;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSimulatingOffline 
              ? '📡 Modo OFFLINE activado (simulación)'
              : '📡 Modo ONLINE activado'
        ),
      ),
    );
  }

  Future<void> _deleteAllAlerts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Eliminar todas las alertas'),
        content: const Text('¿Eliminar todos los archivos de alertas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Documents/alerts');
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          await dir.create(recursive: true);
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final projDir = Directory(
          '${Directory.current.path}${Platform.pathSeparator}Documentos${Platform.pathSeparator}alerts'
        );
        if (await projDir.exists()) {
          await projDir.delete(recursive: true);
          await projDir.create(recursive: true);
        }
      }

      _loadStats();
      _loadAlertFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Alertas eliminadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Testing: Sincronización Offline'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de Conectividad
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Controles
              _buildControlsSection(),
              const SizedBox(height: 16),

              // Estadísticas
              _buildStatsSection(),
              const SizedBox(height: 16),

              // Lista de alertas
              _buildAlertsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isOnline = _syncStats['isOnline'] ?? false;
    
    return Card(
      color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOnline ? '✅ ONLINE' : '❌ OFFLINE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
                if (_isSimulatingOffline)
                  const Chip(
                    label: Text('(Simulado)'),
                    backgroundColor: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOnline
                  ? 'Las alertas se sincronizarán automáticamente'
                  : 'Las alertas se guardarán localmente',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎮 Controles de Testing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _simulateOffline,
                    icon: Icon(_isSimulatingOffline ? Icons.cloud_off : Icons.cloud),
                    label: Text(_isSimulatingOffline ? 'OFFLINE' : 'ONLINE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSimulatingOffline ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _forceSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteAllAlerts,
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar Todas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _loadStats();
                  _loadAlertFiles();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pasos para probar:\n'
                '1. Apagar WiFi del dispositivo\n'
                '2. Ir a la app y activar alerta roja\n'
                '3. La alerta se guardará en Documents/alerts\n'
                '4. Volver aquí y pulsar "Sincronizar"\n'
                '5. Activar WiFi\n'
                '6. Las alertas se sincronizarán a Firebase',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estadísticas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total alertas', '${_syncStats['total'] ?? 0}'),
            _buildStatRow('Sincronizadas', '${_syncStats['synced'] ?? 0}', Colors.green),
            _buildStatRow('Pendientes', '${_syncStats['unsynced'] ?? 0}', Colors.orange),
            const Divider(),
            _buildStatRow('Estado', _isOnline ? 'ONLINE' : 'OFFLINE',
                _isOnline ? Colors.green : Colors.red),
            if (_syncStats['lastUpdate'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Última actualización: ${_syncStats['lastUpdate']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Archivos de Alertas Locales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_alertFiles.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Center(
                  child: Text(
                    'No hay alertas pendientes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alertFiles.length,
                itemBuilder: (ctx, idx) {
                  final alert = _alertFiles[idx];
                  return ExpansionTile(
                    title: Text(
                      'ID: ${alert['id'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${alert['date']} - ${alert['time']}\n'
                      'Estado: ${alert['synced'] ? '✓ Sincronizada' : '⏳ Pendiente'}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _alertDetailRow('Descripción', alert['description']),
                            _alertDetailRow('Usuario', alert['userId']),
                            _alertDetailRow('Estado', alert['status']),
                            _alertDetailRow('Timestamp', alert['timestamp'].toString()),
                            if (alert['latitude'] != null)
                              _alertDetailRow('Latitud', alert['latitude'].toString()),
                            if (alert['longitude'] != null)
                              _alertDetailRow('Longitud', alert['longitude'].toString()),
                            const Divider(),
                            const Text(
                              'Datos Encriptados:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            _alertDetailRow(
                              'Lat Enc',
                              (alert['latitude_encrypted'] as String).substring(
                                0,
                                (alert['latitude_encrypted'] as String).length > 20
                                    ? 20
                                    : (alert['latitude_encrypted'] as String).length,
                              ) + '...',
                            ),
                            _alertDetailRow(
                              'Lon Enc',
                              (alert['longitude_encrypted'] as String).substring(
                                0,
                                (alert['longitude_encrypted'] as String).length > 20
                                    ? 20
                                    : (alert['longitude_encrypted'] as String).length,
                              ) + '...',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _alertDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Flexible(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
