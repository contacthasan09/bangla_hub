import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/widgets/common/login_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuestAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String featureName;
  final String? loginMessage;

  const GuestAwareButton({
    Key? key,
    required this.child,
    this.onPressed,
    required this.featureName,
    this.loginMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return GestureDetector(
          onTap: () {
            if (authProvider.isGuestMode || authProvider.user == null) {
              showDialog(
                context: context,
                builder: (context) => LoginRequiredDialog(
                  featureName: featureName,
                  message: loginMessage ?? 'Please login to view details',
                ),
              );
            } else {
              if (onPressed != null) {
                onPressed!();
              }
            }
          },
          child: child,
        );
      },
    );
  }
}