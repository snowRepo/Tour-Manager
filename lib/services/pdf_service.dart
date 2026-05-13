import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/client_model.dart';
import '../models/payment_model.dart';
import '../constants/app_constants.dart';
import 'financial_service.dart';

class PdfService {
  final FinancialService _fin = FinancialService();
  static final DateFormat _df = DateFormat('dd MMM yyyy');

  // ── Trip Agreement ─────────────────────────────────────────────────────────

  Future<void> printTripAgreement({
    required TripModel trip,
    required ClientModel client,
    required List<PaymentModel> payments,
    required Map<String, String> settings,
  }) async {
    final pdf = _buildTripAgreement(trip, client, payments, settings);
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Trip Agreement — ${client.fullName}',
    );
  }

  // ── Terms Only ─────────────────────────────────────────────────────────────

  Future<void> printTermsOnly({required Map<String, String> settings}) async {
    final pdf = _buildTermsOnly(settings);
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Terms & Conditions',
    );
  }

  // ── Internal Builders ──────────────────────────────────────────────────────

  pw.Document _buildTripAgreement(
    TripModel trip,
    ClientModel client,
    List<PaymentModel> payments,
    Map<String, String> settings,
  ) {
    final pdf = pw.Document();
    final totalPaid = _fin.getTotalPaid(payments);
    final totalRefunded = _fin.getTotalRefunded(payments);
    final balance = _fin.calculateBalance(trip.totalCost, payments);
    final tnc = settings[SettingKeys.termsAndConditions] ?? '';
    final bizName = settings[SettingKeys.businessName] ?? AppStrings.appName;
    final bizPhone = settings[SettingKeys.businessPhone] ?? '';
    final bizEmail = settings[SettingKeys.businessEmail] ?? '';
    final bizLogo = settings[SettingKeys.businessLogo];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: 40,
          top: 80,
          right: 40,
          bottom: 40,
        ),
        build: (context) => [
          // Header
          _header(bizName, bizPhone, bizEmail, bizLogo),
          pw.SizedBox(height: 16),
          _sectionTitle('TRIP AGREEMENT'),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),

          // Client Info
          _sectionTitle('Client Details'),
          pw.SizedBox(height: 4),
          _infoRow('Full Name', client.fullName),
          if (client.phone.isNotEmpty) _infoRow('Phone', client.phone),
          if (client.email.isNotEmpty) _infoRow('Email', client.email),
          if (client.passportNumber.isNotEmpty)
            _infoRow('Passport', client.passportNumber),
          if (client.dateOfBirth.isNotEmpty)
            _infoRow('Date of Birth', _fmtDate(client.dateOfBirth)),
          pw.SizedBox(height: 12),

          // Trip Info
          _sectionTitle('Trip Details'),
          pw.SizedBox(height: 4),
          _infoRow('Destination', trip.destination),
          _infoRow('Departure', _fmtDate(trip.departureDate)),
          _infoRow('Return', _fmtDate(trip.returnDate)),
          _infoRow('Status', TripStatus.label(trip.status)),
          pw.SizedBox(height: 12),

          // Financial Summary
          _sectionTitle('Financial Summary'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableRow(
                'Total Cost',
                _fin.formatCurrency(trip.totalCost),
                isHeader: true,
              ),
              _tableRow('Total Paid', _fin.formatCurrency(totalPaid)),
              _tableRow('Total Refunded', _fin.formatCurrency(totalRefunded)),
              _tableRow(
                'Outstanding Balance',
                _fin.formatCurrency(balance.abs()) +
                    (balance < Decimal.zero ? ' (overpaid)' : ''),
                highlight: true,
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Payment History
          if (payments.isNotEmpty) ...[
            _sectionTitle('Payment History'),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(3),
              },
              children: [
                _paymentHeaderRow(),
                ...payments.map((p) => _paymentRow(p)),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          // T&C
          if (tnc.isNotEmpty) ...[
            _sectionTitle('Terms & Conditions'),
            pw.SizedBox(height: 4),
            pw.Text(
              tnc,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
          ],

          // Signatures
          _signatures(),
        ],
      ),
    );
    return pdf;
  }

  pw.Document _buildTermsOnly(Map<String, String> settings) {
    final pdf = pw.Document();
    final tnc = settings[SettingKeys.termsAndConditions] ?? '';
    final bizName = settings[SettingKeys.businessName] ?? AppStrings.appName;
    final bizPhone = settings[SettingKeys.businessPhone] ?? '';
    final bizEmail = settings[SettingKeys.businessEmail] ?? '';
    final bizLogo = settings[SettingKeys.businessLogo];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: 40,
          top: 80,
          right: 40,
          bottom: 40,
        ),
        build: (context) => [
          _header(bizName, bizPhone, bizEmail, bizLogo),
          pw.SizedBox(height: 16),
          _sectionTitle('TERMS & CONDITIONS'),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),
          pw.Text(
            tnc,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 30),
          _signatures(),
        ],
      ),
    );
    return pdf;
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  pw.Widget _header(
    String name,
    String phone,
    String email,
    String? logoBase64,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoBase64 != null && logoBase64.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.only(right: 16),
            child: pw.Image(
              pw.MemoryImage(base64Decode(logoBase64)),
              width: 120, // Increased to allow wider logos
              height: 80, // Increased to prevent vertical clipping
              fit: pw.BoxFit.contain,
            ),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              if (phone.isNotEmpty)
                pw.Text(
                  'Phone: $phone',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              if (email.isNotEmpty)
                pw.Text(
                  'Email: $email',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey700,
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ],
      ),
    );
  }

  pw.TableRow _tableRow(
    String label,
    String value, {
    bool isHeader = false,
    bool highlight = false,
  }) {
    final bg = highlight
        ? PdfColors.yellow50
        : isHeader
        ? PdfColors.blueGrey50
        : PdfColors.white;
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  pw.TableRow _paymentHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      children: ['Date', 'Method', 'Reference', 'Amount', 'Note']
          .map(
            (h) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.TableRow _paymentRow(PaymentModel p) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _fmtDate(p.paymentDate),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            PaymentMethod.label(p.paymentMethod),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            p.referenceNumber?.isNotEmpty == true ? p.referenceNumber! : '-',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _fin.formatCurrency(p.amount),
            style: pw.TextStyle(
              fontSize: 9,
              color: p.isRefund ? PdfColors.red700 : PdfColors.green700,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(p.note ?? '', style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.Widget _signatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBlock('Client Signature'),
        _signatureBlock('Agent Signature'),
      ],
    );
  }

  pw.Widget _signatureBlock(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Container(width: 180, height: 1, color: PdfColors.grey700),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date: _____________________',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  String _fmtDate(String iso) {
    try {
      return _df.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
