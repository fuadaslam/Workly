import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/report_repository.dart';

class ExcelExportService {
  static final _df = DateFormat('dd MMM yyyy');
  static final _dtf = DateFormat('dd MMM yyyy HH:mm');
  static final _currency = NumberFormat('#,##0.00');

  // ── Colour palette ─────────────────────────────────────────────────────────
  static ExcelColor get _navyBg => ExcelColor.fromHexString('#0D1B2E');
  static ExcelColor get _goldBg => ExcelColor.fromHexString('#D4AF37');
  static ExcelColor get _lightBg => ExcelColor.fromHexString('#EEF2F7');
  static ExcelColor get _greenBg => ExcelColor.fromHexString('#D1FAE5');
  static ExcelColor get _redBg => ExcelColor.fromHexString('#FEE2E2');
  static ExcelColor get _amberBg => ExcelColor.fromHexString('#FEF9C3');
  static ExcelColor get _whiteTxt => ExcelColor.fromHexString('#FFFFFF');
  static ExcelColor get _navyTxt => ExcelColor.fromHexString('#0D1B2E');
  static ExcelColor get _goldTxt => ExcelColor.fromHexString('#92610A');
  static ExcelColor get _greenTxt => ExcelColor.fromHexString('#065F46');
  static ExcelColor get _redTxt => ExcelColor.fromHexString('#991B1B');

  // ── Public entry point ─────────────────────────────────────────────────────
  static Future<void> exportAndShare({
    required String reportTitle,
    required DateTime from,
    required DateTime to,
    required List<Map<String, dynamic>> workOrders,
    required List<Map<String, dynamic>> enquiries,
    required List<Map<String, dynamic>> attendance,
    ReportFilters filters = const ReportFilters(),
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildCoverSheet(excel, reportTitle, from, to, workOrders, enquiries, filters);
    _buildWorkOrdersSheet(excel, workOrders);
    _buildEnquiriesSheet(excel, enquiries);
    _buildEnquirySummarySheet(excel, enquiries, from, to);
    if (attendance.isNotEmpty) _buildAttendanceSheet(excel, attendance);

    final bytes = excel.encode()!;
    final dir = await getTemporaryDirectory();
    final safeTitle = reportTitle.replaceAll(' ', '_').replaceAll('/', '-');
    final file = File('${dir.path}/$safeTitle.xlsx');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: reportTitle,
        text: 'Worqly Work Report: $reportTitle',
      ),
    );
  }

  // ── Sheet builders ─────────────────────────────────────────────────────────

  static void _buildCoverSheet(
    Excel excel,
    String title,
    DateTime from,
    DateTime to,
    List<Map<String, dynamic>> workOrders,
    List<Map<String, dynamic>> enquiries,
    ReportFilters filters,
  ) {
    final sheet = excel['Summary'];

    // Title block
    _mergeWrite(sheet, 0, 0, 6, 'WORQLY — WORK REPORT', bold: true, fontSize: 16,
        bgColor: _navyBg, txtColor: _whiteTxt);
    _mergeWrite(sheet, 1, 0, 6, title, bold: true, fontSize: 13,
        bgColor: _navyBg, txtColor: _goldBg);
    _mergeWrite(sheet, 2, 0, 6,
        'Period: ${_df.format(from)}  →  ${_df.format(to)}',
        fontSize: 11, bgColor: _lightBg, txtColor: _navyTxt);

    sheet.setRowHeight(0, 36);
    sheet.setRowHeight(1, 28);
    sheet.setRowHeight(2, 24);

    // Work Orders KPIs
    const int woRow = 4;
    _sectionHeader(sheet, woRow, 0, 6, 'WORK ORDERS');

    final total = workOrders.length;
    final completed = workOrders.where((w) => (w['status'] ?? '').toString().toLowerCase() == 'completed').length;
    final pending = workOrders.where((w) => (w['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final inProgress = workOrders.where((w) => (w['status'] ?? '').toString().toLowerCase().contains('progress')).length;

    double totalRevenue = 0;
    double totalCollected = 0;
    for (final w in workOrders) {
      final p = w['payments'];
      if (p is List && p.isNotEmpty) {
        totalRevenue += (p[0]['total_amount'] as num? ?? 0).toDouble();
        totalCollected += (p[0]['paid_amount'] as num? ?? 0).toDouble();
      } else if (p is Map) {
        totalRevenue += (p['total_amount'] as num? ?? 0).toDouble();
        totalCollected += (p['paid_amount'] as num? ?? 0).toDouble();
      }
    }

    final convRate = total > 0 ? (completed / total * 100) : 0.0;
    final outstanding = totalRevenue - totalCollected;

    final woKpis = [
      ['Total Orders', '$total', _lightBg, _navyTxt],
      ['Completed', '$completed', _greenBg, _greenTxt],
      ['In Progress', '$inProgress', _amberBg, _goldTxt],
      ['Pending', '$pending', _redBg, _redTxt],
      ['Completion Rate', '${convRate.toStringAsFixed(1)}%', _lightBg, _navyTxt],
      ['Total Revenue', 'SAR ${_currency.format(totalRevenue)}', _greenBg, _greenTxt],
      ['Collected', 'SAR ${_currency.format(totalCollected)}', _greenBg, _greenTxt],
      ['Outstanding', 'SAR ${_currency.format(outstanding)}', _redBg, _redTxt],
    ];

    _kpiGrid(sheet, woRow + 1, woKpis);

    // Enquiries KPIs
    final int eqRow = woRow + 1 + (woKpis.length / 2).ceil() + 2;
    _sectionHeader(sheet, eqRow, 0, 6, 'ENQUIRIES');

    final eqTotal = enquiries.length;
    final eqAccepted = enquiries.where((e) => e['client_status'] == 'accepted').length;
    final eqSettled = enquiries.where((e) =>
        e['final_status'] == 'Settled' || e['final_status'] == 'Executed').length;
    final eqRejected = enquiries.where((e) => e['client_status'] == 'rejected').length;
    final eqConv = eqTotal > 0 ? (eqAccepted / eqTotal * 100) : 0.0;

    double eqRevenue = 0;
    for (final e in enquiries) {
      final agreed = e['final_agreed_service_charge'];
      if (agreed != null) eqRevenue += (agreed as num).toDouble();
    }

    final eqKpis = [
      ['Total Enquiries', '$eqTotal', _lightBg, _navyTxt],
      ['Accepted', '$eqAccepted', _greenBg, _greenTxt],
      ['Settled/Executed', '$eqSettled', _greenBg, _greenTxt],
      ['Rejected', '$eqRejected', _redBg, _redTxt],
      ['Conversion Rate', '${eqConv.toStringAsFixed(1)}%', _lightBg, _navyTxt],
      ['Revenue (Agreed)', 'SAR ${_currency.format(eqRevenue)}', _greenBg, _greenTxt],
    ];

    _kpiGrid(sheet, eqRow + 1, eqKpis);

    // Applied Filters section
    int nextRow = eqRow + 1 + (eqKpis.length / 2).ceil() + 2;
    if (filters.activeCount > 0) {
      _sectionHeader(sheet, nextRow, 0, 6, 'APPLIED FILTERS');
      nextRow++;

      int filterRow = nextRow;
      void writeFilter(String label, List<String> values) {
        if (values.isEmpty) return;
        final lc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filterRow));
        lc.value = TextCellValue(label);
        lc.cellStyle = CellStyle(bold: true, backgroundColorHex: _lightBg, fontColorHex: _navyTxt);
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filterRow),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: filterRow),
        );
        final vc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filterRow));
        vc.value = TextCellValue(values.join(' · '));
        vc.cellStyle = CellStyle(backgroundColorHex: _lightBg);
        filterRow++;
      }

      writeFilter('WO Status', filters.woStatuses);
      writeFilter('WO Priority', filters.woPriorities);
      writeFilter('WO Service Type', filters.woServiceTypes);
      writeFilter('EQ Final Status', filters.eqFinalStatuses);
      writeFilter('EQ Client Decision', filters.eqClientStatuses);
      writeFilter('EQ Service Type', filters.eqServiceTypes);
      writeFilter('EQ Nationality', filters.eqNationalities);
      nextRow = filterRow + 1;
    }

    // Footer
    final footerRow = nextRow;
    _mergeWrite(sheet, footerRow, 0, 6,
        'Generated by Worqly · ${_dtf.format(DateTime.now())}',
        fontSize: 9, txtColor: ExcelColor.fromHexString('#9CA3AF'));

    // Column widths
    for (int c = 0; c < 6; c++) {
      sheet.setColumnWidth(c, c == 0 ? 26 : 18);
    }
  }

  static void _buildWorkOrdersSheet(
      Excel excel, List<Map<String, dynamic>> workOrders) {
    final sheet = excel['Work Orders'];

    final headers = [
      'Order ID', 'Client Name', 'Phone', 'Service Type',
      'Assigned Staff', 'Office', 'Priority', 'Status',
      'Agent', 'Agent Fee (SAR)', 'Total (SAR)', 'Collected (SAR)',
      'Outstanding (SAR)', 'Payment Status', 'Created Date',
    ];

    _tableHeader(sheet, 0, headers);

    final colWidths = [14.0, 20.0, 16.0, 20.0, 18.0, 16.0, 10.0, 14.0,
        16.0, 14.0, 14.0, 14.0, 14.0, 14.0, 18.0];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }

    for (int i = 0; i < workOrders.length; i++) {
      final w = workOrders[i];
      final rowIdx = i + 1;
      final isEven = i % 2 == 0;
      final bg = isEven ? ExcelColor.fromHexString('#F9FAFB') : ExcelColor.fromHexString('#FFFFFF');

      final payment = _extractPayment(w['payments']);
      final total = payment['total'] ?? 0.0;
      final collected = payment['paid'] ?? 0.0;
      final outstanding = total - collected;
      final payStatus = payment['status'] ?? '—';

      final status = (w['status'] ?? '').toString();
      final statusBg = _statusBg(status);

      final row = [
        w['id']?.toString().substring(0, 8) ?? '—',
        w['client_name'] ?? '—',
        w['client_phone_number'] ?? w['client_phone'] ?? '—',
        w['service_type'] ?? '—',
        w['profiles']?['name'] ?? '—',
        w['offices']?['name'] ?? '—',
        w['priority'] ?? '—',
        status,
        w['agent_profiles']?['name'] ?? '—',
        w['agent_fee'] != null ? (w['agent_fee'] as num).toDouble() : null,
        total > 0 ? total : null,
        collected > 0 ? collected : null,
        outstanding > 0 ? outstanding : null,
        payStatus,
        w['created_at'] != null ? _df.format(DateTime.parse(w['created_at'])) : '—',
      ];

      for (int c = 0; c < row.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
        final val = row[c];
        if (val is double) {
          cell.value = DoubleCellValue(val);
          cell.cellStyle = CellStyle(
            backgroundColorHex: c == 7 ? statusBg : bg,
            numberFormat: NumFormat.defaultNumeric,
          );
        } else {
          cell.value = TextCellValue(val?.toString() ?? '—');
          cell.cellStyle = CellStyle(backgroundColorHex: c == 7 ? statusBg : bg);
        }
      }
    }

    if (workOrders.isEmpty) {
      _mergeWrite(sheet, 1, 0, headers.length, 'No work orders in this period.',
          txtColor: ExcelColor.fromHexString('#6B7280'));
    }
  }

  static void _buildEnquiriesSheet(
      Excel excel, List<Map<String, dynamic>> enquiries) {
    final sheet = excel['Enquiries'];

    final headers = [
      'Enquiry ID', 'Client Name', 'Contact', 'Service Type',
      'Nationality', 'Date of Enquiry', 'Official Fee (SAR)',
      'Service Charge (SAR)', 'Total Offered (SAR)',
      'Responsible Staff', 'Client Decision', 'Rejection Reason',
      'Final Status', 'Agreed Charge (SAR)', 'Settlement Date',
      'Days Open', 'Performance', 'Follow-up Date', 'Final Notes',
    ];

    _tableHeader(sheet, 0, headers);

    final colWidths = [12.0, 20.0, 16.0, 20.0, 14.0, 16.0, 14.0, 16.0,
        16.0, 18.0, 14.0, 22.0, 18.0, 16.0, 16.0, 11.0, 14.0, 16.0, 24.0];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }

    for (int i = 0; i < enquiries.length; i++) {
      final e = enquiries[i];
      final rowIdx = i + 1;
      final isEven = i % 2 == 0;
      final bg = isEven ? ExcelColor.fromHexString('#F9FAFB') : ExcelColor.fromHexString('#FFFFFF');

      final officialFee = (e['official_fee'] as num? ?? 0).toDouble();
      final serviceCharge = (e['service_charge_offered'] as num? ?? 0).toDouble();
      final totalOffered = officialFee + serviceCharge;
      final agreedCharge = e['final_agreed_service_charge'] != null
          ? (e['final_agreed_service_charge'] as num).toDouble()
          : null;

      final dateEnquiry = e['date_of_enquiry'] != null
          ? DateTime.tryParse(e['date_of_enquiry'])
          : null;
      final settlementDate = e['settlement_date'] != null
          ? DateTime.tryParse(e['settlement_date'])
          : null;
      final followUpDate = e['follow_up_date'] != null
          ? DateTime.tryParse(e['follow_up_date'])
          : null;

      int daysOpen = 0;
      if (dateEnquiry != null) {
        final finalStatus = (e['final_status'] ?? '').toString();
        final end = (finalStatus == 'Settled' || finalStatus == 'Executed')
            ? (settlementDate ?? DateTime.now())
            : DateTime.now();
        daysOpen = end.difference(dateEnquiry).inDays;
      }

      final perf = _performanceLabel(daysOpen, e['client_status'], e['final_status']);
      final finalStatus = (e['final_status'] ?? '').toString();
      final statusBg = _enquiryStatusBg(finalStatus);

      final row = [
        e['enquiry_code'] ?? '—',
        e['client_name'] ?? '—',
        e['contact_number'] ?? '—',
        e['nature_of_enquiry'] ?? '—',
        e['nationality'] ?? '—',
        dateEnquiry != null ? _df.format(dateEnquiry) : '—',
        officialFee > 0 ? officialFee : null,
        serviceCharge > 0 ? serviceCharge : null,
        totalOffered > 0 ? totalOffered : null,
        e['profiles']?['name'] ?? '—',
        (e['client_status'] ?? 'pending').toString().toUpperCase(),
        e['rejection_reason'] ?? '—',
        finalStatus,
        agreedCharge,
        settlementDate != null ? _df.format(settlementDate) : '—',
        daysOpen > 0 ? daysOpen : null,
        perf,
        followUpDate != null ? _df.format(followUpDate) : '—',
        e['final_notes'] ?? '—',
      ];

      for (int c = 0; c < row.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
        final val = row[c];
        final cellBg = c == 12 ? statusBg : bg;
        if (val is double) {
          cell.value = DoubleCellValue(val);
          cell.cellStyle = CellStyle(backgroundColorHex: cellBg, numberFormat: NumFormat.defaultNumeric);
        } else if (val is int) {
          cell.value = IntCellValue(val);
          cell.cellStyle = CellStyle(backgroundColorHex: cellBg);
        } else {
          cell.value = TextCellValue(val?.toString() ?? '—');
          cell.cellStyle = CellStyle(backgroundColorHex: cellBg);
        }
      }
    }

    if (enquiries.isEmpty) {
      _mergeWrite(sheet, 1, 0, headers.length, 'No enquiries in this period.',
          txtColor: ExcelColor.fromHexString('#6B7280'));
    }
  }

  static void _buildEnquirySummarySheet(
      Excel excel, List<Map<String, dynamic>> enquiries, DateTime from, DateTime to) {
    final sheet = excel['Enquiry Analytics'];
    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 16);

    _mergeWrite(sheet, 0, 0, 4, 'ENQUIRY ANALYTICS — ${_df.format(from)} to ${_df.format(to)}',
        bold: true, bgColor: _navyBg, txtColor: _whiteTxt);

    // By service type
    int row = 2;
    _sectionHeader(sheet, row, 0, 4, 'BY SERVICE TYPE');
    row++;
    _tableHeader(sheet, row, ['Service Type', 'Total', 'Accepted', 'Conv. Rate']);
    row++;

    final Map<String, Map<String, int>> byService = {};
    for (final e in enquiries) {
      final svc = e['nature_of_enquiry'] as String? ?? 'Unknown';
      byService[svc] ??= {'total': 0, 'accepted': 0};
      byService[svc]!['total'] = byService[svc]!['total']! + 1;
      if (e['client_status'] == 'accepted') {
        byService[svc]!['accepted'] = byService[svc]!['accepted']! + 1;
      }
    }
    final sortedSvc = byService.entries.toList()
      ..sort((a, b) => b.value['total']!.compareTo(a.value['total']!));

    for (final entry in sortedSvc) {
      final t = entry.value['total']!;
      final a = entry.value['accepted']!;
      final conv = t > 0 ? '${(a / t * 100).toStringAsFixed(0)}%' : '0%';
      final isEven = (row % 2 == 0);
      final bg = isEven ? ExcelColor.fromHexString('#F9FAFB') : ExcelColor.fromHexString('#FFFFFF');
      _rowWrite(sheet, row, [entry.key, '$t', '$a', conv], bg: bg);
      row++;
    }

    // By staff
    row += 2;
    _sectionHeader(sheet, row, 0, 4, 'BY STAFF');
    row++;
    _tableHeader(sheet, row, ['Staff Member', 'Handled', 'Settled', 'Avg Days']);
    row++;

    final Map<String, Map<String, dynamic>> byStaff = {};
    for (final e in enquiries) {
      final name = e['profiles']?['name'] as String? ?? 'Unassigned';
      byStaff[name] ??= {'total': 0, 'settled': 0, 'days': 0};
      byStaff[name]!['total'] = (byStaff[name]!['total'] as int) + 1;
      final finalStatus = (e['final_status'] ?? '').toString();
      if (finalStatus == 'Settled' || finalStatus == 'Executed') {
        byStaff[name]!['settled'] = (byStaff[name]!['settled'] as int) + 1;
        final dateEnquiry = e['date_of_enquiry'] != null ? DateTime.tryParse(e['date_of_enquiry']) : null;
        final settlementDate = e['settlement_date'] != null ? DateTime.tryParse(e['settlement_date']) : null;
        if (dateEnquiry != null && settlementDate != null) {
          byStaff[name]!['days'] = (byStaff[name]!['days'] as int) + settlementDate.difference(dateEnquiry).inDays;
        }
      }
    }

    for (final entry in byStaff.entries) {
      final t = entry.value['total'] as int;
      final s = entry.value['settled'] as int;
      final days = entry.value['days'] as int;
      final avg = s > 0 ? '${(days / s).toStringAsFixed(1)}d' : '—';
      final isEven = (row % 2 == 0);
      final bg = isEven ? ExcelColor.fromHexString('#F9FAFB') : ExcelColor.fromHexString('#FFFFFF');
      _rowWrite(sheet, row, [entry.key, '$t', '$s', avg], bg: bg);
      row++;
    }

    // Performance distribution
    row += 2;
    _sectionHeader(sheet, row, 0, 4, 'PERFORMANCE DISTRIBUTION');
    row++;
    _tableHeader(sheet, row, ['Rating', 'Count', '% of Total', '']);
    row++;

    final Map<String, int> perfDist = {
      'Excellent': 0, 'Good': 0, 'Average': 0, 'Needs Review': 0
    };
    for (final e in enquiries) {
      final dateEnquiry = e['date_of_enquiry'] != null ? DateTime.tryParse(e['date_of_enquiry']) : null;
      final settlementDate = e['settlement_date'] != null ? DateTime.tryParse(e['settlement_date']) : null;
      final finalStatus = (e['final_status'] ?? '').toString();
      int days = 0;
      if (dateEnquiry != null) {
        final end = (finalStatus == 'Settled' || finalStatus == 'Executed')
            ? (settlementDate ?? DateTime.now())
            : DateTime.now();
        days = end.difference(dateEnquiry).inDays;
      }
      final label = _performanceLabel(days, e['client_status'], e['final_status']);
      perfDist[label] = (perfDist[label] ?? 0) + 1;
    }

    final perfColors = {
      'Excellent': _greenBg, 'Good': ExcelColor.fromHexString('#DBEAFE'),
      'Average': _amberBg, 'Needs Review': _redBg,
    };
    for (final entry in perfDist.entries) {
      final pct = enquiries.isNotEmpty ? '${(entry.value / enquiries.length * 100).toStringAsFixed(0)}%' : '0%';
      _rowWrite(sheet, row, [entry.key, '${entry.value}', pct, ''], bg: perfColors[entry.key] ?? _lightBg);
      row++;
    }
  }

  static void _buildAttendanceSheet(
      Excel excel, List<Map<String, dynamic>> attendance) {
    final sheet = excel['Attendance'];
    final headers = ['Date', 'Staff Name', 'Role', 'Check In', 'Check Out', 'Status', 'Hours'];
    _tableHeader(sheet, 0, headers);

    for (int c = 0; c < [14.0, 20.0, 12.0, 14.0, 14.0, 12.0, 10.0].length; c++) {
      sheet.setColumnWidth(c, [14.0, 20.0, 12.0, 14.0, 14.0, 12.0, 10.0][c]);
    }

    for (int i = 0; i < attendance.length; i++) {
      final a = attendance[i];
      final rowIdx = i + 1;
      final isEven = i % 2 == 0;
      final bg = isEven ? ExcelColor.fromHexString('#F9FAFB') : ExcelColor.fromHexString('#FFFFFF');

      final checkIn = a['check_in'] != null ? a['check_in'].toString().substring(0, 5) : '—';
      final checkOut = a['check_out'] != null ? a['check_out'].toString().substring(0, 5) : '—';

      double? hours;
      if (a['check_in'] != null && a['check_out'] != null) {
        try {
          final parts1 = a['check_in'].toString().split(':');
          final parts2 = a['check_out'].toString().split(':');
          final mins1 = int.parse(parts1[0]) * 60 + int.parse(parts1[1]);
          final mins2 = int.parse(parts2[0]) * 60 + int.parse(parts2[1]);
          hours = (mins2 - mins1) / 60.0;
        } catch (_) {}
      }

      final status = (a['status'] ?? 'present').toString();
      final statusBg = status.toLowerCase() == 'absent' ? _redBg : _greenBg;

      final row = [
        a['date'] != null ? _df.format(DateTime.parse(a['date'])) : '—',
        a['profiles']?['name'] ?? '—',
        a['profiles']?['role'] ?? '—',
        checkIn,
        checkOut,
        status.toUpperCase(),
        hours,
      ];

      for (int c = 0; c < row.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
        final val = row[c];
        final cellBg = c == 5 ? statusBg : bg;
        if (val is double) {
          cell.value = DoubleCellValue(val);
          cell.cellStyle = CellStyle(backgroundColorHex: cellBg, numberFormat: NumFormat.defaultNumeric);
        } else {
          cell.value = TextCellValue(val?.toString() ?? '—');
          cell.cellStyle = CellStyle(backgroundColorHex: cellBg);
        }
      }
    }
  }

  // ── Styling helpers ────────────────────────────────────────────────────────

  static void _mergeWrite(Sheet sheet, int row, int colStart, int colEnd, String text, {
    bool bold = false, double fontSize = 11,
    ExcelColor? bgColor, ExcelColor? txtColor,
  }) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: colEnd - 1, rowIndex: row),
    );
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      backgroundColorHex: bgColor ?? ExcelColor.fromHexString('#FFFFFF'),
      fontColorHex: txtColor ?? ExcelColor.fromHexString('#000000'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static void _sectionHeader(Sheet sheet, int row, int colStart, int colEnd, String text) {
    _mergeWrite(sheet, row, colStart, colEnd, text,
        bold: true, fontSize: 11, bgColor: _goldBg, txtColor: _navyTxt);
    sheet.setRowHeight(row, 22);
  }

  static void _tableHeader(Sheet sheet, int row, List<String> headers) {
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: _navyBg,
        fontColorHex: _whiteTxt,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
    sheet.setRowHeight(row, 20);
  }

  static void _rowWrite(Sheet sheet, int row, List<String> values, {ExcelColor? bg}) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(values[c]);
      if (bg != null) cell.cellStyle = CellStyle(backgroundColorHex: bg);
    }
  }

  static void _kpiGrid(Sheet sheet, int startRow, List<List<dynamic>> kpis) {
    for (int i = 0; i < kpis.length; i++) {
      final kpi = kpis[i];
      final col = (i % 2) * 3;
      final row = startRow + (i ~/ 2);

      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      labelCell.value = TextCellValue(kpi[0] as String);
      labelCell.cellStyle = CellStyle(bold: true, backgroundColorHex: kpi[2] as ExcelColor, fontColorHex: kpi[3] as ExcelColor);

      final valCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: row));
      valCell.value = TextCellValue(kpi[1] as String);
      valCell.cellStyle = CellStyle(backgroundColorHex: kpi[2] as ExcelColor, fontColorHex: kpi[3] as ExcelColor, bold: true);

      sheet.setRowHeight(row, 22);
    }
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _extractPayment(dynamic payments) {
    if (payments == null) return {};
    if (payments is List && payments.isNotEmpty) {
      return {
        'total': (payments[0]['total_amount'] as num? ?? 0).toDouble(),
        'paid': (payments[0]['paid_amount'] as num? ?? 0).toDouble(),
        'status': payments[0]['status'],
      };
    }
    if (payments is Map) {
      return {
        'total': (payments['total_amount'] as num? ?? 0).toDouble(),
        'paid': (payments['paid_amount'] as num? ?? 0).toDouble(),
        'status': payments['status'],
      };
    }
    return {};
  }

  static ExcelColor _statusBg(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') return ExcelColor.fromHexString('#D1FAE5');
    if (s.contains('progress')) return ExcelColor.fromHexString('#FEF9C3');
    if (s == 'pending') return ExcelColor.fromHexString('#FEE2E2');
    return ExcelColor.fromHexString('#F3F4F6');
  }

  static ExcelColor _enquiryStatusBg(String status) {
    switch (status) {
      case 'Settled':
      case 'Executed': return ExcelColor.fromHexString('#D1FAE5');
      case 'In Progress': return ExcelColor.fromHexString('#FEF9C3');
      case 'Rejected by client':
      case 'Cancelled': return ExcelColor.fromHexString('#FEE2E2');
      case 'Postponed by client': return ExcelColor.fromHexString('#FFE4CC');
      default: return ExcelColor.fromHexString('#F3F4F6');
    }
  }

  static String _performanceLabel(int days, dynamic clientStatus, dynamic finalStatus) {
    final cs = (clientStatus ?? '').toString();
    final fs = (finalStatus ?? '').toString();
    if (cs == 'rejected' || fs == 'Rejected by client' || fs == 'Cancelled') {
      return 'Needs Review';
    }
    if (days <= 7) return 'Excellent';
    if (days <= 14) return 'Good';
    if (days <= 30) return 'Average';
    return 'Needs Review';
  }
}
