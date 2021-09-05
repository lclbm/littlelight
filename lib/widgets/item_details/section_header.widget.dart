import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:little_light/core/providers/user_settings/user_settings.consumer.dart';

import 'package:little_light/widgets/common/header.wiget.dart';

mixin VisibleSectionMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, UserSettingsConsumerState<T> {
  String get sectionId;

  bool get visible => userSettings.getVisibilityForDetailsSection(sectionId);

  Widget getHeader(Widget label) {
    return SectionHeaderWidget(
      label: label,
      sectionId: sectionId,
      onChanged: () {
        print(visible);
        setState(() {});
      },
    );
  }
}

class SectionHeaderWidget extends ConsumerStatefulWidget {
  final int hash;
  final Function onChanged;
  final Widget label;
  final String sectionId;
  SectionHeaderWidget({
    this.label,
    this.hash,
    this.onChanged,
    @required this.sectionId,
    Key key,
  }) : super(key: key);
  @override
  SectionHeaderWidgetState createState() => new SectionHeaderWidgetState();
}

class SectionHeaderWidgetState<T extends SectionHeaderWidget>
    extends ConsumerState<T> with UserSettingsConsumerState {
  bool visible = true;

  @override
  void initState() {
    super.initState();
    visible =
        userSettings.getVisibilityForDetailsSection(widget.sectionId) ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return HeaderWidget(
        child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Expanded(child: widget.label), buildTrailing(context)]));
  }

  Widget buildTrailing(BuildContext context) {
    return InkWell(
        onTap: () {
          visible = !visible;
          userSettings.setVisibilityForDetailsSection(
              widget.sectionId, visible);
          setState(() {});
          widget.onChanged?.call();
        },
        child: buildTrailingIcon(context));
  }

  Widget buildTrailingIcon(BuildContext context) {
    if (visible == false) {
      return Icon(FontAwesomeIcons.eyeSlash);
    }
    return Icon(FontAwesomeIcons.eye);
  }
}
