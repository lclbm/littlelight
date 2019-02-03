import 'dart:async';

import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:flutter/material.dart';
import 'package:little_light/services/inventory/inventory.service.dart';
import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:shimmer/shimmer.dart';

class InventoryNotificationWidget extends StatefulWidget {
  final profile = ProfileService();
  final inventory = InventoryService();
  final double barHeight;

  InventoryNotificationWidget(
      {Key key, this.barHeight = kBottomNavigationBarHeight})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return InventoryNotificationWidgetState();
  }
}

class InventoryNotificationWidgetState
    extends State<InventoryNotificationWidget> {
  bool _busy = false;
  String _message = "";
  Widget infoIcons;
  StreamSubscription<ProfileEvent> profileSubscription;
  StreamSubscription<InventoryEvent> inventorySubscription;

  @override
  void initState() {
    super.initState();
    profileSubscription = widget.profile.broadcaster.listen((event) {
      handleProfileEvent(event);
    });

    inventorySubscription = widget.inventory.broadcaster.listen((event) {
      handleInventoryEvent(event);
    });
  }

  void handleProfileEvent(ProfileEvent event) {
    bool busy;
    String message;
    if (event.type == ProfileEventType.requestedUpdate) {
      busy = true;
      message = "Updating";
    }
    if (event.type == ProfileEventType.receivedUpdate) {
      busy = false;
    }

    if (busy != null) {
      setState(() {
        _message = message;
        _busy = busy;
        infoIcons = null;
      });
    }
  }

  void handleInventoryEvent(InventoryEvent event) {
    String message;
    if (event.type == InventoryEventType.requestedTransfer) {
      message = "Transferring";
      var character = widget.profile.getCharacter(event.characterId);
      infoIcons = Row(children: [
        SizedBox(
            width: 24,
            height: 24,
            key:Key("item_${event.item.itemHash}"),
            child: ManifestImageWidget<DestinyInventoryItemDefinition>(
                event.item.itemHash)),
        Icon(Icons.chevron_right),
        SizedBox(
            width: 24,
            height: 24,
            key:Key("character_${event.characterId}"),
            child: ManifestImageWidget<DestinyInventoryItemDefinition>(
                character.emblemHash)),
      ]);
    }

    if (event.type == InventoryEventType.requestedEquip) {
      message = "Equipping";
      infoIcons = null;
    }

    setState(() {
      _message = message;
      _busy = true;
    });
  }

  @override
  void dispose() {
    profileSubscription.cancel();
    inventorySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: bottomPadding + widget.barHeight * 2,
        child: IgnorePointer(
            child: AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                firstChild: Container(
                    alignment: Alignment.bottomCenter,
                    child: idleWidget(context),
                    height: bottomPadding + widget.barHeight * 2),
                secondChild: Container(
                    child: busyWidget(context),
                    height: bottomPadding + widget.barHeight * 2),
                crossFadeState: _busy
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst)));
  }

  Widget idleWidget(context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(fit: StackFit.expand, children: [
      Positioned(
          left: 0,
          right: 0,
          height: 2,
          bottom: bottomPadding + widget.barHeight,
          child: Container(
            color: Colors.blueGrey.shade700,
          ))
    ]);
  }

  Widget busyWidget(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    List<Widget> stackChildren = [
      Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding + widget.barHeight,
          child: shimmerBar(context)),
      Positioned(
          right: 8,
          bottom: bottomPadding + widget.barHeight + 10,
          child: busyText(context)),
    ];
    if (bottomPadding > 1) {
      stackChildren.add(Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: bottomPadding,
        child: bottomPaddingShimmer(context),
      ));
    }
    return Stack(fit: StackFit.expand, children: stackChildren);
  }

  Widget busyText(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade900.withOpacity(.9),
            borderRadius: BorderRadius.all(Radius.circular(16))),
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Shimmer.fromColors(
              baseColor: Colors.blueGrey.shade400,
              highlightColor: Colors.grey.shade100,
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: TranslatedTextWidget(_message,
                      key: Key("inventory_notification_text_$_message"),
                      uppercase: true,
                      style: TextStyle(fontWeight: FontWeight.w700)))),
          busyIcons(context)
        ]));
  }

  Widget busyIcons(BuildContext context) {
    if (infoIcons == null) return Container();
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4), child: infoIcons);
  }

  Widget shimmerBar(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.blueGrey.shade700,
        highlightColor: Colors.grey.shade100,
        child: Container(height: 2, color: Colors.white));
  }

  Widget bottomPaddingShimmer(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.transparent,
        highlightColor: Colors.grey.shade300,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
        ));
  }
}
