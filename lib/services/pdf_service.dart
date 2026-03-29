import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_model.dart';
import '../models/payment_model.dart';
import '../models/group_model.dart';
import '../services/center_service.dart';
import '../services/student_service.dart';
import '../models/student_status.dart';
import '../l10n/app_localizations.dart';

// ─── Couleurs PDF ────────────────────────────────────────────────────────────
class _PdfColors2 {
  static const primary = PdfColor.fromInt(0xFF6C63FF);
  static const primaryLight = PdfColor.fromInt(0xFFE8E7FF);
  static const primaryDark = PdfColor.fromInt(0xFF4A4A8A);
  static const success = PdfColor.fromInt(0xFF22C55E);
  static const warning = PdfColor.fromInt(0xFFF59E0B);
  static const danger = PdfColor.fromInt(0xFFEF4444);
  static const orange = PdfColor.fromInt(0xFFFF9800);
  static const border = PdfColors.grey300;
  static const rowAlt = PdfColor.fromInt(0xFFF8F8FF);
}

// ─── Service PDF Principal ────────────────────────────────────────────────────
class PdfService {
  static final _configService = CenterConfigService();

  // ─── Helper: localisation ──────────────────────────────────────────────────
  static AppLocalizations _l10n() {
    final langService = LanguageService();
    return AppLocalizations(langService.language);
  }

  // ─── Helper: formater date ────────────────────────────────────────────────
  static String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String _fmtMonth(DateTime d, AppLocalizations l) =>
      '${l.monthName(d.month)} ${d.year}';

  // ─── Helper: formater montant ────────────────────────────────────────────
  static String _fmtAmount(double v, AppLocalizations l) =>
      '${NumberFormat('#,###').format(v.toInt())} ${l.currency}';

  // ─── Helper: couleur statut ───────────────────────────────────────────────
  static PdfColor _statusColor(StudentStatus s) {
    switch (s) {
      case StudentStatus.upToDate:
        return _PdfColors2.success;
      case StudentStatus.inProgress:
        return _PdfColors2.warning;
      case StudentStatus.dueSoon:
        return _PdfColors2.orange;
      case StudentStatus.overdue:
        return _PdfColors2.danger;
    }
  }

  static String _statusLabel(StudentStatus s, AppLocalizations l) {
    switch (s) {
      case StudentStatus.upToDate:
        return l.upToDate;
      case StudentStatus.inProgress:
        return l.overdue; // En cours
      case StudentStatus.dueSoon:
        return '\u00c0 payer';
      case StudentStatus.overdue:
        return l.critical; // En retard
    }
  }

  // ─── Helper: entête PDF ───────────────────────────────────────────────────
  static pw.Widget _header({
    required String title,
    required String subtitle,
    required String rightTop,
    required String rightBottom,
    pw.MemoryImage? logo,
    bool rtl = false,
  }) {
    final titleWidget = pw.Text(
      title,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      ),
    );
    final subtitleWidget = pw.Text(
      subtitle,
      style: const pw.TextStyle(
        color: PdfColor.fromInt(0xB3FFFFFF),
        fontSize: 11,
      ),
    );
    final rightTopWidget = pw.Text(
      rightTop,
      style: const pw.TextStyle(
        color: PdfColor.fromInt(0xB3FFFFFF),
        fontSize: 10,
      ),
    );
    final rightBottomWidget = pw.Text(
      rightBottom,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        color: _PdfColors2.primary,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 35,
                  height: 35,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(width: 10),
              ],
              if (rtl)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [titleWidget, subtitleWidget],
                )
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [titleWidget, subtitleWidget],
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [rightTopWidget, rightBottomWidget],
          ),
        ],
      ),
    );
  }

  // ─── Helper: ligne info ────────────────────────────────────────────────────
  static pw.Widget _infoRow(String label, String value, {bool rtl = false}) {
    final labelW = pw.SizedBox(
      width: 120,
      child: pw.Text(label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
    );
    final sep = pw.Text(' : ',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey400));
    final valueW = pw.Expanded(
      child: pw.Text(value,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black)),
    );
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rtl ? [valueW, sep, labelW] : [labelW, sep, valueW],
    );
  }

  // ─── Helper: section titre ─────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              letterSpacing: 1.2,
            ),
          ),
          pw.Divider(color: _PdfColors2.border),
          pw.SizedBox(height: 6),
        ],
      );

  // ─── Helper: pied de page ──────────────────────────────────────────────────
  static pw.Widget _footer(AppLocalizations l) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey200),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              l.receiptFooter,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
            ),
          ),
        ],
      );

  // ─── Helper: signature row ─────────────────────────────────────────────────
  static pw.Widget _signatureRow(String left, String right, {bool rtl = false}) {
    pw.Widget _sig(String label) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 30),
            pw.Container(width: 100, height: 1, color: PdfColors.grey400),
          ],
        );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: rtl ? [_sig(right), _sig(left)] : [_sig(left), _sig(right)],
    );
  }

  // ─── Helper: badge statut ─────────────────────────────────────────────────
  static pw.Widget _statusBadge(StudentStatus s, AppLocalizations l) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: _statusColor(s).shade(0.15),
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: _statusColor(s)),
        ),
        child: pw.Text(
          _statusLabel(s, l),
          style: pw.TextStyle(
            fontSize: 9,
            color: _statusColor(s),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. REÇU DE PAIEMENT ÉTUDIANT
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> printStudentPaymentReceipt({
    required BuildContext context,
    required Student student,
    required Payment payment,
    required Group group,
  }) async {
    final l = _l10n();
    final rtl = l.isAr;
    final centerName = _configService.centerName;
    final isCenterMode = _configService.isCenterMode;
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: rtl
                ? pw.CrossAxisAlignment.end
                : pw.CrossAxisAlignment.start,
            children: [
              _header(
                title: isCenterMode ? centerName : l.paymentReceipt,
                subtitle: isCenterMode ? l.paymentReceipt : '',
                rightTop: '${l.receiptNo} ${payment.id.substring(0, 8).toUpperCase()}',
                rightBottom: _fmtDate(payment.date),
                logo: logoImage,
                rtl: rtl,
              ),
              pw.SizedBox(height: 24),
              _sectionTitle(l.studentInfo.toUpperCase()),
              _infoRow(l.studentName, student.name, rtl: rtl),
              pw.SizedBox(height: 6),
              _infoRow(l.studentGroup, group.name, rtl: rtl),
              if (group.roomName != null && group.roomName!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _infoRow(l.room, group.roomName!, rtl: rtl),
              ],
              pw.SizedBox(height: 6),
              _infoRow(l.studentPhone,
                  student.phone.isNotEmpty ? student.phone : '—', rtl: rtl),
              pw.SizedBox(height: 20),
              _sectionTitle(l.paymentDetails.toUpperCase()),
              _infoRow(l.month, _fmtMonth(payment.date, l), rtl: rtl),
              pw.SizedBox(height: 6),
              _infoRow(l.paymentDate, _fmtDate(payment.date), rtl: rtl),
              pw.SizedBox(height: 6),
              _infoRow(l.sessionsCovered,
                  '${payment.sessionsCount} ${l.sessionsCount}', rtl: rtl),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _PdfColors2.primaryLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _PdfColors2.primary),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      l.amountPaid,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _PdfColors2.primaryDark,
                      ),
                    ),
                    pw.Text(
                      _fmtAmount(payment.amount, l),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _PdfColors2.primary,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.SizedBox(height: 16),
              _footer(l),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Recu_${student.name}_${DateFormat('MM_yyyy').format(payment.date)}',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. ÉTAT D'UN ÉLÈVE (présences + paiements)
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> printStudentReport({
    required BuildContext context,
    required Student student,
    required Group group,
  }) async {
    final l = _l10n();
    final rtl = l.isAr;
    final status = StudentService.computeStatus(student);
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }
    final pdf = pw.Document();

    final sortedAttendances = [...student.attendances]
      ..sort((a, b) => b.compareTo(a));
    final sortedPayments = [...student.payments]
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          _header(
            title: l.studentReport,
            subtitle: student.name,
            rightTop: group.name,
            rightBottom: _fmtDate(DateTime.now()),
            logo: logoImage,
            rtl: rtl,
          ),
          pw.SizedBox(height: 20),

          // Infos élève
          _sectionTitle(l.studentInfo.toUpperCase()),
          _infoRow(l.studentName, student.name, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.studentGroup, group.name, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.studentPhone,
              student.phone.isNotEmpty ? student.phone : '—', rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.pricePerCycle, _fmtAmount(student.pricePerCycle, l), rtl: rtl),
          pw.SizedBox(height: 16),

          // Statut actuel
          _sectionTitle(l.currentStatus.toUpperCase()),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _infoRow(l.sessionsSincePayment,
                  '${student.sessionsSincePayment}', rtl: rtl),
              _statusBadge(status, l),
            ],
          ),
          pw.SizedBox(height: 6),
          _infoRow(l.totalPaid, _fmtAmount(student.totalPaid, l), rtl: rtl),
          pw.SizedBox(height: 20),

          // Historique paiements
          _sectionTitle(l.paymentHistory.toUpperCase()),
          if (sortedPayments.isEmpty)
            pw.Text(l.noData,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _PdfColors2.border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                // En-tête
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _PdfColors2.primary),
                  children: [
                    _tableHeader(l.paymentDate),
                    _tableHeader(l.month),
                    _tableHeader(l.amountPaid),
                    _tableHeader(l.sessionsCount),
                  ],
                ),
                ...sortedPayments.asMap().entries.map((e) {
                  final p = e.value;
                  final alt = e.key.isOdd;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: alt ? _PdfColors2.rowAlt : PdfColors.white,
                    ),
                    children: [
                      _tableCell(_fmtDate(p.date)),
                      _tableCell(_fmtMonth(p.date, l)),
                      _tableCell(_fmtAmount(p.amount, l),
                          bold: true, color: _PdfColors2.primary),
                      _tableCell('${p.sessionsCount}'),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Historique présences
          _sectionTitle(l.presenceHistory.toUpperCase()),
          if (sortedAttendances.isEmpty)
            pw.Text(l.noData,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sortedAttendances.map((d) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _PdfColors2.primary),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: _PdfColors2.primaryLight,
                  ),
                  child: pw.Text(
                    _fmtDate(d),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                );
              }).toList(),
            ),
          pw.SizedBox(height: 24),
          _footer(l),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Etat_${student.name}',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. ÉTAT D'UN GROUPE
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> printGroupReport({
    required BuildContext context,
    required Group group,
    required List<Student> students,
    String? teacherName,
  }) async {
    final l = _l10n();
    final rtl = l.isAr;
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }
    final pdf = pw.Document();

    final stats = {
      'total': students.length,
      'upToDate': students
          .where((s) =>
              StudentService.computeStatus(s) == StudentStatus.upToDate)
          .length,
      'overdue': students
          .where((s) =>
              StudentService.computeStatus(s) == StudentStatus.overdue)
          .length,
      'dueSoon': students
          .where((s) =>
              StudentService.computeStatus(s) == StudentStatus.dueSoon)
          .length,
      'revenue':
          students.fold(0.0, (sum, s) => sum + s.totalPaid),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header(
            title: l.groupReport,
            subtitle: group.name,
            rightTop: group.subject,
            rightBottom: _fmtDate(DateTime.now()),
            logo: logoImage,
            rtl: rtl,
          ),
          pw.SizedBox(height: 20),

          // Infos groupe
          _sectionTitle(l.group.toUpperCase()),
          _infoRow(l.groupName, group.name, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.subject, group.subject, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.schedule, group.schedule, rtl: rtl),
          if (teacherName != null) ...[
            pw.SizedBox(height: 6),
            _infoRow(l.teacher, teacherName, rtl: rtl),
          ],
          if (group.roomName != null && group.roomName!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _infoRow(l.room, group.roomName!, rtl: rtl),
          ],
          pw.SizedBox(height: 16),

          // Stats
          _sectionTitle(l.groupStats.toUpperCase()),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _statBox('${stats['total']}', l.totalStudents, _PdfColors2.primary),
              _statBox('${stats['upToDate']}', l.upToDate, _PdfColors2.success),
              _statBox('${stats['dueSoon']}', '\u00c0 payer', _PdfColors2.orange),
              _statBox('${stats['overdue']}', l.critical, _PdfColors2.danger),
              _statBox(_fmtAmount(stats['revenue'] as double, l),
                  l.totalRevenue, _PdfColors2.primaryDark),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tableau élèves
          _sectionTitle(l.groupStudentsTable.toUpperCase()),
          if (students.isEmpty)
            pw.Text(l.noData,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _PdfColors2.border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _PdfColors2.primary),
                  children: [
                    _tableHeader(l.studentName),
                    _tableHeader(l.sessionsCount),
                    _tableHeader(l.lastPayment),
                    _tableHeader(l.totalPaid),
                    _tableHeader(l.studentStatus),
                  ],
                ),
                ...students.asMap().entries.map((e) {
                  final s = e.value;
                  final status = StudentService.computeStatus(s);
                  final alt = e.key.isOdd;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: alt ? _PdfColors2.rowAlt : PdfColors.white,
                    ),
                    children: [
                      _tableCell(s.name),
                      _tableCell('${s.attendances.length}'),
                      _tableCell(s.lastPaymentDate != null
                          ? _fmtDate(s.lastPaymentDate!)
                          : '—'),
                      _tableCell(_fmtAmount(s.totalPaid, l),
                          bold: true),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: _statusBadge(status, l),
                      ),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 24),
          _footer(l),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Etat_Groupe_${group.name}',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. ÉTAT D'UN ENSEIGNANT + REÇU DE RÈGLEMENT
  // ─────────────────────────────────────────────────────────────────────────────
  static Future<void> printTeacherReport({
    required BuildContext context,
    required Teacher teacher,
    required List<Group> groups,
    required List<Student> allStudents,
    required String centerName,
    DateTime? forMonth,
  }) async {
    final l = _l10n();
    final rtl = l.isAr;
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }
    final pdf = pw.Document();
    final now = forMonth ?? DateTime.now();

    // Calcul par groupe
    final groupData = groups.map((g) {
      final groupStudents =
          allStudents.where((s) => s.groupId == g.id).toList();
      final revenue = groupStudents.fold(0.0, (sum, s) {
        // Revenus du mois courant seulement
        return sum +
            s.payments
                .where((p) =>
                    p.date.year == now.year && p.date.month == now.month)
                .fold(0.0, (ps, p) => ps + p.amount);
      });
      final sessions = groupStudents.fold(
          0, (sum, s) => sum + s.attendances
              .where((d) => d.year == now.year && d.month == now.month)
              .length);
      final tShare = teacher.teacherShare(revenue, sessionCount: sessions);
      final cShare = teacher.centerShare(revenue, sessionCount: sessions);
      return {
        'group': g,
        'revenue': revenue,
        'sessions': sessions,
        'teacherShare': tShare,
        'centerShare': cShare,
      };
    }).toList();

    final totalRevenue =
        groupData.fold(0.0, (sum, d) => sum + (d['revenue'] as double));
    final totalSessions =
        groupData.fold(0, (sum, d) => sum + (d['sessions'] as int));
    final totalTeacherShare =
        groupData.fold(0.0, (sum, d) => sum + (d['teacherShare'] as double));
    final totalCenterShare =
        groupData.fold(0.0, (sum, d) => sum + (d['centerShare'] as double));

    final contractLabel = _contractLabel(teacher.contractType, l);
    final contractDetail = _contractDetail(teacher, l);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header(
            title: l.teacherReport,
            subtitle: teacher.name,
            rightTop: contractLabel,
            rightBottom: _fmtMonth(now, l),
            logo: logoImage,
            rtl: rtl,
          ),
          pw.SizedBox(height: 20),

          // Infos enseignant
          _sectionTitle(l.teacher.toUpperCase()),
          _infoRow(l.teacher, teacher.name, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.contractPourcentage.split(' ')[0], contractLabel, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(contractLabel, contractDetail, rtl: rtl),
          pw.SizedBox(height: 6),
          _infoRow(l.settlementPeriod, _fmtMonth(now, l), rtl: rtl),
          pw.SizedBox(height: 20),

          // Tableau groupes
          _sectionTitle(l.teacherGroupsTable.toUpperCase()),
          if (groups.isEmpty)
            pw.Text(l.noData,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _PdfColors2.border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _PdfColors2.primary),
                  children: [
                    _tableHeader(l.groupName),
                    _tableHeader(l.sessionNumber),
                    _tableHeader(l.grossRevenue),
                    _tableHeader(l.teacherShare),
                    _tableHeader(l.centerShare),
                  ],
                ),
                ...groupData.asMap().entries.map((e) {
                  final d = e.value;
                  final g = d['group'] as Group;
                  final alt = e.key.isOdd;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: alt ? _PdfColors2.rowAlt : PdfColors.white,
                    ),
                    children: [
                      _tableCell(g.name),
                      _tableCell('${d['sessions']}'),
                      _tableCell(_fmtAmount(d['revenue'] as double, l)),
                      _tableCell(_fmtAmount(d['teacherShare'] as double, l),
                          bold: true, color: _PdfColors2.success),
                      _tableCell(_fmtAmount(d['centerShare'] as double, l),
                          bold: true, color: _PdfColors2.primary),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Résumé financier
          _sectionTitle(l.financialSummary.toUpperCase()),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _statBox(_fmtAmount(totalRevenue, l), l.grossRevenue, _PdfColors2.primary),
              _statBox(_fmtAmount(totalTeacherShare, l), l.toTeacher, _PdfColors2.success),
              _statBox(_fmtAmount(totalCenterShare, l), l.toCenter, _PdfColors2.primaryDark),
            ],
          ),
          pw.SizedBox(height: 24),

          // ─── REÇU DE RÈGLEMENT ───────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _PdfColors2.primary, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
              color: _PdfColors2.primaryLight,
            ),
            child: pw.Column(
              crossAxisAlignment: rtl
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l.teacherPaymentReceipt.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _PdfColors2.primary,
                    letterSpacing: 1,
                  ),
                ),
                pw.Divider(color: _PdfColors2.primary),
                pw.SizedBox(height: 8),
                _infoRow(l.teacher, teacher.name, rtl: rtl),
                pw.SizedBox(height: 6),
                _infoRow(l.settlementPeriod, _fmtMonth(now, l), rtl: rtl),
                pw.SizedBox(height: 6),
                _infoRow(l.grossRevenue, _fmtAmount(totalRevenue, l), rtl: rtl),
                pw.SizedBox(height: 6),
                _infoRow(l.sessionNumber, '$totalSessions', rtl: rtl),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _PdfColors2.success),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${l.amountDue} ${l.toTeacher}',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _PdfColors2.primaryDark,
                        ),
                      ),
                      pw.Text(
                        _fmtAmount(totalTeacherShare, l),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _PdfColors2.success,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                // Note selon type contrat
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    _contractNote(teacher, totalRevenue, totalSessions, l),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 16),
                _signatureRow(
                  teacher.name,
                  centerName,
                  rtl: rtl,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _footer(l),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Etat_Enseignant_${teacher.name}_${now.month}_${now.year}',
    );
  }

  // ─── Helpers contrat ──────────────────────────────────────────────────────
  static String _contractLabel(TeacherContractType t, AppLocalizations l) {
    switch (t) {
      case TeacherContractType.salarie:
        return l.contractSalarie;
      case TeacherContractType.locateur:
        return l.contractLocateur;
      case TeacherContractType.pourcentage:
        return l.contractPourcentage;
    }
  }

  static String _contractDetail(Teacher t, AppLocalizations l) {
    switch (t.contractType) {
      case TeacherContractType.salarie:
        return '${l.fixedSalary}: ${NumberFormat('#,###').format(t.fixedAmount.toInt())} ${l.currency}';
      case TeacherContractType.locateur:
        return '${l.rentPerSession}: ${NumberFormat('#,###').format(t.fixedAmount.toInt())} ${l.currency}';
      case TeacherContractType.pourcentage:
        return '${l.percentage}: ${t.percentage.toInt()}%';
    }
  }

  static String _contractNote(
      Teacher t, double rev, int sessions, AppLocalizations l) {
    switch (t.contractType) {
      case TeacherContractType.salarie:
        return '${l.fixedSalary}: ${NumberFormat('#,###').format(t.fixedAmount.toInt())} ${l.currency}';
      case TeacherContractType.locateur:
        return '${l.grossRevenue} ${NumberFormat('#,###').format(rev.toInt())} ${l.currency} - '
            '${l.rentPerSession} ${NumberFormat('#,###').format(t.fixedAmount.toInt())} ${l.currency} × $sessions ${l.sessionsCount} = '
            '${NumberFormat('#,###').format((t.fixedAmount * sessions).toInt())} ${l.currency} ${l.toCenter}';
      case TeacherContractType.pourcentage:
        return '${NumberFormat('#,###').format(rev.toInt())} ${l.currency} × ${t.percentage.toInt()}% = '
            '${NumberFormat('#,###').format(t.teacherShare(rev).toInt())} ${l.currency} ${l.toTeacher}';
    }
  }

  // ─── Table helpers ───────────────────────────────────────────────────────
  static pw.Widget _tableHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );

  static pw.Widget _tableCell(String text,
      {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );

  static pw.Widget _statBox(String value, String label, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color),
          borderRadius: pw.BorderRadius.circular(6),
          color: color.shade(0.1),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. REÇU GLOBAL MULTI-MATIÈRES
  // ─────────────────────────────────────────────────────────────────────────────
  /// Imprime un reçu unique regroupant tous les paiements d'un élève
  /// inscrit dans plusieurs groupes/matières.
  static Future<void> printGlobalReceipt({
    required BuildContext context,
    required String studentName,
    required String studentPhone,
    required List<Map<String, dynamic>> registrations, // [{group, payments, subject}]
  }) async {
    final l = _l10n();
    final rtl = l.isAr;
    final centerName = _configService.centerName;
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }

    final pdf = pw.Document();

    // Calcul du total global
    double grandTotal = 0;
    for (final reg in registrations) {
      final payments = reg['payments'] as List<Payment>;
      grandTotal += payments.fold(0.0, (s, p) => s + p.amount);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          _header(
            title: centerName,
            subtitle: 'Reçu Global – Toutes Matières',
            rightTop: 'Date: ${_fmtDate(DateTime.now())}',
            rightBottom: studentName,
            logo: logoImage,
            rtl: rtl,
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('ÉLÈVE'),
          _infoRow('Nom', studentName, rtl: rtl),
          pw.SizedBox(height: 4),
          if (studentPhone.isNotEmpty) ...[
            _infoRow('Téléphone', studentPhone, rtl: rtl),
            pw.SizedBox(height: 4),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('DÉTAIL PAR MATIÈRE'),
          ...registrations.map((reg) {
            final group = reg['group'] as Group;
            final payments = reg['payments'] as List<Payment>;
            final subtotal = payments.fold(0.0, (s, p) => s + p.amount);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  decoration: pw.BoxDecoration(
                    color: _PdfColors2.primaryLight,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(group.name,
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold,
                              color: _PdfColors2.primaryDark)),
                      pw.Text(_fmtAmount(subtotal, l),
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold,
                              color: _PdfColors2.primary)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                _infoRow('Matière', group.subject, rtl: rtl),
                pw.SizedBox(height: 2),
                if (payments.isNotEmpty)
                  pw.Text(
                    'Dernier paiement: ${_fmtDate(payments.last.date)}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                pw.SizedBox(height: 10),
              ],
            );
          }),
          pw.Divider(color: _PdfColors2.primary, thickness: 1.5),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _PdfColors2.primaryLight,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _PdfColors2.primary, width: 1.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL GLOBAL',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold,
                        color: _PdfColors2.primaryDark)),
                pw.Text(_fmtAmount(grandTotal, l),
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold,
                        color: _PdfColors2.primary)),
              ],
            ),
          ),
          pw.Spacer(),
          _footer(l),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Recu_Global_$studentName',
    );
  }
}
