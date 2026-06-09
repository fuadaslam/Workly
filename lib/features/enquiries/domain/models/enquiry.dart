enum ClientStatus { accepted, rejected, pending }

enum EnquiryFinalStatus { executed, inProgress, settled, postponedByClient, rejectedByClient, cancelled }

enum PerformanceRating { excellent, good, average, needsReview }

const List<String> kNatureOfEnquiry = [
  'Sijil Opening',
  'Qiwa Services',
  'Mudad Service',
  'Gosi',
  'Absher',
  'Business Startup',
  'Baladiya Service',
  'Muqeem Service (Sharika)',
  'Medical Insurance',
  'Vehicle Insurance',
  'Iqama Services',
  'Lawyer Service',
  'Company Related Fine Cutting',
  'Musaned Services',
  'Financial Consultants',
  'Budget Preparation',
  'Cash Flow',
  'Cost Control',
];

const List<String> kNationalities = [
  'Indian',
  'Pakistani',
  'Bangladeshi',
  'Burma',
  'Saudi Arabia',
  'United Arab Emirates',
  'Indonesia',
  'Philippine',
  'Other',
  'Company',
];

const List<String> kRejectionReasons = [
  'Pricing Too High',
  'Competitor Chosen',
  'No Response',
  'Project Delayed',
  'Not a Good Fit',
  'Attitude issue',
  'Other',
];

const List<String> kFinalStatusLabels = [
  'Executed',
  'In Progress',
  'Settled',
  'Postponed by client',
  'Rejected by client',
  'Cancelled',
  'Rejected',
];

class Enquiry {
  final String id;
  final String enquiryCode;
  final String? clientName;
  final String? contactNumber;
  final String? natureOfEnquiry;
  final DateTime? dateOfEnquiry;
  final String? nationality;
  final double? officialFee;
  final double? serviceChargeOffered;
  final String? actionNotes;
  final DateTime? followUpDate;
  final double? finalAgreedServiceCharge;
  final String? responsibleStaffId;
  final String? responsibleStaffName;
  final ClientStatus clientStatus;
  final String? rejectionReason;
  final EnquiryFinalStatus finalStatus;
  final DateTime? settlementDate;
  final String? finalNotes;
  final DateTime? createdAt;

  Enquiry({
    required this.id,
    required this.enquiryCode,
    this.clientName,
    this.contactNumber,
    this.natureOfEnquiry,
    this.dateOfEnquiry,
    this.nationality,
    this.officialFee,
    this.serviceChargeOffered,
    this.actionNotes,
    this.followUpDate,
    this.finalAgreedServiceCharge,
    this.responsibleStaffId,
    this.responsibleStaffName,
    this.clientStatus = ClientStatus.pending,
    this.rejectionReason,
    this.finalStatus = EnquiryFinalStatus.inProgress,
    this.settlementDate,
    this.finalNotes,
    this.createdAt,
  });

  double get totalOffered => (officialFee ?? 0) + (serviceChargeOffered ?? 0);

  int get daysOpen {
    final start = dateOfEnquiry ?? createdAt;
    if (start == null) return 0;
    final end = (finalStatus == EnquiryFinalStatus.settled || finalStatus == EnquiryFinalStatus.executed)
        ? (settlementDate ?? DateTime.now())
        : DateTime.now();
    return end.difference(start).inDays;
  }

  PerformanceRating get performanceRating {
    if (clientStatus == ClientStatus.rejected ||
        finalStatus == EnquiryFinalStatus.rejectedByClient ||
        finalStatus == EnquiryFinalStatus.cancelled) {
      return PerformanceRating.needsReview;
    }
    if (daysOpen <= 7) return PerformanceRating.excellent;
    if (daysOpen <= 14) return PerformanceRating.good;
    if (daysOpen <= 30) return PerformanceRating.average;
    return PerformanceRating.needsReview;
  }

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id'],
      enquiryCode: json['enquiry_code'] ?? '',
      clientName: json['client_name'],
      contactNumber: json['contact_number'],
      natureOfEnquiry: json['nature_of_enquiry'],
      dateOfEnquiry: json['date_of_enquiry'] != null ? DateTime.parse(json['date_of_enquiry']) : null,
      nationality: json['nationality'],
      officialFee: json['official_fee'] != null ? (json['official_fee'] as num).toDouble() : null,
      serviceChargeOffered: json['service_charge_offered'] != null ? (json['service_charge_offered'] as num).toDouble() : null,
      actionNotes: json['action_notes'],
      followUpDate: json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date']) : null,
      finalAgreedServiceCharge: json['final_agreed_service_charge'] != null ? (json['final_agreed_service_charge'] as num).toDouble() : null,
      responsibleStaffId: json['responsible_staff_id'],
      responsibleStaffName: json['profiles']?['name'],
      clientStatus: _parseClientStatus(json['client_status']),
      rejectionReason: json['rejection_reason'],
      finalStatus: _parseFinalStatus(json['final_status']),
      settlementDate: json['settlement_date'] != null ? DateTime.parse(json['settlement_date']) : null,
      finalNotes: json['final_notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'contact_number': contactNumber,
      'nature_of_enquiry': natureOfEnquiry,
      'date_of_enquiry': dateOfEnquiry?.toIso8601String(),
      'nationality': nationality,
      'official_fee': officialFee,
      'service_charge_offered': serviceChargeOffered,
      'action_notes': actionNotes,
      'follow_up_date': followUpDate?.toIso8601String(),
      'final_agreed_service_charge': finalAgreedServiceCharge,
      'responsible_staff_id': responsibleStaffId,
      'client_status': clientStatus.name,
      'rejection_reason': rejectionReason,
      'final_status': _finalStatusToString(finalStatus),
      'settlement_date': settlementDate?.toIso8601String(),
      'final_notes': finalNotes,
    };
  }

  static ClientStatus _parseClientStatus(String? s) {
    switch (s) {
      case 'accepted': return ClientStatus.accepted;
      case 'rejected': return ClientStatus.rejected;
      default: return ClientStatus.pending;
    }
  }

  static EnquiryFinalStatus _parseFinalStatus(String? s) {
    switch (s) {
      case 'Executed': return EnquiryFinalStatus.executed;
      case 'Settled': return EnquiryFinalStatus.settled;
      case 'Postponed by client': return EnquiryFinalStatus.postponedByClient;
      case 'Rejected by client': return EnquiryFinalStatus.rejectedByClient;
      case 'Cancelled': return EnquiryFinalStatus.cancelled;
      default: return EnquiryFinalStatus.inProgress;
    }
  }

  static String _finalStatusToString(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed: return 'Executed';
      case EnquiryFinalStatus.settled: return 'Settled';
      case EnquiryFinalStatus.postponedByClient: return 'Postponed by client';
      case EnquiryFinalStatus.rejectedByClient: return 'Rejected by client';
      case EnquiryFinalStatus.cancelled: return 'Cancelled';
      case EnquiryFinalStatus.inProgress: return 'In Progress';
    }
  }

  Enquiry copyWith({
    String? clientName,
    String? contactNumber,
    String? natureOfEnquiry,
    DateTime? dateOfEnquiry,
    String? nationality,
    double? officialFee,
    double? serviceChargeOffered,
    String? actionNotes,
    DateTime? followUpDate,
    double? finalAgreedServiceCharge,
    String? responsibleStaffId,
    String? responsibleStaffName,
    ClientStatus? clientStatus,
    String? rejectionReason,
    EnquiryFinalStatus? finalStatus,
    DateTime? settlementDate,
    String? finalNotes,
  }) {
    return Enquiry(
      id: id,
      enquiryCode: enquiryCode,
      clientName: clientName ?? this.clientName,
      contactNumber: contactNumber ?? this.contactNumber,
      natureOfEnquiry: natureOfEnquiry ?? this.natureOfEnquiry,
      dateOfEnquiry: dateOfEnquiry ?? this.dateOfEnquiry,
      nationality: nationality ?? this.nationality,
      officialFee: officialFee ?? this.officialFee,
      serviceChargeOffered: serviceChargeOffered ?? this.serviceChargeOffered,
      actionNotes: actionNotes ?? this.actionNotes,
      followUpDate: followUpDate ?? this.followUpDate,
      finalAgreedServiceCharge: finalAgreedServiceCharge ?? this.finalAgreedServiceCharge,
      responsibleStaffId: responsibleStaffId ?? this.responsibleStaffId,
      responsibleStaffName: responsibleStaffName ?? this.responsibleStaffName,
      clientStatus: clientStatus ?? this.clientStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      finalStatus: finalStatus ?? this.finalStatus,
      settlementDate: settlementDate ?? this.settlementDate,
      finalNotes: finalNotes ?? this.finalNotes,
      createdAt: createdAt,
    );
  }
}
