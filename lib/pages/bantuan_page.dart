import 'package:flutter/material.dart';
import '../main.dart';

// ============================================
// BANTUAN PAGE
// ============================================
class BantuanPage extends StatelessWidget {
  BantuanPage({super.key});

  final List<Map<String, String>> _faqList = [
    {
      'question': 'Apa itu Aplikasi Penjemputan?',
      'answer':
          'Aplikasi Penjemputan adalah aplikasi yang membantu orang tua/wali murid untuk memanggil Ananda saat waktu penjemputan.',
    },
    {
      'question': 'Bagaimana saya mau memanggil Ananda?',
      'answer':
          'Untuk memanggil Ananda, buka tab "Jemput" di aplikasi dan tekan tombol "JEMPUT" yang berwarna biru. Setelah itu, tunggu nama Ananda dipanggil melalui pengeras suara sekolah.',
    },
    {
      'question': 'Bagaimana jika Ananda belum datang saat saya sudah panggil?',
      'answer':
          'Jika Ananda belum datang setelah dipanggil, silakan tunggu beberapa menit karena Ananda mungkin sedang dalam perjalanan dari kelas. Jika setelah 10 menit Ananda belum datang, Anda dapat memanggil Ananda kembali atau menghubungi guru piket atau wali kelas untuk membantu mencari Ananda.',
    },
    {
      'question': 'Bagaimana cara saya mengedit profil Ananda?',
      'answer':
          'Untuk mengedit profil Ananda, buka menu Profil di tab "Profil" di halaman utama, lalu pilih "Data Siswa". Di halaman tersebut Anda dapat mengubah informasi seperti foto, nama pengejaan, dan data lainnya. Jangan lupa untuk menyimpan perubahan setelah selesai mengedit.',
    },
    {
      'question': 'Bagaimana cara saya menghapus riwayat penjemputan Ananda?',
      'answer':
          'Riwayat penjemputan tidak dapat dihapus oleh orang tua/wali murid karena merupakan data penting yang digunakan sekolah untuk dokumentasi. Jika Anda memiliki pertanyaan maupun keluhan terkait riwayat penjemputan, silakan hubungi pihak sekolah.',
    },
    {
      'question':
          'Saya sudah klik panggil di aplikasi, kenapa tidak dapat muncul panggilan?',
      'answer':
          'Beberapa kemungkinan penyebab:\n\n1. Koneksi internet Anda tidak stabil\n2. Server sekolah sedang mengalami gangguan\n3. Antrian panggilan sedang penuh sehingga Anda harus menunggu giliran\n\nJika masalah berlanjut, silahkan untuk menghubungi Guru Piket agar dipanggilkan secara manual.',
    },
    {
      'question': 'Apa itu nama pengejaan?',
      'answer':
          'Untuk menghindari kesalahan pengucapan nama Ananda, silahkan untuk mengatur nama pengejaan agar nama Ananda diucapkan dengan benar saat dipanggil melalui pengeras suara sekolah.',
    },
    {
      'question': 'Apakah jadwal kepulangan di Aplikasi Penjemputan Akurat?',
      'answer':
          'Ya, jadwal kepulangan di aplikasi selalu diperbarui sesuai dengan jadwal resmi sekolah. Namun, terkadang ada perubahan jadwal karena kegiatan tertentu. Aktifkan notifikasi perubahan jadwal agar Anda selalu mendapat informasi terbaru.',
    },
    {
      'question':
          'Bagaimana jika jadwal pulang tidak sesuai dengan surat pemberitahuan sekolah?',
      'answer':
          'Tetap prioritaskan surat pemberitahuan sekolah sebagai informasi kepulangan Ananda, kami akan terus memperbarui jadwal di aplikasi Penjemputan jika terjadi kesalahan.',
    },
    {
      'question':
          'Jika terjadi error pada aplikasi Penjemputan saya, apa yang harus saya lakukan?',
      'answer':
          'Jika terjadi error:\n\n1. Tutup aplikasi dan buka kembali\n2. Pastikan aplikasi sudah versi terbaru\n3. Periksa koneksi internet Anda\n4. Coba restart perangkat Anda\n\nJika error masih terjadi, silahkan untuk menghubungi Guru Piket agar dipanggilkan secara manual.',
    },
    {
      'question': 'Apakah data Ananda aman?',
      'answer':
          'Ya, data Ananda aman. Data Ananda hanya dapat diakses oleh pihak sekolah dan guru Piket. Tidak ada pihak kedua yang terlibat pada penggunaan data Anda',
    },
    {
      'question':
          'Apa saja data yang di ambil oleh pihak sekolah pada aplikasi penjemputan?',
      'answer':
          'Jangan khawatir, kami hanya mengambil data pribadi Ananda seperti nama, kelas, waktu penjemputan, untuk dokumentasi sekolah. Dan tracking penggunaan Anda pada aplikasi Penjemputan guna memastikan aplikasi Penjemputan lebih baik kedepannya (Hanya aplikasi Penjemputan), kami selalu bertekad menjaga data Ananda aman. ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Pusat Bantuan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Header Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShadcnCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pertanyaan Umum',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ketuk pertanyaan untuk melihat jawaban',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FAQ List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  return _buildFaqItem(
                    context,
                    index: index + 1,
                    question: _faqList[index]['question']!,
                    answer: _faqList[index]['answer']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required int index,
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showAnswerBottomSheet(context, question, answer),
        child: ShadcnCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswerBottomSheet(
    BuildContext context,
    String question,
    String answer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLighter,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pertanyaan',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                question,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Container(height: 1, color: AppColors.border),

                    const SizedBox(height: 20),

                    // Answer Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jawaban',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                answer,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Mengerti',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
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
