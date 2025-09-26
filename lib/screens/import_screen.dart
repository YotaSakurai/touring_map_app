import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/route_provider.dart';
import '../services/file_service.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedFilePath;
  String? _selectedFileName;
  String _visibility = 'private';
  final List<String> _selectedTags = [];
  
  bool _isImporting = false;
  bool _addElevation = true;
  double _simplifyTolerance = 5.0;
  String? _importJobId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ファイルインポート'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ファイル選択エリア
            _buildFileSelectionCard(),
            const SizedBox(height: 24),
            
            // インポート設定
            if (_selectedFilePath != null) ...[
              _buildImportSettingsCard(),
              const SizedBox(height: 24),
            ],
            
            // ルート情報入力
            if (_selectedFilePath != null) ...[
              _buildRouteInfoCard(),
              const SizedBox(height: 24),
            ],
            
            // インポートボタン
            if (_selectedFilePath != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _startImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isImporting ? 'インポート中...' : 'インポート開始'),
                ),
              ),
            ],
            
            // インポート結果表示
            if (_importJobId != null) ...[
              const SizedBox(height: 24),
              _buildImportResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ファイル選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_selectedFilePath == null) ...[
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: _selectFile,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GPX/KMLファイルを選択',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '対応形式: .gpx, .kml',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFileName!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearFile,
                          icon: const Icon(Icons.close),
                          tooltip: 'ファイルをクリア',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ファイルが選択されました',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '対応ファイル形式:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildFormatChip('GPX', 'GPS Exchange Format'),
                const SizedBox(width: 8),
                _buildFormatChip('KML', 'Google Earth'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format, String description) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              format,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'インポート設定',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // 標高データ追加
            SwitchListTile(
              title: const Text('標高データを追加'),
              subtitle: const Text('GPSデータに標高情報がない場合に追加'),
              value: _addElevation,
              onChanged: (value) {
                setState(() {
                  _addElevation = value;
                });
              },
            ),
            
            // 簡略化設定
            ListTile(
              title: const Text('ルート簡略化'),
              subtitle: Text('許容誤差: ${_simplifyTolerance.toStringAsFixed(1)}m'),
              trailing: Text('${_simplifyTolerance.toStringAsFixed(1)}m'),
            ),
            Slider(
              value: _simplifyTolerance,
              min: 0.0,
              max: 50.0,
              divisions: 50,
              label: '${_simplifyTolerance.toStringAsFixed(1)}m',
              onChanged: (value) {
                setState(() {
                  _simplifyTolerance = value;
                });
              },
            ),
            Text(
              'ルートのポイント数を減らしてファイルサイズを小さくします',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ルート情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // ルート名
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ルート名 *',
                border: OutlineInputBorder(),
                hintText: 'ファイル名から自動設定されます',
              ),
            ),
            const SizedBox(height: 16),
            
            // 説明
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                border: OutlineInputBorder(),
                hintText: 'ルートの説明を入力してください',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 可視性選択
            Text(
              '公開設定',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _visibility,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'private',
                  child: Text('非公開'),
                ),
                DropdownMenuItem(
                  value: 'unlisted',
                  child: Text('限定公開'),
                ),
                DropdownMenuItem(
                  value: 'public',
                  child: Text('公開'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _visibility = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // タグ選択
            Text(
              'タグ',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'night',
                'onsen',
                'parking2w',
                'rider_welcome',
                'scenic',
                'food',
              ].map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(_getTagDisplayName(tag)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportResultCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'インポート開始',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ジョブID: $_importJobId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'ファイルの解析とルート作成が完了すると通知されます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx', 'kml'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
          
          // ファイル名からルート名を自動設定
          if (_titleController.text.isEmpty) {
            final nameWithoutExtension = file.name.split('.').first;
            _titleController.text = nameWithoutExtension;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ファイル選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _titleController.clear();
      _descriptionController.clear();
      _selectedTags.clear();
      _importJobId = null;
    });
  }

  Future<void> _startImport() async {
    if (_selectedFilePath == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ファイルとルート名を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importJobId = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final jobId = await apiService.importFile(
        _selectedFilePath!,
        simplifyToleranceM: _simplifyTolerance,
        addElevation: _addElevation,
      );

      setState(() {
        _importJobId = jobId;
        _isImporting = false;
      });

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('インポートを開始しました（ジョブID: $jobId）'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('インポートエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTagDisplayName(String tag) {
    switch (tag) {
      case 'night':
        return '夜間営業';
      case 'onsen':
        return '温泉';
      case 'parking2w':
        return '二輪駐車場';
      case 'rider_welcome':
        return 'ライダー歓迎';
      case 'scenic':
        return '景色';
      case 'food':
        return 'グルメ';
      default:
        return tag;
    }
  }
}
