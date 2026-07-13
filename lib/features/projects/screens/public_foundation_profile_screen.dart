import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/formatter.dart';

class PublicFoundationProfileScreen extends StatefulWidget {
  final String foundationId;

  const PublicFoundationProfileScreen({super.key, required this.foundationId});

  @override
  State<PublicFoundationProfileScreen> createState() => _PublicFoundationProfileScreenState();
}

class _PublicFoundationProfileScreenState extends State<PublicFoundationProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _foundation;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadFoundationProfile();
  }

  Future<void> _loadFoundationProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch foundation details
      final fRes = await _supabase
          .from('foundations')
          .select('name, description, logo_url, banner_url')
          .eq('id', widget.foundationId)
          .single();

      // 2. Fetch all public projects of this foundation
      final pRes = await _supabase
          .from('projects')
          .select('*, foundations(name)')
          .eq('foundation_id', widget.foundationId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      final projectList = List<Map<String, dynamic>>.from(pRes as List);

      // 3. For each project, fetch its raised amount
      for (var proj in projectList) {
        final txs = await _supabase
            .from('transactions')
            .select('amount')
            .eq('project_id', proj['id'])
            .eq('status', 'approved')
            .eq('type', 'income');

        double raised = 0;
        for (var tx in txs as List) {
          raised += (tx['amount'] as num).toDouble();
        }
        proj['raised'] = raised;
      }

      setState(() {
        _foundation = fRes;
        _projects = projectList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat profil yayasan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Text(
          _foundation?['name'] ?? 'Profil Yayasan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F5A47)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal Memuat Profil',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A47)),
                          onPressed: _loadFoundationProfile,
                          child: Text('Coba Lagi', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Section
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: isDesktop ? 260 : 160,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F5A47), Color(0xFF1D7860)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: _foundation?['banner_url'] != null
                                ? Image.network(
                                    _foundation!['banner_url'],
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          // Logo Circular Avatar Overlay
                          Positioned(
                            bottom: -50,
                            left: isDesktop ? 48 : 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF0F5A47),
                                backgroundImage: _foundation?['logo_url'] != null
                                    ? NetworkImage(_foundation!['logo_url'])
                                    : null,
                                child: _foundation?['logo_url'] == null
                                    ? Text(
                                        (_foundation?['name'] as String).substring(0, 1).toUpperCase(),
                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 64),

                      // Foundation Description & Info
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundation?['name'] ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_foundation?['description'] != null && (_foundation?['description'] as String).isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEBEBEB)),
                                ),
                                child: Text(
                                  _foundation!['description'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: const Color(0xFF4A5552),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'Belum ada deskripsi profil untuk yayasan ini.',
                                style: GoogleFonts.outfit(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),

                            const SizedBox(height: 40),
                            Text(
                              'Kampanye Crowdfunding Publik',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Daftar proyek aktif yang dapat Anda bantu donasikan',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),

                            // Projects List
                            _projects.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tidak ada proyek publik aktif saat ini.',
                                            style: GoogleFonts.outfit(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 3 : 1,
                                      crossAxisSpacing: 24,
                                      mainAxisSpacing: 24,
                                      childAspectRatio: isDesktop ? 0.95 : 1.3,
                                    ),
                                    itemCount: _projects.length,
                                    itemBuilder: (context, index) {
                                      final proj = _projects[index];
                                      return _buildProjectCard(proj);
                                    },
                                  ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> proj) {
    final double target = (proj['target_amount'] as num?)?.toDouble() ?? 0.0;
    final double raised = (proj['raised'] as num?)?.toDouble() ?? 0.0;
    final double progress = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).round();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/public/project?id=${proj['id']}',
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE6F0EC), Color(0xFFD4E8E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.volunteer_activism, color: Color(0xFF0F5A47), size: 28),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proj['name'] ?? '',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A2A25)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proj['description'] ?? 'Tidak ada deskripsi',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terkumpul',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7F79)),
                        ),
                        Text(
                          '$percent%',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F5A47)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE6F0EC),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F5A47)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatter.formatRupiah(raised),
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F5A47)),
                        ),
                        Text(
                          'Target: ${Formatter.formatRupiah(target)}',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
