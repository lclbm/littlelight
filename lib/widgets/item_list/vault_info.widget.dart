import 'package:bungie_api/models/destiny_character_component.dart';
import 'package:bungie_api/models/destiny_inventory_bucket_definition.dart';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_vendor_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:little_light/core/providers/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/core/providers/inventory/inventory.consumer.dart';
import 'package:little_light/core/providers/inventory/transfer_destination.dart';
import 'package:little_light/core/providers/loadouts/loadouts.consumer.dart';
import 'package:little_light/models/loadout.dart';

import 'package:little_light/services/profile/profile.service.dart';
import 'package:little_light/utils/inventory_utils.dart';
import 'package:little_light/utils/item_with_owner.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/item_list/character_info.widget.dart';
import 'package:little_light/widgets/option_sheets/loadout_select_sheet.widget.dart';

class VaultInfoWidget extends CharacterInfoWidget {
  final ProfileService profile = ProfileService(
    
  );
  

  VaultInfoWidget({Key key}) : super(key: key);

  @override
  createState() {
    return VaultInfoWidgetState();
  }
}

class VaultInfoWidgetState extends CharacterInfoWidgetState<VaultInfoWidget>
    with LoadoutsConsumerState {
  @override
  void initState() {
    super.initState();
  }

  @override
  loadDefinitions() {}

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      mainCharacterInfo(context, character),
      Positioned.fill(
        bottom: 16,
        child: ghostIcon(context),
      ),
      currencyInfo(context),
      characterStatsInfo(context, null),
      Positioned.fill(
          child: MaterialButton(
              child: Container(),
              onPressed: () {
                showOptionsSheet(context);
              }))
    ]);
  }

  Widget mainCharacterInfo(
      BuildContext context, DestinyCharacterComponent character) {
    return Positioned(
        top: 0,
        left: 8,
        bottom: 16,
        child: Container(
          alignment: Alignment.centerLeft,
          child: ManifestText<DestinyVendorDefinition>(1037843411,
              uppercase: true,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        ));
  }

  Widget characterStatsInfo(
      BuildContext context, DestinyCharacterComponent character) {
    int itemCount = widget.profile
        .getAllItems()
        .where((i) => i.bucketHash == InventoryBucket.general)
        .length;
    return Positioned(
      right: 8,
      top: 0,
      bottom: 16,
      child: Container(
          alignment: Alignment.centerRight,
          child: ManifestText<DestinyInventoryBucketDefinition>(
              InventoryBucket.general,
              textExtractor: (def) => "$itemCount/${def.itemCount}",
              key: Key("$itemCount"),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
    );
  }

  showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return VaultOptionsSheet();
        });
  }
}

class VaultOptionsSheet extends ConsumerStatefulWidget {
  final ProfileService profile = ProfileService();

  VaultOptionsSheet({Key key}) : super(key: key);

  @override
  createState() {
    return VaultOptionsSheetState();
  }
}

class VaultOptionsSheetState extends ConsumerState<VaultOptionsSheet>
    with LoadoutsConsumerState, InventoryConsumerState {
  final TextStyle buttonStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

  List<Loadout> loadouts;
  List<DestinyItemComponent> itemsInPostmaster;

  @override
  void initState() {
    super.initState();
    getItemsInPostmaster();
    getLoadouts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTransferLoadout(),
              Container(height: 4),
              buildPullFromPostmaster()
            ]));
  }

  Widget buildTransferLoadout() {
    if ((loadouts?.length ?? 0) <= 0) return Container();
    return buildActionButton(
      TranslatedTextWidget(
        "Transfer Loadout",
        style: buttonStyle,
        uppercase: true,
        textAlign: TextAlign.center,
      ),
      onTap: () {
        Navigator.of(context).pop();
        showModalBottomSheet(
            context: context,
            builder: (context) => LoadoutSelectSheet(
                loadouts: loadouts,
                onSelect: (loadout) => inventory.transferLoadout(loadout)));
      },
    );
  }

  Widget buildPullFromPostmaster() {
    if ((itemsInPostmaster?.length ?? 0) <= 0) return Container();
    return buildActionButton(
      TranslatedTextWidget(
        "Pull everything from postmaster",
        style: buttonStyle,
        uppercase: true,
        textAlign: TextAlign.center,
      ),
      onTap: () {
        Navigator.of(context).pop();
        transferEverythingFromPostmaster();
      },
    );
  }

  Widget buildActionButton(Widget content, {Function onTap}) {
    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
            child: Material(
          color: Colors.blueGrey.shade500,
        )),
        Container(padding: EdgeInsets.all(8), child: content),
        Positioned.fill(
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                )))
      ],
    );
  }

  transferEverythingFromPostmaster() async {
    var characters = widget.profile.getCharacters();
    for (var char in characters) {
      var all = widget.profile.getCharacterInventory(char.characterId);
      var inPostmaster =
          all.where((i) => i.bucketHash == InventoryBucket.lostItems).toList();
      await inventory.transferMultiple(
          inPostmaster.map((i) => ItemWithOwner(i, char.characterId)).toList(),
          ItemDestination.Vault,
          char.characterId);
    }
  }

  Widget buildLoadoutListModal(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: loadouts
                  .map(
                    (loadout) => Container(
                        color: Theme.of(context).buttonColor,
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Stack(children: [
                          Positioned.fill(
                              child: loadout.emblemHash != null
                                  ? ManifestImageWidget<
                                      DestinyInventoryItemDefinition>(
                                      loadout.emblemHash,
                                      fit: BoxFit.cover,
                                      urlExtractor: (def) {
                                        return def?.secondarySpecial;
                                      },
                                    )
                                  : Container()),
                          Container(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                loadout.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                          Positioned.fill(
                              child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                inventory.transferLoadout(loadout);
                              },
                            ),
                          ))
                        ])),
                  )
                  .toList(),
            )));
  }

  bool isLoadoutComplete(LoadoutItemIndex index) {
    return false;
  }

  void getLoadouts() async {
    this.loadouts = await loadoutsService.getLoadouts();
    if (mounted) {
      setState(() {});
    }
  }

  void getItemsInPostmaster() {
    var all = widget.profile.getAllItems();
    var inPostmaster =
        all.where((i) => i.bucketHash == InventoryBucket.lostItems).toList();
    itemsInPostmaster = inPostmaster;
  }
}
