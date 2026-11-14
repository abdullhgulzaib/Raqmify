import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../models/net_settlement_model.dart';
import '../../../models/split_expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/split_provider.dart';

class SettlementProofModal {
  // Helper to convert an image file to a base64 data URL string
  static Future<String?> _fileToBase64DataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 1.5 * 1024 * 1024) {
      throw Exception('Receipt image size exceeds 1.5 MB. Please select a smaller photo.');
    }
    final isPng = file.path.toLowerCase().endsWith('.png');
    final mime = isPng ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  // Helper widget to display either base64 or network image safely
  static Widget _buildImageWidget(String imageUrl, {double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
        );
      } catch (_) {
        return _buildImageErrorPlaceholder();
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
      );
    }
    return _buildImageErrorPlaceholder();
  }

  static Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 80,
      color: Colors.grey.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        'Receipt image could not be loaded',
        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }

  // --- 1. Net Settlement Submission Dialog (Debtor) ---
  static void showSubmitNetSettlementProof({
    required BuildContext context,
    required String toUserId,
    required String creditorName,
    required double amount,
    String? groupId,
    required String currentUserId,
  }) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final tidController = TextEditingController();
    final noteController = TextEditingController();
    String method = 'Easypaisa';
    XFile? pickedReceipt;
    bool isSubmitting = false;
    String? errorMessage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.darkInk;
          final inputBg = isDark ? const Color(0xFF24322F) : AppColors.surfaceSubtle;
          final borderColor = isDark ? const Color(0xFF2C3E38) : const Color(0xFFE2EAE5);

          Future<void> pickImage(ImageSource source) async {
            try {
              final file = await picker.pickImage(
                source: source,
                imageQuality: 80,
                maxWidth: 1280,
                maxHeight: 1280,
              );
              if (file != null) {
                setDialogState(() {
                  pickedReceipt = file;
                  errorMessage = null;
                });
              }
            } catch (_) {
              setDialogState(() {
                errorMessage = 'Could not access camera or gallery.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Settle Net Balance',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net settlement payment to $creditorName:',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs ${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    dropdownColor: dialogBg,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textMuted),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['Easypaisa', 'JazzCash', 'Bank Transfer', 'Cash', 'Raast', 'SadaPay', 'NayaPay'].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            if (val != null) setDialogState(() => method = val);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tidController,
                    enabled: !isSubmitting,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Transaction ID / TID (e.g. EP-9831772)',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(AppIcons.receipt, color: AppColors.deepEmerald),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    enabled: !isSubmitting,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Note (Optional, e.g. Sent via Raast)',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.deepEmerald),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Receipt Picture Section
                  Text(
                    'Payment Receipt / Screenshot',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.darkInk,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (pickedReceipt == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepEmerald,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: Text('Gallery', style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepEmerald,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: Text('Camera', style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(pickedReceipt!.path),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedReceipt!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready to attach',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.errorRed),
                            onPressed: isSubmitting
                                ? null
                                : () => setDialogState(() => pickedReceipt = null),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final tid = tidController.text.trim();
                        if (tid.isEmpty && pickedReceipt == null) {
                          setDialogState(() {
                            errorMessage = 'Please enter a Transaction ID or attach a receipt image.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });

                        String? base64Img;
                        if (pickedReceipt != null) {
                          try {
                            base64Img = await _fileToBase64DataUrl(pickedReceipt!);
                          } catch (err) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = err.toString().replaceAll('Exception: ', '');
                            });
                            return;
                          }
                        }

                        final result = await splitProvider.createSettlement(
                          toUserId: toUserId,
                          groupId: groupId,
                          amount: amount,
                          method: method,
                          transactionId: tid,
                          imageUrl: base64Img,
                          senderNote: noteController.text.trim(),
                          currentUserId: currentUserId,
                        );

                        if (!ctx.mounted) return;

                        if (result.isSuccess) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Settlement proof submitted for Rs ${amount.toStringAsFixed(2)}. Awaiting verification.'),
                                backgroundColor: AppColors.deepEmerald,
                              ),
                            );
                          }
                        } else {
                          final failMsg = result.failureOrNull?.message ?? 'Failed to submit settlement proof.';
                          setDialogState(() {
                            isSubmitting = false;
                            if (failMsg.toLowerCase().contains('balance changed')) {
                              errorMessage = 'Balances changed, please review the new amount.';
                            } else {
                              errorMessage = failMsg;
                            }
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Settlement'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 2. Net Settlement Review Dialog (Creditor) ---
  static void showReviewNetSettlement({
    required BuildContext context,
    required SettlementModel settlement,
    required String currentUserId,
  }) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    bool isProcessing = false;
    String? inlineError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.darkInk;
          final containerBg = isDark ? const Color(0xFF16322B) : AppColors.lightEmerald;
          final proof = settlement.proof;
          final hasProofImage = proof?.imageUrl != null && proof!.imageUrl.isNotEmpty;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Review Settlement Proof',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${settlement.fromUserName} claims payment:',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Net Amount:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              'Rs ${settlement.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Method:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              proof?.method ?? 'Easypaisa',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Transaction ID:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              proof?.transactionId.isNotEmpty == true ? proof!.transactionId : 'None provided',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF4FD1C5) : AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                        if (proof?.senderNote != null && proof!.senderNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Note:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                              Flexible(
                                child: Text(
                                  proof.senderNote,
                                  style: GoogleFonts.outfit(fontSize: 12, color: textColor),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Receipt Picture Preview
                  if (hasProofImage) ...[
                    Text(
                      'Receipt Image (Tap to zoom)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showFullScreenReceipt(context, proof.imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _buildImageWidget(proof.imageUrl, height: 120),
                            Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pinch & Zoom',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.image_not_supported_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'No receipt image attached',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],

                  if (inlineError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      inlineError!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    'Verify funds received before approving. Approval clears mutual balances.',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Ask for rejection reason
                        final reasonController = TextEditingController();
                        final reasonResult = await showDialog<String>(
                          context: context,
                          builder: (rCtx) => AlertDialog(
                            backgroundColor: dialogBg,
                            title: Text('Reason for Rejection', style: TextStyle(color: textColor)),
                            content: TextField(
                              controller: reasonController,
                              style: TextStyle(color: textColor),
                              decoration: const InputDecoration(
                                hintText: 'e.g. Transaction ID not found or invalid amount',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(rCtx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                onPressed: () => Navigator.pop(rCtx, reasonController.text.trim()),
                                child: const Text('Reject', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (reasonResult == null) return;

                        setDialogState(() {
                          isProcessing = true;
                          inlineError = null;
                        });

                        final res = await splitProvider.verifySettlement(
                          settlementId: settlement.id,
                          approve: false,
                          reason: reasonResult,
                          currentUserId: currentUserId,
                        );

                        if (!ctx.mounted) return;

                        if (res.isSuccess) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settlement rejected. Debtor notified to re-submit.'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isProcessing = false;
                            inlineError = res.failureOrNull?.message ?? 'Failed to reject settlement.';
                          });
                        }
                      },
                child: const Text('Reject', style: TextStyle(color: AppColors.errorRed)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() {
                          isProcessing = true;
                          inlineError = null;
                        });

                        final result = await splitProvider.verifySettlement(
                          settlementId: settlement.id,
                          approve: true,
                          currentUserId: currentUserId,
                        );

                        if (!ctx.mounted) return;

                        if (result.isSuccess) {
                          // Await server confirmation, then refresh personal expenses list
                          unawaited(expenseProvider.fetchExpenses());
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settlement approved! All mutual debts cleared and recorded.'),
                                backgroundColor: AppColors.deepEmerald,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isProcessing = false;
                            inlineError = result.failureOrNull?.message ?? 'Failed to approve settlement.';
                          });
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Approve & Clear'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 3. Per-Split Proof Submission Dialog (Activity View) ---
  static void showSubmitProof({
    required BuildContext context,
    required String expenseId,
    required String expenseTitle,
    required String creditorName,
    required double amount,
    required String userId,
  }) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final tidController = TextEditingController();
    String method = 'Easypaisa';
    XFile? pickedReceipt;
    bool isSubmitting = false;
    String? errorMessage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.darkInk;
          final inputBg = isDark ? const Color(0xFF24322F) : AppColors.surfaceSubtle;
          final borderColor = isDark ? const Color(0xFF2C3E38) : const Color(0xFFE2EAE5);

          Future<void> pickImage(ImageSource source) async {
            try {
              final file = await picker.pickImage(
                source: source,
                imageQuality: 80,
                maxWidth: 1280,
                maxHeight: 1280,
              );
              if (file != null) {
                setDialogState(() {
                  pickedReceipt = file;
                  errorMessage = null;
                });
              }
            } catch (_) {
              setDialogState(() {
                errorMessage = 'Could not access camera or gallery.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Submit Settlement Proof',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settling share for "$expenseTitle":',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs ${amount.toStringAsFixed(2)} owed to $creditorName',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    dropdownColor: dialogBg,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textMuted),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['Easypaisa', 'JazzCash', 'Bank Transfer', 'Cash', 'Raast', 'SadaPay', 'NayaPay'].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            if (val != null) setDialogState(() => method = val);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tidController,
                    enabled: !isSubmitting,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Transaction ID / Receipt # (e.g. EP-9831772)',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(AppIcons.receipt, color: AppColors.deepEmerald),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Receipt Picture Section
                  Text(
                    'Payment Receipt / Screenshot',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.darkInk,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (pickedReceipt == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepEmerald,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: Text('Gallery', style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepEmerald,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: Text('Camera', style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(pickedReceipt!.path),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedReceipt!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready to attach',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.errorRed),
                            onPressed: isSubmitting
                                ? null
                                : () => setDialogState(() => pickedReceipt = null),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final tid = tidController.text.trim();
                        if (tid.isEmpty && pickedReceipt == null) {
                          setDialogState(() {
                            errorMessage = 'Please enter a Transaction ID or attach a receipt image.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });

                        String? base64Img;
                        if (pickedReceipt != null) {
                          try {
                            base64Img = await _fileToBase64DataUrl(pickedReceipt!);
                          } catch (err) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = err.toString().replaceAll('Exception: ', '');
                            });
                            return;
                          }
                        }

                        final result = await splitProvider.submitProof(
                          expenseId: expenseId,
                          userId: userId,
                          transactionId: tid,
                          paymentMethod: method,
                          imageUrl: base64Img,
                        );

                        if (!ctx.mounted) return;

                        if (result.isSuccess) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Proof TID $tid submitted for verification.'),
                                backgroundColor: AppColors.deepEmerald,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = result.failureOrNull?.message ?? 'Failed to submit proof. Try again.';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Proof'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 4. Per-Split Proof Review Dialog (Activity View) ---
  static void showReviewProof({
    required BuildContext context,
    required SplitExpenseModel expense,
    required SplitMemberShare share,
  }) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    bool isProcessing = false;
    String? inlineError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.darkInk;
          final containerBg = isDark ? const Color(0xFF16322B) : AppColors.lightEmerald;
          final hasProofImage = share.proofImageUrl != null && share.proofImageUrl!.isNotEmpty;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Review Settlement Proof',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${share.name} claims payment for "${expense.title}":',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount Claimed:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              'Rs ${share.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Method:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              share.paymentMethod ?? 'Easypaisa',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Transaction ID:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            Text(
                              share.proofTid ?? 'None',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF4FD1C5) : AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Receipt Picture Preview
                  if (hasProofImage) ...[
                    Text(
                      'Receipt Image (Tap to zoom)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showFullScreenReceipt(context, share.proofImageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _buildImageWidget(share.proofImageUrl!, height: 120),
                            Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pinch & Zoom',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.image_not_supported_outlined, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'No receipt image attached',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],

                  if (inlineError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      inlineError!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    'Verify against your wallet or bank statement before confirming.',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() {
                          isProcessing = true;
                          inlineError = null;
                        });

                        final res = await splitProvider.verifyProof(
                          expenseId: expense.id,
                          userId: share.userId,
                          approve: false,
                        );

                        if (!ctx.mounted) return;

                        if (res.isSuccess) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment marked as rejected.'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isProcessing = false;
                            inlineError = res.failureOrNull?.message ?? 'Failed to reject proof.';
                          });
                        }
                      },
                child: const Text('Reject', style: TextStyle(color: AppColors.errorRed)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() {
                          isProcessing = true;
                          inlineError = null;
                        });

                        final result = await splitProvider.verifyProof(
                          expenseId: expense.id,
                          userId: share.userId,
                          approve: true,
                        );

                        if (!ctx.mounted) return;

                        if (result.isSuccess) {
                          // Refresh personal expenses list
                          unawaited(expenseProvider.fetchExpenses());
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment verified and marked Settled.'),
                                backgroundColor: AppColors.deepEmerald,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isProcessing = false;
                            inlineError = result.failureOrNull?.message ?? 'Failed to verify payment.';
                          });
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Settle'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Full Screen Zoomable Viewer ---
  static void _showFullScreenReceipt(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: _buildImageWidget(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
