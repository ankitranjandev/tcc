import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A widget that rebuilds based on screen size breakpoints
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType)? builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : assert(
          builder != null || (mobile != null),
          'Either builder or mobile must be provided',
        ),
        super();

  factory ResponsiveBuilder.withScreens({
    Key? key,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return ResponsiveBuilder(
      key: key,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceType(context);

        // If custom builder is provided, use it
        if (builder != null) {
          return builder!(context, deviceType);
        }

        // Otherwise use the predefined widgets
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile!;
          case DeviceType.tablet:
            return tablet ?? mobile!;
          case DeviceType.smallDesktop:
          case DeviceType.largeDesktop:
            return desktop ?? tablet ?? mobile!;
        }
      },
    );
  }
}

/// A responsive container that adapts its constraints based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getResponsiveValue<double>(
      context,
      mobile: double.infinity,
      tablet: 768,
      desktop: 1200,
    );

    final responsivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);

    return Container(
      alignment: alignment ?? Alignment.center,
      margin: margin,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: responsiveMaxWidth,
        ),
        padding: responsivePadding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// A responsive row that can switch to column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool columnOnMobile;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.columnOnMobile = true,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (columnOnMobile && isMobile) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _buildChildrenWithSpacing(true),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: _buildChildrenWithSpacing(false),
    );
  }

  List<Widget> _buildChildrenWithSpacing(bool isColumn) {
    if (spacing <= 0) return children;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          SizedBox(
            width: isColumn ? 0 : spacing,
            height: isColumn ? spacing : 0,
          ),
        );
      }
    }
    return spacedChildren;
  }
}

/// A responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumns(
      context,
      mobileColumns: mobileColumns ?? 2,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}