import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final double? height;
  final FontStyle? fontStyle;
  final TextDirection? textDirection;
  final TextBaseline? textBaseline;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Locale? locale;
  final bool? softWrap;

  const CustomText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color ,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.letterSpacing,
    this.height,
    this.fontStyle,
    this.textDirection,
    this.textBaseline,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.locale,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {



    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      textDirection: textDirection,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      softWrap: softWrap,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,

        decoration: decoration,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
        textBaseline: textBaseline,
        locale: locale,
      ),
    );
  }
}