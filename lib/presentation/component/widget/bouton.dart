import 'package:flutter/material.dart';

class Bouton extends StatelessWidget {
  final String texte;
  final Color? background;
  final Color? couleur;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final double height;

  const Bouton({
    super.key,
    required this.texte,
    this.couleur,
    this.background,
    this.onTap,
    this.isLoading = false,
    this.width = 200.0,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser le thème si les couleurs ne sont pas fournies
    final bgColor = background ?? Theme.of(context).colorScheme.primary;
    final textColor = couleur ?? Theme.of(context).colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Center(
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.transparent, width: 2.0),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Text(
                      texte,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}