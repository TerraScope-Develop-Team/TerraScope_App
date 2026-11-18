import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/export_service.dart';
import '../models/avistamiento_model.dart';

class ExportDialog extends StatefulWidget {
  final List<Avistamiento> avistamientos;

  const ExportDialog({super.key, required this.avistamientos});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  String? _exportedFilePath;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _exportToExcel() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedFilePath = null;
      _successMessage = null;
    });

    try {
      final file = await _exportService.exportToExcel(widget.avistamientos);

      if (file != null) {
        setState(() {
          _exportedFilePath = file.path;
          _isExporting = false;
          _successMessage = 'Archivo Excel generado y abierto exitosamente';
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo crear el archivo Excel';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isExporting = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedFilePath = null;
      _successMessage = null;
    });

    try {
      final csvContent = _exportService.generateCSV(widget.avistamientos);
      final file = await _exportService.saveCSV(csvContent);

      if (file != null) {
        setState(() {
          _exportedFilePath = file.path;
          _isExporting = false;
          _successMessage = 'Archivo CSV generado y abierto exitosamente';
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo crear el archivo CSV';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isExporting = false;
      });
    }
  }

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedFilePath = null;
      _successMessage = null;
    });

    try {
      final file = await _exportService.exportToPDF(widget.avistamientos);

      if (file != null) {
        setState(() {
          _exportedFilePath = file.path;
          _isExporting = false;
          _successMessage = 'Archivo PDF generado y abierto exitosamente';
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo crear el archivo PDF';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.file_download,
                  color: Color(0xFF5C6445),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Exportar Datos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Se exportarán ${widget.avistamientos.length} registros',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            if (_isExporting)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF5C6445)),
                    SizedBox(height: 16),
                    Text(
                      'Generando y abriendo archivo...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Exportación exitosa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _successMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Archivo guardado en:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _exportedFilePath!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _buildPreview(),
                  _buildExportButton(
                    icon: Icons.table_chart,
                    label: 'Exportar a Excel',
                    description: 'Formato .xlsx (se abrirá automáticamente)',
                    onPressed: _exportToExcel,
                  ),
                  const SizedBox(height: 12),
                  _buildExportButton(
                    icon: Icons.description,
                    label: 'Exportar a CSV',
                    description: 'Formato .csv (se abrirá automáticamente)',
                    onPressed: _exportToCSV,
                  ),
                  const SizedBox(height: 12),
                  _buildExportButton(
                    icon: Icons.picture_as_pdf,
                    label: 'Exportar a PDF',
                    description: 'Formato .pdf (se abrirá automáticamente)',
                    onPressed: _exportToPDF,
                  ),
                ],
              ),

            const SizedBox(height: 24),
            if (_successMessage != null || _errorMessage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6445),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.avistamientos.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstAvistamiento = widget.avistamientos.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Color(0xFF5C6445), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Vista Previa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Primer registro de ${widget.avistamientos.length} totales:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${firstAvistamiento.nombreComun} (${firstAvistamiento.nombreCientifico})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${firstAvistamiento.tipo} | Especie: ${firstAvistamiento.especie}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Usuario: ${firstAvistamiento.nombreUsuario}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Comentarios: ${firstAvistamiento.comentarios?.length ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF5C6445)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5C6445), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF5C6445),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
