import '../models/transaction.dart';

class SMSParserService {
  static Transaction? parseSBIMessage(String body, String sender) {
    if (body.toLowerCase().contains('credited') ||
        body.toLowerCase().contains('debited')) {
      // First pattern (UPI user format)
      final RegExp upiAccountRegex =
          RegExp(r'A/C\s+([X\d]+)', caseSensitive: false);
      final RegExp upiAmountRegex =
          RegExp(r'debited by (\d+(?:\.\d{1,2})?)', caseSensitive: false);
      final RegExp upiDateRegex =
          RegExp(r'on date (\d{2}\w{3}\d{2})', caseSensitive: false);
      final RegExp upiReceiverRegex =
          RegExp(r'trf to ([A-Za-z\s]+)(?=\s+Ref)', caseSensitive: false);
      final RegExp upiRefRegex = RegExp(r'Refno (\d+)', caseSensitive: false);

      // Second pattern (original format)
      final RegExp amountRegex =
          RegExp(r'Rs\.?(\d+(?:\.\d{1,2})?)', caseSensitive: false);
      final RegExp dateRegex =
          RegExp(r'on (\d{2}\w{3}\d{2})', caseSensitive: false);
      final RegExp refRegex =
          RegExp(r'(?:Ref No|RefNo|ref)\.?\s*(\d+)', caseSensitive: false);
      final RegExp partyRegex = RegExp(
          r'(?:from|to)\s+([A-Za-z\s]+?)(?=\s+(?:Ref|on|UPI|$))',
          caseSensitive: false);

      // Extract bank name from message ending
      final RegExp bankRegex = RegExp(r'-([^-]+)$', caseSensitive: false);
      final bankMatch = bankRegex.firstMatch(body);
      final bankName = bankMatch?.group(1)?.trim() ?? 'SBI';

      // Try UPI format first
      final accountMatch = upiAccountRegex.firstMatch(body);
      final upiAmountMatch = upiAmountRegex.firstMatch(body);
      final upiDateMatch = upiDateRegex.firstMatch(body);
      final upiReceiverMatch = upiReceiverRegex.firstMatch(body);
      final upiRefMatch = upiRefRegex.firstMatch(body);

      if (accountMatch != null &&
          upiAmountMatch != null &&
          upiDateMatch != null) {
        return Transaction(
          amount: double.parse(upiAmountMatch.group(1)!),
          date: upiDateMatch.group(1)!,
          refNo: upiRefMatch?.group(1) ?? '',
          bank: bankName,
          type: 'Debit',
          accountNumber: accountMatch.group(1) ?? '',
          receiverName: upiReceiverMatch?.group(1)?.trim(),
        );
      }

      // Try original format
      final amount = amountRegex.firstMatch(body)?.group(1);
      final date = dateRegex.firstMatch(body)?.group(1);
      final refNo = refRegex.firstMatch(body)?.group(1);
      final partyMatch = partyRegex.firstMatch(body);

      if (amount != null && date != null) {
        final isCredit = body.toLowerCase().contains('credited');
        return Transaction(
          amount: double.parse(amount),
          date: date,
          refNo: refNo ?? '',
          bank: bankName,
          type: isCredit ? 'Credit' : 'Debit',
          receiverName: partyMatch?.group(1)?.trim(),
        );
      }
    }
    return null;
  }

  static Transaction? parseKeralaGraminMessage(String body, String sender) {
    // Regular expressions for different formats
    final RegExp accountRegex1 =
        RegExp(r'A/c\s+([X\d]+)', caseSensitive: false);
    final RegExp accountRegex2 =
        RegExp(r'Account\s+([X\d]+)', caseSensitive: false);

    final RegExp amountRegex1 =
        RegExp(r'Rs\.?(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final RegExp amountRegex2 =
        RegExp(r'INR\s+(\d+(?:\.\d{1,2})?)', caseSensitive: false);

    final RegExp balanceRegex = RegExp(
        r'Bal(?:ance)?\s+(?:after\s+txn\s+)?Rs\s*(\d+(?:\.\d{2})?)',
        caseSensitive: false);

    // Two date formats
    final RegExp dateRegex1 =
        RegExp(r'Time\s+(\d{2}-\d{2}-\d{4})', caseSensitive: false);
    final RegExp dateRegex2 =
        RegExp(r'on\s+(\d{2}-\d{2}-\d{4})', caseSensitive: false);

    final RegExp msgIdRegex = RegExp(r'Msg Id\s+(\d+)', caseSensitive: false);
    final RegExp upiRefRegex =
        RegExp(r'UPI Ref\. no\.\s+([^\s-]+)', caseSensitive: false);
    final RegExp senderRegex = RegExp(r'from\s+([^\s]+)', caseSensitive: false);

    // Extract bank name
    final RegExp bankRegex = RegExp(r'-([^-]+)$', caseSensitive: false);
    final bankMatch = bankRegex.firstMatch(body);
    final bankName = bankMatch?.group(1)?.trim() ?? 'Kerala Gramin Bank';

    // Try to match account number
    final accountMatch =
        accountRegex1.firstMatch(body) ?? accountRegex2.firstMatch(body);

    // Try to match amount
    final amountMatch =
        amountRegex1.firstMatch(body) ?? amountRegex2.firstMatch(body);

    // Try to match date
    final dateMatch =
        dateRegex1.firstMatch(body) ?? dateRegex2.firstMatch(body);

    final balanceMatch = balanceRegex.firstMatch(body);
    final msgIdMatch = msgIdRegex.firstMatch(body);
    final upiRefMatch = upiRefRegex.firstMatch(body);
    final senderMatch = senderRegex.firstMatch(body);

    if (amountMatch != null && dateMatch != null) {
      return Transaction(
        amount: double.parse(amountMatch.group(1)!),
        date: dateMatch.group(1)!,
        refNo: upiRefMatch?.group(1) ?? msgIdMatch?.group(1) ?? '',
        bank: bankName,
        type: body.toLowerCase().contains('credited') ? 'Credit' : 'Debit',
        accountNumber: accountMatch?.group(1) ?? '',
        balance:
            balanceMatch != null ? double.parse(balanceMatch.group(1)!) : null,
        receiverName: senderMatch?.group(1),
      );
    }
    return null;
  }

  static Transaction? parseMessage(String body, String sender) {
    // Try SBI format first
    if (body.endsWith('-SBI') || sender.toUpperCase().contains('SBI')) {
      return parseSBIMessage(body, sender);
    }
    // Try Kerala Gramin Bank format
    else if (body.contains('Kerala Gramin Bank')) {
      return parseKeralaGraminMessage(body, sender);
    }
    return null;
  }
}
