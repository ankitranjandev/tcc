import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive text widget that automatically scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final bool autoScale;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.autoScale = true,
  });

  factory ResponsiveText.headline(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return ResponsiveText(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      mobileFontSize: 24,
      tabletFontSize: 28,
      desktopFontSize: 32,
    );
  }

  factory ResponsiveText.title(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return ResponsiveText(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      mobileFontSize: 20,
      tabletFontSize: 22,
      desktopFontSize: 24,
    );
  }

  factory ResponsiveText.body(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return ResponsiveText(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      mobileFontSize: 14,
      tabletFontSize: 16,
      desktopFontSize: 16,
    );
  }

  factory ResponsiveText.caption(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return ResponsiveText(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      mobileFontSize: 12,
      tabletFontSize: 13,
      desktopFontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!autoScale) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final baseFontSize = style?.fontSize ?? 14.0;
    final responsiveFontSize = ResponsiveHelper.getFontSize(
      context,
      mobile: mobileFontSize ?? baseFontSize,
      tablet: tabletFontSize ?? (mobileFontSize ?? baseFontSize) * 1.1,
      desktop: desktopFontSize ?? (mobileFontSize ?? baseFontSize) * 1.2,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Auto-sizing text that fits within its bounds
class AutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double minFontSize;
  final double maxFontSize;
  final double stepGranularity;
  final TextAlign? textAlign;
  final int? maxLines;

  const AutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = style ?? DefaultTextStyle.of(context).style;
        double fontSize = textStyle.fontSize ?? 14.0;

        if (fontSize > maxFontSize) {
          fontSize = maxFontSize;
        }

        // Calculate if text fits
        while (fontSize > minFontSize) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: textStyle.copyWith(fontSize: fontSize),
            ),
            maxLines: maxLines,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          if (textPainter.didExceedMaxLines ||
              textPainter.height > constraints.maxHeight) {
            fontSize -= stepGranularity;
          } else {
            break;
          }
        }

        return Text(
          text,
          style: textStyle.copyWith(fontSize: fontSize),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}