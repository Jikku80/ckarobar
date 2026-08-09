/// Mirrors dentaldb/types/index.ts `Invoice` / `InvoiceItem` / `InvoiceStatus`
/// / `PaymentMethod`.
library;

import 'recall.dart' show RecallPatientRef;

enum InvoiceStatus {
  draft,
  sent,
  paid,
  partiallyPaid,
  notYetPaid,
  overdue,
  cancelled,
  refunded;

  static InvoiceStatus fromJson(String? value) {
    switch (value) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially_paid':
        return InvoiceStatus.partiallyPaid;
      case 'not_yet_paid':
        return InvoiceStatus.notYetPaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'refunded':
        return InvoiceStatus.refunded;
      default:
        return InvoiceStatus.notYetPaid;
    }
  }

  String get wireValue => switch (this) {
        InvoiceStatus.draft => 'draft',
        InvoiceStatus.sent => 'sent',
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.partiallyPaid => 'partially_paid',
        InvoiceStatus.notYetPaid => 'not_yet_paid',
        InvoiceStatus.overdue => 'overdue',
        InvoiceStatus.cancelled => 'cancelled',
        InvoiceStatus.refunded => 'refunded',
      };

  String get label => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.sent => 'Sent',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.partiallyPaid => 'Partially paid',
        InvoiceStatus.notYetPaid => 'Not yet paid',
        InvoiceStatus.overdue => 'Overdue',
        InvoiceStatus.cancelled => 'Cancelled',
        InvoiceStatus.refunded => 'Refunded',
      };
}

enum PaymentMethod {
  cash,
  esewa,
  khalti,
  paypal,
  bankTransfer,
  insurance,
  walletCredit,
  walletDebit;

  static PaymentMethod fromJson(String? value) {
    switch (value) {
      case 'esewa':
        return PaymentMethod.esewa;
      case 'khalti':
        return PaymentMethod.khalti;
      case 'paypal':
        return PaymentMethod.paypal;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'insurance':
        return PaymentMethod.insurance;
      case 'wallet_credit':
        return PaymentMethod.walletCredit;
      case 'wallet_debit':
        return PaymentMethod.walletDebit;
      default:
        return PaymentMethod.cash;
    }
  }

  String get wireValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.esewa => 'esewa',
        PaymentMethod.khalti => 'khalti',
        PaymentMethod.paypal => 'paypal',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.insurance => 'insurance',
        PaymentMethod.walletCredit => 'wallet_credit',
        PaymentMethod.walletDebit => 'wallet_debit',
      };

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.esewa => 'eSewa',
        PaymentMethod.khalti => 'Khalti',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.bankTransfer => 'Bank transfer',
        PaymentMethod.insurance => 'Insurance',
        PaymentMethod.walletCredit => 'Wallet credit',
        PaymentMethod.walletDebit => 'Patient wallet',
      };
}

class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const InvoiceItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class Invoice {
  final String id;
  final String clinicId;
  final String? branchId;
  final String invoiceNumber;
  final String patientId;
  final RecallPatientRef? patient;
  final String? appointmentId;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double paidAmount;
  final double dueAmount;
  final InvoiceStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentTransactionId;
  final String? paidAt;
  final String? dueDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const Invoice({
    required this.id,
    required this.clinicId,
    this.branchId,
    required this.invoiceNumber,
    required this.patientId,
    this.patient,
    this.appointmentId,
    this.items = const [],
    this.subtotal = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.status = InvoiceStatus.notYetPaid,
    this.paymentMethod,
    this.paymentTransactionId,
    this.paidAt,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patient: json['patient'] != null
          ? RecallPatientRef.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      appointmentId: json['appointmentId'] as String?,
      items: (json['items'] as List? ?? const [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.fromJson(json['status'] as String?),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromJson(json['paymentMethod'] as String?)
          : null,
      paymentTransactionId: json['paymentTransactionId'] as String?,
      paidAt: json['paidAt'] as String?,
      dueDate: json['dueDate'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}