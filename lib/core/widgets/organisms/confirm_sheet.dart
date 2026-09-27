import 'package:flutter/material.dart';

import '../molecules/main_button.dart';
import 'app_bottom_sheet.dart';

/// Asks before something that cannot be taken back — 18e's "Delete this
/// line?", a form's "Discard changes?". `true` only when [confirmLabel] was
/// tapped; dismissing the sheet counts as keeping things as they are.
///
/// [destructive] draws the confirm button in the danger colour, as 18e does.
/// [recap] sits between the text and the buttons — what is about to go.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  Widget? recap,
}) async {
  final bool? confirmed = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheetContext) => AppSheetScaffold(
      title: title,
      subtitle: message,
      body: recap ?? const SizedBox.shrink(),
      actions: <Widget>[
        MainButton(
          label: confirmLabel,
          tone: destructive ? MainButtonTone.danger : MainButtonTone.normal,
          onPressed: () => Navigator.pop(sheetContext, true),
        ),
        MainButton(
          label: cancelLabel,
          style: MainButtonStyle.ghost,
          onPressed: () => Navigator.pop(sheetContext, false),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
