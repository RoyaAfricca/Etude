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

class PdfReceiptService {
  static final _configService = CenterConfigService();

  /// Génère et affiche la boîte de dialogue d'impression pour un reçu de paiement.
  static Future<void> printReceipt({
    required BuildContext context,
    required Student student,
    required Payment payment,
    required Group group,
  }) async {
    final centerName = _configService.centerName;
    final isCenterMode = _configService.isCenterMode;
    final logoBase64 = _configService.centerLogoBase64;
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      logoImage = pw.MemoryImage(base64Decode(logoBase64));
    }

    final pdf = pw.Document();

    final dateFormatter = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Entête ──────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  color: const PdfColor.fromInt(0xFF6C63FF),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 35,
                            height: 35,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              isCenterMode ? centerName : 'Reçu de Paiement',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (isCenterMode)
                              pw.Text(
                                'Reçu de Paiement',
                                style: const pw.TextStyle(
                                  color: PdfColor.fromInt(0xB3FFFFFF),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'N° ${payment.id.substring(0, 8).toUpperCase()}',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xB3FFFFFF),
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          dateFormatter.format(payment.date),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── Informations Élève ──────────────────────────────────
              pw.Text(
                'INFORMATIONS ÉLÈVE',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              _infoRow('Nom & Prénom', student.name),
              pw.SizedBox(height: 6),
              _infoRow('Groupe', group.name),
              if (group.roomName != null && group.roomName!.isNotEmpty)
                ...[pw.SizedBox(height: 6), _infoRow('Salle', group.roomName!)],
              pw.SizedBox(height: 6),
              _infoRow('Téléphone', student.phone.isNotEmpty ? student.phone : '—'),
              pw.SizedBox(height: 20),

              // ── Détails du Paiement ─────────────────────────────────
              pw.Text(
                'DÉTAILS DU PAIEMENT',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              _infoRow('Date', dateFormatter.format(payment.date)),
              pw.SizedBox(height: 6),
              if (payment.sessionsCount == 0)
                _infoRow('Objet', 'Frais d\'inscription')
              else ...[
                _infoRow('Objet', 'Mensualité'),
                pw.SizedBox(height: 6),
                _infoRow('Mois', DateFormat('MMMM yyyy', 'fr_FR').format(payment.date)),
              ],
              pw.SizedBox(height: 16),

              // ── Montant ─────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0F0FF),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFF6C63FF)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'MONTANT PAYÉ',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF4A4A8A),
                      ),
                    ),
                    pw.Text(
                      '${NumberFormat('#,###').format(payment.amount.toInt())} DT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey200),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Ce reçu atteste du paiement effectué — Étude App',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recu_${student.name}_${DateFormat('MM_yyyy').format(payment.date)}',
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(label,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        ),
        pw.Text(' : ',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey400)),
        pw.Expanded(
          child: pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
      ],
    );
  }
}
