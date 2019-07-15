import 'dart:io';

import 'package:bungie_api/helpers/bungie_net_token.dart';
import 'package:bungie_api/helpers/oauth.dart';
import 'package:bungie_api/models/user_info_card.dart';
import 'package:bungie_api/models/user_membership_data.dart';
import 'package:flutter/material.dart';
import 'package:little_light/services/bungie_api/bungie_api.service.dart';
import 'package:little_light/services/storage/storage.service.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  static final api = BungieApiService();
  static BungieNetToken _currentToken;
  static UserInfoCard _currentMembership;
  static UserMembershipData _membershipData;
  static bool waitingAuthCode = false;
  Future<BungieNetToken> _getStoredToken() async {
    StorageService storage = StorageService.account();
    var json = await storage.getJson(StorageKeys.latestToken);
    try{
      return BungieNetToken.fromJson(json);
    }catch(e){
      print("failed retrieving token for account: ${StorageService.getAccount()}");
      print(e);
    }
    return null;
  }

  Future<BungieNetToken> refreshToken(BungieNetToken token) async {
    BungieNetToken bNetToken = await api.refreshToken(token.refreshToken);
    _saveToken(bNetToken);
    return token;
  }

  Future<void> _saveToken(BungieNetToken token) async {
    if(token?.accessToken == null){
      return;
    }
    await StorageService.setAccount(token.membershipId);
    StorageService storage = StorageService.account();
    await storage.setJson(StorageKeys.latestToken, token.toJson());
    await storage.setDate(StorageKeys.latestTokenDate, DateTime.now());
    await Future.delayed(Duration(milliseconds: 1));
    _currentToken = token;
  }

  Future<BungieNetToken> getToken() async {
    BungieNetToken token = _currentToken;
    if (token == null) {
      token = await _getStoredToken();
    }
    if (token?.accessToken == null || token?.expiresIn == null) {
      return null;
    }
    DateTime now = DateTime.now();
    StorageService storage = StorageService.account();
    DateTime savedDate = storage.getDate(StorageKeys.latestTokenDate);
    DateTime expire = savedDate.add(Duration(seconds: token.expiresIn));
    DateTime refreshExpire =
        savedDate.add(Duration(seconds: token.refreshExpiresIn));
    if (refreshExpire.isBefore(now)) {
      return null;
    }
    if (expire.isBefore(now)) {
      token = await refreshToken(token);
    }
    return token;
  }

  Future<BungieNetToken> requestToken(String code) async {
    BungieNetToken token = await api.requestToken(code);
    await _saveToken(token);
    return token;
  }

  Future<String> checkAuthorizationCode() async {
    Uri uri = await getInitialUri();
    if (uri?.queryParameters == null) return null;
    print("initialURI: $uri");
    if (uri.queryParameters.containsKey("code") ||
        uri.queryParameters.containsKey("error")) {
      closeWebView();
    }

    if (uri.queryParameters.containsKey("code")) {
      return uri.queryParameters["code"];
    } else {
      String errorType = uri.queryParameters["error"];
      String errorDescription =
          uri.queryParameters["error_description"] ?? uri.toString();
      throw OAuthException(errorType, errorDescription);
    }
  }

  Future<String> authorize([reauth = false]) async {
    String currentLanguage = StorageService.getLanguage();
    var browser = new BungieAuthBrowser();
    OAuth.openOAuth(browser, BungieApiService.clientId, currentLanguage, true);
    Stream<String> _stream = getLinksStream();
    Uri uri;
    if(waitingAuthCode) return null;
    waitingAuthCode = true;
    await for (var link in _stream) {
      uri = Uri.parse(link);
      if (uri.queryParameters.containsKey("code") ||
          uri.queryParameters.containsKey("error")) {
        break;
      }
    }
    closeWebView();
    waitingAuthCode = false;
    if (uri.queryParameters.containsKey("code")) {
      return uri.queryParameters["code"];
    } else {
      String errorType = uri.queryParameters["error"];
      String errorDescription = uri.queryParameters["error_description"];
      throw OAuthException(errorType, errorDescription);
    }
  }

  Future<UserMembershipData> updateMembershipData() async{
    UserMembershipData membershipData =
        await api.getMemberships();
    var storage = StorageService.account();
    await storage.setJson(StorageKeys.membershipData, membershipData);
    return membershipData;
  }

  Future<UserMembershipData> getMembershipData() async{
    return _membershipData ?? await _getStoredMembershipData();
  }

  Future<UserMembershipData> _getStoredMembershipData() async {
    var storage = StorageService.account();
    var json = await storage.getJson(StorageKeys.membershipData);
    if(json == null){
      return null;
    }
    UserMembershipData membershipData =
        UserMembershipData.fromJson(json);
    return membershipData;
  }

  void reset(){
    _currentMembership = null;
    _currentToken = null;
    _membershipData = null;
  }

  Future<UserInfoCard> getMembership() async {
    if (_currentMembership == null) {
      var _membershipData = await _getStoredMembershipData();
      var _membershipId = StorageService.getMembership();
      _currentMembership = getMembershipById(_membershipData, _membershipId);
    }
    return _currentMembership;
  }

  UserInfoCard getMembershipById(UserMembershipData membershipData, String membershipId){
    return membershipData?.destinyMemberships
          ?.firstWhere((membership) => membership?.membershipId == membershipId, orElse: ()=>membershipData?.destinyMemberships?.first ?? null);
  }

  Future<void> saveMembership(
      UserMembershipData membershipData, String membershipId) async {
    StorageService storage = StorageService.account();
    _currentMembership = getMembershipById(membershipData, membershipId);
    storage.setJson(StorageKeys.membershipData, membershipData.toJson());
    StorageService.setMembership(membershipId);
  }

  bool get isLogged {
    return _currentMembership != null;
  }
}

class BungieAuthBrowser implements OAuthBrowser {
  BungieAuthBrowser() : super();

  @override
  dynamic open(String url) async {
    if (Platform.isIOS) {
      await launch(url,
          forceSafariVC: true, statusBarBrightness: Brightness.light);
    } else {
      await launch(url, forceSafariVC: true);
    }
  }
}
