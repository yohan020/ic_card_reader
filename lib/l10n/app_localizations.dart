import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'일본 교통카드 리더'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @history.
  ///
  /// In ko, this message translates to:
  /// **'이용내역'**
  String get history;

  /// No description provided for @tools.
  ///
  /// In ko, this message translates to:
  /// **'도구'**
  String get tools;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'IC 카드 리더'**
  String get homeTitle;

  /// No description provided for @scanPrompt.
  ///
  /// In ko, this message translates to:
  /// **'IC 카드를 스캔해 주세요'**
  String get scanPrompt;

  /// No description provided for @homeNfcHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 기기 뒷면 NFC 위치에 대면\n최근 이용내역을 읽어옵니다.'**
  String get homeNfcHint;

  /// No description provided for @scanCard.
  ///
  /// In ko, this message translates to:
  /// **'IC 카드 스캔'**
  String get scanCard;

  /// No description provided for @compareBalances.
  ///
  /// In ko, this message translates to:
  /// **'여러 카드 잔액 비교'**
  String get compareBalances;

  /// No description provided for @whereToTap.
  ///
  /// In ko, this message translates to:
  /// **'카드를 어디에 대야 하나요?'**
  String get whereToTap;

  /// No description provided for @noReadableHistory.
  ///
  /// In ko, this message translates to:
  /// **'읽을 수 있는 이용내역이 없어요'**
  String get noReadableHistory;

  /// No description provided for @noReadableHistoryHint.
  ///
  /// In ko, this message translates to:
  /// **'카드에서 표시할 이용내역을 찾지 못했습니다. 카드 종류나 기록 상태에 따라 읽을 수 있는 정보가 다를 수 있습니다.'**
  String get noReadableHistoryHint;

  /// No description provided for @nfcStartRetry.
  ///
  /// In ko, this message translates to:
  /// **'NFC 읽기를 시작하지 못했어요. 카드를 잠시 떼었다가 다시 스캔해 주세요.'**
  String get nfcStartRetry;

  /// No description provided for @notice.
  ///
  /// In ko, this message translates to:
  /// **'안내'**
  String get notice;

  /// No description provided for @recentHistory.
  ///
  /// In ko, this message translates to:
  /// **'최근 이용내역'**
  String get recentHistory;

  /// No description provided for @viewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get viewAll;

  /// No description provided for @noScannedCard.
  ///
  /// In ko, this message translates to:
  /// **'아직 스캔한 카드가 없습니다.'**
  String get noScannedCard;

  /// No description provided for @noHistoryFound.
  ///
  /// In ko, this message translates to:
  /// **'읽은 카드에서 표시할 수 있는 이용내역을 찾지 못했습니다.'**
  String get noHistoryFound;

  /// No description provided for @balanceAfterLabel.
  ///
  /// In ko, this message translates to:
  /// **'이용 후 잔액'**
  String get balanceAfterLabel;

  /// No description provided for @supportedCards.
  ///
  /// In ko, this message translates to:
  /// **'지원 카드'**
  String get supportedCards;

  /// No description provided for @supportedCardsHint.
  ///
  /// In ko, this message translates to:
  /// **'Suica · PASMO · ICOCA 등 일본 전국호환 교통계 IC 카드'**
  String get supportedCardsHint;

  /// No description provided for @pitapaLimit.
  ///
  /// In ko, this message translates to:
  /// **'PiTaPa 포스트페이 및 일부 거래는 지원되지 않을 수 있습니다.'**
  String get pitapaLimit;

  /// No description provided for @localCardData.
  ///
  /// In ko, this message translates to:
  /// **'카드 데이터는 이 기기에서만 처리합니다'**
  String get localCardData;

  /// No description provided for @stationCode.
  ///
  /// In ko, this message translates to:
  /// **'역 코드 {code}'**
  String stationCode(String code);

  /// No description provided for @entryStationUnknown.
  ///
  /// In ko, this message translates to:
  /// **'입장역을 확인했지만 역명을 찾지 못했습니다.'**
  String get entryStationUnknown;

  /// No description provided for @tripInProgress.
  ///
  /// In ko, this message translates to:
  /// **'현재 이동 중'**
  String get tripInProgress;

  /// No description provided for @enteredAt.
  ///
  /// In ko, this message translates to:
  /// **'{station}에서 입장하여 이동 중입니다.'**
  String enteredAt(String station);

  /// No description provided for @newVersion.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 있어요'**
  String get newVersion;

  /// No description provided for @newVersionHint.
  ///
  /// In ko, this message translates to:
  /// **'최신 기능과 개선 사항을 적용해 보세요.'**
  String get newVersionHint;

  /// No description provided for @opening.
  ///
  /// In ko, this message translates to:
  /// **'여는 중'**
  String get opening;

  /// No description provided for @update.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get update;

  /// No description provided for @cancelScan.
  ///
  /// In ko, this message translates to:
  /// **'스캔 취소'**
  String get cancelScan;

  /// No description provided for @scanTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 스캔'**
  String get scanTitle;

  /// No description provided for @holdTransitCard.
  ///
  /// In ko, this message translates to:
  /// **'교통카드를 대 주세요'**
  String get holdTransitCard;

  /// No description provided for @holdCardStill.
  ///
  /// In ko, this message translates to:
  /// **'카드를 움직이지 말고\n가까이 대 주세요'**
  String get holdCardStill;

  /// No description provided for @scanWaitHint.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 뒷면 NFC 위치에 카드 한 장을 대고\n스캔이 완료될 때까지 기다려 주세요.'**
  String get scanWaitHint;

  /// No description provided for @scanTimeElapsed.
  ///
  /// In ko, this message translates to:
  /// **'스캔 제한 시간 경과'**
  String get scanTimeElapsed;

  /// No description provided for @scanTimeLeft.
  ///
  /// In ko, this message translates to:
  /// **'스캔 대기 시간 · 남은 시간 {seconds}초'**
  String scanTimeLeft(int seconds);

  /// No description provided for @retryWithoutClosing.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생해도 앱을 종료하지 않고 다시 시도할 수 있습니다.'**
  String get retryWithoutClosing;

  /// No description provided for @scanComplete.
  ///
  /// In ko, this message translates to:
  /// **'스캔 완료'**
  String get scanComplete;

  /// No description provided for @cardRead.
  ///
  /// In ko, this message translates to:
  /// **'카드를 읽었습니다'**
  String get cardRead;

  /// No description provided for @brandCardRead.
  ///
  /// In ko, this message translates to:
  /// **'{brand} 카드를 읽었습니다'**
  String brandCardRead(String brand);

  /// No description provided for @blocksRead.
  ///
  /// In ko, this message translates to:
  /// **'읽은 블록'**
  String get blocksRead;

  /// No description provided for @decodedRecords.
  ///
  /// In ko, this message translates to:
  /// **'해석한 내역'**
  String get decodedRecords;

  /// No description provided for @needsReview.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get needsReview;

  /// No description provided for @someDataUnconfirmed.
  ///
  /// In ko, this message translates to:
  /// **'일부 정보는 아직 확인 중입니다'**
  String get someDataUnconfirmed;

  /// No description provided for @someDataUnconfirmedHint.
  ///
  /// In ko, this message translates to:
  /// **'원본 기록은 정상적으로 읽었습니다. 역명과 거래 유형 데이터베이스가 연결되면 더 자세히 표시할 수 있습니다.'**
  String get someDataUnconfirmedHint;

  /// No description provided for @historyOnDevice.
  ///
  /// In ko, this message translates to:
  /// **'읽은 이용내역은 이 기기 안에만 표시됩니다'**
  String get historyOnDevice;

  /// No description provided for @idmNotStored.
  ///
  /// In ko, this message translates to:
  /// **'카드 IDm 원문은 저장하거나 화면에 표시하지 않습니다.'**
  String get idmNotStored;

  /// No description provided for @viewHistory.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 보기'**
  String get viewHistory;

  /// No description provided for @scanAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 스캔'**
  String get scanAgain;

  /// No description provided for @unavailableAmount.
  ///
  /// In ko, this message translates to:
  /// **'계산 불가'**
  String get unavailableAmount;

  /// No description provided for @unknownBus.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사 미확인'**
  String get unknownBus;

  /// No description provided for @refund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get refund;

  /// No description provided for @adjustment.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get adjustment;

  /// No description provided for @unknownTransaction.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형 미확인'**
  String get unknownTransaction;

  /// No description provided for @stationUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'역 정보 확인 불가'**
  String get stationUnavailable;

  /// No description provided for @nfcSettingsError.
  ///
  /// In ko, this message translates to:
  /// **'NFC 설정을 열지 못했어요. 휴대폰 설정에서 NFC를 확인해 주세요.'**
  String get nfcSettingsError;

  /// No description provided for @sessionCleared.
  ///
  /// In ko, this message translates to:
  /// **'현재 세션의 이용내역을 지웠습니다.'**
  String get sessionCleared;

  /// No description provided for @updateStartError.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get updateStartError;

  /// No description provided for @checkingNfc.
  ///
  /// In ko, this message translates to:
  /// **'NFC 상태 확인 중'**
  String get checkingNfc;

  /// No description provided for @nfcOn.
  ///
  /// In ko, this message translates to:
  /// **'NFC가 켜져 있어요'**
  String get nfcOn;

  /// No description provided for @turnNfcOn.
  ///
  /// In ko, this message translates to:
  /// **'NFC를 켜 주세요'**
  String get turnNfcOn;

  /// No description provided for @nfcUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 NFC 읽기를 지원하지 않아요'**
  String get nfcUnsupported;

  /// No description provided for @nfcUnknown.
  ///
  /// In ko, this message translates to:
  /// **'NFC 상태를 확인하지 못했어요'**
  String get nfcUnknown;

  /// No description provided for @openNfcSettings.
  ///
  /// In ko, this message translates to:
  /// **'NFC 설정 열기'**
  String get openNfcSettings;

  /// No description provided for @checkAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get checkAgain;

  /// No description provided for @couldNotStartNfc.
  ///
  /// In ko, this message translates to:
  /// **'NFC 읽기를 시작하지 못했어요'**
  String get couldNotStartNfc;

  /// No description provided for @nfcUnsupportedHint.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 NFC 읽기를 지원하지 않습니다. NFC-F/FeliCa 읽기를 지원하는 Android 기기를 이용해 주세요.'**
  String get nfcUnsupportedHint;

  /// No description provided for @nfcEnabledHint.
  ///
  /// In ko, this message translates to:
  /// **'NFC가 켜져 있는지 확인해 주세요. Samsung 기기는 NFC를 기본 모드로 설정한 뒤 다시 시도해 주세요.'**
  String get nfcEnabledHint;

  /// No description provided for @checkCardSupport.
  ///
  /// In ko, this message translates to:
  /// **'지원하는 교통카드인지 확인해 주세요'**
  String get checkCardSupport;

  /// No description provided for @checkCardSupportHint.
  ///
  /// In ko, this message translates to:
  /// **'Suica·PASMO·ICOCA 등 일본 전국호환 교통계 IC 카드를 한 장만 대 주세요. NFC-F/FeliCa 읽기를 지원하는 기기가 필요합니다.'**
  String get checkCardSupportHint;

  /// No description provided for @scanTimedOut.
  ///
  /// In ko, this message translates to:
  /// **'시간 안에 스캔을 완료하지 못했어요'**
  String get scanTimedOut;

  /// No description provided for @scanTimedOutHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 지갑에서 꺼내 휴대폰 뒷면의 위치를 조금씩 바꿔 다시 시도해 주세요. 카드 종류나 기기의 NFC-F 지원 여부도 영향을 줄 수 있습니다.'**
  String get scanTimedOutHint;

  /// No description provided for @cardConnectionLost.
  ///
  /// In ko, this message translates to:
  /// **'카드와 통신을 완료하지 못했어요'**
  String get cardConnectionLost;

  /// No description provided for @cardConnectionLostHint.
  ///
  /// In ko, this message translates to:
  /// **'카드 한 장을 NFC 위치에 가까이 대고 완료될 때까지 움직이지 말아 주세요.'**
  String get cardConnectionLostHint;

  /// No description provided for @couldNotReadCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 정보를 읽지 못했어요'**
  String get couldNotReadCard;

  /// No description provided for @couldNotReadCardHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 다시 대 주세요. 이 메시지만으로 카드 고장이나 잔액 이상을 의미하지는 않습니다.'**
  String get couldNotReadCardHint;

  /// No description provided for @scanFailed.
  ///
  /// In ko, this message translates to:
  /// **'스캔을 완료하지 못했어요'**
  String get scanFailed;

  /// No description provided for @scanFailedHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 잠시 떼었다가 다시 시도해 주세요. 계속되면 NFC 설정과 지원 카드 안내를 확인해 주세요.'**
  String get scanFailedHint;

  /// No description provided for @scanHelp.
  ///
  /// In ko, this message translates to:
  /// **'스캔 도움말'**
  String get scanHelp;

  /// No description provided for @dismissNotice.
  ///
  /// In ko, this message translates to:
  /// **'안내 닫기'**
  String get dismissNotice;

  /// No description provided for @howToScan.
  ///
  /// In ko, this message translates to:
  /// **'카드 스캔 방법'**
  String get howToScan;

  /// No description provided for @closeHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말 닫기'**
  String get closeHelp;

  /// No description provided for @holdOneCard.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 뒷면에 교통카드 한 장을 대 주세요.'**
  String get holdOneCard;

  /// No description provided for @prepareOneCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 한 장 준비'**
  String get prepareOneCard;

  /// No description provided for @prepareOneCardHint.
  ///
  /// In ko, this message translates to:
  /// **'지갑에서 실물 교통카드 한 장을 꺼내 주세요. Samsung 기기는 NFC 기본 모드를 확인해 주세요.'**
  String get prepareOneCardHint;

  /// No description provided for @tapScanHold.
  ///
  /// In ko, this message translates to:
  /// **'스캔을 누르고 뒷면에 대기'**
  String get tapScanHold;

  /// No description provided for @tapScanHoldHint.
  ///
  /// In ko, this message translates to:
  /// **'스캔 화면이 열리면 카드를 휴대폰 뒷면 NFC 위치에 대 주세요. NFC 위치는 기기마다 다릅니다.'**
  String get tapScanHoldHint;

  /// No description provided for @waitForScan.
  ///
  /// In ko, this message translates to:
  /// **'완료될 때까지 고정'**
  String get waitForScan;

  /// No description provided for @waitForScanHint.
  ///
  /// In ko, this message translates to:
  /// **'반응이 없으면 카드 위치를 조금씩 바꾸거나 두꺼운 케이스·금속 부착물을 분리한 뒤 다시 시도해 주세요.'**
  String get waitForScanHint;

  /// No description provided for @deviceRequirements.
  ///
  /// In ko, this message translates to:
  /// **'기기 조건'**
  String get deviceRequirements;

  /// No description provided for @felicaRequired.
  ///
  /// In ko, this message translates to:
  /// **'NFC-F/FeliCa 읽기 지원이 필요합니다. NFC 켜짐 표시만으로 지원이 확인되는 것은 아닙니다.'**
  String get felicaRequired;

  /// No description provided for @readOnlyPhysicalCard.
  ///
  /// In ko, this message translates to:
  /// **'실물 카드 스캔 기준입니다. 카드 충전이나 기록 변경은 하지 않습니다.'**
  String get readOnlyPhysicalCard;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @placementSemantics.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 뒷면에 실물 교통카드 한 장을 가까이 대는 예시'**
  String get placementSemantics;

  /// No description provided for @nfcPlacementVaries.
  ///
  /// In ko, this message translates to:
  /// **'NFC 위치는 기기마다 달라요'**
  String get nfcPlacementVaries;

  /// No description provided for @noMatchingHistory.
  ///
  /// In ko, this message translates to:
  /// **'해당 조건의 이용내역이 없습니다.'**
  String get noMatchingHistory;

  /// No description provided for @unknownTotalExplanation.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형이 확인되지 않아 금액은 합산하지 않습니다.'**
  String get unknownTotalExplanation;

  /// No description provided for @topUpTotalExplanation.
  ///
  /// In ko, this message translates to:
  /// **'확인된 충전액만 합산하며 지출에는 포함하지 않습니다.'**
  String get topUpTotalExplanation;

  /// No description provided for @spendingTotalExplanation.
  ///
  /// In ko, this message translates to:
  /// **'충전·계산 불가·확인 필요·특수 거래는 지출에서 제외합니다.'**
  String get spendingTotalExplanation;

  /// No description provided for @unknownRecordCount.
  ///
  /// In ko, this message translates to:
  /// **'미확인 {count}건'**
  String unknownRecordCount(int count);

  /// No description provided for @noTopUpTotal.
  ///
  /// In ko, this message translates to:
  /// **'합산 가능한 충전 기록이 없어요'**
  String get noTopUpTotal;

  /// No description provided for @noSpendingTotal.
  ///
  /// In ko, this message translates to:
  /// **'합산 가능한 지출 기록이 없어요'**
  String get noSpendingTotal;

  /// No description provided for @totalCount.
  ///
  /// In ko, this message translates to:
  /// **'합산 {included}건 · 합계 제외 {excluded}건'**
  String totalCount(int included, int excluded);

  /// No description provided for @recentTotalHint.
  ///
  /// In ko, this message translates to:
  /// **'카드에서 읽은 최근 기록만 합산합니다.\n{explanation}'**
  String recentTotalHint(String explanation);

  /// No description provided for @currentBalance.
  ///
  /// In ko, this message translates to:
  /// **'현재 카드 잔액'**
  String get currentBalance;

  /// No description provided for @currentBrandBalance.
  ///
  /// In ko, this message translates to:
  /// **'현재 {brand} 잔액'**
  String currentBrandBalance(String brand);

  /// No description provided for @balanceAfterScan.
  ///
  /// In ko, this message translates to:
  /// **'카드 스캔 후 표시'**
  String get balanceAfterScan;

  /// No description provided for @initialBalanceBasis.
  ///
  /// In ko, this message translates to:
  /// **'초기 잔액 기록 기준'**
  String get initialBalanceBasis;

  /// No description provided for @latestBalanceBasis.
  ///
  /// In ko, this message translates to:
  /// **'가장 최근 기록 기준'**
  String get latestBalanceBasis;

  /// No description provided for @noDisplayableHistory.
  ///
  /// In ko, this message translates to:
  /// **'이 카드에는 표시할 이용내역이 없습니다'**
  String get noDisplayableHistory;

  /// No description provided for @noHistoryYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 읽은 이용내역이 없습니다'**
  String get noHistoryYet;

  /// No description provided for @initialBalanceOnly.
  ///
  /// In ko, this message translates to:
  /// **'초기 잔액 기록만 확인되었습니다.'**
  String get initialBalanceOnly;

  /// No description provided for @scanFromHome.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 IC 카드를 스캔해 주세요.'**
  String get scanFromHome;

  /// No description provided for @balanceValue.
  ///
  /// In ko, this message translates to:
  /// **'잔액 {amount}'**
  String balanceValue(String amount);

  /// No description provided for @historyDetail.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 상세'**
  String get historyDetail;

  /// No description provided for @boarding.
  ///
  /// In ko, this message translates to:
  /// **'승차'**
  String get boarding;

  /// No description provided for @alighting.
  ///
  /// In ko, this message translates to:
  /// **'하차'**
  String get alighting;

  /// No description provided for @balanceAfterValue.
  ///
  /// In ko, this message translates to:
  /// **'이용 후 잔액 {amount}'**
  String balanceAfterValue(String amount);

  /// No description provided for @cantCalculateAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액을 계산할 수 없습니다'**
  String get cantCalculateAmount;

  /// No description provided for @icaZeroAmount.
  ///
  /// In ko, this message translates to:
  /// **'이 ICa 기록에는 금액이 0엔으로 저장되어 있어 이용 금액으로 표시하지 않습니다.'**
  String get icaZeroAmount;

  /// No description provided for @multipleStationCandidates.
  ///
  /// In ko, this message translates to:
  /// **'여러 역 후보가 있습니다'**
  String get multipleStationCandidates;

  /// No description provided for @stationInfoNeedsReview.
  ///
  /// In ko, this message translates to:
  /// **'일부 역 정보 확인이 필요합니다'**
  String get stationInfoNeedsReview;

  /// No description provided for @multipleStationHint.
  ///
  /// In ko, this message translates to:
  /// **'역 후보가 여러 개여서 특정 역으로 확정할 수 없습니다. 아래 오류 제보에서 올바른 역을 알려 주세요.'**
  String get multipleStationHint;

  /// No description provided for @stationInfoNeedsReviewHint.
  ///
  /// In ko, this message translates to:
  /// **'일부 역명을 확인할 수 없습니다. 아래 오류 제보에서 올바른 역을 알려 주세요.'**
  String get stationInfoNeedsReviewHint;

  /// No description provided for @details.
  ///
  /// In ko, this message translates to:
  /// **'상세 정보'**
  String get details;

  /// No description provided for @transactionType.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형'**
  String get transactionType;

  /// No description provided for @boardingStation.
  ///
  /// In ko, this message translates to:
  /// **'승차역'**
  String get boardingStation;

  /// No description provided for @alightingStation.
  ///
  /// In ko, this message translates to:
  /// **'하차역'**
  String get alightingStation;

  /// No description provided for @busOperator.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사'**
  String get busOperator;

  /// No description provided for @paymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 방식'**
  String get paymentMethod;

  /// No description provided for @combinedCash.
  ///
  /// In ko, this message translates to:
  /// **'현금 병용'**
  String get combinedCash;

  /// No description provided for @transactionTime.
  ///
  /// In ko, this message translates to:
  /// **'거래 시각'**
  String get transactionTime;

  /// No description provided for @topUpMethod.
  ///
  /// In ko, this message translates to:
  /// **'충전 방식'**
  String get topUpMethod;

  /// No description provided for @topUpLocation.
  ///
  /// In ko, this message translates to:
  /// **'충전 장소'**
  String get topUpLocation;

  /// No description provided for @processingLocation.
  ///
  /// In ko, this message translates to:
  /// **'처리 장소'**
  String get processingLocation;

  /// No description provided for @processingDetail.
  ///
  /// In ko, this message translates to:
  /// **'세부 처리'**
  String get processingDetail;

  /// No description provided for @unknown.
  ///
  /// In ko, this message translates to:
  /// **'확인할 수 없음'**
  String get unknown;

  /// No description provided for @balance.
  ///
  /// In ko, this message translates to:
  /// **'잔액'**
  String get balance;

  /// No description provided for @reportTransaction.
  ///
  /// In ko, this message translates to:
  /// **'이 내역의 오류 제보하기'**
  String get reportTransaction;

  /// No description provided for @stationNotRegistered.
  ///
  /// In ko, this message translates to:
  /// **'역 정보 미등록'**
  String get stationNotRegistered;

  /// No description provided for @spendingTotal.
  ///
  /// In ko, this message translates to:
  /// **'지출 합계'**
  String get spendingTotal;

  /// No description provided for @topUpTotal.
  ///
  /// In ko, this message translates to:
  /// **'충전 합계'**
  String get topUpTotal;

  /// No description provided for @unknownRecords.
  ///
  /// In ko, this message translates to:
  /// **'미확인 기록'**
  String get unknownRecords;

  /// No description provided for @all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// No description provided for @transport.
  ///
  /// In ko, this message translates to:
  /// **'교통'**
  String get transport;

  /// No description provided for @purchases.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get purchases;

  /// No description provided for @topUp.
  ///
  /// In ko, this message translates to:
  /// **'충전'**
  String get topUp;

  /// No description provided for @unconfirmed.
  ///
  /// In ko, this message translates to:
  /// **'미확인'**
  String get unconfirmed;

  /// No description provided for @checkAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 확인 필요'**
  String get checkAmount;

  /// No description provided for @oldestRecord.
  ///
  /// In ko, this message translates to:
  /// **'이 기록은 카드에 남아 있는 가장 오래된 이용내역입니다. 그보다 오래된 잔액 기록이 없어 잔액 차이로 이용 금액을 계산할 수 없습니다.'**
  String get oldestRecord;

  /// No description provided for @noDecrease.
  ///
  /// In ko, this message translates to:
  /// **'이전 기록과 비교했을 때 잔액이 줄지 않았습니다. 충전·환불 등일 수 있어 일반 이용 금액으로 표시하지 않습니다.'**
  String get noDecrease;

  /// No description provided for @notEnoughBalances.
  ///
  /// In ko, this message translates to:
  /// **'비교할 수 있는 잔액 정보가 부족해 이용 금액을 계산할 수 없습니다.'**
  String get notEnoughBalances;

  /// No description provided for @unknownTransactionSummary.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형을 확인할 수 없습니다'**
  String get unknownTransactionSummary;

  /// No description provided for @busOrTram.
  ///
  /// In ko, this message translates to:
  /// **'버스·노면전차 이용'**
  String get busOrTram;

  /// No description provided for @railRide.
  ///
  /// In ko, this message translates to:
  /// **'철도 이용'**
  String get railRide;

  /// No description provided for @busRide.
  ///
  /// In ko, this message translates to:
  /// **'버스 이용'**
  String get busRide;

  /// No description provided for @purchase.
  ///
  /// In ko, this message translates to:
  /// **'물품 구매'**
  String get purchase;

  /// No description provided for @gateWindow.
  ///
  /// In ko, this message translates to:
  /// **'개찰 창구 처리'**
  String get gateWindow;

  /// No description provided for @unknownType.
  ///
  /// In ko, this message translates to:
  /// **'유형 미확인'**
  String get unknownType;

  /// No description provided for @ticketMachine.
  ///
  /// In ko, this message translates to:
  /// **'자동발권기'**
  String get ticketMachine;

  /// No description provided for @stationGateTerminal.
  ///
  /// In ko, this message translates to:
  /// **'역 개찰 단말'**
  String get stationGateTerminal;

  /// No description provided for @stationTerminal.
  ///
  /// In ko, this message translates to:
  /// **'역 단말'**
  String get stationTerminal;

  /// No description provided for @mobile.
  ///
  /// In ko, this message translates to:
  /// **'모바일'**
  String get mobile;

  /// No description provided for @mobileBenefit.
  ///
  /// In ko, this message translates to:
  /// **'모바일 특전'**
  String get mobileBenefit;

  /// No description provided for @storeTerminal.
  ///
  /// In ko, this message translates to:
  /// **'매장 단말'**
  String get storeTerminal;

  /// No description provided for @ticketMachineTopUp.
  ///
  /// In ko, this message translates to:
  /// **'자동발권기에서 충전'**
  String get ticketMachineTopUp;

  /// No description provided for @ticketMachineTopUpAt.
  ///
  /// In ko, this message translates to:
  /// **'자동발권기에서 충전 · {station}'**
  String ticketMachineTopUpAt(String station);

  /// No description provided for @gateTerminalTopUp.
  ///
  /// In ko, this message translates to:
  /// **'역 개찰 단말에서 충전'**
  String get gateTerminalTopUp;

  /// No description provided for @topUpAt.
  ///
  /// In ko, this message translates to:
  /// **'충전 · {station}'**
  String topUpAt(String station);

  /// No description provided for @stationTerminalTopUp.
  ///
  /// In ko, this message translates to:
  /// **'역 단말에서 충전'**
  String get stationTerminalTopUp;

  /// No description provided for @mobileBenefitTopUp.
  ///
  /// In ko, this message translates to:
  /// **'모바일 특전 충전'**
  String get mobileBenefitTopUp;

  /// No description provided for @mobileTopUp.
  ///
  /// In ko, this message translates to:
  /// **'모바일에서 충전'**
  String get mobileTopUp;

  /// No description provided for @storeTopUp.
  ///
  /// In ko, this message translates to:
  /// **'매장에서 충전'**
  String get storeTopUp;

  /// No description provided for @cardTopUp.
  ///
  /// In ko, this message translates to:
  /// **'카드 충전'**
  String get cardTopUp;

  /// No description provided for @unknownBusOperator.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사 확인 불가'**
  String get unknownBusOperator;

  /// No description provided for @purchaseWithCash.
  ///
  /// In ko, this message translates to:
  /// **'물품 구매 · 현금 병용'**
  String get purchaseWithCash;

  /// No description provided for @gateWindowAt.
  ///
  /// In ko, this message translates to:
  /// **'개찰 창구 처리 · {station}'**
  String gateWindowAt(String station);

  /// No description provided for @displaySettings.
  ///
  /// In ko, this message translates to:
  /// **'화면'**
  String get displaySettings;

  /// No description provided for @theme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get system;

  /// No description provided for @light.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get dark;

  /// No description provided for @stationNames.
  ///
  /// In ko, this message translates to:
  /// **'역명 표기'**
  String get stationNames;

  /// No description provided for @stationNamesHint.
  ///
  /// In ko, this message translates to:
  /// **'한국어 표기가 확인된 역에만 적용됩니다.'**
  String get stationNamesHint;

  /// No description provided for @stationFallbackHint.
  ///
  /// In ko, this message translates to:
  /// **'확인된 표기가 없으면 일본어 역명을 표시합니다.'**
  String get stationFallbackHint;

  /// No description provided for @japanese.
  ///
  /// In ko, this message translates to:
  /// **'일본어'**
  String get japanese;

  /// No description provided for @korean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get english;

  /// No description provided for @both.
  ///
  /// In ko, this message translates to:
  /// **'함께 표시'**
  String get both;

  /// No description provided for @appLanguage.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어'**
  String get appLanguage;

  /// No description provided for @deviceLanguage.
  ///
  /// In ko, this message translates to:
  /// **'기기 언어'**
  String get deviceLanguage;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfo;

  /// No description provided for @appVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get appVersion;

  /// No description provided for @dataSources.
  ///
  /// In ko, this message translates to:
  /// **'데이터 출처 및 운임 기준'**
  String get dataSources;

  /// No description provided for @dataSourcesHint.
  ///
  /// In ko, this message translates to:
  /// **'교통패스별 운임 데이터·라이선스·계산 범위'**
  String get dataSourcesHint;

  /// No description provided for @appUpdate.
  ///
  /// In ko, this message translates to:
  /// **'앱 업데이트'**
  String get appUpdate;

  /// No description provided for @openSource.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get openSource;

  /// No description provided for @privacyData.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 및 데이터'**
  String get privacyData;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyHint.
  ///
  /// In ko, this message translates to:
  /// **'NFC와 오류 제보 데이터 처리 안내'**
  String get privacyPolicyHint;

  /// No description provided for @clearCurrentHistory.
  ///
  /// In ko, this message translates to:
  /// **'현재 이용내역 지우기'**
  String get clearCurrentHistory;

  /// No description provided for @nothingToClear.
  ///
  /// In ko, this message translates to:
  /// **'지울 이용내역이 없습니다.'**
  String get nothingToClear;

  /// No description provided for @transactionCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 이용내역이 있습니다.'**
  String transactionCount(int count);

  /// No description provided for @support.
  ///
  /// In ko, this message translates to:
  /// **'문의'**
  String get support;

  /// No description provided for @cardSupport.
  ///
  /// In ko, this message translates to:
  /// **'카드 인식 문의'**
  String get cardSupport;

  /// No description provided for @cardSupportHint.
  ///
  /// In ko, this message translates to:
  /// **'카드 읽기·브랜드 구분 문제'**
  String get cardSupportHint;

  /// No description provided for @developerTools.
  ///
  /// In ko, this message translates to:
  /// **'개발 도구'**
  String get developerTools;

  /// No description provided for @cardDiagnostics.
  ///
  /// In ko, this message translates to:
  /// **'카드 브랜드 진단'**
  String get cardDiagnostics;

  /// No description provided for @cardDiagnosticsHint.
  ///
  /// In ko, this message translates to:
  /// **'브랜드 선택·직접 입력 후 메타데이터 확인'**
  String get cardDiagnosticsHint;

  /// No description provided for @japanIcCards.
  ///
  /// In ko, this message translates to:
  /// **'일본 전국호환 교통계 IC 카드'**
  String get japanIcCards;

  /// No description provided for @checkingUpdates.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 정보를 확인하고 있습니다.'**
  String get checkingUpdates;

  /// No description provided for @automaticUpdateCheck.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열면 자동으로 업데이트를 확인합니다.'**
  String get automaticUpdateCheck;

  /// No description provided for @appUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'현재 최신 버전을 사용 중입니다.'**
  String get appUpToDate;

  /// No description provided for @updateShownOnHome.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 홈 화면에 안내됩니다.'**
  String get updateShownOnHome;

  /// No description provided for @updateStatusUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'지금은 업데이트 정보를 확인할 수 없습니다.'**
  String get updateStatusUnavailable;

  /// No description provided for @clearHistoryQuestion.
  ///
  /// In ko, this message translates to:
  /// **'현재 이용내역을 지울까요?'**
  String get clearHistoryQuestion;

  /// No description provided for @clearHistoryHint.
  ///
  /// In ko, this message translates to:
  /// **'이번에 읽은 이용내역과 원본 기록이\n앱 화면에서 삭제됩니다.'**
  String get clearHistoryHint;

  /// No description provided for @physicalCardUnchanged.
  ///
  /// In ko, this message translates to:
  /// **'실물 카드 안의 데이터는 변경되지 않습니다.'**
  String get physicalCardUnchanged;

  /// No description provided for @clearHistory.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 지우기'**
  String get clearHistory;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @comparePasses.
  ///
  /// In ko, this message translates to:
  /// **'교통패스 비교'**
  String get comparePasses;

  /// No description provided for @comparePassesHint.
  ///
  /// In ko, this message translates to:
  /// **'패스 가격과 예상\n교통비 비교'**
  String get comparePassesHint;

  /// No description provided for @contactlessRoutes.
  ///
  /// In ko, this message translates to:
  /// **'컨택리스 노선'**
  String get contactlessRoutes;

  /// No description provided for @contactlessRoutesHint.
  ///
  /// In ko, this message translates to:
  /// **'회사·노선별 터치 승차 지원 확인'**
  String get contactlessRoutesHint;

  /// No description provided for @findLockers.
  ///
  /// In ko, this message translates to:
  /// **'코인락커 찾기'**
  String get findLockers;

  /// No description provided for @findLockersHint.
  ///
  /// In ko, this message translates to:
  /// **'주요 역·공항의\n코인락커 위치 안내'**
  String get findLockersHint;

  /// No description provided for @comparisonUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 카드 읽기 방식에서는 여러 카드 비교를 사용할 수 없어요.'**
  String get comparisonUnavailable;

  /// No description provided for @comparisonUpdated.
  ///
  /// In ko, this message translates to:
  /// **'{card}의 잔액을 갱신했어요.'**
  String comparisonUpdated(String card);

  /// No description provided for @comparisonAdded.
  ///
  /// In ko, this message translates to:
  /// **'{card}를 추가했어요.'**
  String comparisonAdded(String card);

  /// No description provided for @checkNfcSettings.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정에서 NFC를 확인해 주세요.'**
  String get checkNfcSettings;

  /// No description provided for @scanStillEnding.
  ///
  /// In ko, this message translates to:
  /// **'스캔 종료를 기다리고 있어요. 잠시 후 다시 시도해 주세요.'**
  String get scanStillEnding;

  /// No description provided for @renameCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 이름 변경'**
  String get renameCard;

  /// No description provided for @cardName.
  ///
  /// In ko, this message translates to:
  /// **'카드 이름'**
  String get cardName;

  /// No description provided for @enterCardName.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해 주세요.'**
  String get enterCardName;

  /// No description provided for @saveName.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get saveName;

  /// No description provided for @comparisonHelpHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 한 장씩 스캔해 최대 10장의 잔액을 비교합니다. 카드 항목을 누르면 해당 카드의 이용내역을 볼 수 있어요.\n\n잔액은 각 카드의 스캔 시점 기준이며 자동 갱신되지 않습니다. 같은 카드를 다시 읽으면 기존 항목을 갱신합니다.\n\n비교 정보는 기기 메모리에서만 사용하며 비교 종료 또는 앱 프로세스 종료 시 사라집니다. 기존 홈의 카드 이용내역은 변경하지 않습니다.'**
  String get comparisonHelpHint;

  /// No description provided for @exitComparison.
  ///
  /// In ko, this message translates to:
  /// **'비교 종료'**
  String get exitComparison;

  /// No description provided for @comparisonHelp.
  ///
  /// In ko, this message translates to:
  /// **'비교 도움말'**
  String get comparisonHelp;

  /// No description provided for @comparingCount.
  ///
  /// In ko, this message translates to:
  /// **'비교 중인 카드 {count}장'**
  String comparingCount(int count);

  /// No description provided for @deleteAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get deleteAll;

  /// No description provided for @tapCardHistory.
  ///
  /// In ko, this message translates to:
  /// **'카드를 누르면 이용내역을 볼 수 있어요.'**
  String get tapCardHistory;

  /// No description provided for @addCardsToCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교할 카드를 추가해 주세요.'**
  String get addCardsToCompare;

  /// No description provided for @scanOneAtATime.
  ///
  /// In ko, this message translates to:
  /// **'카드는 한 장씩 스캔해 주세요.'**
  String get scanOneAtATime;

  /// No description provided for @cardMenu.
  ///
  /// In ko, this message translates to:
  /// **'{card} 메뉴'**
  String cardMenu(String card);

  /// No description provided for @rename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @addCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 추가'**
  String get addCard;

  /// No description provided for @comparisonLimit.
  ///
  /// In ko, this message translates to:
  /// **'최대 10장까지 비교할 수 있어요. 기존 카드는 메뉴에서 다시 스캔할 수 있어요.'**
  String get comparisonLimit;

  /// No description provided for @checkedAt.
  ///
  /// In ko, this message translates to:
  /// **'확인 {date}'**
  String checkedAt(String date);

  /// No description provided for @exitComparisonQuestion.
  ///
  /// In ko, this message translates to:
  /// **'잔액 비교를 종료할까요?'**
  String get exitComparisonQuestion;

  /// No description provided for @exitComparisonHint.
  ///
  /// In ko, this message translates to:
  /// **'비교 중인 카드와 이용내역은 저장되지 않으며 종료하면 모두 삭제됩니다.'**
  String get exitComparisonHint;

  /// No description provided for @exit.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get exit;

  /// No description provided for @clearComparisonQuestion.
  ///
  /// In ko, this message translates to:
  /// **'비교 목록을 비울까요?'**
  String get clearComparisonQuestion;

  /// No description provided for @clearComparisonHint.
  ///
  /// In ko, this message translates to:
  /// **'추가한 카드와 이용내역을\n비교 목록에서 삭제합니다.'**
  String get clearComparisonHint;

  /// No description provided for @balancesUnchanged.
  ///
  /// In ko, this message translates to:
  /// **'실제 카드 잔액은 바뀌지 않아요.'**
  String get balancesUnchanged;

  /// No description provided for @mapOffline.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인한 뒤 지도를 새로고침해 주세요.'**
  String get mapOffline;

  /// No description provided for @mapStationsUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'두 역의 위치를 확인할 수 없어 지도를 표시하지 않습니다.'**
  String get mapStationsUnavailable;

  /// No description provided for @mapConfigUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 지도 설정을 확인할 수 없습니다. 역 정보는 위에서 확인해 주세요.'**
  String get mapConfigUnavailable;

  /// No description provided for @mapPreparationFailed.
  ///
  /// In ko, this message translates to:
  /// **'지도를 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get mapPreparationFailed;

  /// No description provided for @stationLocations.
  ///
  /// In ko, this message translates to:
  /// **'역 위치'**
  String get stationLocations;

  /// No description provided for @mapLegend.
  ///
  /// In ko, this message translates to:
  /// **'파란 핀: 승차 · 붉은 핀: 하차'**
  String get mapLegend;

  /// No description provided for @mapCandidates.
  ///
  /// In ko, this message translates to:
  /// **'복합역·구간의 후보 위치'**
  String get mapCandidates;

  /// No description provided for @mapLoading.
  ///
  /// In ko, this message translates to:
  /// **'지도 준비 중'**
  String get mapLoading;

  /// No description provided for @refreshMap.
  ///
  /// In ko, this message translates to:
  /// **'지도 새로고침'**
  String get refreshMap;

  /// No description provided for @mapAttribution.
  ///
  /// In ko, this message translates to:
  /// **'역 좌표: Wikidata · CC0'**
  String get mapAttribution;

  /// No description provided for @mapBoth.
  ///
  /// In ko, this message translates to:
  /// **'승차·하차 · {station}'**
  String mapBoth(String station);

  /// No description provided for @mapBoarding.
  ///
  /// In ko, this message translates to:
  /// **'승차 · {station}'**
  String mapBoarding(String station);

  /// No description provided for @mapAlighting.
  ///
  /// In ko, this message translates to:
  /// **'하차 · {station}'**
  String mapAlighting(String station);

  /// No description provided for @mapCandidateRole.
  ///
  /// In ko, this message translates to:
  /// **'{role} 후보'**
  String mapCandidateRole(String role);

  /// No description provided for @comparisonUnidentified.
  ///
  /// In ko, this message translates to:
  /// **'카드를 구분하지 못했어요. 다시 스캔해 주세요.'**
  String get comparisonUnidentified;

  /// No description provided for @comparisonBalanceUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'잔액을 확인하지 못했어요. 카드를 다시 스캔해 주세요.'**
  String get comparisonBalanceUnavailable;

  /// No description provided for @comparisonDifferentCard.
  ///
  /// In ko, this message translates to:
  /// **'선택한 카드와 다른 카드예요. 기존 카드를 다시 대 주세요.'**
  String get comparisonDifferentCard;

  /// No description provided for @comparisonAtLimit.
  ///
  /// In ko, this message translates to:
  /// **'카드는 최대 10장까지 비교할 수 있어요.'**
  String get comparisonAtLimit;

  /// No description provided for @defaultCardName.
  ///
  /// In ko, this message translates to:
  /// **'카드 {number}'**
  String defaultCardName(String number);

  /// No description provided for @reportTitle.
  ///
  /// In ko, this message translates to:
  /// **'오류 제보'**
  String get reportTitle;

  /// No description provided for @reportQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 정보가 잘못되었나요?'**
  String get reportQuestion;

  /// No description provided for @reportChooseClosest.
  ///
  /// In ko, this message translates to:
  /// **'가장 가까운 항목 하나를 선택해 주세요.'**
  String get reportChooseClosest;

  /// No description provided for @reportStationIssue.
  ///
  /// In ko, this message translates to:
  /// **'역 정보가 없거나 잘못됨'**
  String get reportStationIssue;

  /// No description provided for @reportKoreanNameIssue.
  ///
  /// In ko, this message translates to:
  /// **'역명 한글 표기 추가 요청'**
  String get reportKoreanNameIssue;

  /// No description provided for @reportBusIssue.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사 정보가 없거나 잘못됨'**
  String get reportBusIssue;

  /// No description provided for @reportTypeIssue.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형이 잘못됨'**
  String get reportTypeIssue;

  /// No description provided for @reportAmountIssue.
  ///
  /// In ko, this message translates to:
  /// **'금액 또는 잔액이 잘못됨'**
  String get reportAmountIssue;

  /// No description provided for @reportOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportOther;

  /// No description provided for @reportNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get reportNext;

  /// No description provided for @reportWhichKoreanStation.
  ///
  /// In ko, this message translates to:
  /// **'어느 역의 한글 표기인가요?'**
  String get reportWhichKoreanStation;

  /// No description provided for @reportWhichStation.
  ///
  /// In ko, this message translates to:
  /// **'어느 역 정보인가요?'**
  String get reportWhichStation;

  /// No description provided for @reportChooseStations.
  ///
  /// In ko, this message translates to:
  /// **'승차역·하차역을 선택해 주세요'**
  String get reportChooseStations;

  /// No description provided for @reportCorrectBoarding.
  ///
  /// In ko, this message translates to:
  /// **'올바른 승차역'**
  String get reportCorrectBoarding;

  /// No description provided for @reportCorrectAlighting.
  ///
  /// In ko, this message translates to:
  /// **'올바른 하차역'**
  String get reportCorrectAlighting;

  /// No description provided for @reportCorrectType.
  ///
  /// In ko, this message translates to:
  /// **'올바른 거래 유형'**
  String get reportCorrectType;

  /// No description provided for @reportChooseType.
  ///
  /// In ko, this message translates to:
  /// **'유형을 선택해 주세요'**
  String get reportChooseType;

  /// No description provided for @reportCustomType.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력한 거래 유형'**
  String get reportCustomType;

  /// No description provided for @reportTicketExample.
  ///
  /// In ko, this message translates to:
  /// **'예: 승차권 구매'**
  String get reportTicketExample;

  /// No description provided for @reportTransactionType.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형'**
  String get reportTransactionType;

  /// No description provided for @reportKoreanBoarding.
  ///
  /// In ko, this message translates to:
  /// **'승차역 한글 표기'**
  String get reportKoreanBoarding;

  /// No description provided for @reportKoreanAlighting.
  ///
  /// In ko, this message translates to:
  /// **'하차역 한글 표기'**
  String get reportKoreanAlighting;

  /// No description provided for @reportOptionalDetails.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명 (선택)'**
  String get reportOptionalDetails;

  /// No description provided for @reportDetailsHint.
  ///
  /// In ko, this message translates to:
  /// **'개인정보를 제외하고 추가로 알려줄 내용을 적어주세요.'**
  String get reportDetailsHint;

  /// No description provided for @reportBack.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get reportBack;

  /// No description provided for @reportReview.
  ///
  /// In ko, this message translates to:
  /// **'검토하기'**
  String get reportReview;

  /// No description provided for @reportReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'전송 전 확인'**
  String get reportReviewTitle;

  /// No description provided for @reportIssueType.
  ///
  /// In ko, this message translates to:
  /// **'제보 유형'**
  String get reportIssueType;

  /// No description provided for @reportAffectedStation.
  ///
  /// In ko, this message translates to:
  /// **'문제가 있는 역 정보'**
  String get reportAffectedStation;

  /// No description provided for @reportNotSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택되지 않음'**
  String get reportNotSelected;

  /// No description provided for @reportSuggestedType.
  ///
  /// In ko, this message translates to:
  /// **'제안 거래 유형'**
  String get reportSuggestedType;

  /// No description provided for @reportActualBus.
  ///
  /// In ko, this message translates to:
  /// **'실제 버스 회사명'**
  String get reportActualBus;

  /// No description provided for @reportBusArea.
  ///
  /// In ko, this message translates to:
  /// **'운행 도시·지역'**
  String get reportBusArea;

  /// No description provided for @reportSuggestedKoreanBoarding.
  ///
  /// In ko, this message translates to:
  /// **'제안 승차역 한글 표기'**
  String get reportSuggestedKoreanBoarding;

  /// No description provided for @reportNoInput.
  ///
  /// In ko, this message translates to:
  /// **'입력 없음'**
  String get reportNoInput;

  /// No description provided for @reportParsedBoardingLine.
  ///
  /// In ko, this message translates to:
  /// **'파서 확인 승차역 노선'**
  String get reportParsedBoardingLine;

  /// No description provided for @reportSuggestedKoreanAlighting.
  ///
  /// In ko, this message translates to:
  /// **'제안 하차역 한글 표기'**
  String get reportSuggestedKoreanAlighting;

  /// No description provided for @reportParsedAlightingLine.
  ///
  /// In ko, this message translates to:
  /// **'파서 확인 하차역 노선'**
  String get reportParsedAlightingLine;

  /// No description provided for @reportSelectedRecord.
  ///
  /// In ko, this message translates to:
  /// **'선택한 내역'**
  String get reportSelectedRecord;

  /// No description provided for @reportTypeAmount.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형 / 금액'**
  String get reportTypeAmount;

  /// No description provided for @reportUsageDate.
  ///
  /// In ko, this message translates to:
  /// **'이용 날짜'**
  String get reportUsageDate;

  /// No description provided for @reportAnonymousRecord.
  ///
  /// In ko, this message translates to:
  /// **'익명 원본 기록'**
  String get reportAnonymousRecord;

  /// No description provided for @reportPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 보호'**
  String get reportPrivacy;

  /// No description provided for @reportRecordPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'카드 IDm은 포함하지 않습니다. 선택한 이용내역 1건과 입력한 역·도시·노선, 버스 회사·도시 또는 거래 유형, 제보 내용만 전송 대상으로 준비합니다.'**
  String get reportRecordPrivacy;

  /// No description provided for @reportSendConsent.
  ///
  /// In ko, this message translates to:
  /// **'위 정보의 전송에 동의합니다.'**
  String get reportSendConsent;

  /// No description provided for @reportSendFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'제보를 전송하지 못했습니다'**
  String get reportSendFailedTitle;

  /// No description provided for @reportSendAnonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명으로 제보하기'**
  String get reportSendAnonymous;

  /// No description provided for @reportUnexpectedError.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.'**
  String get reportUnexpectedError;

  /// No description provided for @reportStationRequired.
  ///
  /// In ko, this message translates to:
  /// **'역 범위를 선택해 주세요.'**
  String get reportStationRequired;

  /// No description provided for @reportTypeRequired.
  ///
  /// In ko, this message translates to:
  /// **'올바른 거래 유형을 선택해 주세요.'**
  String get reportTypeRequired;

  /// No description provided for @reportCorrectStationInfo.
  ///
  /// In ko, this message translates to:
  /// **'올바른 역 정보'**
  String get reportCorrectStationInfo;

  /// No description provided for @reportBusInfo.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사 정보'**
  String get reportBusInfo;

  /// No description provided for @reportSuggestKorean.
  ///
  /// In ko, this message translates to:
  /// **'한글 역명 제안'**
  String get reportSuggestKorean;

  /// No description provided for @reportDetails.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명'**
  String get reportDetails;

  /// No description provided for @reportStationGuide.
  ///
  /// In ko, this message translates to:
  /// **'역 이름과 도시·지역을 입력해 주세요. 노선명은 알고 있는 경우에만 적어주세요.'**
  String get reportStationGuide;

  /// No description provided for @reportTypeGuide.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 선택하고, 없는 유형은 직접 입력해 주세요.'**
  String get reportTypeGuide;

  /// No description provided for @reportBusGuide.
  ///
  /// In ko, this message translates to:
  /// **'실제 버스 회사명과 운행 도시·지역을 입력해 주세요.'**
  String get reportBusGuide;

  /// No description provided for @reportKoreanGuide.
  ///
  /// In ko, this message translates to:
  /// **'승차역·하차역 중 해당 범위를 선택해 주세요. 한글 발음을 아는 경우에만 표기를 입력하면 됩니다.'**
  String get reportKoreanGuide;

  /// No description provided for @reportGeneralGuide.
  ///
  /// In ko, this message translates to:
  /// **'알고 있는 내용을 적어주시면 해석 정확도를 높이는 데 도움이 됩니다.'**
  String get reportGeneralGuide;

  /// No description provided for @reportNoCustomInput.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력 없음'**
  String get reportNoCustomInput;

  /// No description provided for @reportStationName.
  ///
  /// In ko, this message translates to:
  /// **'역 이름'**
  String get reportStationName;

  /// No description provided for @reportCity.
  ///
  /// In ko, this message translates to:
  /// **'도시·지역'**
  String get reportCity;

  /// No description provided for @reportOptionalLine.
  ///
  /// In ko, this message translates to:
  /// **'노선명 (선택)'**
  String get reportOptionalLine;

  /// No description provided for @reportKoreanName.
  ///
  /// In ko, this message translates to:
  /// **'한글 표기'**
  String get reportKoreanName;

  /// No description provided for @reportKoreanExample.
  ///
  /// In ko, this message translates to:
  /// **'예: 시부야 (모르면 비워 두세요)'**
  String get reportKoreanExample;

  /// No description provided for @reportBusOperator.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사명'**
  String get reportBusOperator;

  /// No description provided for @reportSelectKoreanStation.
  ///
  /// In ko, this message translates to:
  /// **'한글 표기를 추가할 역을 선택해 주세요.'**
  String get reportSelectKoreanStation;

  /// No description provided for @reportSelectIncorrectStation.
  ///
  /// In ko, this message translates to:
  /// **'표시되지 않거나 잘못된 역 정보를 선택해 주세요.'**
  String get reportSelectIncorrectStation;

  /// No description provided for @reportSelectCorrectType.
  ///
  /// In ko, this message translates to:
  /// **'올바른 거래 유형을 선택해 주세요'**
  String get reportSelectCorrectType;

  /// No description provided for @reportCustomTypeGuide.
  ///
  /// In ko, this message translates to:
  /// **'목록에 없는 유형은 직접 입력할 수 있습니다.'**
  String get reportCustomTypeGuide;

  /// No description provided for @reportBoarding.
  ///
  /// In ko, this message translates to:
  /// **'승차역'**
  String get reportBoarding;

  /// No description provided for @reportAlighting.
  ///
  /// In ko, this message translates to:
  /// **'하차역'**
  String get reportAlighting;

  /// No description provided for @reportBothStations.
  ///
  /// In ko, this message translates to:
  /// **'승차역과 하차역 모두'**
  String get reportBothStations;

  /// No description provided for @reportRail.
  ///
  /// In ko, this message translates to:
  /// **'철도 이용'**
  String get reportRail;

  /// No description provided for @reportBus.
  ///
  /// In ko, this message translates to:
  /// **'버스 이용'**
  String get reportBus;

  /// No description provided for @reportPurchase.
  ///
  /// In ko, this message translates to:
  /// **'물품 구매'**
  String get reportPurchase;

  /// No description provided for @reportCharge.
  ///
  /// In ko, this message translates to:
  /// **'충전'**
  String get reportCharge;

  /// No description provided for @reportGateWindow.
  ///
  /// In ko, this message translates to:
  /// **'개찰 창구 처리'**
  String get reportGateWindow;

  /// No description provided for @reportRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get reportRefund;

  /// No description provided for @reportAdjustment.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get reportAdjustment;

  /// No description provided for @reportCustomOption.
  ///
  /// In ko, this message translates to:
  /// **'목록에 없음 / 직접 입력'**
  String get reportCustomOption;

  /// No description provided for @reportSelectedHistory.
  ///
  /// In ko, this message translates to:
  /// **'선택한 이용내역'**
  String get reportSelectedHistory;

  /// No description provided for @reportUnknownBus.
  ///
  /// In ko, this message translates to:
  /// **'버스 회사 미확인'**
  String get reportUnknownBus;

  /// No description provided for @reportUnknownType.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형 미확인'**
  String get reportUnknownType;

  /// No description provided for @reportAmountUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'계산 불가'**
  String get reportAmountUnavailable;

  /// No description provided for @reportNeedsReview.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get reportNeedsReview;

  /// No description provided for @reportDiagnosticsUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 읽기 방식에서는 카드 진단을 지원하지 않아요.'**
  String get reportDiagnosticsUnsupported;

  /// No description provided for @reportScanPrompt.
  ///
  /// In ko, this message translates to:
  /// **'카드 한 장을 기기 뒷면 NFC 위치에 대 주세요.'**
  String get reportScanPrompt;

  /// No description provided for @reportDiagnosticsReady.
  ///
  /// In ko, this message translates to:
  /// **'진단 정보를 확인했어요. 아직 서버로 전송하지 않았어요.'**
  String get reportDiagnosticsReady;

  /// No description provided for @reportDiagnosticsCancelled.
  ///
  /// In ko, this message translates to:
  /// **'진단을 취소했어요.'**
  String get reportDiagnosticsCancelled;

  /// No description provided for @reportEnableNfc.
  ///
  /// In ko, this message translates to:
  /// **'NFC를 켠 뒤 다시 시도해 주세요.'**
  String get reportEnableNfc;

  /// No description provided for @reportDiagnosticsTimeout.
  ///
  /// In ko, this message translates to:
  /// **'시간이 초과됐어요. 다시 진단해 주세요.'**
  String get reportDiagnosticsTimeout;

  /// No description provided for @reportMetadataFailed.
  ///
  /// In ko, this message translates to:
  /// **'메타데이터를 읽지 못했어요. 최소 오류 코드와 설명만 문의할 수 있어요.'**
  String get reportMetadataFailed;

  /// No description provided for @reportDiagnosticsFailed.
  ///
  /// In ko, this message translates to:
  /// **'진단을 완료하지 못했어요. 다시 시도해 주세요.'**
  String get reportDiagnosticsFailed;

  /// No description provided for @reportViewPayload.
  ///
  /// In ko, this message translates to:
  /// **'전송 항목 전체 보기'**
  String get reportViewPayload;

  /// No description provided for @reportPayloadNotice.
  ///
  /// In ko, this message translates to:
  /// **'아래 내용만 전송해요. 이 화면을 여는 것만으로는 전송되지 않아요.'**
  String get reportPayloadNotice;

  /// No description provided for @reportClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get reportClose;

  /// No description provided for @reportSupportReceived.
  ///
  /// In ko, this message translates to:
  /// **'문의가 접수되었습니다'**
  String get reportSupportReceived;

  /// No description provided for @reportSupportPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'카드 IDm·잔액·이용내역은 전송되지 않았습니다.'**
  String get reportSupportPrivacy;

  /// No description provided for @reportConnectionRetry.
  ///
  /// In ko, this message translates to:
  /// **'전송하지 못했어요. 연결을 확인하고 다시 시도해 주세요.'**
  String get reportConnectionRetry;

  /// No description provided for @reportCardSupport.
  ///
  /// In ko, this message translates to:
  /// **'카드 인식 문의'**
  String get reportCardSupport;

  /// No description provided for @reportUnreadableQuestion.
  ///
  /// In ko, this message translates to:
  /// **'읽히지 않는 카드가 있나요?'**
  String get reportUnreadableQuestion;

  /// No description provided for @reportSupportIntro.
  ///
  /// In ko, this message translates to:
  /// **'카드 읽기·브랜드 구분 문제를 알려 주세요.\n일반 스캔의 이용내역은 바뀌지 않아요.'**
  String get reportSupportIntro;

  /// No description provided for @reportSupportTopic.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용'**
  String get reportSupportTopic;

  /// No description provided for @reportOptionalBrand.
  ///
  /// In ko, this message translates to:
  /// **'카드 브랜드 (선택)'**
  String get reportOptionalBrand;

  /// No description provided for @reportBrandExample.
  ///
  /// In ko, this message translates to:
  /// **'예: Kitaca · 모르면 비워 두세요'**
  String get reportBrandExample;

  /// No description provided for @reportOptionalProblem.
  ///
  /// In ko, this message translates to:
  /// **'문제 설명 (선택)'**
  String get reportOptionalProblem;

  /// No description provided for @reportProblemHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 문제가 있었나요?'**
  String get reportProblemHint;

  /// No description provided for @reportNoPersonalInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름·카드번호·연락처는 적지 마세요.'**
  String get reportNoPersonalInfo;

  /// No description provided for @reportMinimalDiagnostics.
  ///
  /// In ko, this message translates to:
  /// **'최소 진단 확인'**
  String get reportMinimalDiagnostics;

  /// No description provided for @reportDiagnosticsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'시스템 코드·제조 정보(PMm)·일부 서비스의 존재 여부·통신 오류 코드만 확인해요.\n카드 전체·서비스 본문·IDm·카드번호·잔액·이용내역은 수집하지 않아요.'**
  String get reportDiagnosticsPrivacy;

  /// No description provided for @reportScanConsent.
  ///
  /// In ko, this message translates to:
  /// **'최소 진단 확인에 동의해요'**
  String get reportScanConsent;

  /// No description provided for @reportCheckingCard.
  ///
  /// In ko, this message translates to:
  /// **'카드 확인 중…'**
  String get reportCheckingCard;

  /// No description provided for @reportDiagnosticScan.
  ///
  /// In ko, this message translates to:
  /// **'진단용 카드 스캔'**
  String get reportDiagnosticScan;

  /// No description provided for @reportCancelDiagnostics.
  ///
  /// In ko, this message translates to:
  /// **'진단 취소'**
  String get reportCancelDiagnostics;

  /// No description provided for @reportReviewPayload.
  ///
  /// In ko, this message translates to:
  /// **'전송할 내용 확인'**
  String get reportReviewPayload;

  /// No description provided for @reportSendInquiry.
  ///
  /// In ko, this message translates to:
  /// **'문의 전송'**
  String get reportSendInquiry;

  /// No description provided for @reportSupportRetention.
  ///
  /// In ko, this message translates to:
  /// **'문의·최소 진단·앱/OS 버전·접수 번호·동의 버전을 Supabase로 보내 카드 인식 개선에 사용해요.\n처리 완료 후 1년 뒤 삭제하며, 검토 중인 문의는 유지해요. 익명 인증 ID는 접수 제한에 사용해요.'**
  String get reportSupportRetention;

  /// No description provided for @reportSupportConsent.
  ///
  /// In ko, this message translates to:
  /// **'문의 전송에 동의해요'**
  String get reportSupportConsent;

  /// No description provided for @reportSupportUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'문의 서버가 준비되지 않았어요. 설정의 이메일로 연락해 주세요.'**
  String get reportSupportUnavailable;

  /// No description provided for @reportSending.
  ///
  /// In ko, this message translates to:
  /// **'전송 중…'**
  String get reportSending;

  /// No description provided for @reportAgreeSend.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 문의 보내기'**
  String get reportAgreeSend;

  /// No description provided for @reportEmailContact.
  ///
  /// In ko, this message translates to:
  /// **'개별 답변 문의: iccardreader10@gmail.com'**
  String get reportEmailContact;

  /// No description provided for @reportReadingError.
  ///
  /// In ko, this message translates to:
  /// **'카드 읽기 오류'**
  String get reportReadingError;

  /// No description provided for @reportBrandProblem.
  ///
  /// In ko, this message translates to:
  /// **'카드 브랜드 구분'**
  String get reportBrandProblem;

  /// No description provided for @reportChooseTopic.
  ///
  /// In ko, this message translates to:
  /// **'문의 유형 선택'**
  String get reportChooseTopic;

  /// No description provided for @reportReportReceived.
  ///
  /// In ko, this message translates to:
  /// **'제보가 접수되었습니다'**
  String get reportReportReceived;

  /// No description provided for @reportReportPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'카드 IDm과 다른 이용내역은 전송되지 않았습니다.'**
  String get reportReportPrivacy;

  /// No description provided for @reportReceiptUnknown.
  ///
  /// In ko, this message translates to:
  /// **'문의 접수를 확인하지 못했어요. 다시 시도해 주세요.'**
  String get reportReceiptUnknown;

  /// No description provided for @reportSupportRateLimit.
  ///
  /// In ko, this message translates to:
  /// **'접수가 많아요. 10분 뒤 다시 시도해 주세요.'**
  String get reportSupportRateLimit;

  /// No description provided for @reportSupportRestricted.
  ///
  /// In ko, this message translates to:
  /// **'문의 전송이 제한되었어요. 설정의 문의 이메일로 연락해 주세요.'**
  String get reportSupportRestricted;

  /// No description provided for @reportInvalidDiagnostics.
  ///
  /// In ko, this message translates to:
  /// **'전송 항목을 확인하지 못했어요. 다시 진단해 주세요.'**
  String get reportInvalidDiagnostics;

  /// No description provided for @reportSupportConnection.
  ///
  /// In ko, this message translates to:
  /// **'문의 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get reportSupportConnection;

  /// No description provided for @reportCheckConnection.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인한 뒤 다시 시도해 주세요.'**
  String get reportCheckConnection;

  /// No description provided for @reportReportNotReceived.
  ///
  /// In ko, this message translates to:
  /// **'제보를 접수하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get reportReportNotReceived;

  /// No description provided for @reportInvalidResponse.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답을 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.'**
  String get reportInvalidResponse;

  /// No description provided for @reportAnonymousConnection.
  ///
  /// In ko, this message translates to:
  /// **'익명 연결을 시작하지 못했습니다. 인터넷 연결을 확인해 주세요.'**
  String get reportAnonymousConnection;

  /// No description provided for @reportAlreadyReceived.
  ///
  /// In ko, this message translates to:
  /// **'이미 접수된 제보입니다.'**
  String get reportAlreadyReceived;

  /// No description provided for @reportReportRateLimit.
  ///
  /// In ko, this message translates to:
  /// **'짧은 시간에 제보가 많이 접수되었습니다. 10분 뒤 다시 시도해 주세요.'**
  String get reportReportRateLimit;

  /// No description provided for @reportReportRestricted.
  ///
  /// In ko, this message translates to:
  /// **'제보 전송이 제한되었습니다. 문의가 필요하면 앱 설정의 이메일로 연락해 주세요.'**
  String get reportReportRestricted;

  /// No description provided for @reportInvalidReport.
  ///
  /// In ko, this message translates to:
  /// **'제보 내용을 확인할 수 없습니다. 입력 내용을 다시 확인해 주세요.'**
  String get reportInvalidReport;

  /// No description provided for @reportServerConnection.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get reportServerConnection;

  /// No description provided for @reportReportUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'오류 제보 서버가 설정되지 않았습니다. 앱 설정을 확인해 주세요.'**
  String get reportReportUnavailable;

  /// No description provided for @reportUnreadableDescription.
  ///
  /// In ko, this message translates to:
  /// **'카드를 읽을 수 없어요'**
  String get reportUnreadableDescription;

  /// No description provided for @reportBrandDescription.
  ///
  /// In ko, this message translates to:
  /// **'카드 브랜드가 표시되지 않거나 달라요'**
  String get reportBrandDescription;

  /// No description provided for @reportStep.
  ///
  /// In ko, this message translates to:
  /// **'{step}/3 단계'**
  String reportStep(int step);

  /// No description provided for @reportRequiredField.
  ///
  /// In ko, this message translates to:
  /// **'{label}을 입력해 주세요.'**
  String reportRequiredField(String label);

  /// No description provided for @reportReceiptHelp.
  ///
  /// In ko, this message translates to:
  /// **'보내주신 내용은 확인 후\n앱 개선에 활용됩니다.'**
  String get reportReceiptHelp;

  /// No description provided for @reportReceiptId.
  ///
  /// In ko, this message translates to:
  /// **'접수 번호'**
  String get reportReceiptId;

  /// No description provided for @reportDone.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get reportDone;

  /// No description provided for @privacyOverviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 정보는 기본적으로 기기 안에서 처리됩니다'**
  String get privacyOverviewTitle;

  /// No description provided for @privacyOverviewBody.
  ///
  /// In ko, this message translates to:
  /// **'교통카드의 최근 이용내역은 NFC로 읽어 화면에 표시하며, 앱을 종료하면 유지하지 않습니다. 카드 IDm 원문은 NFC 통신 중에만 일시적으로 사용하고 저장·표시·전송하지 않습니다.'**
  String get privacyOverviewBody;

  /// No description provided for @privacyNfcTitle.
  ///
  /// In ko, this message translates to:
  /// **'1. NFC 사용 목적'**
  String get privacyNfcTitle;

  /// No description provided for @privacyNfcBody.
  ///
  /// In ko, this message translates to:
  /// **'NFC 권한은 사용자가 스캔을 시작했을 때 일본 교통계 IC 카드의 이용내역과 카드 종류를 확인하는 데 사용합니다. 별도 카드 인식 문의에서는 동의한 경우 최소 메타데이터만 확인합니다. 앱은 카드에 정보를 기록하거나 변경하지 않습니다.'**
  String get privacyNfcBody;

  /// No description provided for @privacyOnDeviceTitle.
  ///
  /// In ko, this message translates to:
  /// **'2. 기기 안에서 처리하는 정보'**
  String get privacyOnDeviceTitle;

  /// No description provided for @privacyOnDeviceBody.
  ///
  /// In ko, this message translates to:
  /// **'최근 이용내역의 원본 16바이트 기록, 날짜, 거래 유형, 역 코드·역명, 금액과 잔액을 기기 안에서 해석해 표시합니다. 이용내역은 영구 저장하지 않으며 일반 스캔에서 다른 카드를 읽으면 현재 결과로 교체됩니다.\n\n여러 카드 잔액 비교에서는 최대 10장의 이름·잔액·확인 시각과 이용내역을 비교 화면의 메모리에서만 보관합니다. 같은 카드 구분에는 매 비교마다 생성한 무작위 키로 만든 세션 한정 비교값을 사용하며 IDm 원문을 보관하지 않습니다. 비교값·키·카드 이름은 서버나 파일에 저장·전송하지 않고 비교 종료 또는 앱 프로세스 종료 시 정리합니다. 개별 카드 삭제 시 해당 비교 정보도 제거합니다. 비교용 스캔은 홈의 기존 카드 결과를 변경하지 않습니다.'**
  String get privacyOnDeviceBody;

  /// No description provided for @privacyReportsTitle.
  ///
  /// In ko, this message translates to:
  /// **'3. 오류 제보 시 전송하는 정보'**
  String get privacyReportsTitle;

  /// No description provided for @privacyReportsBody.
  ///
  /// In ko, this message translates to:
  /// **'오류 제보는 선택 사항입니다. 사용자가 미리보기를 확인하고 동의한 경우에만 선택한 이용내역 1건의 원본 기록과 코드·해석 결과, 이용 날짜, 금액·잔액, 입력한 역·도시·노선 또는 버스 회사·운행 도시/지역·설명, 앱·파서·역 데이터 버전, 플랫폼과 OS 버전을 Supabase로 전송합니다. 전송된 내용은 앱 개선을 위해 사용합니다.\n\n별도 카드 인식 문의는 이용내역 제보와 다릅니다. 진단 스캔에 동의하면 시스템 코드·제조 정보(PMm)·허용된 일부 서비스 존재 여부·통신 오류 코드만 기기에서 확인합니다. 다시 전송 항목·목적·보관 기간을 확인하고 명시적으로 동의한 경우에만 해당 최소 진단과 입력한 카드 종류·설명, 앱/OS 버전·접수 번호·동의 문서 버전을 Supabase로 전송합니다. 카드 종류 구분·읽기 오류 개선에 사용하며, 카드 전체 덤프·서비스 본문·잔액·이용내역은 이 문의에 포함하지 않습니다. 화면을 나가면 앱에 문의 내용을 남기지 않습니다.'**
  String get privacyReportsBody;

  /// No description provided for @privacyNotSentTitle.
  ///
  /// In ko, this message translates to:
  /// **'4. 전송하지 않는 정보'**
  String get privacyNotSentTitle;

  /// No description provided for @privacyNotSentBody.
  ///
  /// In ko, this message translates to:
  /// **'카드 IDm 원문, 선택하지 않은 다른 이용내역, 이름, 이메일 주소, 기기 고유 식별자, 현재 위치와 이동 경로는 제보 데이터에 포함하지 않습니다.'**
  String get privacyNotSentBody;

  /// No description provided for @privacyServicesTitle.
  ///
  /// In ko, this message translates to:
  /// **'5. 외부 처리 서비스'**
  String get privacyServicesTitle;

  /// No description provided for @privacyServicesBody.
  ///
  /// In ko, this message translates to:
  /// **'오류 제보 접수에는 Supabase의 익명 인증·서버·데이터베이스 기능을 사용합니다. 익명 인증 ID는 서버 내부에서 10분당 5건 제한과 악성 제보 차단에만 사용하며, 이메일·카드 IDm·기기 고유 ID가 아닙니다. 이 값은 앱 화면에 표시하지 않고 제보 내용과 함께 서버에서만 접근을 제한하는 데 사용합니다. 제보 내용은 Supabase 인프라를 통해 처리되고, 네트워크 연결 과정의 기술 정보는 해당 서비스 운영 정책에 따라 처리될 수 있습니다.'**
  String get privacyServicesBody;

  /// No description provided for @privacyMapsTitle.
  ///
  /// In ko, this message translates to:
  /// **'5-1. Google 지도'**
  String get privacyMapsTitle;

  /// No description provided for @privacyMapsBody.
  ///
  /// In ko, this message translates to:
  /// **'철도 이용내역 상세를 열면 인터넷 연결·역 위치·지도 설정을 확인한 경우 Google Maps SDK 지도를 자동으로 표시합니다. 복합역·구간은 후보 위치를 표시합니다. 표시할 역 주변 영역과 좌표가 지도 요청에 사용되며, Google은 IP 주소, 기기·운영체제·SDK 정보, SDK 전용 가명 식별값, 진단·사용 정보를 처리할 수 있습니다. 현재 위치 권한은 요청하지 않으며 카드 IDm·카드번호·잔액·이용내역 원문은 지도 SDK에 전달하지 않습니다. Google의 개인정보처리방침(https://policies.google.com/privacy)이 적용됩니다. 인터넷 연결이 확인되지 않으면 지도를 표시하지 않으며, 연결 후 지도 새로고침으로 다시 시도할 수 있습니다. 연결 상태는 Android 네트워크 기능 정보로 기기에서 확인하며 별도 확인 서버에 요청하지 않습니다. 지도 표시 중단이나 새로고침은 이미 발생한 지도 요청을 취소하거나 삭제하는 것은 아닙니다. 지도 연결 없이도 카드 읽기와 이용내역 목록은 사용할 수 있습니다. 앱은 지도 이용내역을 별도로 저장하지 않으며 Google의 보관·삭제 기준은 해당 정책을 따릅니다.'**
  String get privacyMapsBody;

  /// No description provided for @privacyStationDataTitle.
  ///
  /// In ko, this message translates to:
  /// **'6. 역 코드 데이터'**
  String get privacyStationDataTitle;

  /// No description provided for @privacyStationDataBody.
  ///
  /// In ko, this message translates to:
  /// **'역명 조회에는 허가받아 앱에 포함한 Yoiko 역 코드 데이터를 사용합니다. 조회는 기기 안에서 수행되며, 역명을 확인하기 위해 카드 기록을 외부 서버로 보내지 않습니다. 이용 조건은 설정의 데이터 출처 및 운임 기준 화면에서 확인할 수 있습니다.'**
  String get privacyStationDataBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In ko, this message translates to:
  /// **'7. 보관과 삭제'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In ko, this message translates to:
  /// **'기기에서 읽은 이용내역은 앱이 영구 저장하지 않습니다. 선택적으로 전송된 오류 제보 중 반영 완료 또는 제외된 문의와 검토 이력은 해결 후 1년간 보관한 뒤 매월 자동 삭제합니다. 확인 중인 문의는 실수로 삭제되지 않도록 자동 삭제하지 않습니다. 악성 제보 차단 정보는 서버 보안 목적에 한해 유지하며, 법령상 보존 의무가 있는 경우에는 해당 기간 동안 보관할 수 있습니다.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'8. 정책 변경과 문의'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In ko, this message translates to:
  /// **'데이터 처리 방식이 변경되면 이 방침과 시행일을 함께 갱신합니다. 개인정보 확인·삭제 요청, 앱 오류, 이용 방법과 기타 문의는 iccardreader10@gmail.com으로 접수합니다. 공개 방침: https://yohan020.github.io/ic_card_reader/'**
  String get privacyContactBody;

  /// No description provided for @privacyEffectiveDate.
  ///
  /// In ko, this message translates to:
  /// **'시행일: 2026년 10월 27일'**
  String get privacyEffectiveDate;

  /// No description provided for @passRegionHokkaido.
  ///
  /// In ko, this message translates to:
  /// **'홋카이도'**
  String get passRegionHokkaido;

  /// No description provided for @passRegionTohoku.
  ///
  /// In ko, this message translates to:
  /// **'도호쿠'**
  String get passRegionTohoku;

  /// No description provided for @passRegionKanto.
  ///
  /// In ko, this message translates to:
  /// **'도쿄·간토'**
  String get passRegionKanto;

  /// No description provided for @passRegionChubu.
  ///
  /// In ko, this message translates to:
  /// **'주부'**
  String get passRegionChubu;

  /// No description provided for @passRegionKansai.
  ///
  /// In ko, this message translates to:
  /// **'간사이'**
  String get passRegionKansai;

  /// No description provided for @passRegionChugoku.
  ///
  /// In ko, this message translates to:
  /// **'주고쿠'**
  String get passRegionChugoku;

  /// No description provided for @passRegionShikoku.
  ///
  /// In ko, this message translates to:
  /// **'시코쿠'**
  String get passRegionShikoku;

  /// No description provided for @passRegionKyushu.
  ///
  /// In ko, this message translates to:
  /// **'규슈'**
  String get passRegionKyushu;

  /// No description provided for @passRegionOkinawa.
  ///
  /// In ko, this message translates to:
  /// **'오키나와'**
  String get passRegionOkinawa;

  /// No description provided for @passRegionHokkaidoHint.
  ///
  /// In ko, this message translates to:
  /// **'삿포로·하코다테 등'**
  String get passRegionHokkaidoHint;

  /// No description provided for @passRegionTohokuHint.
  ///
  /// In ko, this message translates to:
  /// **'센다이·아오모리 등'**
  String get passRegionTohokuHint;

  /// No description provided for @passRegionKantoHint.
  ///
  /// In ko, this message translates to:
  /// **'도쿄·가나가와 지역 패스'**
  String get passRegionKantoHint;

  /// No description provided for @passRegionChubuHint.
  ///
  /// In ko, this message translates to:
  /// **'나고야·호쿠리쿠 등'**
  String get passRegionChubuHint;

  /// No description provided for @passRegionKansaiHint.
  ///
  /// In ko, this message translates to:
  /// **'오사카·교토·나라 지역 패스'**
  String get passRegionKansaiHint;

  /// No description provided for @passRegionChugokuHint.
  ///
  /// In ko, this message translates to:
  /// **'히로시마·오카야마 등'**
  String get passRegionChugokuHint;

  /// No description provided for @passRegionShikokuHint.
  ///
  /// In ko, this message translates to:
  /// **'마쓰야마·다카마쓰 등'**
  String get passRegionShikokuHint;

  /// No description provided for @passRegionKyushuHint.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카 지역 패스'**
  String get passRegionKyushuHint;

  /// No description provided for @passRegionOkinawaHint.
  ///
  /// In ko, this message translates to:
  /// **'나하·오키나와 지역'**
  String get passRegionOkinawaHint;

  /// No description provided for @passTitle.
  ///
  /// In ko, this message translates to:
  /// **'교통패스 비교'**
  String get passTitle;

  /// No description provided for @passIntro.
  ///
  /// In ko, this message translates to:
  /// **'입력한 이동 계획을 기준으로 일반 운임과 패스 가격을 비교합니다.'**
  String get passIntro;

  /// No description provided for @passCalculationBasis.
  ///
  /// In ko, this message translates to:
  /// **'계산 기준'**
  String get passCalculationBasis;

  /// No description provided for @passCalculationNotice.
  ///
  /// In ko, this message translates to:
  /// **'지원 데이터로 확인되는 이동만 계산합니다. 확인할 수 없는 운임은 합산하지 않으며, 구매 전 공식 상품 조건과 운임을 확인해 주세요.'**
  String get passCalculationNotice;

  /// No description provided for @passSapporo.
  ///
  /// In ko, this message translates to:
  /// **'삿포로 지하철 1일권'**
  String get passSapporo;

  /// No description provided for @passSapporoScope.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 · 전 구간'**
  String get passSapporoScope;

  /// No description provided for @passSubwayDescription.
  ///
  /// In ko, this message translates to:
  /// **'지하철 전 구간의 일반 운임과 비교합니다.'**
  String get passSubwayDescription;

  /// No description provided for @passSapporoPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥830'**
  String get passSapporoPeriod;

  /// No description provided for @passHokkaido.
  ///
  /// In ko, this message translates to:
  /// **'홋카이도 레일패스'**
  String get passHokkaido;

  /// No description provided for @passHokkaidoScope.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도선 · 보통차 지정석'**
  String get passHokkaidoScope;

  /// No description provided for @passHokkaidoDescription.
  ///
  /// In ko, this message translates to:
  /// **'5·7·10일권과 철도·버스 이동 예상 운임을 비교합니다.'**
  String get passHokkaidoDescription;

  /// No description provided for @passHokkaidoFive.
  ///
  /// In ko, this message translates to:
  /// **'5일권 · ¥23,000'**
  String get passHokkaidoFive;

  /// No description provided for @passHokkaidoSeven.
  ///
  /// In ko, this message translates to:
  /// **'7일권 · ¥29,000'**
  String get passHokkaidoSeven;

  /// No description provided for @passHokkaidoTen.
  ///
  /// In ko, this message translates to:
  /// **'10일권 · ¥38,000'**
  String get passHokkaidoTen;

  /// No description provided for @passTokyoScope.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Metro · 도에이 지하철'**
  String get passTokyoScope;

  /// No description provided for @passTokyoDescription.
  ///
  /// In ko, this message translates to:
  /// **'24·48·72시간권의 손익을 비교합니다.'**
  String get passTokyoDescription;

  /// No description provided for @passHours24.
  ///
  /// In ko, this message translates to:
  /// **'24시간'**
  String get passHours24;

  /// No description provided for @passHours48.
  ///
  /// In ko, this message translates to:
  /// **'48시간'**
  String get passHours48;

  /// No description provided for @passHours72.
  ///
  /// In ko, this message translates to:
  /// **'72시간'**
  String get passHours72;

  /// No description provided for @passEnokama.
  ///
  /// In ko, this message translates to:
  /// **'에노시마·가마쿠라 프리패스'**
  String get passEnokama;

  /// No description provided for @passEnokamaScope.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 · 오다큐 전철'**
  String get passEnokamaScope;

  /// No description provided for @passEnokamaDescription.
  ///
  /// In ko, this message translates to:
  /// **'출발역별 가격과 프리구간 운임을 비교합니다.'**
  String get passEnokamaDescription;

  /// No description provided for @passEnokamaPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · 발역별 가격'**
  String get passEnokamaPeriod;

  /// No description provided for @passEnoden.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 1일 승차권'**
  String get passEnoden;

  /// No description provided for @passEnodenScope.
  ///
  /// In ko, this message translates to:
  /// **'에노시마 전철 · 에노덴 전선'**
  String get passEnodenScope;

  /// No description provided for @passEnodenDescription.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 내부 이동의 일반 운임과 비교합니다.'**
  String get passEnodenDescription;

  /// No description provided for @passEnodenPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥800'**
  String get passEnodenPeriod;

  /// No description provided for @passHakone.
  ///
  /// In ko, this message translates to:
  /// **'하코네 프리패스'**
  String get passHakone;

  /// No description provided for @passHakoneScope.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 70개 출발역 · 하코네 교통수단'**
  String get passHakoneScope;

  /// No description provided for @passHakoneDescription.
  ///
  /// In ko, this message translates to:
  /// **'출발역별 성인 가격과 하코네 현지 운임을 비교합니다.'**
  String get passHakoneDescription;

  /// No description provided for @passDaysTwo.
  ///
  /// In ko, this message translates to:
  /// **'2일권'**
  String get passDaysTwo;

  /// No description provided for @passDaysThree.
  ///
  /// In ko, this message translates to:
  /// **'3일권'**
  String get passDaysThree;

  /// No description provided for @passTokunai.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 패스'**
  String get passTokunai;

  /// No description provided for @passTokunaiScope.
  ///
  /// In ko, this message translates to:
  /// **'도쿄 23구 내 지정 JR 구간'**
  String get passTokunaiScope;

  /// No description provided for @passTokunaiDescription.
  ///
  /// In ko, this message translates to:
  /// **'1일권과 적용 JR 구간의 일반 운임을 비교합니다.'**
  String get passTokunaiDescription;

  /// No description provided for @passTokunaiPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥870'**
  String get passTokunaiPeriod;

  /// No description provided for @passKyotoSubway.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철 1일권'**
  String get passKyotoSubway;

  /// No description provided for @passKyotoSubwayScope.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 · 전 구간'**
  String get passKyotoSubwayScope;

  /// No description provided for @passOsaka.
  ///
  /// In ko, this message translates to:
  /// **'오사카 주유패스'**
  String get passOsaka;

  /// No description provided for @passOsakaScope.
  ///
  /// In ko, this message translates to:
  /// **'오사카 메트로 · 사철 · 시티버스'**
  String get passOsakaScope;

  /// No description provided for @passOsakaDescription.
  ///
  /// In ko, this message translates to:
  /// **'1·2일권과 환승 경로의 일반 운임을 비교합니다.'**
  String get passOsakaDescription;

  /// No description provided for @passOsakaOne.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥3,500'**
  String get passOsakaOne;

  /// No description provided for @passOsakaTwo.
  ///
  /// In ko, this message translates to:
  /// **'2일권 · ¥5,000'**
  String get passOsakaTwo;

  /// No description provided for @passKyotoBus.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철·버스 1일권'**
  String get passKyotoBus;

  /// No description provided for @passKyotoBusScope.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 · 버스 예상 운임'**
  String get passKyotoBusScope;

  /// No description provided for @passKyotoBusDescription.
  ///
  /// In ko, this message translates to:
  /// **'지하철 자동 운임과 버스 이용 추정을 비교합니다.'**
  String get passKyotoBusDescription;

  /// No description provided for @passKyotoBusPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥1,100'**
  String get passKyotoBusPeriod;

  /// No description provided for @passHankyu.
  ///
  /// In ko, this message translates to:
  /// **'한큐패스 1일권'**
  String get passHankyu;

  /// No description provided for @passHankyuScope.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 전 노선'**
  String get passHankyuScope;

  /// No description provided for @passHankyuDescription.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 내부 이동의 일반 운임과 비교합니다.'**
  String get passHankyuDescription;

  /// No description provided for @passHankyuPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥1,300'**
  String get passHankyuPeriod;

  /// No description provided for @passKintetsu.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰 레일 패스'**
  String get passKintetsu;

  /// No description provided for @passKintetsuScope.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰 전철 · 이가철도 · 케이블카'**
  String get passKintetsuScope;

  /// No description provided for @passKintetsuDescription.
  ///
  /// In ko, this message translates to:
  /// **'권종별 적용 구간과 일반 운임을 비교합니다.'**
  String get passKintetsuDescription;

  /// No description provided for @passDaysOne.
  ///
  /// In ko, this message translates to:
  /// **'1일권'**
  String get passDaysOne;

  /// No description provided for @passDaysFive.
  ///
  /// In ko, this message translates to:
  /// **'5일권'**
  String get passDaysFive;

  /// No description provided for @passDaysFivePlus.
  ///
  /// In ko, this message translates to:
  /// **'5일권 Plus'**
  String get passDaysFivePlus;

  /// No description provided for @passOkayama.
  ///
  /// In ko, this message translates to:
  /// **'오카야마·구라시키 tabiwa 구루링 패스'**
  String get passOkayama;

  /// No description provided for @passOkayamaScope.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스'**
  String get passOkayamaScope;

  /// No description provided for @passOkayamaDescription.
  ///
  /// In ko, this message translates to:
  /// **'3일권과 철도·노면전차·버스 이동 운임을 비교합니다.'**
  String get passOkayamaDescription;

  /// No description provided for @passOkayamaPeriod.
  ///
  /// In ko, this message translates to:
  /// **'3일권 · ¥3,800'**
  String get passOkayamaPeriod;

  /// No description provided for @passHiroden.
  ///
  /// In ko, this message translates to:
  /// **'히로덴 전차 패스'**
  String get passHiroden;

  /// No description provided for @passHirodenScope.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 · 전차 전 노선'**
  String get passHirodenScope;

  /// No description provided for @passHirodenDescription.
  ///
  /// In ko, this message translates to:
  /// **'일반 운임과 1일·8시간·24시간권을 비교합니다.'**
  String get passHirodenDescription;

  /// No description provided for @passHirodenOne.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥700'**
  String get passHirodenOne;

  /// No description provided for @passHirodenEight.
  ///
  /// In ko, this message translates to:
  /// **'8시간권 · ¥600'**
  String get passHirodenEight;

  /// No description provided for @passHirodenTwentyFour.
  ///
  /// In ko, this message translates to:
  /// **'24시간권 · ¥700'**
  String get passHirodenTwentyFour;

  /// No description provided for @passNagasaki.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 패스'**
  String get passNagasaki;

  /// No description provided for @passNagasakiScope.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 · 노면전차 전 노선'**
  String get passNagasakiScope;

  /// No description provided for @passNagasakiDescription.
  ///
  /// In ko, this message translates to:
  /// **'IC·터치 기준 일반 운임과 1일·24시간권을 비교합니다.'**
  String get passNagasakiDescription;

  /// No description provided for @passNagasakiOne.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥600'**
  String get passNagasakiOne;

  /// No description provided for @passFukuoka.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카 지하철 1일권'**
  String get passFukuoka;

  /// No description provided for @passFukuokaScope.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 · 3개 노선'**
  String get passFukuokaScope;

  /// No description provided for @passFukuokaPeriod.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · ¥640'**
  String get passFukuokaPeriod;

  /// No description provided for @passYui.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 패스'**
  String get passYui;

  /// No description provided for @passYuiScope.
  ///
  /// In ko, this message translates to:
  /// **'오키나와 도시 모노레일 · 전 노선'**
  String get passYuiScope;

  /// No description provided for @passYuiDescription.
  ///
  /// In ko, this message translates to:
  /// **'24·48시간권과 유이레일 일반 운임을 비교합니다.'**
  String get passYuiDescription;

  /// No description provided for @passYuiOne.
  ///
  /// In ko, this message translates to:
  /// **'24시간 · ¥1,000'**
  String get passYuiOne;

  /// No description provided for @passYuiTwo.
  ///
  /// In ko, this message translates to:
  /// **'48시간 · ¥1,800'**
  String get passYuiTwo;

  /// No description provided for @passChooseRegion.
  ///
  /// In ko, this message translates to:
  /// **'비교할 지역을\n선택해 주세요'**
  String get passChooseRegion;

  /// No description provided for @passChooseRegionHint.
  ///
  /// In ko, this message translates to:
  /// **'여행할 지역을 먼저 선택하면 해당 지역의 교통패스를 볼 수 있습니다.'**
  String get passChooseRegionHint;

  /// No description provided for @passComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get passComingSoon;

  /// No description provided for @passStepSelect.
  ///
  /// In ko, this message translates to:
  /// **'패스 선택'**
  String get passStepSelect;

  /// No description provided for @passStepPlan.
  ///
  /// In ko, this message translates to:
  /// **'이용 계획'**
  String get passStepPlan;

  /// No description provided for @passStepResult.
  ///
  /// In ko, this message translates to:
  /// **'비교 결과'**
  String get passStepResult;

  /// No description provided for @passSelectStation.
  ///
  /// In ko, this message translates to:
  /// **'역 선택'**
  String get passSelectStation;

  /// No description provided for @passRemoveSegment.
  ///
  /// In ko, this message translates to:
  /// **'구간 삭제'**
  String get passRemoveSegment;

  /// No description provided for @passEstimateNote.
  ///
  /// In ko, this message translates to:
  /// **'입력한 교통 이용 기준의 예상 비교입니다.'**
  String get passEstimateNote;

  /// No description provided for @passChooseInRegion.
  ///
  /// In ko, this message translates to:
  /// **'{region}의\n교통패스를 선택해 주세요'**
  String passChooseInRegion(String region);

  /// No description provided for @passViewRegion.
  ///
  /// In ko, this message translates to:
  /// **'{region} 교통패스 {count}개 보기'**
  String passViewRegion(String region, int count);

  /// No description provided for @passRegionComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'{region} 교통패스 준비 중'**
  String passRegionComingSoon(String region);

  /// No description provided for @passCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String passCount(int count);

  /// No description provided for @passStartComparison.
  ///
  /// In ko, this message translates to:
  /// **'{title} 비교 시작'**
  String passStartComparison(String title);

  /// No description provided for @passSearchStation.
  ///
  /// In ko, this message translates to:
  /// **'{label}역 검색'**
  String passSearchStation(String label);

  /// No description provided for @passDeparture.
  ///
  /// In ko, this message translates to:
  /// **'출발'**
  String get passDeparture;

  /// No description provided for @passArrival.
  ///
  /// In ko, this message translates to:
  /// **'도착'**
  String get passArrival;

  /// No description provided for @passFlow001.
  ///
  /// In ko, this message translates to:
  /// **'이동 구간'**
  String get passFlow001;

  /// No description provided for @passFlow002.
  ///
  /// In ko, this message translates to:
  /// **'비교 결과 보기'**
  String get passFlow002;

  /// No description provided for @passFlow003.
  ///
  /// In ko, this message translates to:
  /// **'비우기'**
  String get passFlow003;

  /// No description provided for @passFlow004.
  ///
  /// In ko, this message translates to:
  /// **'성인 일반 운임 ¥{arg0}'**
  String passFlow004(String arg0);

  /// No description provided for @passFlow005.
  ///
  /// In ko, this message translates to:
  /// **'역 이름을 검색해 주세요'**
  String get passFlow005;

  /// No description provided for @passFlow006.
  ///
  /// In ko, this message translates to:
  /// **'이동 계획을 입력해 주세요'**
  String get passFlow006;

  /// No description provided for @passFlow007.
  ///
  /// In ko, this message translates to:
  /// **'이동 구간 추가'**
  String get passFlow007;

  /// No description provided for @passFlow008.
  ///
  /// In ko, this message translates to:
  /// **'패스가 더 이득이에요'**
  String get passFlow008;

  /// No description provided for @passFlow009.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}역 선택'**
  String passFlow009(String arg0);

  /// No description provided for @passFlow010.
  ///
  /// In ko, this message translates to:
  /// **'두 역을 선택하면 운임을 자동으로 확인합니다.'**
  String get passFlow010;

  /// No description provided for @passFlow011.
  ///
  /// In ko, this message translates to:
  /// **'예상 손익'**
  String get passFlow011;

  /// No description provided for @passFlow012.
  ///
  /// In ko, this message translates to:
  /// **'일반 운임과 같아요'**
  String get passFlow012;

  /// No description provided for @passFlow013.
  ///
  /// In ko, this message translates to:
  /// **'일치하는 역을 찾지 못했어요'**
  String get passFlow013;

  /// No description provided for @passFlow014.
  ///
  /// In ko, this message translates to:
  /// **'출발·도착 바꾸기'**
  String get passFlow014;

  /// No description provided for @passFlow015.
  ///
  /// In ko, this message translates to:
  /// **'개별 결제가 더 저렴해요'**
  String get passFlow015;

  /// No description provided for @passFlow016.
  ///
  /// In ko, this message translates to:
  /// **'다른 표기나 초성으로 다시 검색해 주세요.'**
  String get passFlow016;

  /// No description provided for @passFlow017.
  ///
  /// In ko, this message translates to:
  /// **'비교할 구간이 부족해요'**
  String get passFlow017;

  /// No description provided for @passFlow018.
  ///
  /// In ko, this message translates to:
  /// **'이 구간의 운임을 확인할 수 없습니다.'**
  String get passFlow018;

  /// No description provided for @passFlow019.
  ///
  /// In ko, this message translates to:
  /// **'찾고 싶은 역을 입력해 주세요'**
  String get passFlow019;

  /// No description provided for @passFlow020.
  ///
  /// In ko, this message translates to:
  /// **'패스 가격'**
  String get passFlow020;

  /// No description provided for @passFlow021.
  ///
  /// In ko, this message translates to:
  /// **'교통비 기준 ¥{arg0} 절약'**
  String passFlow021(String arg0);

  /// No description provided for @passFlow022.
  ///
  /// In ko, this message translates to:
  /// **'이동별 상세'**
  String get passFlow022;

  /// No description provided for @passFlow023.
  ///
  /// In ko, this message translates to:
  /// **'패스 가격과 일반 결제 예상 합계가 같아요'**
  String get passFlow023;

  /// No description provided for @passFlow024.
  ///
  /// In ko, this message translates to:
  /// **'현재 계획에서는 ¥{arg0} 차이'**
  String passFlow024(String arg0);

  /// No description provided for @passFlow025.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get passFlow025;

  /// No description provided for @passFlow026.
  ///
  /// In ko, this message translates to:
  /// **'패스 데이터를 불러오지 못했어요'**
  String get passFlow026;

  /// No description provided for @passFlow027.
  ///
  /// In ko, this message translates to:
  /// **'한국어·초성·일본어·영어로 검색할 수 있습니다.'**
  String get passFlow027;

  /// No description provided for @passFlow028.
  ///
  /// In ko, this message translates to:
  /// **'한국어·초성·일본어로 검색할 수 있습니다.'**
  String get passFlow028;

  /// No description provided for @passFlow029.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}회'**
  String passFlow029(String arg0);

  /// No description provided for @passFlow030.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철'**
  String get passFlow030;

  /// No description provided for @passFlow031.
  ///
  /// In ko, this message translates to:
  /// **'패스 출발역 선택'**
  String get passFlow031;

  /// No description provided for @passFlow032.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}일권'**
  String passFlow032(String arg0);

  /// No description provided for @passFlow033.
  ///
  /// In ko, this message translates to:
  /// **'1회 늘리기'**
  String get passFlow033;

  /// No description provided for @passFlow034.
  ///
  /// In ko, this message translates to:
  /// **'1회 줄이기'**
  String get passFlow034;

  /// No description provided for @passFlow035.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 출발역'**
  String passFlow035(String arg0);

  /// No description provided for @passFlow036.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}개 출발역'**
  String passFlow036(String arg0);

  /// No description provided for @passFlow037.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}시간'**
  String passFlow037(String arg0);

  /// No description provided for @passFlow038.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}일권 {arg1}엔'**
  String passFlow038(String arg0, String arg1);

  /// No description provided for @passFlow039.
  ///
  /// In ko, this message translates to:
  /// **'1회 ¥{arg0}'**
  String passFlow039(String arg0);

  /// No description provided for @passFlow040.
  ///
  /// In ko, this message translates to:
  /// **'24시간권'**
  String get passFlow040;

  /// No description provided for @passFlow041.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 {arg0}개'**
  String passFlow041(String arg0);

  /// No description provided for @passFlow042.
  ///
  /// In ko, this message translates to:
  /// **'검색어 지우기'**
  String get passFlow042;

  /// No description provided for @passFlow043.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰 전 노선과 이가철도'**
  String get passFlow043;

  /// No description provided for @passFlow044.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도'**
  String get passFlow044;

  /// No description provided for @passFlow045.
  ///
  /// In ko, this message translates to:
  /// **'노선 선택'**
  String get passFlow045;

  /// No description provided for @passFlow046.
  ///
  /// In ko, this message translates to:
  /// **'다마선'**
  String get passFlow046;

  /// No description provided for @passFlow047.
  ///
  /// In ko, this message translates to:
  /// **'도니치카 킵'**
  String get passFlow047;

  /// No description provided for @passFlow048.
  ///
  /// In ko, this message translates to:
  /// **'도에이 지하철'**
  String get passFlow048;

  /// No description provided for @passFlow049.
  ///
  /// In ko, this message translates to:
  /// **'버스 예상 운임'**
  String get passFlow049;

  /// No description provided for @passFlow050.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철'**
  String get passFlow050;

  /// No description provided for @passFlow051.
  ///
  /// In ko, this message translates to:
  /// **'실제로 개찰을 통과할 출발역과 하차역을 입력하면 운임을 자동으로 찾습니다.'**
  String get passFlow051;

  /// No description provided for @passFlow052.
  ///
  /// In ko, this message translates to:
  /// **'에노시마선'**
  String get passFlow052;

  /// No description provided for @passFlow053.
  ///
  /// In ko, this message translates to:
  /// **'오다와라선'**
  String get passFlow053;

  /// No description provided for @passFlow054.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 출발역을 선택해 주세요'**
  String get passFlow054;

  /// No description provided for @passFlow055.
  ///
  /// In ko, this message translates to:
  /// **'운임 데이터를 읽지 못했습니다'**
  String get passFlow055;

  /// No description provided for @passFlow056.
  ///
  /// In ko, this message translates to:
  /// **'유이레일'**
  String get passFlow056;

  /// No description provided for @passFlow057.
  ///
  /// In ko, this message translates to:
  /// **'일반 결제 예상 합계'**
  String get passFlow057;

  /// No description provided for @passFlow058.
  ///
  /// In ko, this message translates to:
  /// **'일치하는 출발역을 찾지 못했어요. 한글·초성·일본어로 다시 검색해 주세요.'**
  String get passFlow058;

  /// No description provided for @passFlow059.
  ///
  /// In ko, this message translates to:
  /// **'철도 일반 운임'**
  String get passFlow059;

  /// No description provided for @passFlow060.
  ///
  /// In ko, this message translates to:
  /// **'출발역 검색'**
  String get passFlow060;

  /// No description provided for @passFlow061.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철'**
  String get passFlow061;

  /// No description provided for @passFlow062.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철'**
  String get passFlow062;

  /// No description provided for @passFlow063.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철'**
  String get passFlow063;

  /// No description provided for @passFlow064.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본'**
  String get passFlow064;

  /// No description provided for @passFlow065.
  ///
  /// In ko, this message translates to:
  /// **' 버스는 직접 입력한 운임만 반영해요.'**
  String get passFlow065;

  /// No description provided for @passFlow066.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} · {arg1}개 구간 적용'**
  String passFlow066(String arg0, String arg1);

  /// No description provided for @passFlow067.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} · 오다와라 왕복 1회 포함'**
  String passFlow067(String arg0);

  /// No description provided for @passFlow068.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 가격'**
  String passFlow068(String arg0);

  /// No description provided for @passFlow069.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 검색'**
  String passFlow069(String arg0);

  /// No description provided for @passFlow070.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 기준으로 삿포로시 지하철의 성인 일반 운임만 합산합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.'**
  String passFlow070(String arg0);

  /// No description provided for @passFlow071.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 기준으로 성인 일반 운임을 1회 ¥240씩 합산합니다. 입력한 구간 하나를 별도로 운임이 청구되는 1회 이용으로 보며, MOBIRY DAYS 할인과 자동 환승·재승차 판정은 포함하지 않습니다.'**
  String passFlow071(String arg0);

  /// No description provided for @passFlow072.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 기준으로 성인 IC·터치 결제 운임을 합산합니다. 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함하며, 현금·버스·소아요금은 포함하지 않습니다.'**
  String passFlow072(String arg0);

  /// No description provided for @passFlow073.
  ///
  /// In ko, this message translates to:
  /// **'{arg0} 선택'**
  String passFlow073(String arg0);

  /// No description provided for @passFlow074.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}번 이동 · {arg1}'**
  String passFlow074(String arg0, String arg1);

  /// No description provided for @passFlow075.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}시간 ¥{arg1}'**
  String passFlow075(String arg0, String arg1);

  /// No description provided for @passFlow076.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}시간권'**
  String passFlow076(String arg0);

  /// No description provided for @passFlow077.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}시간권 {arg1}엔'**
  String passFlow077(String arg0, String arg1);

  /// No description provided for @passFlow078.
  ///
  /// In ko, this message translates to:
  /// **'{arg0}일권 ¥{arg1}'**
  String passFlow078(String arg0, String arg1);

  /// No description provided for @passFlow079.
  ///
  /// In ko, this message translates to:
  /// **'1일권 · JR 파생 운임'**
  String get passFlow079;

  /// No description provided for @passFlow080.
  ///
  /// In ko, this message translates to:
  /// **'1일권 ¥3,500 · 2일권 ¥5,000 · 환승 자동 계산'**
  String get passFlow080;

  /// No description provided for @passFlow081.
  ///
  /// In ko, this message translates to:
  /// **'1회 예상 ¥300'**
  String get passFlow081;

  /// No description provided for @passFlow082.
  ///
  /// In ko, this message translates to:
  /// **'24·48·72시간권 · 자동 운임'**
  String get passFlow082;

  /// No description provided for @passFlow083.
  ///
  /// In ko, this message translates to:
  /// **'2일'**
  String get passFlow083;

  /// No description provided for @passFlow084.
  ///
  /// In ko, this message translates to:
  /// **'2일권과 같은 나라교통 구간 및 미에교통·도바 카모메 버스 지정 구간'**
  String get passFlow084;

  /// No description provided for @passFlow085.
  ///
  /// In ko, this message translates to:
  /// **'3일'**
  String get passFlow085;

  /// No description provided for @passFlow086.
  ///
  /// In ko, this message translates to:
  /// **'8시간권'**
  String get passFlow086;

  /// No description provided for @passFlow087.
  ///
  /// In ko, this message translates to:
  /// **'검증된 철도·버스 운임 데이터를 불러오는 중입니다.'**
  String get passFlow087;

  /// No description provided for @passFlow088.
  ///
  /// In ko, this message translates to:
  /// **'검증할 패스를 선택해 주세요'**
  String get passFlow088;

  /// No description provided for @passFlow089.
  ///
  /// In ko, this message translates to:
  /// **'결과 사용 시 주의'**
  String get passFlow089;

  /// No description provided for @passFlow090.
  ///
  /// In ko, this message translates to:
  /// **'공개된 거리·운임 규칙으로 검증한 철도 운임과 오사카 시티버스 일반 운임을 자동 합산합니다. 관광시설 무료입장 가치는 포함하지 않습니다.'**
  String get passFlow090;

  /// No description provided for @passFlow091.
  ///
  /// In ko, this message translates to:
  /// **'공식 안내를 열 수 없어요.'**
  String get passFlow091;

  /// No description provided for @passFlow092.
  ///
  /// In ko, this message translates to:
  /// **'공식 안내에서 적용이 확인된 버스의 성인 일반 운임 합계만 입력해 주세요. 앱이 버스 적용 여부를 판정하지는 않아요.'**
  String get passFlow092;

  /// No description provided for @passFlow093.
  ///
  /// In ko, this message translates to:
  /// **'공식 적용 구간 확인'**
  String get passFlow093;

  /// No description provided for @passFlow094.
  ///
  /// In ko, this message translates to:
  /// **'관광시설 입장·할인 혜택은 포함하지 않습니다.'**
  String get passFlow094;

  /// No description provided for @passFlow095.
  ///
  /// In ko, this message translates to:
  /// **'관광시설 혜택, 패스 제외 버스, 특급권·좌석요금은 포함하지 않습니다. 사업자가 바뀌는 이동은 지원 역 그래프의 거리 기반 추천 경로로 계산하므로, 실제 이용 경로와 구매 전 최신 공식 조건을 확인해 주세요.'**
  String get passFlow095;

  /// No description provided for @passFlow096.
  ///
  /// In ko, this message translates to:
  /// **'관광시설 혜택은 제외하며, 버스 대표 요금은 실제 요금과 다를 수 있습니다.'**
  String get passFlow096;

  /// No description provided for @passFlow097.
  ///
  /// In ko, this message translates to:
  /// **'관광시설을 이용하면 추가 이득이 생길 수 있습니다.'**
  String get passFlow097;

  /// No description provided for @passFlow098.
  ///
  /// In ko, this message translates to:
  /// **'관광특급버스'**
  String get passFlow098;

  /// No description provided for @passFlow099.
  ///
  /// In ko, this message translates to:
  /// **'교토 버스 예상 이용'**
  String get passFlow099;

  /// No description provided for @passFlow100.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철·버스 1일권 기준 탑승 횟수를 직접 입력해 주세요.'**
  String get passFlow100;

  /// No description provided for @passFlow101.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow101;

  /// No description provided for @passFlow102.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 이동 구간을 입력해 주세요.'**
  String get passFlow102;

  /// No description provided for @passFlow103.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 일반 운임'**
  String get passFlow103;

  /// No description provided for @passFlow104.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 전 구간의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.'**
  String get passFlow104;

  /// No description provided for @passFlow105.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 전 구간의 성인 일반 운임만 합산합니다. 1일권은 이용일 당일 영업 종료까지 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.'**
  String get passFlow105;

  /// No description provided for @passFlow106.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철은 역 선택 기반 성인 일반 운임, 버스는 입력한 횟수 기반 예상 운임입니다.'**
  String get passFlow106;

  /// No description provided for @passFlow107.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철은 역을 선택하면 성인 운임을 자동으로 찾습니다.'**
  String get passFlow107;

  /// No description provided for @passFlow108.
  ///
  /// In ko, this message translates to:
  /// **'교통비만 보면 일반 결제가 저렴해요'**
  String get passFlow108;

  /// No description provided for @passFlow109.
  ///
  /// In ko, this message translates to:
  /// **'교통비만 비교합니다'**
  String get passFlow109;

  /// No description provided for @passFlow110.
  ///
  /// In ko, this message translates to:
  /// **'교통비만으로 ¥{arg0} 절약'**
  String passFlow110(String arg0);

  /// No description provided for @passFlow111.
  ///
  /// In ko, this message translates to:
  /// **'교통수단 선택'**
  String get passFlow111;

  /// No description provided for @passFlow112.
  ///
  /// In ko, this message translates to:
  /// **'교통패스 비교 프로토타입'**
  String get passFlow112;

  /// No description provided for @passFlow113.
  ///
  /// In ko, this message translates to:
  /// **'구간별 판정'**
  String get passFlow113;

  /// No description provided for @passFlow114.
  ///
  /// In ko, this message translates to:
  /// **'권종의 적용 범위 안에서 이동하는 구간만 계산해요. 특급권·로프웨이·할인·특전은 포함하지 않아요.'**
  String get passFlow114;

  /// No description provided for @passFlow115.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰에서 실제로 개찰을 통과할 출발역과 하차역을 입력하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow115;

  /// No description provided for @passFlow116.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 1일권'**
  String get passFlow116;

  /// No description provided for @passFlow117.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 24시간권'**
  String get passFlow117;

  /// No description provided for @passFlow118.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 이동 구간을 입력해 주세요.'**
  String get passFlow118;

  /// No description provided for @passFlow119.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 일반 운임'**
  String get passFlow119;

  /// No description provided for @passFlow120.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 정류장을 선택하면 IC·터치 기준 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow120;

  /// No description provided for @passFlow121.
  ///
  /// In ko, this message translates to:
  /// **'나라교통: 나라공원·니시노쿄·호류지 지정 구간'**
  String get passFlow121;

  /// No description provided for @passFlow122.
  ///
  /// In ko, this message translates to:
  /// **'나라교통: 나라공원·니시노쿄·호류지·아스카·무로·야마노베노미치 지정 구간'**
  String get passFlow122;

  /// No description provided for @passFlow123.
  ///
  /// In ko, this message translates to:
  /// **'노면전차·버스 이용'**
  String get passFlow123;

  /// No description provided for @passFlow124.
  ///
  /// In ko, this message translates to:
  /// **'노면전차·버스 일반 운임'**
  String get passFlow124;

  /// No description provided for @passFlow125.
  ///
  /// In ko, this message translates to:
  /// **'데이터 준비 중'**
  String get passFlow125;

  /// No description provided for @passFlow126.
  ///
  /// In ko, this message translates to:
  /// **'도착역'**
  String get passFlow126;

  /// No description provided for @passFlow127.
  ///
  /// In ko, this message translates to:
  /// **'도쿄메트로'**
  String get passFlow127;

  /// No description provided for @passFlow128.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 패스 1일권'**
  String get passFlow128;

  /// No description provided for @passFlow129.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 패스 적용 JR'**
  String get passFlow129;

  /// No description provided for @passFlow130.
  ///
  /// In ko, this message translates to:
  /// **'두 지점을 선택하면 성인 일반 운임을 확인합니다.'**
  String get passFlow130;

  /// No description provided for @passFlow131.
  ///
  /// In ko, this message translates to:
  /// **'등산전차'**
  String get passFlow131;

  /// No description provided for @passFlow132.
  ///
  /// In ko, this message translates to:
  /// **'등산전차·케이블카·로프웨이·해적선은 정확 운임으로, 버스는 평균 운임과 횟수로 계산합니다. 로망스카 특급권은 포함하지 않습니다.'**
  String get passFlow132;

  /// No description provided for @passFlow133.
  ///
  /// In ko, this message translates to:
  /// **'로프웨이'**
  String get passFlow133;

  /// No description provided for @passFlow134.
  ///
  /// In ko, this message translates to:
  /// **'버스 대표 요금은 실제 이용 구간의 요금과 다를 수 있습니다.'**
  String get passFlow134;

  /// No description provided for @passFlow135.
  ///
  /// In ko, this message translates to:
  /// **'버스 운임 (선택)'**
  String get passFlow135;

  /// No description provided for @passFlow136.
  ///
  /// In ko, this message translates to:
  /// **'버스 운임은 예상값입니다'**
  String get passFlow136;

  /// No description provided for @passFlow137.
  ///
  /// In ko, this message translates to:
  /// **'버스 이용 추정'**
  String get passFlow137;

  /// No description provided for @passFlow138.
  ///
  /// In ko, this message translates to:
  /// **'버스 이용 횟수 늘리기'**
  String get passFlow138;

  /// No description provided for @passFlow139.
  ///
  /// In ko, this message translates to:
  /// **'버스 이용 횟수 줄이기'**
  String get passFlow139;

  /// No description provided for @passFlow140.
  ///
  /// In ko, this message translates to:
  /// **'버스는 추정 요금이며, 실제 경로·환승 운임에 따라 차이가 날 수 있습니다.'**
  String get passFlow140;

  /// No description provided for @passFlow141.
  ///
  /// In ko, this message translates to:
  /// **'버스는 횟수 기반 예상 운임입니다'**
  String get passFlow141;

  /// No description provided for @passFlow142.
  ///
  /// In ko, this message translates to:
  /// **'보통·쾌속'**
  String get passFlow142;

  /// No description provided for @passFlow143.
  ///
  /// In ko, this message translates to:
  /// **'비교 제외'**
  String get passFlow143;

  /// No description provided for @passFlow144.
  ///
  /// In ko, this message translates to:
  /// **'비교 제외 외부 운임'**
  String get passFlow144;

  /// No description provided for @passFlow145.
  ///
  /// In ko, this message translates to:
  /// **'비교할 이동이 부족해요'**
  String get passFlow145;

  /// No description provided for @passFlow146.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow146;

  /// No description provided for @passFlow147.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 이동 구간을 입력해 주세요.'**
  String get passFlow147;

  /// No description provided for @passFlow148.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 일반 운임'**
  String get passFlow148;

  /// No description provided for @passFlow149.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.'**
  String get passFlow149;

  /// No description provided for @passFlow150.
  ///
  /// In ko, this message translates to:
  /// **'선택한 권종 안의 성인 기본 운임만 합산해요. 범위를 넘는 이동의 정산액, 특급권·로프웨이·할인·특전은 포함하지 않아요.{arg0}'**
  String passFlow150(String arg0);

  /// No description provided for @passFlow151.
  ///
  /// In ko, this message translates to:
  /// **'선택한 오다큐 출발역의 패스 가격과 후지사와 왕복 성인 IC 운임, 프리구간의 실제 입력 이동만 비교합니다.'**
  String get passFlow151;

  /// No description provided for @passFlow152.
  ///
  /// In ko, this message translates to:
  /// **'성인 일반 운임만 기준으로 하코네 프리패스의 손익을 비교합니다.'**
  String get passFlow152;

  /// No description provided for @passFlow153.
  ///
  /// In ko, this message translates to:
  /// **'성인 일반 운임을 1회 ¥240으로 계산합니다. 입력한 구간 하나를 별도로 운임이 청구되는 1회 이용으로 보며, MOBIRY DAYS 할인과 자동 환승·재승차 판정은 포함하지 않습니다.'**
  String get passFlow153;

  /// No description provided for @passFlow154.
  ///
  /// In ko, this message translates to:
  /// **'성인 IC·터치 결제 기준 운임을 계산합니다. 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함하며, 현금·버스·소아요금은 포함하지 않습니다.'**
  String get passFlow154;

  /// No description provided for @passFlow155.
  ///
  /// In ko, this message translates to:
  /// **'시모덴 버스 대표 운임'**
  String get passFlow155;

  /// No description provided for @passFlow156.
  ///
  /// In ko, this message translates to:
  /// **'시티버스 일반 운임'**
  String get passFlow156;

  /// No description provided for @passFlow157.
  ///
  /// In ko, this message translates to:
  /// **'실제로 개찰을 통과해 하차한 역을 입력해 주세요. 추천 경로는 시간표 기반 최속 경로가 아닙니다.'**
  String get passFlow157;

  /// No description provided for @passFlow158.
  ///
  /// In ko, this message translates to:
  /// **'실제로 개찰을 통과해 하차한 역을 입력해 주세요. 확인되지 않은 운임은 계산하지 않습니다.'**
  String get passFlow158;

  /// No description provided for @passFlow159.
  ///
  /// In ko, this message translates to:
  /// **'아직 비교할 이동이 없어요'**
  String get passFlow159;

  /// No description provided for @passFlow160.
  ///
  /// In ko, this message translates to:
  /// **'앱을 다시 실행하거나 다시 시도해 주세요.'**
  String get passFlow160;

  /// No description provided for @passFlow161.
  ///
  /// In ko, this message translates to:
  /// **'약 ¥{arg0}/회'**
  String passFlow161(String arg0);

  /// No description provided for @passFlow162.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 이동 구간을 입력해 주세요.'**
  String get passFlow162;

  /// No description provided for @passFlow163.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 일반 운임'**
  String get passFlow163;

  /// No description provided for @passFlow164.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 전선 15개 역의 성인 일반 운임만 합산합니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.'**
  String get passFlow164;

  /// No description provided for @passFlow165.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 전선 내부 이동의 성인 일반 운임만 계산합니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.'**
  String get passFlow165;

  /// No description provided for @passFlow166.
  ///
  /// In ko, this message translates to:
  /// **'에노덴·오다큐 프리구간 역을 검색할 수 있습니다.'**
  String get passFlow166;

  /// No description provided for @passFlow167.
  ///
  /// In ko, this message translates to:
  /// **'에노덴에서 실제로 개찰을 통과할 출발역과 하차역을 입력하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow167;

  /// No description provided for @passFlow168.
  ///
  /// In ko, this message translates to:
  /// **'에노시마 전철'**
  String get passFlow168;

  /// No description provided for @passFlow169.
  ///
  /// In ko, this message translates to:
  /// **'에노시마 전철 · 에노덴'**
  String get passFlow169;

  /// No description provided for @passFlow170.
  ///
  /// In ko, this message translates to:
  /// **'에노시마·가마쿠라 프리패스 1일권'**
  String get passFlow170;

  /// No description provided for @passFlow171.
  ///
  /// In ko, this message translates to:
  /// **'역'**
  String get passFlow171;

  /// No description provided for @passFlow172.
  ///
  /// In ko, this message translates to:
  /// **'역 구매 가격 · 사전 구매 시 ¥1,000 저렴'**
  String get passFlow172;

  /// No description provided for @passFlow173.
  ///
  /// In ko, this message translates to:
  /// **'역과 운임 데이터를 준비한 뒤 다시 시도해 주세요.'**
  String get passFlow173;

  /// No description provided for @passFlow174.
  ///
  /// In ko, this message translates to:
  /// **'예: 800'**
  String get passFlow174;

  /// No description provided for @passFlow175.
  ///
  /// In ko, this message translates to:
  /// **'예상 비용 차이가 없습니다'**
  String get passFlow175;

  /// No description provided for @passFlow176.
  ///
  /// In ko, this message translates to:
  /// **'예상 절약액 ¥{arg0}'**
  String passFlow176(String arg0);

  /// No description provided for @passFlow177.
  ///
  /// In ko, this message translates to:
  /// **'오사카 시티버스'**
  String get passFlow177;

  /// No description provided for @passFlow178.
  ///
  /// In ko, this message translates to:
  /// **'오사카 시티버스 {arg0}회'**
  String passFlow178(String arg0);

  /// No description provided for @passFlow179.
  ///
  /// In ko, this message translates to:
  /// **'오사카 주유패스 1일권'**
  String get passFlow179;

  /// No description provided for @passFlow180.
  ///
  /// In ko, this message translates to:
  /// **'오사카 주유패스 2일권'**
  String get passFlow180;

  /// No description provided for @passFlow181.
  ///
  /// In ko, this message translates to:
  /// **'오사카·나라·교토의 긴테쓰 노선 (오사카선은 산본마쓰까지)'**
  String get passFlow181;

  /// No description provided for @passFlow182.
  ///
  /// In ko, this message translates to:
  /// **'오사카난바–긴테쓰나라, 교토–쓰쓰이, 나가타–이코마, 도리이마에–이코마산조'**
  String get passFlow182;

  /// No description provided for @passFlow183.
  ///
  /// In ko, this message translates to:
  /// **'오사카는 교통비만 비교합니다'**
  String get passFlow183;

  /// No description provided for @passFlow184.
  ///
  /// In ko, this message translates to:
  /// **'오카야마·구라시키 tabiwa 구루링 패스 3일권'**
  String get passFlow184;

  /// No description provided for @passFlow185.
  ///
  /// In ko, this message translates to:
  /// **'운영사 정보 없음'**
  String get passFlow185;

  /// No description provided for @passFlow186.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 {arg0}'**
  String passFlow186(String arg0);

  /// No description provided for @passFlow187.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow187;

  /// No description provided for @passFlow188.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 이동 구간을 입력해 주세요.'**
  String get passFlow188;

  /// No description provided for @passFlow189.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 일반 운임'**
  String get passFlow189;

  /// No description provided for @passFlow190.
  ///
  /// In ko, this message translates to:
  /// **'유이레일의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.'**
  String get passFlow190;

  /// No description provided for @passFlow191.
  ///
  /// In ko, this message translates to:
  /// **'유이레일의 성인 일반 운임만 합산합니다. {arg0}시간권은 발권 시점부터 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.'**
  String passFlow191(String arg0);

  /// No description provided for @passFlow192.
  ///
  /// In ko, this message translates to:
  /// **'유효시간 밖'**
  String get passFlow192;

  /// No description provided for @passFlow193.
  ///
  /// In ko, this message translates to:
  /// **'유효한 이동 구간을 입력하면 판정 근거가 표시됩니다.'**
  String get passFlow193;

  /// No description provided for @passFlow194.
  ///
  /// In ko, this message translates to:
  /// **'이 권종의 적용 범위 밖이에요. 비교 합계에서 제외합니다.'**
  String get passFlow194;

  /// No description provided for @passFlow195.
  ///
  /// In ko, this message translates to:
  /// **'이동 계획 수정'**
  String get passFlow195;

  /// No description provided for @passFlow196.
  ///
  /// In ko, this message translates to:
  /// **'이용 당일 이동만 입력해 주세요.'**
  String get passFlow196;

  /// No description provided for @passFlow197.
  ///
  /// In ko, this message translates to:
  /// **'이용 시작일부터 연속 {arg0}일간의 이동만 입력해 주세요.'**
  String passFlow197(String arg0);

  /// No description provided for @passFlow198.
  ///
  /// In ko, this message translates to:
  /// **'이용 열차'**
  String get passFlow198;

  /// No description provided for @passFlow199.
  ///
  /// In ko, this message translates to:
  /// **'이용 횟수'**
  String get passFlow199;

  /// No description provided for @passFlow200.
  ///
  /// In ko, this message translates to:
  /// **'이용할 교통수단의 횟수를 입력해 주세요.'**
  String get passFlow200;

  /// No description provided for @passFlow201.
  ///
  /// In ko, this message translates to:
  /// **'일반 1일권'**
  String get passFlow201;

  /// No description provided for @passFlow202.
  ///
  /// In ko, this message translates to:
  /// **'일반 결제가 더 저렴해요'**
  String get passFlow202;

  /// No description provided for @passFlow203.
  ///
  /// In ko, this message translates to:
  /// **'일반 시내버스'**
  String get passFlow203;

  /// No description provided for @passFlow204.
  ///
  /// In ko, this message translates to:
  /// **'일반 시내버스와 관광특급버스 횟수만 합산합니다. 실제 노선·사업자·조정 운임 구간·심야 할증과 패스 제외 노선은 자동 판정하지 않습니다.'**
  String get passFlow204;

  /// No description provided for @passFlow205.
  ///
  /// In ko, this message translates to:
  /// **'일반 운임 합계'**
  String get passFlow205;

  /// No description provided for @passFlow206.
  ///
  /// In ko, this message translates to:
  /// **'일부 특정 노선과 온디맨드 버스는 패스 대상이 아닙니다.'**
  String get passFlow206;

  /// No description provided for @passFlow207.
  ///
  /// In ko, this message translates to:
  /// **'입력한 교통 이용 기준의 예상 비교입니다.\n버스는 추정 요금이며 실제 요금과 다를 수 있습니다.\n\n패스 가격 ¥{arg0}\n입력 구간 운임 ¥{arg1}\n버스 예상 운임 ¥{arg2}\n예상 손익 ¥{arg3}'**
  String passFlow207(String arg0, String arg1, String arg2, String arg3);

  /// No description provided for @passFlow208.
  ///
  /// In ko, this message translates to:
  /// **'적용 버스 운임 (직접 입력)'**
  String get passFlow208;

  /// No description provided for @passFlow209.
  ///
  /// In ko, this message translates to:
  /// **'적용 버스 운임 합계'**
  String get passFlow209;

  /// No description provided for @passFlow210.
  ///
  /// In ko, this message translates to:
  /// **'적용 범위 밖 · 합계 제외'**
  String get passFlow210;

  /// No description provided for @passFlow211.
  ///
  /// In ko, this message translates to:
  /// **'적용 철도 일반 운임'**
  String get passFlow211;

  /// No description provided for @passFlow212.
  ///
  /// In ko, this message translates to:
  /// **'정류장별 운임이 아닌 사업자별 평균 성인 운임입니다.'**
  String get passFlow212;

  /// No description provided for @passFlow213.
  ///
  /// In ko, this message translates to:
  /// **'주유패스 대상 일반 노선'**
  String get passFlow213;

  /// No description provided for @passFlow214.
  ///
  /// In ko, this message translates to:
  /// **'주유패스 대상 일반 노선 탑승 횟수 · 1회 ¥{arg0}'**
  String passFlow214(String arg0);

  /// No description provided for @passFlow215.
  ///
  /// In ko, this message translates to:
  /// **'지원 데이터에서 경로를 확인할 수 없습니다.'**
  String get passFlow215;

  /// No description provided for @passFlow216.
  ///
  /// In ko, this message translates to:
  /// **'지원 데이터에서 해당 역 사이의 경로와 운임을 찾지 못했습니다.'**
  String get passFlow216;

  /// No description provided for @passFlow217.
  ///
  /// In ko, this message translates to:
  /// **'지하철 구간 또는 버스 이용 횟수를 입력해 주세요.'**
  String get passFlow217;

  /// No description provided for @passFlow218.
  ///
  /// In ko, this message translates to:
  /// **'지하철 일반 운임'**
  String get passFlow218;

  /// No description provided for @passFlow219.
  ///
  /// In ko, this message translates to:
  /// **'지하철은 실제 개찰을 통과해 하차한 역을 입력해 주세요. 버스 운임 기준은 설정의 데이터 출처 및 운임 기준에서 확인할 수 있습니다.'**
  String get passFlow219;

  /// No description provided for @passFlow220.
  ///
  /// In ko, this message translates to:
  /// **'참고용 자동 계산 결과'**
  String get passFlow220;

  /// No description provided for @passFlow221.
  ///
  /// In ko, this message translates to:
  /// **'철도 {arg0}역·환승 연결 {arg1}개와 시티버스 일반 운임을 사용합니다. 관광시설 혜택은 포함하지 않습니다.'**
  String passFlow221(String arg0, String arg1);

  /// No description provided for @passFlow222.
  ///
  /// In ko, this message translates to:
  /// **'철도 구간을 선택하거나 버스 탑승 횟수를 입력해 주세요.'**
  String get passFlow222;

  /// No description provided for @passFlow223.
  ///
  /// In ko, this message translates to:
  /// **'출발역'**
  String get passFlow223;

  /// No description provided for @passFlow224.
  ///
  /// In ko, this message translates to:
  /// **'출발역 ↔ 후지사와 왕복 포함'**
  String get passFlow224;

  /// No description provided for @passFlow225.
  ///
  /// In ko, this message translates to:
  /// **'출발역과 도착역 바꾸기'**
  String get passFlow225;

  /// No description provided for @passFlow226.
  ///
  /// In ko, this message translates to:
  /// **'출발역과 도착역을 모두 선택해 주세요.'**
  String get passFlow226;

  /// No description provided for @passFlow227.
  ///
  /// In ko, this message translates to:
  /// **'출발역과 도착역을 선택한 이동 구간을 추가하면 손익을 계산합니다.'**
  String get passFlow227;

  /// No description provided for @passFlow228.
  ///
  /// In ko, this message translates to:
  /// **'출발역과 도착역을 선택해 주세요'**
  String get passFlow228;

  /// No description provided for @passFlow229.
  ///
  /// In ko, this message translates to:
  /// **'출발역에 따라 {arg0}일권 가격이 달라집니다.'**
  String passFlow229(String arg0);

  /// No description provided for @passFlow230.
  ///
  /// In ko, this message translates to:
  /// **'출발역에 따라 패스 가격이 달라집니다.'**
  String get passFlow230;

  /// No description provided for @passFlow231.
  ///
  /// In ko, this message translates to:
  /// **'출발역을 선택하면 {arg0}일권 가격을 적용합니다.'**
  String passFlow231(String arg0);

  /// No description provided for @passFlow232.
  ///
  /// In ko, this message translates to:
  /// **'출발역을 선택하면 해당 패스 가격을 적용합니다.'**
  String get passFlow232;

  /// No description provided for @passFlow233.
  ///
  /// In ko, this message translates to:
  /// **'케이블카'**
  String get passFlow233;

  /// No description provided for @passFlow234.
  ///
  /// In ko, this message translates to:
  /// **'탑승 횟수'**
  String get passFlow234;

  /// No description provided for @passFlow235.
  ///
  /// In ko, this message translates to:
  /// **'토·일·공휴일 및 12/29~1/3에만 이용할 수 있어요.'**
  String get passFlow235;

  /// No description provided for @passFlow236.
  ///
  /// In ko, this message translates to:
  /// **'특급'**
  String get passFlow236;

  /// No description provided for @passFlow237.
  ///
  /// In ko, this message translates to:
  /// **'특급은 보통차 지정석 기준으로 계산합니다. 버스는 1회 ¥300의 예상값입니다.'**
  String get passFlow237;

  /// No description provided for @passFlow238.
  ///
  /// In ko, this message translates to:
  /// **'패스 가격보다 ¥{arg0} 적습니다.'**
  String passFlow238(String arg0);

  /// No description provided for @passFlow239.
  ///
  /// In ko, this message translates to:
  /// **'패스 적용'**
  String get passFlow239;

  /// No description provided for @passFlow240.
  ///
  /// In ko, this message translates to:
  /// **'패스 적용 구간 일반 운임'**
  String get passFlow240;

  /// No description provided for @passFlow241.
  ///
  /// In ko, this message translates to:
  /// **'패스 적용 구간과 운임을 입력해 주세요'**
  String get passFlow241;

  /// No description provided for @passFlow242.
  ///
  /// In ko, this message translates to:
  /// **'패스 적용 범위를 벗어나요.'**
  String get passFlow242;

  /// No description provided for @passFlow243.
  ///
  /// In ko, this message translates to:
  /// **'패스 적용 외'**
  String get passFlow243;

  /// No description provided for @passFlow244.
  ///
  /// In ko, this message translates to:
  /// **'패스 출발역과 에노덴·오다큐 프리구간 이동을 입력하면 성인 IC 기준 운임을 비교합니다.'**
  String get passFlow244;

  /// No description provided for @passFlow245.
  ///
  /// In ko, this message translates to:
  /// **'패스 출발역과 후지사와 사이의 왕복 1회, 에노덴 전선과 오다큐 후지사와–가타세에노시마 구간만 계산합니다. 프리구간 밖 추가 이동, 특급·좌석요금과 할인은 포함하지 않습니다.'**
  String get passFlow245;

  /// No description provided for @passFlow246.
  ///
  /// In ko, this message translates to:
  /// **'패스가 적용되는 이동 구간을 입력해 주세요.'**
  String get passFlow246;

  /// No description provided for @passFlow247.
  ///
  /// In ko, this message translates to:
  /// **'패스를 사면 ¥{arg0} 더 들어요'**
  String passFlow247(String arg0);

  /// No description provided for @passFlow248.
  ///
  /// In ko, this message translates to:
  /// **'프로토타입'**
  String get passFlow248;

  /// No description provided for @passFlow249.
  ///
  /// In ko, this message translates to:
  /// **'프로토타입 asset을 다시 생성한 뒤 실행해 주세요.'**
  String get passFlow249;

  /// No description provided for @passFlow250.
  ///
  /// In ko, this message translates to:
  /// **'프리구간 내부 출발역'**
  String get passFlow250;

  /// No description provided for @passFlow251.
  ///
  /// In ko, this message translates to:
  /// **'하코네 프리패스 {arg0}일권'**
  String passFlow251(String arg0);

  /// No description provided for @passFlow252.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 87개 역의 성인 일반 운임만 합산합니다. 고베고속선과 다른 회사 환승은 포함하지 않습니다.'**
  String get passFlow252;

  /// No description provided for @passFlow253.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 내부 이동만 계산합니다. 고베고속선, 특급·좌석요금, 할인과 다른 회사 환승은 포함하지 않습니다.'**
  String get passFlow253;

  /// No description provided for @passFlow254.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow254;

  /// No description provided for @passFlow255.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 이동 구간을 입력해 주세요.'**
  String get passFlow255;

  /// No description provided for @passFlow256.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 일반 운임'**
  String get passFlow256;

  /// No description provided for @passFlow257.
  ///
  /// In ko, this message translates to:
  /// **'해적선'**
  String get passFlow257;

  /// No description provided for @passFlow258.
  ///
  /// In ko, this message translates to:
  /// **'홋카이도 레일패스 {arg0}일권'**
  String passFlow258(String arg0);

  /// No description provided for @passFlow259.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get passFlow259;

  /// No description provided for @passFlow260.
  ///
  /// In ko, this message translates to:
  /// **'횟수 입력 상세'**
  String get passFlow260;

  /// No description provided for @passFlow261.
  ///
  /// In ko, this message translates to:
  /// **'후지사와 왕복 포함'**
  String get passFlow261;

  /// No description provided for @passFlow262.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow262;

  /// No description provided for @passFlow263.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 이동 구간을 입력해 주세요.'**
  String get passFlow263;

  /// No description provided for @passFlow264.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 일반 운임'**
  String get passFlow264;

  /// No description provided for @passFlow265.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.'**
  String get passFlow265;

  /// No description provided for @passFlow266.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철의 성인 일반 운임만 합산합니다. 1일권은 개찰 당일 첫차부터 막차까지 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.'**
  String get passFlow266;

  /// No description provided for @passFlow267.
  ///
  /// In ko, this message translates to:
  /// **'히로덴 전차 1일권'**
  String get passFlow267;

  /// No description provided for @passFlow268.
  ///
  /// In ko, this message translates to:
  /// **'히로덴 전차 24시간권'**
  String get passFlow268;

  /// No description provided for @passFlow269.
  ///
  /// In ko, this message translates to:
  /// **'히로덴 전차 8시간권'**
  String get passFlow269;

  /// No description provided for @passFlow270.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 이동 구간을 입력해 주세요.'**
  String get passFlow270;

  /// No description provided for @passFlow271.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 일반 운임'**
  String get passFlow271;

  /// No description provided for @passFlow272.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 정류장을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow272;

  /// No description provided for @passFlow273.
  ///
  /// In ko, this message translates to:
  /// **'JR 동일본'**
  String get passFlow273;

  /// No description provided for @passFlow274.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow274;

  /// No description provided for @passFlow275.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본 일반 운임'**
  String get passFlow275;

  /// No description provided for @passFlow276.
  ///
  /// In ko, this message translates to:
  /// **'JR 이동 구간 또는 노면전차·버스 이용 횟수를 입력해 주세요.'**
  String get passFlow276;

  /// No description provided for @passFlow277.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도 · 보통·쾌속'**
  String get passFlow277;

  /// No description provided for @passFlow278.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도 · 특급'**
  String get passFlow278;

  /// No description provided for @passFlow279.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도 버스'**
  String get passFlow279;

  /// No description provided for @passFlow280.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'**
  String get passFlow280;

  /// No description provided for @passFlow281.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도선의 성인 운임을 계산합니다. 특급은 보통차 지정석만, 버스는 1회 ¥300 예상값만 반영합니다.'**
  String get passFlow281;

  /// No description provided for @passFlow282.
  ///
  /// In ko, this message translates to:
  /// **'JR·노면전차와 선택한 시모덴 버스 횟수를 합산합니다. 관광시설 입장·렌터사이클 혜택, 특급·할인과 다른 회사 환승은 계산하지 않습니다.'**
  String get passFlow282;

  /// No description provided for @passFlow283.
  ///
  /// In ko, this message translates to:
  /// **'JR·오카야마 전기궤도는 성인 일반 운임을 합산합니다. 시모덴 버스 대표 운임은 실제 정류장별 운임과 차이가 있을 수 있으며, 관광시설·렌터사이클 혜택은 계산하지 않습니다.'**
  String get passFlow283;

  /// No description provided for @passFlow284.
  ///
  /// In ko, this message translates to:
  /// **'Metro ↔ 도에이 지하철'**
  String get passFlow284;

  /// No description provided for @passFlow285.
  ///
  /// In ko, this message translates to:
  /// **'Metro↔도에이 구간은 공식 지정 환승역·60분 이내 환승·70엔 할인을 전제로 계산합니다. 패스 구매 전 공식 운임과 상품 구매 조건을 다시 확인해 주세요.'**
  String get passFlow285;

  /// No description provided for @passFlow286.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Subway 24시간권'**
  String get passFlow286;

  /// No description provided for @passFlow287.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Subway 48시간권'**
  String get passFlow287;

  /// No description provided for @passFlow288.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Subway 72시간권'**
  String get passFlow288;

  /// No description provided for @passFlow289.
  ///
  /// In ko, this message translates to:
  /// **'Web 프로토타입에서 검증된 상품만 Android 앱에 반영합니다.'**
  String get passFlow289;

  /// No description provided for @passSource001.
  ///
  /// In ko, this message translates to:
  /// **'교토시 교통국 지하철 운임'**
  String get passSource001;

  /// No description provided for @passSource002.
  ///
  /// In ko, this message translates to:
  /// **'교토시 오픈데이터: 京都市営地下鉄 駅間距離・運賃'**
  String get passSource002;

  /// No description provided for @passSource003.
  ///
  /// In ko, this message translates to:
  /// **'「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 1일권은 이용일 당일 영업 종료까지 유효하며, 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.'**
  String get passSource003;

  /// No description provided for @passSource004.
  ///
  /// In ko, this message translates to:
  /// **'「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 버스 노선·사업자·조정 운임 구간·심야 할증·제외 노선은 자동 판정하지 않습니다.'**
  String get passSource004;

  /// No description provided for @passSource005.
  ///
  /// In ko, this message translates to:
  /// **'301개 역, 45,150개 역쌍의 성인 기본 운임 중 권종에 적용되는 구간만 합산합니다. 지정 버스는 적용을 확인한 뒤 직접 입력한 운임만 반영합니다.'**
  String get passSource005;

  /// No description provided for @passSource006.
  ///
  /// In ko, this message translates to:
  /// **'310개 JR홋카이도 역의 성인 기본 운임을 조회합니다. 검증된 특급 역쌍은 보통차 지정석 포함 운임을 선택할 수 있고, JR홋카이도 버스는 1회 ¥300 예상값을 입력 횟수만큼 합산합니다.'**
  String get passSource006;

  /// No description provided for @passSource007.
  ///
  /// In ko, this message translates to:
  /// **'36개 물리 역의 방향별 성인 일반 운임 1,260건을 기기 내 운임표로 조회합니다. 나카스카와바타와 하카타의 환승 노선 코드는 하나의 물리 역으로 묶어 중복 계산하지 않습니다.'**
  String get passSource007;

  /// No description provided for @passSource008.
  ///
  /// In ko, this message translates to:
  /// **'38개 정류장의 방향별 성인 IC·터치 운임 1,406건을 기기 내 운임표로 조회합니다. 昭和町通은 赤迫 방면만 정차하므로 출발·도착 방향을 구분합니다.'**
  String get passSource008;

  /// No description provided for @passSource009.
  ///
  /// In ko, this message translates to:
  /// **'46개 물리 역의 인접 영업거리와 공식 거리 구간 규칙으로 성인 일반 운임을 계산합니다. 삿포로와 오도리는 환승 노선이 있어도 각각 하나의 물리 역으로 계산합니다.'**
  String get passSource009;

  /// No description provided for @passSource010.
  ///
  /// In ko, this message translates to:
  /// **'77개 정류장 중 서로 다른 두 정류장을 선택하면 성인 일반 운임 ¥240을 적용합니다. 입력한 이동 구간 하나를 별도로 운임이 청구되는 1회 이용으로 합산합니다.'**
  String get passSource010;

  /// No description provided for @passSource011.
  ///
  /// In ko, this message translates to:
  /// **'江ノ電1日乗車券「のりおりくん」 · 에노덴 전선'**
  String get passSource011;

  /// No description provided for @passSource012.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철 1일권'**
  String get passSource012;

  /// No description provided for @passSource013.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철 1일권 공식 안내'**
  String get passSource013;

  /// No description provided for @passSource014.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철·버스 1일권'**
  String get passSource014;

  /// No description provided for @passSource015.
  ///
  /// In ko, this message translates to:
  /// **'교토 지하철·버스 1일권 공식 안내'**
  String get passSource015;

  /// No description provided for @passSource016.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 · 사용자 입력 버스 예상 운임'**
  String get passSource016;

  /// No description provided for @passSource017.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 · 전 구간'**
  String get passSource017;

  /// No description provided for @passSource018.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철 역간 거리와 성인 운임대로 일반 운임을 계산하고, 입력한 모든 이동의 합계를 성인 ¥800 1일권과 비교합니다.'**
  String get passSource018;

  /// No description provided for @passSource019.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철은 역간 거리와 성인 운임대로 계산합니다. 버스는 일반 시내버스 ¥230·관광특급버스 ¥500의 입력 횟수만 예상 운임으로 합산합니다.'**
  String get passSource019;

  /// No description provided for @passSource020.
  ///
  /// In ko, this message translates to:
  /// **'교통패스별 데이터 출처'**
  String get passSource020;

  /// No description provided for @passSource021.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰 레일 패스'**
  String get passSource021;

  /// No description provided for @passSource022.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 2026 노선·운임 안내'**
  String get passSource022;

  /// No description provided for @passSource023.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 여객운송규칙'**
  String get passSource023;

  /// No description provided for @passSource024.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도 패스'**
  String get passSource024;

  /// No description provided for @passSource025.
  ///
  /// In ko, this message translates to:
  /// **'데이터 출처'**
  String get passSource025;

  /// No description provided for @passSource026.
  ///
  /// In ko, this message translates to:
  /// **'데이터 출처 및 운임 기준'**
  String get passSource026;

  /// No description provided for @passSource027.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 적용 77개 역의 영업거리와 JR 동일본 성인 IC 운임표를 바탕으로 만든 오프라인 운임표를 사용합니다.'**
  String get passSource027;

  /// No description provided for @passSource028.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 패스'**
  String get passSource028;

  /// No description provided for @passSource029.
  ///
  /// In ko, this message translates to:
  /// **'비교할 패스를 선택하면 운임 계산 기준, 출처와 제한사항을 확인할 수 있습니다.'**
  String get passSource029;

  /// No description provided for @passSource030.
  ///
  /// In ko, this message translates to:
  /// **'삿포로 지하철 1일권'**
  String get passSource030;

  /// No description provided for @passSource031.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 1일 승차권 공식 안내'**
  String get passSource031;

  /// No description provided for @passSource032.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 운임 공개 데이터셋'**
  String get passSource032;

  /// No description provided for @passSource033.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철 운임 안내'**
  String get passSource033;

  /// No description provided for @passSource034.
  ///
  /// In ko, this message translates to:
  /// **'선택한 오다큐 발역별 패스 가격과 발역↔후지사와 왕복 성인 IC 운임, 에노덴·오다큐 프리구간의 실제 입력 운임을 합산해 비교합니다.'**
  String get passSource034;

  /// No description provided for @passSource035.
  ///
  /// In ko, this message translates to:
  /// **'성인 1일권(¥600)과 24시간권(¥700)을 비교합니다. 운임은 IC·터치 결제 기준이며, 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함합니다. 역·노선 및 운임 규칙 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따르며, 공식 PDF 원문은 앱에 포함하지 않습니다. 현금·버스·소아요금은 계산하지 않습니다.'**
  String get passSource035;

  /// No description provided for @passSource036.
  ///
  /// In ko, this message translates to:
  /// **'성인 기준으로 오다큐 70개 출발역의 2·3일권 가격을 조회합니다. 등산전차·케이블카·로프웨이·해적선은 정확 운임, 버스는 사업자별 평균 운임과 입력 횟수의 예상값으로 합산합니다.'**
  String get passSource036;

  /// No description provided for @passSource037.
  ///
  /// In ko, this message translates to:
  /// **'성인 지하철 전용 1일 승차권(¥830)과 도니치카 킵(¥520)을 비교합니다. 도니치카 킵은 토·일·공휴일 및 12/29~1/3에만 이용할 수 있습니다. 운임 구간은 삿포로시 공개 데이터(CC BY 4.0)와 공식 안내를 대조했으며, 역 순서·인접 영업거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따릅니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.'**
  String get passSource037;

  /// No description provided for @passSource038.
  ///
  /// In ko, this message translates to:
  /// **'시간표 기반 최속 경로, 관광시설 혜택, 제외 버스, 특급·좌석요금은 포함하지 않습니다. 일부 게이한 영업거리 자료는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다.'**
  String get passSource038;

  /// No description provided for @passSource039.
  ///
  /// In ko, this message translates to:
  /// **'시모덴 버스 운임 개정 안내'**
  String get passSource039;

  /// No description provided for @passSource040.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 15개 역의 영업거리와 성인 일반 운임 거리대 규칙을 바탕으로 두 역 사이의 운임을 계산합니다.'**
  String get passSource040;

  /// No description provided for @passSource041.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 1일 승차권'**
  String get passSource041;

  /// No description provided for @passSource042.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 1일 승차권 「のりおりくん」 공식 안내'**
  String get passSource042;

  /// No description provided for @passSource043.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 역·영업거리와 운임 거리대 자료를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.'**
  String get passSource043;

  /// No description provided for @passSource044.
  ///
  /// In ko, this message translates to:
  /// **'에노덴 전선 · 오다큐 후지사와–가타세에노시마'**
  String get passSource044;

  /// No description provided for @passSource045.
  ///
  /// In ko, this message translates to:
  /// **'에노시마·가마쿠라 프리패스'**
  String get passSource045;

  /// No description provided for @passSource046.
  ///
  /// In ko, this message translates to:
  /// **'에노시마·가마쿠라 프리패스 공식 안내'**
  String get passSource046;

  /// No description provided for @passSource047.
  ///
  /// In ko, this message translates to:
  /// **'역 순서와 영업거리 기반 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 공식 역별 운임과 전 구간을 대조했습니다. OKICA 등 결제수단별 할인, 다른 회사 환승과 소아요금은 포함하지 않습니다.'**
  String get passSource047;

  /// No description provided for @passSource048.
  ///
  /// In ko, this message translates to:
  /// **'역 위치 지도'**
  String get passSource048;

  /// No description provided for @passSource049.
  ///
  /// In ko, this message translates to:
  /// **'역 정보는 후쿠오카시 공개 데이터(CC BY)와 현재 공식 안내를 대조해 구성했으며, 2026-09-03 기준 성인 운임만 사용합니다. 1일권은 개찰 당일 첫차부터 막차까지 유효합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.'**
  String get passSource049;

  /// No description provided for @passSource050.
  ///
  /// In ko, this message translates to:
  /// **'역·운임·정차역 순서 파생 데이터는 CC BY-SA 4.0 조건과 원 출처 고지를 유지합니다. 특급은 검증된 정규 열차 공통 정차역쌍에서만 선택할 수 있으며, 버스는 정확 운임이 아닌 예상값입니다. 그린차와 관광·계절·SL 열차는 포함하지 않습니다.'**
  String get passSource050;

  /// No description provided for @passSource051.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 영업거리와 운임 거리대, 에노덴 영업거리 자료를 가공해 만들었습니다. 해당 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특급·좌석요금, 할인과 프리구간 밖 추가 이동은 포함하지 않습니다.'**
  String get passSource051;

  /// No description provided for @passSource052.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 출발역별 가격 · 하코네 지정 교통수단'**
  String get passSource052;

  /// No description provided for @passSource053.
  ///
  /// In ko, this message translates to:
  /// **'오다큐선은 출발역↔오다와라 왕복 1회만 포함하며 로망스카 특급권은 별도입니다. 역·거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0, 구조화 식별 정보는 Wikidata CC0을 따릅니다. 버스 결과는 예상값입니다.'**
  String get passSource053;

  /// No description provided for @passSource054.
  ///
  /// In ko, this message translates to:
  /// **'오사카 메트로 · 사철 · 시티버스'**
  String get passSource054;

  /// No description provided for @passSource055.
  ///
  /// In ko, this message translates to:
  /// **'오사카 시티버스 이용 안내'**
  String get passSource055;

  /// No description provided for @passSource056.
  ///
  /// In ko, this message translates to:
  /// **'오사카 주유패스'**
  String get passSource056;

  /// No description provided for @passSource057.
  ///
  /// In ko, this message translates to:
  /// **'오사카 주유패스 공식 안내'**
  String get passSource057;

  /// No description provided for @passSource058.
  ///
  /// In ko, this message translates to:
  /// **'오카야마 전기궤도 운임 안내'**
  String get passSource058;

  /// No description provided for @passSource059.
  ///
  /// In ko, this message translates to:
  /// **'오카야마·구라시키 tabiwa 구루링 패스'**
  String get passSource059;

  /// No description provided for @passSource060.
  ///
  /// In ko, this message translates to:
  /// **'오카야마·구라시키 tabiwa 구루링 패스 공식 안내'**
  String get passSource060;

  /// No description provided for @passSource061.
  ///
  /// In ko, this message translates to:
  /// **'오키나와 도시 모노레일 · 전 노선'**
  String get passSource061;

  /// No description provided for @passSource062.
  ///
  /// In ko, this message translates to:
  /// **'운임 계산 기준'**
  String get passSource062;

  /// No description provided for @passSource063.
  ///
  /// In ko, this message translates to:
  /// **'운임과 패스 조건은 개정될 수 있으므로 구매 전 공식 안내를 확인해 주세요.'**
  String get passSource063;

  /// No description provided for @passSource064.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 19개 역의 방향별 성인 일반 운임 342건을 기기 내 운임표로 조회합니다. 24시간권 또는 48시간권 가격과 입력한 모든 이동의 합계를 비교합니다.'**
  String get passSource064;

  /// No description provided for @passSource065.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 운임 공식 안내'**
  String get passSource065;

  /// No description provided for @passSource066.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 패스'**
  String get passSource066;

  /// No description provided for @passSource067.
  ///
  /// In ko, this message translates to:
  /// **'유이레일 프리 승차권 공식 안내'**
  String get passSource067;

  /// No description provided for @passSource068.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 상세의 역 좌표는 Wikidata P625(CC0)에서 생성했습니다. 역 코드·역명·사업자·노선을 대조하며 미확인 위치는 표시하지 않습니다. 실제 이동 경로가 아닌 역 위치 참고용입니다. 지도 배경은 Google Maps가 제공하며 지도 안의 저작권 표기를 따릅니다.\nhttps://www.wikidata.org/wiki/Wikidata:Licensing'**
  String get passSource068;

  /// No description provided for @passSource069.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 긴테쓰·이가철도 노선 정보'**
  String get passSource069;

  /// No description provided for @passSource070.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 에노시마 전철선·에노시마 전철'**
  String get passSource070;

  /// No description provided for @passSource071.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 오다큐·에노덴 노선 정보'**
  String get passSource071;

  /// No description provided for @passSource072.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 오키나와 도시 모노레일선'**
  String get passSource072;

  /// No description provided for @passSource073.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 長崎電気軌道'**
  String get passSource073;

  /// No description provided for @passSource074.
  ///
  /// In ko, this message translates to:
  /// **'일본어 위키백과: 한큐 각 노선 역·영업거리'**
  String get passSource074;

  /// No description provided for @passSource075.
  ///
  /// In ko, this message translates to:
  /// **'長崎電気軌道 一日乗車券 · 24時間乗車券 · 노면전차 전 노선'**
  String get passSource075;

  /// No description provided for @passSource076.
  ///
  /// In ko, this message translates to:
  /// **'電車一日乗車券 · 디지털 8시간권 · 24시간권'**
  String get passSource076;

  /// No description provided for @passSource077.
  ///
  /// In ko, this message translates to:
  /// **'종이 전차 1일 승차권(¥700), 디지털 8시간권(¥600), 24시간권(¥700)을 비교합니다. 정류장 식별 정보는 Wikidata CC0, 정규화한 역 코드·운임·상품 사실값은 Wikimedia 기반 CC BY-SA 4.0 조건을 유지합니다. MOBIRY DAYS의 거리별 할인, 자동 환승·재승차 판정, 버스·선박·소아요금은 포함하지 않습니다.'**
  String get passSource077;

  /// No description provided for @passSource078.
  ///
  /// In ko, this message translates to:
  /// **'地下鉄専用1日乗車券 · ドニチカキップ · 삿포로시 지하철 전 구간'**
  String get passSource078;

  /// No description provided for @passSource079.
  ///
  /// In ko, this message translates to:
  /// **'참고용 계산 결과이므로 실제 이용 전 적용 구간과 최신 운임을 확인해 주세요.'**
  String get passSource079;

  /// No description provided for @passSource080.
  ///
  /// In ko, this message translates to:
  /// **'철도 사업자별 공개 운임 자료, 역간 거리와 환승 연결을 바탕으로 일반 운임을 계산합니다.'**
  String get passSource080;

  /// No description provided for @passSource081.
  ///
  /// In ko, this message translates to:
  /// **'阪急1dayパス · 한큐 전철 전 노선(고베고속선 제외)'**
  String get passSource081;

  /// No description provided for @passSource082.
  ///
  /// In ko, this message translates to:
  /// **'阪急1dayパス 공식 안내'**
  String get passSource082;

  /// No description provided for @passSource083.
  ///
  /// In ko, this message translates to:
  /// **'하코네 나비: 로프웨이·해적선 운임'**
  String get passSource083;

  /// No description provided for @passSource084.
  ///
  /// In ko, this message translates to:
  /// **'하코네 프리패스'**
  String get passSource084;

  /// No description provided for @passSource085.
  ///
  /// In ko, this message translates to:
  /// **'하코네 프리패스 공식 가격표'**
  String get passSource085;

  /// No description provided for @passSource086.
  ///
  /// In ko, this message translates to:
  /// **'하코네 프리패스 공식 안내'**
  String get passSource086;

  /// No description provided for @passSource087.
  ///
  /// In ko, this message translates to:
  /// **'한큐 각 노선의 역간 영업거리 데이터를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 고베고속선, 특급·좌석요금, 할인·IC 특례와 다른 회사 환승은 포함하지 않습니다.'**
  String get passSource087;

  /// No description provided for @passSource088.
  ///
  /// In ko, this message translates to:
  /// **'한큐 여객영업규칙'**
  String get passSource088;

  /// No description provided for @passSource089.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철 87개 역의 인접 역간 영업거리와 성인 보통 운임 거리대 규칙으로 계산한 일반 운임을 사용합니다.'**
  String get passSource089;

  /// No description provided for @passSource090.
  ///
  /// In ko, this message translates to:
  /// **'한큐패스 1일권'**
  String get passSource090;

  /// No description provided for @passSource091.
  ///
  /// In ko, this message translates to:
  /// **'홋카이도 레일패스'**
  String get passSource091;

  /// No description provided for @passSource092.
  ///
  /// In ko, this message translates to:
  /// **'홋카이도 레일패스 공식 안내'**
  String get passSource092;

  /// No description provided for @passSource093.
  ///
  /// In ko, this message translates to:
  /// **'확인할 점'**
  String get passSource093;

  /// No description provided for @passSource094.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카 지하철 1일권'**
  String get passSource094;

  /// No description provided for @passSource095.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 역 데이터 공개 데이터셋'**
  String get passSource095;

  /// No description provided for @passSource096.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철'**
  String get passSource096;

  /// No description provided for @passSource097.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 1일 승차권 공식 안내'**
  String get passSource097;

  /// No description provided for @passSource098.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카시 지하철 운임 안내'**
  String get passSource098;

  /// No description provided for @passSource099.
  ///
  /// In ko, this message translates to:
  /// **'히로덴 전차 패스'**
  String get passSource099;

  /// No description provided for @passSource100.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 운임 개정 자료'**
  String get passSource100;

  /// No description provided for @passSource101.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철 전차 승차권 공식 안내'**
  String get passSource101;

  /// No description provided for @passSource102.
  ///
  /// In ko, this message translates to:
  /// **'JR 동일본 도쿄 23구 내 지정 구간'**
  String get passSource102;

  /// No description provided for @passSource103.
  ///
  /// In ko, this message translates to:
  /// **'JR 동일본 도쿠나이 패스 공식 안내'**
  String get passSource103;

  /// No description provided for @passSource104.
  ///
  /// In ko, this message translates to:
  /// **'JR 동일본 운임·요금 안내'**
  String get passSource104;

  /// No description provided for @passSource105.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스'**
  String get passSource105;

  /// No description provided for @passSource106.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본 대상 35개 역의 성인 일반 운임 1,190건을 조회합니다. 오카야마 전기궤도는 1회 ¥160을 정확히 합산하고, 시모덴 버스는 선택한 서비스별 입력 횟수와 대표 운임을 합산합니다.'**
  String get passSource106;

  /// No description provided for @passSource107.
  ///
  /// In ko, this message translates to:
  /// **'JR 역간 거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 시모덴 버스의 고지마–구라시키·도코하이호는 대표 운임이므로 실제 정류장별 운임과 다를 수 있습니다. 관광시설·렌터사이클 혜택, 특급·할인과 다른 회사 환승은 계산하지 않습니다.'**
  String get passSource107;

  /// No description provided for @passSource108.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도 열차 안내'**
  String get passSource108;

  /// No description provided for @passSource109.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도선 · 5·7·10일권'**
  String get passSource109;

  /// No description provided for @passSource110.
  ///
  /// In ko, this message translates to:
  /// **'KINTETSU RAIL PASS · 1일권·2일권·5일권·5일권 Plus'**
  String get passSource110;

  /// No description provided for @passSource111.
  ///
  /// In ko, this message translates to:
  /// **'KINTETSU RAIL PASS 권종별 공식 안내'**
  String get passSource111;

  /// No description provided for @passSource112.
  ///
  /// In ko, this message translates to:
  /// **'MOBIRY DAYS 운임 안내'**
  String get passSource112;

  /// No description provided for @passSource113.
  ///
  /// In ko, this message translates to:
  /// **'ODPT 공개 교통 데이터 센터'**
  String get passSource113;

  /// No description provided for @passSource114.
  ///
  /// In ko, this message translates to:
  /// **'ODPT 역·성인 IC 운임 데이터로 도쿄메트로와 도에이 지하철의 적용 구간 운임을 계산합니다.'**
  String get passSource114;

  /// No description provided for @passSource115.
  ///
  /// In ko, this message translates to:
  /// **'Osaka Metro 운임 안내'**
  String get passSource115;

  /// No description provided for @passSource116.
  ///
  /// In ko, this message translates to:
  /// **'tabiwa 상품 상세'**
  String get passSource116;

  /// No description provided for @passSource117.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Metro · 도에이 지하철'**
  String get passSource117;

  /// No description provided for @passSource118.
  ///
  /// In ko, this message translates to:
  /// **'Tokyo Subway Ticket 공식 안내'**
  String get passSource118;

  /// No description provided for @passSource119.
  ///
  /// In ko, this message translates to:
  /// **'Wikidata(CC0)와 Wikipedia/Wikimedia의 영업거리 사실값(CC BY-SA 4.0)을 가공해 만든 파생 데이터입니다. 특급은 별도 특급권이 필요하며, 로프웨이·할인·특전은 계산하지 않습니다.'**
  String get passSource119;

  /// No description provided for @passMeta001.
  ///
  /// In ko, this message translates to:
  /// **'에노시마 전철'**
  String get passMeta001;

  /// No description provided for @passMeta002.
  ///
  /// In ko, this message translates to:
  /// **'에노덴'**
  String get passMeta002;

  /// No description provided for @passMeta003.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 전철'**
  String get passMeta003;

  /// No description provided for @passMeta004.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 다마선'**
  String get passMeta004;

  /// No description provided for @passMeta005.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 에노시마선'**
  String get passMeta005;

  /// No description provided for @passMeta006.
  ///
  /// In ko, this message translates to:
  /// **'오다큐 오다와라선'**
  String get passMeta006;

  /// No description provided for @passMeta007.
  ///
  /// In ko, this message translates to:
  /// **'한큐 전철'**
  String get passMeta007;

  /// No description provided for @passMeta008.
  ///
  /// In ko, this message translates to:
  /// **'JR 홋카이도'**
  String get passMeta008;

  /// No description provided for @passMeta009.
  ///
  /// In ko, this message translates to:
  /// **'교토시영 지하철'**
  String get passMeta009;

  /// No description provided for @passMeta010.
  ///
  /// In ko, this message translates to:
  /// **'가라스마선'**
  String get passMeta010;

  /// No description provided for @passMeta011.
  ///
  /// In ko, this message translates to:
  /// **'도자이선'**
  String get passMeta011;

  /// No description provided for @passMeta012.
  ///
  /// In ko, this message translates to:
  /// **'오사카 메트로'**
  String get passMeta012;

  /// No description provided for @passMeta013.
  ///
  /// In ko, this message translates to:
  /// **'오사카 시티버스'**
  String get passMeta013;

  /// No description provided for @passMeta014.
  ///
  /// In ko, this message translates to:
  /// **'한신 전철'**
  String get passMeta014;

  /// No description provided for @passMeta015.
  ///
  /// In ko, this message translates to:
  /// **'게이한 전철'**
  String get passMeta015;

  /// No description provided for @passMeta016.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰'**
  String get passMeta016;

  /// No description provided for @passMeta017.
  ///
  /// In ko, this message translates to:
  /// **'긴테쓰 전철'**
  String get passMeta017;

  /// No description provided for @passMeta018.
  ///
  /// In ko, this message translates to:
  /// **'이가철도'**
  String get passMeta018;

  /// No description provided for @passMeta019.
  ///
  /// In ko, this message translates to:
  /// **'난카이 전철'**
  String get passMeta019;

  /// No description provided for @passMeta020.
  ///
  /// In ko, this message translates to:
  /// **'삿포로시 지하철'**
  String get passMeta020;

  /// No description provided for @passMeta021.
  ///
  /// In ko, this message translates to:
  /// **'히로시마 전철'**
  String get passMeta021;

  /// No description provided for @passMeta022.
  ///
  /// In ko, this message translates to:
  /// **'나가사키 전기궤도'**
  String get passMeta022;

  /// No description provided for @passMeta023.
  ///
  /// In ko, this message translates to:
  /// **'JR 서일본'**
  String get passMeta023;

  /// No description provided for @passMeta024.
  ///
  /// In ko, this message translates to:
  /// **'유이레일'**
  String get passMeta024;

  /// No description provided for @passMeta025.
  ///
  /// In ko, this message translates to:
  /// **'등산전차'**
  String get passMeta025;

  /// No description provided for @passMeta026.
  ///
  /// In ko, this message translates to:
  /// **'케이블카'**
  String get passMeta026;

  /// No description provided for @passMeta027.
  ///
  /// In ko, this message translates to:
  /// **'로프웨이'**
  String get passMeta027;

  /// No description provided for @passMeta028.
  ///
  /// In ko, this message translates to:
  /// **'해적선'**
  String get passMeta028;

  /// No description provided for @passMeta029.
  ///
  /// In ko, this message translates to:
  /// **'도에이 지하철'**
  String get passMeta029;

  /// No description provided for @passMeta030.
  ///
  /// In ko, this message translates to:
  /// **'御堂筋線'**
  String get passMeta030;

  /// No description provided for @passMeta031.
  ///
  /// In ko, this message translates to:
  /// **'今里筋線'**
  String get passMeta031;

  /// No description provided for @passMeta032.
  ///
  /// In ko, this message translates to:
  /// **'千日前線'**
  String get passMeta032;

  /// No description provided for @passMeta033.
  ///
  /// In ko, this message translates to:
  /// **'四つ橋線'**
  String get passMeta033;

  /// No description provided for @passMeta034.
  ///
  /// In ko, this message translates to:
  /// **'中央線'**
  String get passMeta034;

  /// No description provided for @passMeta035.
  ///
  /// In ko, this message translates to:
  /// **'ニュートラム'**
  String get passMeta035;

  /// No description provided for @passMeta036.
  ///
  /// In ko, this message translates to:
  /// **'長堀鶴見緑地線'**
  String get passMeta036;

  /// No description provided for @passMeta037.
  ///
  /// In ko, this message translates to:
  /// **'谷町線'**
  String get passMeta037;

  /// No description provided for @passMeta038.
  ///
  /// In ko, this message translates to:
  /// **'堺筋線'**
  String get passMeta038;

  /// No description provided for @passMeta039.
  ///
  /// In ko, this message translates to:
  /// **'中之島線'**
  String get passMeta039;

  /// No description provided for @passMeta040.
  ///
  /// In ko, this message translates to:
  /// **'京阪本線'**
  String get passMeta040;

  /// No description provided for @passMeta041.
  ///
  /// In ko, this message translates to:
  /// **'南海本線'**
  String get passMeta041;

  /// No description provided for @passMeta042.
  ///
  /// In ko, this message translates to:
  /// **'高野線'**
  String get passMeta042;

  /// No description provided for @passMeta043.
  ///
  /// In ko, this message translates to:
  /// **'南大阪線'**
  String get passMeta043;

  /// No description provided for @passMeta044.
  ///
  /// In ko, this message translates to:
  /// **'難波線'**
  String get passMeta044;

  /// No description provided for @passMeta045.
  ///
  /// In ko, this message translates to:
  /// **'宝塚本線'**
  String get passMeta045;

  /// No description provided for @passMeta046.
  ///
  /// In ko, this message translates to:
  /// **'京都本線'**
  String get passMeta046;

  /// No description provided for @passMeta047.
  ///
  /// In ko, this message translates to:
  /// **'千里線'**
  String get passMeta047;

  /// No description provided for @passMeta048.
  ///
  /// In ko, this message translates to:
  /// **'神戸本線'**
  String get passMeta048;

  /// No description provided for @passMeta049.
  ///
  /// In ko, this message translates to:
  /// **'阪神なんば線'**
  String get passMeta049;

  /// No description provided for @passMeta050.
  ///
  /// In ko, this message translates to:
  /// **'本線'**
  String get passMeta050;

  /// No description provided for @passMeta051.
  ///
  /// In ko, this message translates to:
  /// **'도쿠나이 패스 적용 JR'**
  String get passMeta051;

  /// No description provided for @passMeta052.
  ///
  /// In ko, this message translates to:
  /// **'JR 동일본'**
  String get passMeta052;

  /// No description provided for @passMeta053.
  ///
  /// In ko, this message translates to:
  /// **'Metro ↔ 도에이 지하철'**
  String get passMeta053;

  /// No description provided for @passMeta054.
  ///
  /// In ko, this message translates to:
  /// **'오카야마 전기궤도'**
  String get passMeta054;

  /// No description provided for @passMeta055.
  ///
  /// In ko, this message translates to:
  /// **'시모덴 버스 고지마–구라시키'**
  String get passMeta055;

  /// No description provided for @passMeta056.
  ///
  /// In ko, this message translates to:
  /// **'도코하이호'**
  String get passMeta056;

  /// No description provided for @passMeta057.
  ///
  /// In ko, this message translates to:
  /// **'진즈 버스'**
  String get passMeta057;

  /// No description provided for @passMeta058.
  ///
  /// In ko, this message translates to:
  /// **'와슈잔 석양 감상 버스'**
  String get passMeta058;

  /// No description provided for @passMeta059.
  ///
  /// In ko, this message translates to:
  /// **'전선 균일'**
  String get passMeta059;

  /// No description provided for @passMeta060.
  ///
  /// In ko, this message translates to:
  /// **'전 구간 대표 운임'**
  String get passMeta060;

  /// No description provided for @passMeta061.
  ///
  /// In ko, this message translates to:
  /// **'대표 운임'**
  String get passMeta061;

  /// No description provided for @passMeta062.
  ///
  /// In ko, this message translates to:
  /// **'금·토·일·공휴일 운행'**
  String get passMeta062;

  /// No description provided for @passMeta063.
  ///
  /// In ko, this message translates to:
  /// **'금·토·공휴일 전날 운행'**
  String get passMeta063;

  /// No description provided for @passMeta064.
  ///
  /// In ko, this message translates to:
  /// **'가라스마선·도자이선'**
  String get passMeta064;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
