import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_button.dart';
import '../providers/project_provider.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId; // Jika null berarti tambah, jika ada berarti edit

  const ProjectFormScreen({super.key, this.projectId});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetAmountController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  bool _isPublic = false;

  // Cover Image State
  Uint8List? _coverBytes;
  String? _coverName;
  String? _coverImageUrl;
  bool _deleteCover = false;

  // Gallery Image State
  List<String> _existingGalleryUrls = [];
  final List<Uint8List> _newGalleryBytes = [];
  final List<String> _newGalleryNames = [];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _targetAmountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadProjectData();
      _initialized = true;
    }
  }

  void _loadProjectData() {
    if (widget.projectId != null) {
      final projectState = ref.read(projectProvider);
      final project = projectState.projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => throw Exception('Proyek tidak ditemukan'),
      );

      _nameController.text = project.name;
      _descController.text = project.description ?? '';
      _targetAmountController.text = project.targetAmount != null && project.targetAmount! > 0
          ? Formatter.formatRupiah(project.targetAmount!)
              .replaceAll('Rp', '')
              .replaceAll(',00', '')
              .trim()
          : '';
      _startDate = project.startDate;
      _endDate = project.endDate;
      _status = project.status;
      _isPublic = project.isPublic;
      _coverImageUrl = project.coverImageUrl;
      _existingGalleryUrls = project.galleryUrls != null ? List<String>.from(project.galleryUrls!) : [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) return;
        setState(() {
          _coverBytes = file.bytes;
          _coverName = file.name;
          _deleteCover = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover: $e');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.bytes != null) {
              _newGalleryBytes.add(file.bytes!);
              _newGalleryNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking gallery images: $e');
    }
  }

  Future<void> _pickDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    // Validasi cover image jika proyek diset publik
    final hasCover = _coverBytes != null || (_coverImageUrl != null && !_deleteCover);
    if (_isPublic && !hasCover) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar cover utama wajib diunggah jika proyek diset publik (crowdfunding)'),
          backgroundColor: AppTheme.colorError,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final status = _status;

      final double? targetAmount = _targetAmountController.text.trim().isEmpty
          ? null
          : double.parse(_targetAmountController.text.replaceAll('.', ''));

      bool success;
      if (widget.projectId == null) {
        // Mode Tambah
        success = await ref.read(projectProvider.notifier).addProject(
              name: name,
              description: desc.isEmpty ? null : desc,
              startDate: _startDate,
              endDate: _endDate,
              status: status,
              isPublic: _isPublic,
              targetAmount: targetAmount,
              coverBytes: _coverBytes,
              coverName: _coverName,
              galleryBytesList: _newGalleryBytes,
              galleryNamesList: _newGalleryNames,
            );
      } else {
        // Mode Edit
        success = await ref.read(projectProvider.notifier).updateProject(
              id: widget.projectId!,
              name: name,
              description: desc.isEmpty ? null : desc,
              startDate: _startDate,
              endDate: _endDate,
              status: status,
              isPublic: _isPublic,
              targetAmount: targetAmount,
              setTargetAmountToNull: targetAmount == null,
              coverBytes: _coverBytes,
              coverName: _coverName,
              existingCoverUrl: _coverImageUrl,
              deleteCoverImage: _deleteCover,
              galleryBytesList: _newGalleryBytes,
              galleryNamesList: _newGalleryNames,
              existingGalleryUrls: _existingGalleryUrls,
            );
      }

      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.projectId == null
                ? 'Proyek berhasil ditambahkan'
                : 'Proyek berhasil diperbarui'),
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);
    final hasCover = _coverBytes != null || (_coverImageUrl != null && !_deleteCover);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projectId == null ? 'Tambah Proyek Baru' : 'Ubah Proyek',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: AppButton(
                  text: widget.projectId == null ? 'Tambah' : 'Simpan',
                  height: 36,
                  onPressed: _handleSubmit,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== SECTION 1: INFORMASI DASAR ====================
                    _buildSectionHeader('Informasi Dasar'),
                    _buildSectionContainer(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Proyek',
                            hintText: 'Renovasi Panti Asuhan',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama proyek tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Proyek',
                            hintText: 'Renovasi gedung utama yayasan...',
                          ),
                          maxLines: 5,
                        ),
                      ],
                    ),

                    // ==================== SECTION 2: MEDIA PROYEK ====================
                    _buildSectionHeader('Media Proyek'),
                    _buildSectionContainer(
                      children: [
                        // Cover/Banner Upload Box
                        Text(
                          'Cover / Banner Utama',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F6F2),
                              borderRadius: AppRadius.radiusSm,
                              border: Border.all(
                                color: AppColors.divider,
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasCover
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: _coverBytes != null
                                            ? Image.memory(_coverBytes!, fit: BoxFit.cover)
                                            : Image.network(_coverImageUrl!, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black54,
                                            radius: 18,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  _coverBytes = null;
                                                  _coverName = null;
                                                  _deleteCover = true;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : InkWell(
                                    onTap: _pickCoverImage,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppTheme.primaryColor),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pilih Gambar Cover Proyek',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rasio disarankan 16:9 (cth: 1280x720 px)',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                        if (_isPublic) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '* Wajib untuk proyek publik',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppTheme.colorError,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Gallery Photos Upload Box
                        Text(
                          'Galeri Foto Tambahan (Opsional)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: _existingGalleryUrls.length + _newGalleryBytes.length + 1,
                          itemBuilder: (context, index) {
                            // 1. Plus Button at the end
                            if (index == _existingGalleryUrls.length + _newGalleryBytes.length) {
                              return InkWell(
                                onTap: _pickGalleryImages,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F6F2),
                                    borderRadius: AppRadius.radiusSm,
                                    border: Border.all(
                                      color: AppColors.divider,
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryColor),
                                  ),
                                ),
                              );
                            }

                            // 2. Existing Gallery Photo
                            if (index < _existingGalleryUrls.length) {
                              final url = _existingGalleryUrls[index];
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: AppRadius.radiusSm,
                                      child: Image.network(url, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 12,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, color: Colors.white, size: 12),
                                        onPressed: () {
                                          setState(() {
                                            _existingGalleryUrls.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            // 3. New picked gallery photo
                            final newIndex = index - _existingGalleryUrls.length;
                            final bytes = _newGalleryBytes[newIndex];
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: AppRadius.radiusSm,
                                    child: Image.memory(bytes, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 12,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, color: Colors.white, size: 12),
                                      onPressed: () {
                                        setState(() {
                                          _newGalleryBytes.removeAt(newIndex);
                                          _newGalleryNames.removeAt(newIndex);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    // ==================== SECTION 3: JADWAL & STATUS ====================
                    _buildSectionHeader('Jadwal & Status'),
                    _buildSectionContainer(
                      children: [
                        Row(
                          children: [
                            // Tanggal Mulai
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
                                ),
                                onPressed: () => _pickDate(true),
                                child: Column(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _startDate == null ? 'Mulai (Pilih)' : Formatter.formatTanggalPendek(_startDate!),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tanggal Selesai
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
                                ),
                                onPressed: () => _pickDate(false),
                                child: Column(
                                  children: [
                                    const Icon(Icons.event, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _endDate == null ? 'Selesai (Pilih)' : Formatter.formatTanggalPendek(_endDate!),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status Proyek',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'planned', child: Text('Direncanakan (Planned)')),
                            DropdownMenuItem(value: 'active', child: Text('Berjalan (Active)')),
                            DropdownMenuItem(value: 'completed', child: Text('Selesai (Completed)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    // ==================== SECTION 4: PUBLIKASI ====================
                    _buildSectionHeader('Publikasi'),
                    _buildSectionContainer(
                      children: [
                        SwitchListTile(
                          value: _isPublic,
                          title: const Text('Jadikan Proyek Publik'),
                          subtitle: const Text('Donatur publik dapat melihat proyek ini tanpa login'),
                          activeThumbColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _isPublic = val;
                            });
                          },
                        ),
                        if (_isPublic) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target Dana Crowdfunding (Rp) (Opsional)',
                              hintText: 'Kosongkan jika donasi terbuka tanpa target',
                              prefixText: 'Rp ',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _RupiahInputFormatter(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int numValue = int.parse(newValue.text.replaceAll('.', ''));
    final String formatted = Formatter.formatRupiah(numValue.toDouble())
        .replaceAll('Rp', '')
        .replaceAll(',00', '')
        .trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
