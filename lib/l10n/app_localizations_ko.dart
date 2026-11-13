// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '일본 교통카드 리더';

  @override
  String get home => '홈';

  @override
  String get history => '이용내역';

  @override
  String get tools => '도구';

  @override
  String get settings => '설정';

  @override
  String get homeTitle => 'IC 카드 리더';

  @override
  String get scanPrompt => 'IC 카드를 스캔해 주세요';

  @override
  String get homeNfcHint => '카드를 기기 뒷면 NFC 위치에 대면\n최근 이용내역을 읽어옵니다.';

  @override
  String get scanCard => 'IC 카드 스캔';

  @override
  String get compareBalances => '여러 카드 잔액 비교';

  @override
  String get whereToTap => '카드를 어디에 대야 하나요?';

  @override
  String get noReadableHistory => '읽을 수 있는 이용내역이 없어요';

  @override
  String get noReadableHistoryHint =>
      '카드에서 표시할 이용내역을 찾지 못했습니다. 카드 종류나 기록 상태에 따라 읽을 수 있는 정보가 다를 수 있습니다.';

  @override
  String get nfcStartRetry => 'NFC 읽기를 시작하지 못했어요. 카드를 잠시 떼었다가 다시 스캔해 주세요.';

  @override
  String get notice => '안내';

  @override
  String get recentHistory => '최근 이용내역';

  @override
  String get viewAll => '전체 보기';

  @override
  String get noScannedCard => '아직 스캔한 카드가 없습니다.';

  @override
  String get noHistoryFound => '읽은 카드에서 표시할 수 있는 이용내역을 찾지 못했습니다.';

  @override
  String get balanceAfterLabel => '이용 후 잔액';

  @override
  String get supportedCards => '지원 카드';

  @override
  String get supportedCardsHint => 'Suica · PASMO · ICOCA 등 일본 전국호환 교통계 IC 카드';

  @override
  String get pitapaLimit => 'PiTaPa 포스트페이 및 일부 거래는 지원되지 않을 수 있습니다.';

  @override
  String get localCardData => '카드 데이터는 이 기기에서만 처리합니다';

  @override
  String stationCode(String code) {
    return '역 코드 $code';
  }

  @override
  String get entryStationUnknown => '입장역을 확인했지만 역명을 찾지 못했습니다.';

  @override
  String get tripInProgress => '현재 이동 중';

  @override
  String enteredAt(String station) {
    return '$station에서 입장하여 이동 중입니다.';
  }

  @override
  String get newVersion => '새 버전이 있어요';

  @override
  String get newVersionHint => '최신 기능과 개선 사항을 적용해 보세요.';

  @override
  String get opening => '여는 중';

  @override
  String get update => '업데이트';

  @override
  String get cancelScan => '스캔 취소';

  @override
  String get scanTitle => '카드 스캔';

  @override
  String get holdTransitCard => '교통카드를 대 주세요';

  @override
  String get holdCardStill => '카드를 움직이지 말고\n가까이 대 주세요';

  @override
  String get scanWaitHint => '휴대폰 뒷면 NFC 위치에 카드 한 장을 대고\n스캔이 완료될 때까지 기다려 주세요.';

  @override
  String get scanTimeElapsed => '스캔 제한 시간 경과';

  @override
  String scanTimeLeft(int seconds) {
    return '스캔 대기 시간 · 남은 시간 $seconds초';
  }

  @override
  String get retryWithoutClosing => '오류가 발생해도 앱을 종료하지 않고 다시 시도할 수 있습니다.';

  @override
  String get scanComplete => '스캔 완료';

  @override
  String get cardRead => '카드를 읽었습니다';

  @override
  String brandCardRead(String brand) {
    return '$brand 카드를 읽었습니다';
  }

  @override
  String get blocksRead => '읽은 블록';

  @override
  String get decodedRecords => '해석한 내역';

  @override
  String get needsReview => '확인 필요';

  @override
  String get someDataUnconfirmed => '일부 정보는 아직 확인 중입니다';

  @override
  String get someDataUnconfirmedHint =>
      '원본 기록은 정상적으로 읽었습니다. 역명과 거래 유형 데이터베이스가 연결되면 더 자세히 표시할 수 있습니다.';

  @override
  String get historyOnDevice => '읽은 이용내역은 이 기기 안에만 표시됩니다';

  @override
  String get idmNotStored => '카드 IDm 원문은 저장하거나 화면에 표시하지 않습니다.';

  @override
  String get viewHistory => '이용내역 보기';

  @override
  String get scanAgain => '다시 스캔';

  @override
  String get unavailableAmount => '계산 불가';

  @override
  String get unknownBus => '버스 회사 미확인';

  @override
  String get refund => '환불';

  @override
  String get adjustment => '정산';

  @override
  String get unknownTransaction => '거래 유형 미확인';

  @override
  String get stationUnavailable => '역 정보 확인 불가';

  @override
  String get nfcSettingsError => 'NFC 설정을 열지 못했어요. 휴대폰 설정에서 NFC를 확인해 주세요.';

  @override
  String get sessionCleared => '현재 세션의 이용내역을 지웠습니다.';

  @override
  String get updateStartError => '업데이트를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get checkingNfc => 'NFC 상태 확인 중';

  @override
  String get nfcOn => 'NFC가 켜져 있어요';

  @override
  String get turnNfcOn => 'NFC를 켜 주세요';

  @override
  String get nfcUnsupported => '이 기기는 NFC 읽기를 지원하지 않아요';

  @override
  String get nfcUnknown => 'NFC 상태를 확인하지 못했어요';

  @override
  String get openNfcSettings => 'NFC 설정 열기';

  @override
  String get checkAgain => '다시 확인';

  @override
  String get couldNotStartNfc => 'NFC 읽기를 시작하지 못했어요';

  @override
  String get nfcUnsupportedHint =>
      '이 기기는 NFC 읽기를 지원하지 않습니다. NFC-F/FeliCa 읽기를 지원하는 Android 기기를 이용해 주세요.';

  @override
  String get nfcEnabledHint =>
      'NFC가 켜져 있는지 확인해 주세요. Samsung 기기는 NFC를 기본 모드로 설정한 뒤 다시 시도해 주세요.';

  @override
  String get checkCardSupport => '지원하는 교통카드인지 확인해 주세요';

  @override
  String get checkCardSupportHint =>
      'Suica·PASMO·ICOCA 등 일본 전국호환 교통계 IC 카드를 한 장만 대 주세요. NFC-F/FeliCa 읽기를 지원하는 기기가 필요합니다.';

  @override
  String get scanTimedOut => '시간 안에 스캔을 완료하지 못했어요';

  @override
  String get scanTimedOutHint =>
      '카드를 지갑에서 꺼내 휴대폰 뒷면의 위치를 조금씩 바꿔 다시 시도해 주세요. 카드 종류나 기기의 NFC-F 지원 여부도 영향을 줄 수 있습니다.';

  @override
  String get cardConnectionLost => '카드와 통신을 완료하지 못했어요';

  @override
  String get cardConnectionLostHint =>
      '카드 한 장을 NFC 위치에 가까이 대고 완료될 때까지 움직이지 말아 주세요.';

  @override
  String get couldNotReadCard => '카드 정보를 읽지 못했어요';

  @override
  String get couldNotReadCardHint =>
      '카드를 다시 대 주세요. 이 메시지만으로 카드 고장이나 잔액 이상을 의미하지는 않습니다.';

  @override
  String get scanFailed => '스캔을 완료하지 못했어요';

  @override
  String get scanFailedHint =>
      '카드를 잠시 떼었다가 다시 시도해 주세요. 계속되면 NFC 설정과 지원 카드 안내를 확인해 주세요.';

  @override
  String get scanHelp => '스캔 도움말';

  @override
  String get dismissNotice => '안내 닫기';

  @override
  String get howToScan => '카드 스캔 방법';

  @override
  String get closeHelp => '도움말 닫기';

  @override
  String get holdOneCard => '휴대폰 뒷면에 교통카드 한 장을 대 주세요.';

  @override
  String get prepareOneCard => '카드 한 장 준비';

  @override
  String get prepareOneCardHint =>
      '지갑에서 실물 교통카드 한 장을 꺼내 주세요. Samsung 기기는 NFC 기본 모드를 확인해 주세요.';

  @override
  String get tapScanHold => '스캔을 누르고 뒷면에 대기';

  @override
  String get tapScanHoldHint =>
      '스캔 화면이 열리면 카드를 휴대폰 뒷면 NFC 위치에 대 주세요. NFC 위치는 기기마다 다릅니다.';

  @override
  String get waitForScan => '완료될 때까지 고정';

  @override
  String get waitForScanHint =>
      '반응이 없으면 카드 위치를 조금씩 바꾸거나 두꺼운 케이스·금속 부착물을 분리한 뒤 다시 시도해 주세요.';

  @override
  String get deviceRequirements => '기기 조건';

  @override
  String get felicaRequired =>
      'NFC-F/FeliCa 읽기 지원이 필요합니다. NFC 켜짐 표시만으로 지원이 확인되는 것은 아닙니다.';

  @override
  String get readOnlyPhysicalCard => '실물 카드 스캔 기준입니다. 카드 충전이나 기록 변경은 하지 않습니다.';

  @override
  String get close => '닫기';

  @override
  String get placementSemantics => '휴대폰 뒷면에 실물 교통카드 한 장을 가까이 대는 예시';

  @override
  String get nfcPlacementVaries => 'NFC 위치는 기기마다 달라요';

  @override
  String get noMatchingHistory => '해당 조건의 이용내역이 없습니다.';

  @override
  String get unknownTotalExplanation => '거래 유형이 확인되지 않아 금액은 합산하지 않습니다.';

  @override
  String get topUpTotalExplanation => '확인된 충전액만 합산하며 지출에는 포함하지 않습니다.';

  @override
  String get spendingTotalExplanation => '충전·계산 불가·확인 필요·특수 거래는 지출에서 제외합니다.';

  @override
  String unknownRecordCount(int count) {
    return '미확인 $count건';
  }

  @override
  String get noTopUpTotal => '합산 가능한 충전 기록이 없어요';

  @override
  String get noSpendingTotal => '합산 가능한 지출 기록이 없어요';

  @override
  String totalCount(int included, int excluded) {
    return '합산 $included건 · 합계 제외 $excluded건';
  }

  @override
  String recentTotalHint(String explanation) {
    return '카드에서 읽은 최근 기록만 합산합니다.\n$explanation';
  }

  @override
  String get currentBalance => '현재 카드 잔액';

  @override
  String currentBrandBalance(String brand) {
    return '현재 $brand 잔액';
  }

  @override
  String get balanceAfterScan => '카드 스캔 후 표시';

  @override
  String get initialBalanceBasis => '초기 잔액 기록 기준';

  @override
  String get latestBalanceBasis => '가장 최근 기록 기준';

  @override
  String get noDisplayableHistory => '이 카드에는 표시할 이용내역이 없습니다';

  @override
  String get noHistoryYet => '아직 읽은 이용내역이 없습니다';

  @override
  String get initialBalanceOnly => '초기 잔액 기록만 확인되었습니다.';

  @override
  String get scanFromHome => '홈에서 IC 카드를 스캔해 주세요.';

  @override
  String balanceValue(String amount) {
    return '잔액 $amount';
  }

  @override
  String get historyDetail => '이용내역 상세';

  @override
  String get boarding => '승차';

  @override
  String get alighting => '하차';

  @override
  String balanceAfterValue(String amount) {
    return '이용 후 잔액 $amount';
  }

  @override
  String get cantCalculateAmount => '금액을 계산할 수 없습니다';

  @override
  String get icaZeroAmount => '이 ICa 기록에는 금액이 0엔으로 저장되어 있어 이용 금액으로 표시하지 않습니다.';

  @override
  String get multipleStationCandidates => '여러 역 후보가 있습니다';

  @override
  String get stationInfoNeedsReview => '일부 역 정보 확인이 필요합니다';

  @override
  String get multipleStationHint =>
      '역 후보가 여러 개여서 특정 역으로 확정할 수 없습니다. 아래 오류 제보에서 올바른 역을 알려 주세요.';

  @override
  String get stationInfoNeedsReviewHint =>
      '일부 역명을 확인할 수 없습니다. 아래 오류 제보에서 올바른 역을 알려 주세요.';

  @override
  String get details => '상세 정보';

  @override
  String get transactionType => '거래 유형';

  @override
  String get boardingStation => '승차역';

  @override
  String get alightingStation => '하차역';

  @override
  String get busOperator => '버스 회사';

  @override
  String get paymentMethod => '결제 방식';

  @override
  String get combinedCash => '현금 병용';

  @override
  String get transactionTime => '거래 시각';

  @override
  String get topUpMethod => '충전 방식';

  @override
  String get topUpLocation => '충전 장소';

  @override
  String get processingLocation => '처리 장소';

  @override
  String get processingDetail => '세부 처리';

  @override
  String get unknown => '확인할 수 없음';

  @override
  String get balance => '잔액';

  @override
  String get reportTransaction => '이 내역의 오류 제보하기';

  @override
  String get stationNotRegistered => '역 정보 미등록';

  @override
  String get spendingTotal => '지출 합계';

  @override
  String get topUpTotal => '충전 합계';

  @override
  String get unknownRecords => '미확인 기록';

  @override
  String get all => '전체';

  @override
  String get transport => '교통';

  @override
  String get purchases => '결제';

  @override
  String get topUp => '충전';

  @override
  String get unconfirmed => '미확인';

  @override
  String get checkAmount => '금액 확인 필요';

  @override
  String get oldestRecord =>
      '이 기록은 카드에 남아 있는 가장 오래된 이용내역입니다. 그보다 오래된 잔액 기록이 없어 잔액 차이로 이용 금액을 계산할 수 없습니다.';

  @override
  String get noDecrease =>
      '이전 기록과 비교했을 때 잔액이 줄지 않았습니다. 충전·환불 등일 수 있어 일반 이용 금액으로 표시하지 않습니다.';

  @override
  String get notEnoughBalances => '비교할 수 있는 잔액 정보가 부족해 이용 금액을 계산할 수 없습니다.';

  @override
  String get unknownTransactionSummary => '거래 유형을 확인할 수 없습니다';

  @override
  String get busOrTram => '버스·노면전차 이용';

  @override
  String get railRide => '철도 이용';

  @override
  String get busRide => '버스 이용';

  @override
  String get purchase => '물품 구매';

  @override
  String get gateWindow => '개찰 창구 처리';

  @override
  String get unknownType => '유형 미확인';

  @override
  String get ticketMachine => '자동발권기';

  @override
  String get stationGateTerminal => '역 개찰 단말';

  @override
  String get stationTerminal => '역 단말';

  @override
  String get mobile => '모바일';

  @override
  String get mobileBenefit => '모바일 특전';

  @override
  String get storeTerminal => '매장 단말';

  @override
  String get ticketMachineTopUp => '자동발권기에서 충전';

  @override
  String ticketMachineTopUpAt(String station) {
    return '자동발권기에서 충전 · $station';
  }

  @override
  String get gateTerminalTopUp => '역 개찰 단말에서 충전';

  @override
  String topUpAt(String station) {
    return '충전 · $station';
  }

  @override
  String get stationTerminalTopUp => '역 단말에서 충전';

  @override
  String get mobileBenefitTopUp => '모바일 특전 충전';

  @override
  String get mobileTopUp => '모바일에서 충전';

  @override
  String get storeTopUp => '매장에서 충전';

  @override
  String get cardTopUp => '카드 충전';

  @override
  String get unknownBusOperator => '버스 회사 확인 불가';

  @override
  String get purchaseWithCash => '물품 구매 · 현금 병용';

  @override
  String gateWindowAt(String station) {
    return '개찰 창구 처리 · $station';
  }

  @override
  String get displaySettings => '화면';

  @override
  String get theme => '테마';

  @override
  String get system => '시스템';

  @override
  String get light => '라이트';

  @override
  String get dark => '다크';

  @override
  String get stationNames => '역명 표기';

  @override
  String get stationNamesHint => '한국어 표기가 확인된 역에만 적용됩니다.';

  @override
  String get stationFallbackHint => '확인된 표기가 없으면 일본어 역명을 표시합니다.';

  @override
  String get japanese => '일본어';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get both => '함께 표시';

  @override
  String get appLanguage => '앱 언어';

  @override
  String get deviceLanguage => '기기 언어';

  @override
  String get appInfo => '앱 정보';

  @override
  String get appVersion => '앱 버전';

  @override
  String get dataSources => '데이터 출처 및 운임 기준';

  @override
  String get dataSourcesHint => '교통패스별 운임 데이터·라이선스·계산 범위';

  @override
  String get appUpdate => '앱 업데이트';

  @override
  String get openSource => '오픈소스 라이선스';

  @override
  String get privacyData => '개인정보 및 데이터';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get privacyPolicyHint => 'NFC와 오류 제보 데이터 처리 안내';

  @override
  String get clearCurrentHistory => '현재 이용내역 지우기';

  @override
  String get nothingToClear => '지울 이용내역이 없습니다.';

  @override
  String transactionCount(int count) {
    return '$count개의 이용내역이 있습니다.';
  }

  @override
  String get support => '문의';

  @override
  String get cardSupport => '카드 인식 문의';

  @override
  String get cardSupportHint => '카드 읽기·브랜드 구분 문제';

  @override
  String get developerTools => '개발 도구';

  @override
  String get cardDiagnostics => '카드 브랜드 진단';

  @override
  String get cardDiagnosticsHint => '브랜드 선택·직접 입력 후 메타데이터 확인';

  @override
  String get japanIcCards => '일본 전국호환 교통계 IC 카드';

  @override
  String get checkingUpdates => '업데이트 정보를 확인하고 있습니다.';

  @override
  String get automaticUpdateCheck => '앱을 열면 자동으로 업데이트를 확인합니다.';

  @override
  String get appUpToDate => '현재 최신 버전을 사용 중입니다.';

  @override
  String get updateShownOnHome => '새 버전이 홈 화면에 안내됩니다.';

  @override
  String get updateStatusUnavailable => '지금은 업데이트 정보를 확인할 수 없습니다.';

  @override
  String get clearHistoryQuestion => '현재 이용내역을 지울까요?';

  @override
  String get clearHistoryHint => '이번에 읽은 이용내역과 원본 기록이\n앱 화면에서 삭제됩니다.';

  @override
  String get physicalCardUnchanged => '실물 카드 안의 데이터는 변경되지 않습니다.';

  @override
  String get clearHistory => '이용내역 지우기';

  @override
  String get cancel => '취소';

  @override
  String get comparePasses => '교통패스 비교';

  @override
  String get comparePassesHint => '패스 가격과 예상\n교통비 비교';

  @override
  String get contactlessRoutes => '컨택리스 노선';

  @override
  String get contactlessRoutesHint => '회사·노선별 터치 승차 지원 확인';

  @override
  String get findLockers => '코인락커 찾기';

  @override
  String get findLockersHint => '주요 역·공항의\n코인락커 위치 안내';

  @override
  String get comparisonUnavailable => '이 카드 읽기 방식에서는 여러 카드 비교를 사용할 수 없어요.';

  @override
  String comparisonUpdated(String card) {
    return '$card의 잔액을 갱신했어요.';
  }

  @override
  String comparisonAdded(String card) {
    return '$card를 추가했어요.';
  }

  @override
  String get checkNfcSettings => '휴대폰 설정에서 NFC를 확인해 주세요.';

  @override
  String get scanStillEnding => '스캔 종료를 기다리고 있어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get renameCard => '카드 이름 변경';

  @override
  String get cardName => '카드 이름';

  @override
  String get enterCardName => '이름을 입력해 주세요.';

  @override
  String get saveName => '변경';

  @override
  String get comparisonHelpHint =>
      '카드를 한 장씩 스캔해 최대 10장의 잔액을 비교합니다. 카드 항목을 누르면 해당 카드의 이용내역을 볼 수 있어요.\n\n잔액은 각 카드의 스캔 시점 기준이며 자동 갱신되지 않습니다. 같은 카드를 다시 읽으면 기존 항목을 갱신합니다.\n\n비교 정보는 기기 메모리에서만 사용하며 비교 종료 또는 앱 프로세스 종료 시 사라집니다. 기존 홈의 카드 이용내역은 변경하지 않습니다.';

  @override
  String get exitComparison => '비교 종료';

  @override
  String get comparisonHelp => '비교 도움말';

  @override
  String comparingCount(int count) {
    return '비교 중인 카드 $count장';
  }

  @override
  String get deleteAll => '전체 삭제';

  @override
  String get tapCardHistory => '카드를 누르면 이용내역을 볼 수 있어요.';

  @override
  String get addCardsToCompare => '비교할 카드를 추가해 주세요.';

  @override
  String get scanOneAtATime => '카드는 한 장씩 스캔해 주세요.';

  @override
  String cardMenu(String card) {
    return '$card 메뉴';
  }

  @override
  String get rename => '이름 변경';

  @override
  String get delete => '삭제';

  @override
  String get addCard => '카드 추가';

  @override
  String get comparisonLimit => '최대 10장까지 비교할 수 있어요. 기존 카드는 메뉴에서 다시 스캔할 수 있어요.';

  @override
  String checkedAt(String date) {
    return '확인 $date';
  }

  @override
  String get exitComparisonQuestion => '잔액 비교를 종료할까요?';

  @override
  String get exitComparisonHint => '비교 중인 카드와 이용내역은 저장되지 않으며 종료하면 모두 삭제됩니다.';

  @override
  String get exit => '종료';

  @override
  String get clearComparisonQuestion => '비교 목록을 비울까요?';

  @override
  String get clearComparisonHint => '추가한 카드와 이용내역을\n비교 목록에서 삭제합니다.';

  @override
  String get balancesUnchanged => '실제 카드 잔액은 바뀌지 않아요.';

  @override
  String get mapOffline => '인터넷 연결을 확인한 뒤 지도를 새로고침해 주세요.';

  @override
  String get mapStationsUnavailable => '두 역의 위치를 확인할 수 없어 지도를 표시하지 않습니다.';

  @override
  String get mapConfigUnavailable =>
      '이 기기에서 지도 설정을 확인할 수 없습니다. 역 정보는 위에서 확인해 주세요.';

  @override
  String get mapPreparationFailed => '지도를 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get stationLocations => '역 위치';

  @override
  String get mapLegend => '파란 핀: 승차 · 붉은 핀: 하차';

  @override
  String get mapCandidates => '복합역·구간의 후보 위치';

  @override
  String get mapLoading => '지도 준비 중';

  @override
  String get refreshMap => '지도 새로고침';

  @override
  String get mapAttribution => '역 좌표: Wikidata · CC0';

  @override
  String mapBoth(String station) {
    return '승차·하차 · $station';
  }

  @override
  String mapBoarding(String station) {
    return '승차 · $station';
  }

  @override
  String mapAlighting(String station) {
    return '하차 · $station';
  }

  @override
  String mapCandidateRole(String role) {
    return '$role 후보';
  }

  @override
  String get comparisonUnidentified => '카드를 구분하지 못했어요. 다시 스캔해 주세요.';

  @override
  String get comparisonBalanceUnavailable => '잔액을 확인하지 못했어요. 카드를 다시 스캔해 주세요.';

  @override
  String get comparisonDifferentCard => '선택한 카드와 다른 카드예요. 기존 카드를 다시 대 주세요.';

  @override
  String get comparisonAtLimit => '카드는 최대 10장까지 비교할 수 있어요.';

  @override
  String defaultCardName(String number) {
    return '카드 $number';
  }

  @override
  String get reportTitle => '오류 제보';

  @override
  String get reportQuestion => '어떤 정보가 잘못되었나요?';

  @override
  String get reportChooseClosest => '가장 가까운 항목 하나를 선택해 주세요.';

  @override
  String get reportStationIssue => '역 정보가 없거나 잘못됨';

  @override
  String get reportKoreanNameIssue => '역명 한글 표기 추가 요청';

  @override
  String get reportBusIssue => '버스 회사 정보가 없거나 잘못됨';

  @override
  String get reportTypeIssue => '거래 유형이 잘못됨';

  @override
  String get reportAmountIssue => '금액 또는 잔액이 잘못됨';

  @override
  String get reportOther => '기타';

  @override
  String get reportNext => '다음';

  @override
  String get reportWhichKoreanStation => '어느 역의 한글 표기인가요?';

  @override
  String get reportWhichStation => '어느 역 정보인가요?';

  @override
  String get reportChooseStations => '승차역·하차역을 선택해 주세요';

  @override
  String get reportCorrectBoarding => '올바른 승차역';

  @override
  String get reportCorrectAlighting => '올바른 하차역';

  @override
  String get reportCorrectType => '올바른 거래 유형';

  @override
  String get reportChooseType => '유형을 선택해 주세요';

  @override
  String get reportCustomType => '직접 입력한 거래 유형';

  @override
  String get reportTicketExample => '예: 승차권 구매';

  @override
  String get reportTransactionType => '거래 유형';

  @override
  String get reportKoreanBoarding => '승차역 한글 표기';

  @override
  String get reportKoreanAlighting => '하차역 한글 표기';

  @override
  String get reportOptionalDetails => '추가 설명 (선택)';

  @override
  String get reportDetailsHint => '개인정보를 제외하고 추가로 알려줄 내용을 적어주세요.';

  @override
  String get reportBack => '이전';

  @override
  String get reportReview => '검토하기';

  @override
  String get reportReviewTitle => '전송 전 확인';

  @override
  String get reportIssueType => '제보 유형';

  @override
  String get reportAffectedStation => '문제가 있는 역 정보';

  @override
  String get reportNotSelected => '선택되지 않음';

  @override
  String get reportSuggestedType => '제안 거래 유형';

  @override
  String get reportActualBus => '실제 버스 회사명';

  @override
  String get reportBusArea => '운행 도시·지역';

  @override
  String get reportSuggestedKoreanBoarding => '제안 승차역 한글 표기';

  @override
  String get reportNoInput => '입력 없음';

  @override
  String get reportParsedBoardingLine => '파서 확인 승차역 노선';

  @override
  String get reportSuggestedKoreanAlighting => '제안 하차역 한글 표기';

  @override
  String get reportParsedAlightingLine => '파서 확인 하차역 노선';

  @override
  String get reportSelectedRecord => '선택한 내역';

  @override
  String get reportTypeAmount => '거래 유형 / 금액';

  @override
  String get reportUsageDate => '이용 날짜';

  @override
  String get reportAnonymousRecord => '익명 원본 기록';

  @override
  String get reportPrivacy => '개인정보 보호';

  @override
  String get reportRecordPrivacy =>
      '카드 IDm은 포함하지 않습니다. 선택한 이용내역 1건과 입력한 역·도시·노선, 버스 회사·도시 또는 거래 유형, 제보 내용만 전송 대상으로 준비합니다.';

  @override
  String get reportSendConsent => '위 정보의 전송에 동의합니다.';

  @override
  String get reportSendFailedTitle => '제보를 전송하지 못했습니다';

  @override
  String get reportSendAnonymous => '익명으로 제보하기';

  @override
  String get reportUnexpectedError => '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportStationRequired => '역 범위를 선택해 주세요.';

  @override
  String get reportTypeRequired => '올바른 거래 유형을 선택해 주세요.';

  @override
  String get reportCorrectStationInfo => '올바른 역 정보';

  @override
  String get reportBusInfo => '버스 회사 정보';

  @override
  String get reportSuggestKorean => '한글 역명 제안';

  @override
  String get reportDetails => '추가 설명';

  @override
  String get reportStationGuide =>
      '역 이름과 도시·지역을 입력해 주세요. 노선명은 알고 있는 경우에만 적어주세요.';

  @override
  String get reportTypeGuide => '목록에서 선택하고, 없는 유형은 직접 입력해 주세요.';

  @override
  String get reportBusGuide => '실제 버스 회사명과 운행 도시·지역을 입력해 주세요.';

  @override
  String get reportKoreanGuide =>
      '승차역·하차역 중 해당 범위를 선택해 주세요. 한글 발음을 아는 경우에만 표기를 입력하면 됩니다.';

  @override
  String get reportGeneralGuide => '알고 있는 내용을 적어주시면 해석 정확도를 높이는 데 도움이 됩니다.';

  @override
  String get reportNoCustomInput => '직접 입력 없음';

  @override
  String get reportStationName => '역 이름';

  @override
  String get reportCity => '도시·지역';

  @override
  String get reportOptionalLine => '노선명 (선택)';

  @override
  String get reportKoreanName => '한글 표기';

  @override
  String get reportKoreanExample => '예: 시부야 (모르면 비워 두세요)';

  @override
  String get reportBusOperator => '버스 회사명';

  @override
  String get reportSelectKoreanStation => '한글 표기를 추가할 역을 선택해 주세요.';

  @override
  String get reportSelectIncorrectStation => '표시되지 않거나 잘못된 역 정보를 선택해 주세요.';

  @override
  String get reportSelectCorrectType => '올바른 거래 유형을 선택해 주세요';

  @override
  String get reportCustomTypeGuide => '목록에 없는 유형은 직접 입력할 수 있습니다.';

  @override
  String get reportBoarding => '승차역';

  @override
  String get reportAlighting => '하차역';

  @override
  String get reportBothStations => '승차역과 하차역 모두';

  @override
  String get reportRail => '철도 이용';

  @override
  String get reportBus => '버스 이용';

  @override
  String get reportPurchase => '물품 구매';

  @override
  String get reportCharge => '충전';

  @override
  String get reportGateWindow => '개찰 창구 처리';

  @override
  String get reportRefund => '환불';

  @override
  String get reportAdjustment => '정산';

  @override
  String get reportCustomOption => '목록에 없음 / 직접 입력';

  @override
  String get reportSelectedHistory => '선택한 이용내역';

  @override
  String get reportUnknownBus => '버스 회사 미확인';

  @override
  String get reportUnknownType => '거래 유형 미확인';

  @override
  String get reportAmountUnavailable => '계산 불가';

  @override
  String get reportNeedsReview => '확인 필요';

  @override
  String get reportDiagnosticsUnsupported => '이 읽기 방식에서는 카드 진단을 지원하지 않아요.';

  @override
  String get reportScanPrompt => '카드 한 장을 기기 뒷면 NFC 위치에 대 주세요.';

  @override
  String get reportDiagnosticsReady => '진단 정보를 확인했어요. 아직 서버로 전송하지 않았어요.';

  @override
  String get reportDiagnosticsCancelled => '진단을 취소했어요.';

  @override
  String get reportEnableNfc => 'NFC를 켠 뒤 다시 시도해 주세요.';

  @override
  String get reportDiagnosticsTimeout => '시간이 초과됐어요. 다시 진단해 주세요.';

  @override
  String get reportMetadataFailed => '메타데이터를 읽지 못했어요. 최소 오류 코드와 설명만 문의할 수 있어요.';

  @override
  String get reportDiagnosticsFailed => '진단을 완료하지 못했어요. 다시 시도해 주세요.';

  @override
  String get reportViewPayload => '전송 항목 전체 보기';

  @override
  String get reportPayloadNotice => '아래 내용만 전송해요. 이 화면을 여는 것만으로는 전송되지 않아요.';

  @override
  String get reportClose => '닫기';

  @override
  String get reportSupportReceived => '문의가 접수되었습니다';

  @override
  String get reportSupportPrivacy => '카드 IDm·잔액·이용내역은 전송되지 않았습니다.';

  @override
  String get reportConnectionRetry => '전송하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get reportCardSupport => '카드 인식 문의';

  @override
  String get reportUnreadableQuestion => '읽히지 않는 카드가 있나요?';

  @override
  String get reportSupportIntro =>
      '카드 읽기·브랜드 구분 문제를 알려 주세요.\n일반 스캔의 이용내역은 바뀌지 않아요.';

  @override
  String get reportSupportTopic => '문의 내용';

  @override
  String get reportOptionalBrand => '카드 브랜드 (선택)';

  @override
  String get reportBrandExample => '예: Kitaca · 모르면 비워 두세요';

  @override
  String get reportOptionalProblem => '문제 설명 (선택)';

  @override
  String get reportProblemHint => '어떤 문제가 있었나요?';

  @override
  String get reportNoPersonalInfo => '이름·카드번호·연락처는 적지 마세요.';

  @override
  String get reportMinimalDiagnostics => '최소 진단 확인';

  @override
  String get reportDiagnosticsPrivacy =>
      '시스템 코드·제조 정보(PMm)·일부 서비스의 존재 여부·통신 오류 코드만 확인해요.\n카드 전체·서비스 본문·IDm·카드번호·잔액·이용내역은 수집하지 않아요.';

  @override
  String get reportScanConsent => '최소 진단 확인에 동의해요';

  @override
  String get reportCheckingCard => '카드 확인 중…';

  @override
  String get reportDiagnosticScan => '진단용 카드 스캔';

  @override
  String get reportCancelDiagnostics => '진단 취소';

  @override
  String get reportReviewPayload => '전송할 내용 확인';

  @override
  String get reportSendInquiry => '문의 전송';

  @override
  String get reportSupportRetention =>
      '문의·최소 진단·앱/OS 버전·접수 번호·동의 버전을 Supabase로 보내 카드 인식 개선에 사용해요.\n처리 완료 후 1년 뒤 삭제하며, 검토 중인 문의는 유지해요. 익명 인증 ID는 접수 제한에 사용해요.';

  @override
  String get reportSupportConsent => '문의 전송에 동의해요';

  @override
  String get reportSupportUnavailable => '문의 서버가 준비되지 않았어요. 설정의 이메일로 연락해 주세요.';

  @override
  String get reportSending => '전송 중…';

  @override
  String get reportAgreeSend => '동의하고 문의 보내기';

  @override
  String get reportEmailContact => '개별 답변 문의: iccardreader10@gmail.com';

  @override
  String get reportReadingError => '카드 읽기 오류';

  @override
  String get reportBrandProblem => '카드 브랜드 구분';

  @override
  String get reportChooseTopic => '문의 유형 선택';

  @override
  String get reportReportReceived => '제보가 접수되었습니다';

  @override
  String get reportReportPrivacy => '카드 IDm과 다른 이용내역은 전송되지 않았습니다.';

  @override
  String get reportReceiptUnknown => '문의 접수를 확인하지 못했어요. 다시 시도해 주세요.';

  @override
  String get reportSupportRateLimit => '접수가 많아요. 10분 뒤 다시 시도해 주세요.';

  @override
  String get reportSupportRestricted => '문의 전송이 제한되었어요. 설정의 문의 이메일로 연락해 주세요.';

  @override
  String get reportInvalidDiagnostics => '전송 항목을 확인하지 못했어요. 다시 진단해 주세요.';

  @override
  String get reportSupportConnection => '문의 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportCheckConnection => '인터넷 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get reportReportNotReceived => '제보를 접수하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportInvalidResponse => '서버 응답을 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportAnonymousConnection => '익명 연결을 시작하지 못했습니다. 인터넷 연결을 확인해 주세요.';

  @override
  String get reportAlreadyReceived => '이미 접수된 제보입니다.';

  @override
  String get reportReportRateLimit =>
      '짧은 시간에 제보가 많이 접수되었습니다. 10분 뒤 다시 시도해 주세요.';

  @override
  String get reportReportRestricted =>
      '제보 전송이 제한되었습니다. 문의가 필요하면 앱 설정의 이메일로 연락해 주세요.';

  @override
  String get reportInvalidReport => '제보 내용을 확인할 수 없습니다. 입력 내용을 다시 확인해 주세요.';

  @override
  String get reportServerConnection => '서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get reportReportUnavailable => '오류 제보 서버가 설정되지 않았습니다. 앱 설정을 확인해 주세요.';

  @override
  String get reportUnreadableDescription => '카드를 읽을 수 없어요';

  @override
  String get reportBrandDescription => '카드 브랜드가 표시되지 않거나 달라요';

  @override
  String reportStep(int step) {
    return '$step/3 단계';
  }

  @override
  String reportRequiredField(String label) {
    return '$label을 입력해 주세요.';
  }

  @override
  String get reportReceiptHelp => '보내주신 내용은 확인 후\n앱 개선에 활용됩니다.';

  @override
  String get reportReceiptId => '접수 번호';

  @override
  String get reportDone => '확인';

  @override
  String get privacyOverviewTitle => '카드 정보는 기본적으로 기기 안에서 처리됩니다';

  @override
  String get privacyOverviewBody =>
      '교통카드의 최근 이용내역은 NFC로 읽어 화면에 표시하며, 앱을 종료하면 유지하지 않습니다. 카드 IDm 원문은 NFC 통신 중에만 일시적으로 사용하고 저장·표시·전송하지 않습니다.';

  @override
  String get privacyNfcTitle => '1. NFC 사용 목적';

  @override
  String get privacyNfcBody =>
      'NFC 권한은 사용자가 스캔을 시작했을 때 일본 교통계 IC 카드의 이용내역과 카드 종류를 확인하는 데 사용합니다. 별도 카드 인식 문의에서는 동의한 경우 최소 메타데이터만 확인합니다. 앱은 카드에 정보를 기록하거나 변경하지 않습니다.';

  @override
  String get privacyOnDeviceTitle => '2. 기기 안에서 처리하는 정보';

  @override
  String get privacyOnDeviceBody =>
      '최근 이용내역의 원본 16바이트 기록, 날짜, 거래 유형, 역 코드·역명, 금액과 잔액을 기기 안에서 해석해 표시합니다. 이용내역은 영구 저장하지 않으며 일반 스캔에서 다른 카드를 읽으면 현재 결과로 교체됩니다.\n\n여러 카드 잔액 비교에서는 최대 10장의 이름·잔액·확인 시각과 이용내역을 비교 화면의 메모리에서만 보관합니다. 같은 카드 구분에는 매 비교마다 생성한 무작위 키로 만든 세션 한정 비교값을 사용하며 IDm 원문을 보관하지 않습니다. 비교값·키·카드 이름은 서버나 파일에 저장·전송하지 않고 비교 종료 또는 앱 프로세스 종료 시 정리합니다. 개별 카드 삭제 시 해당 비교 정보도 제거합니다. 비교용 스캔은 홈의 기존 카드 결과를 변경하지 않습니다.';

  @override
  String get privacyReportsTitle => '3. 오류 제보 시 전송하는 정보';

  @override
  String get privacyReportsBody =>
      '오류 제보는 선택 사항입니다. 사용자가 미리보기를 확인하고 동의한 경우에만 선택한 이용내역 1건의 원본 기록과 코드·해석 결과, 이용 날짜, 금액·잔액, 입력한 역·도시·노선 또는 버스 회사·운행 도시/지역·설명, 앱·파서·역 데이터 버전, 플랫폼과 OS 버전을 Supabase로 전송합니다. 전송된 내용은 앱 개선을 위해 사용합니다.\n\n별도 카드 인식 문의는 이용내역 제보와 다릅니다. 진단 스캔에 동의하면 시스템 코드·제조 정보(PMm)·허용된 일부 서비스 존재 여부·통신 오류 코드만 기기에서 확인합니다. 다시 전송 항목·목적·보관 기간을 확인하고 명시적으로 동의한 경우에만 해당 최소 진단과 입력한 카드 종류·설명, 앱/OS 버전·접수 번호·동의 문서 버전을 Supabase로 전송합니다. 카드 종류 구분·읽기 오류 개선에 사용하며, 카드 전체 덤프·서비스 본문·잔액·이용내역은 이 문의에 포함하지 않습니다. 화면을 나가면 앱에 문의 내용을 남기지 않습니다.';

  @override
  String get privacyNotSentTitle => '4. 전송하지 않는 정보';

  @override
  String get privacyNotSentBody =>
      '카드 IDm 원문, 선택하지 않은 다른 이용내역, 이름, 이메일 주소, 기기 고유 식별자, 현재 위치와 이동 경로는 제보 데이터에 포함하지 않습니다.';

  @override
  String get privacyServicesTitle => '5. 외부 처리 서비스';

  @override
  String get privacyServicesBody =>
      '오류 제보 접수에는 Supabase의 익명 인증·서버·데이터베이스 기능을 사용합니다. 익명 인증 ID는 서버 내부에서 10분당 5건 제한과 악성 제보 차단에만 사용하며, 이메일·카드 IDm·기기 고유 ID가 아닙니다. 이 값은 앱 화면에 표시하지 않고 제보 내용과 함께 서버에서만 접근을 제한하는 데 사용합니다. 제보 내용은 Supabase 인프라를 통해 처리되고, 네트워크 연결 과정의 기술 정보는 해당 서비스 운영 정책에 따라 처리될 수 있습니다.';

  @override
  String get privacyMapsTitle => '5-1. Google 지도';

  @override
  String get privacyMapsBody =>
      '철도 이용내역 상세를 열면 인터넷 연결·역 위치·지도 설정을 확인한 경우 Google Maps SDK 지도를 자동으로 표시합니다. 복합역·구간은 후보 위치를 표시합니다. 표시할 역 주변 영역과 좌표가 지도 요청에 사용되며, Google은 IP 주소, 기기·운영체제·SDK 정보, SDK 전용 가명 식별값, 진단·사용 정보를 처리할 수 있습니다. 현재 위치 권한은 요청하지 않으며 카드 IDm·카드번호·잔액·이용내역 원문은 지도 SDK에 전달하지 않습니다. Google의 개인정보처리방침(https://policies.google.com/privacy)이 적용됩니다. 인터넷 연결이 확인되지 않으면 지도를 표시하지 않으며, 연결 후 지도 새로고침으로 다시 시도할 수 있습니다. 연결 상태는 Android 네트워크 기능 정보로 기기에서 확인하며 별도 확인 서버에 요청하지 않습니다. 지도 표시 중단이나 새로고침은 이미 발생한 지도 요청을 취소하거나 삭제하는 것은 아닙니다. 지도 연결 없이도 카드 읽기와 이용내역 목록은 사용할 수 있습니다. 앱은 지도 이용내역을 별도로 저장하지 않으며 Google의 보관·삭제 기준은 해당 정책을 따릅니다.';

  @override
  String get privacyStationDataTitle => '6. 역 코드 데이터';

  @override
  String get privacyStationDataBody =>
      '역명 조회에는 허가받아 앱에 포함한 Yoiko 역 코드 데이터를 사용합니다. 조회는 기기 안에서 수행되며, 역명을 확인하기 위해 카드 기록을 외부 서버로 보내지 않습니다. 이용 조건은 설정의 데이터 출처 및 운임 기준 화면에서 확인할 수 있습니다.';

  @override
  String get privacyRetentionTitle => '7. 보관과 삭제';

  @override
  String get privacyRetentionBody =>
      '기기에서 읽은 이용내역은 앱이 영구 저장하지 않습니다. 선택적으로 전송된 오류 제보 중 반영 완료 또는 제외된 문의와 검토 이력은 해결 후 1년간 보관한 뒤 매월 자동 삭제합니다. 확인 중인 문의는 실수로 삭제되지 않도록 자동 삭제하지 않습니다. 악성 제보 차단 정보는 서버 보안 목적에 한해 유지하며, 법령상 보존 의무가 있는 경우에는 해당 기간 동안 보관할 수 있습니다.';

  @override
  String get privacyContactTitle => '8. 정책 변경과 문의';

  @override
  String get privacyContactBody =>
      '데이터 처리 방식이 변경되면 이 방침과 시행일을 함께 갱신합니다. 개인정보 확인·삭제 요청, 앱 오류, 이용 방법과 기타 문의는 iccardreader10@gmail.com으로 접수합니다. 공개 방침: https://yohan020.github.io/ic_card_reader/';

  @override
  String get privacyEffectiveDate => '시행일: 2026년 10월 27일';

  @override
  String get passRegionHokkaido => '홋카이도';

  @override
  String get passRegionTohoku => '도호쿠';

  @override
  String get passRegionKanto => '도쿄·간토';

  @override
  String get passRegionChubu => '주부';

  @override
  String get passRegionKansai => '간사이';

  @override
  String get passRegionChugoku => '주고쿠';

  @override
  String get passRegionShikoku => '시코쿠';

  @override
  String get passRegionKyushu => '규슈';

  @override
  String get passRegionOkinawa => '오키나와';

  @override
  String get passRegionHokkaidoHint => '삿포로·하코다테 등';

  @override
  String get passRegionTohokuHint => '센다이·아오모리 등';

  @override
  String get passRegionKantoHint => '도쿄·가나가와 지역 패스';

  @override
  String get passRegionChubuHint => '나고야·호쿠리쿠 등';

  @override
  String get passRegionKansaiHint => '오사카·교토·나라 지역 패스';

  @override
  String get passRegionChugokuHint => '히로시마·오카야마 등';

  @override
  String get passRegionShikokuHint => '마쓰야마·다카마쓰 등';

  @override
  String get passRegionKyushuHint => '후쿠오카 지역 패스';

  @override
  String get passRegionOkinawaHint => '나하·오키나와 지역';

  @override
  String get passTitle => '교통패스 비교';

  @override
  String get passIntro => '입력한 이동 계획을 기준으로 일반 운임과 패스 가격을 비교합니다.';

  @override
  String get passCalculationBasis => '계산 기준';

  @override
  String get passCalculationNotice =>
      '지원 데이터로 확인되는 이동만 계산합니다. 확인할 수 없는 운임은 합산하지 않으며, 구매 전 공식 상품 조건과 운임을 확인해 주세요.';

  @override
  String get passSapporo => '삿포로 지하철 1일권';

  @override
  String get passSapporoScope => '삿포로시 지하철 · 전 구간';

  @override
  String get passSubwayDescription => '지하철 전 구간의 일반 운임과 비교합니다.';

  @override
  String get passSapporoPeriod => '1일권 · ¥830';

  @override
  String get passHokkaido => '홋카이도 레일패스';

  @override
  String get passHokkaidoScope => 'JR 홋카이도선 · 보통차 지정석';

  @override
  String get passHokkaidoDescription => '5·7·10일권과 철도·버스 이동 예상 운임을 비교합니다.';

  @override
  String get passHokkaidoFive => '5일권 · ¥23,000';

  @override
  String get passHokkaidoSeven => '7일권 · ¥29,000';

  @override
  String get passHokkaidoTen => '10일권 · ¥38,000';

  @override
  String get passTokyoScope => 'Tokyo Metro · 도에이 지하철';

  @override
  String get passTokyoDescription => '24·48·72시간권의 손익을 비교합니다.';

  @override
  String get passHours24 => '24시간';

  @override
  String get passHours48 => '48시간';

  @override
  String get passHours72 => '72시간';

  @override
  String get passEnokama => '에노시마·가마쿠라 프리패스';

  @override
  String get passEnokamaScope => '에노덴 · 오다큐 전철';

  @override
  String get passEnokamaDescription => '출발역별 가격과 프리구간 운임을 비교합니다.';

  @override
  String get passEnokamaPeriod => '1일권 · 발역별 가격';

  @override
  String get passEnoden => '에노덴 1일 승차권';

  @override
  String get passEnodenScope => '에노시마 전철 · 에노덴 전선';

  @override
  String get passEnodenDescription => '에노덴 내부 이동의 일반 운임과 비교합니다.';

  @override
  String get passEnodenPeriod => '1일권 · ¥800';

  @override
  String get passHakone => '하코네 프리패스';

  @override
  String get passHakoneScope => '오다큐 70개 출발역 · 하코네 교통수단';

  @override
  String get passHakoneDescription => '출발역별 성인 가격과 하코네 현지 운임을 비교합니다.';

  @override
  String get passDaysTwo => '2일권';

  @override
  String get passDaysThree => '3일권';

  @override
  String get passTokunai => '도쿠나이 패스';

  @override
  String get passTokunaiScope => '도쿄 23구 내 지정 JR 구간';

  @override
  String get passTokunaiDescription => '1일권과 적용 JR 구간의 일반 운임을 비교합니다.';

  @override
  String get passTokunaiPeriod => '1일권 · ¥870';

  @override
  String get passKyotoSubway => '교토 지하철 1일권';

  @override
  String get passKyotoSubwayScope => '교토시영 지하철 · 전 구간';

  @override
  String get passOsaka => '오사카 주유패스';

  @override
  String get passOsakaScope => '오사카 메트로 · 사철 · 시티버스';

  @override
  String get passOsakaDescription => '1·2일권과 환승 경로의 일반 운임을 비교합니다.';

  @override
  String get passOsakaOne => '1일권 · ¥3,500';

  @override
  String get passOsakaTwo => '2일권 · ¥5,000';

  @override
  String get passKyotoBus => '교토 지하철·버스 1일권';

  @override
  String get passKyotoBusScope => '교토시영 지하철 · 버스 예상 운임';

  @override
  String get passKyotoBusDescription => '지하철 자동 운임과 버스 이용 추정을 비교합니다.';

  @override
  String get passKyotoBusPeriod => '1일권 · ¥1,100';

  @override
  String get passHankyu => '한큐패스 1일권';

  @override
  String get passHankyuScope => '한큐 전철 전 노선';

  @override
  String get passHankyuDescription => '한큐 전철 내부 이동의 일반 운임과 비교합니다.';

  @override
  String get passHankyuPeriod => '1일권 · ¥1,300';

  @override
  String get passKintetsu => '긴테쓰 레일 패스';

  @override
  String get passKintetsuScope => '긴테쓰 전철 · 이가철도 · 케이블카';

  @override
  String get passKintetsuDescription => '권종별 적용 구간과 일반 운임을 비교합니다.';

  @override
  String get passDaysOne => '1일권';

  @override
  String get passDaysFive => '5일권';

  @override
  String get passDaysFivePlus => '5일권 Plus';

  @override
  String get passOkayama => '오카야마·구라시키 tabiwa 구루링 패스';

  @override
  String get passOkayamaScope => 'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스';

  @override
  String get passOkayamaDescription => '3일권과 철도·노면전차·버스 이동 운임을 비교합니다.';

  @override
  String get passOkayamaPeriod => '3일권 · ¥3,800';

  @override
  String get passHiroden => '히로덴 전차 패스';

  @override
  String get passHirodenScope => '히로시마 전철 · 전차 전 노선';

  @override
  String get passHirodenDescription => '일반 운임과 1일·8시간·24시간권을 비교합니다.';

  @override
  String get passHirodenOne => '1일권 · ¥700';

  @override
  String get passHirodenEight => '8시간권 · ¥600';

  @override
  String get passHirodenTwentyFour => '24시간권 · ¥700';

  @override
  String get passNagasaki => '나가사키 전기궤도 패스';

  @override
  String get passNagasakiScope => '나가사키 전기궤도 · 노면전차 전 노선';

  @override
  String get passNagasakiDescription => 'IC·터치 기준 일반 운임과 1일·24시간권을 비교합니다.';

  @override
  String get passNagasakiOne => '1일권 · ¥600';

  @override
  String get passFukuoka => '후쿠오카 지하철 1일권';

  @override
  String get passFukuokaScope => '후쿠오카시 지하철 · 3개 노선';

  @override
  String get passFukuokaPeriod => '1일권 · ¥640';

  @override
  String get passYui => '유이레일 패스';

  @override
  String get passYuiScope => '오키나와 도시 모노레일 · 전 노선';

  @override
  String get passYuiDescription => '24·48시간권과 유이레일 일반 운임을 비교합니다.';

  @override
  String get passYuiOne => '24시간 · ¥1,000';

  @override
  String get passYuiTwo => '48시간 · ¥1,800';

  @override
  String get passChooseRegion => '비교할 지역을\n선택해 주세요';

  @override
  String get passChooseRegionHint => '여행할 지역을 먼저 선택하면 해당 지역의 교통패스를 볼 수 있습니다.';

  @override
  String get passComingSoon => '준비 중';

  @override
  String get passStepSelect => '패스 선택';

  @override
  String get passStepPlan => '이용 계획';

  @override
  String get passStepResult => '비교 결과';

  @override
  String get passSelectStation => '역 선택';

  @override
  String get passRemoveSegment => '구간 삭제';

  @override
  String get passEstimateNote => '입력한 교통 이용 기준의 예상 비교입니다.';

  @override
  String passChooseInRegion(String region) {
    return '$region의\n교통패스를 선택해 주세요';
  }

  @override
  String passViewRegion(String region, int count) {
    return '$region 교통패스 $count개 보기';
  }

  @override
  String passRegionComingSoon(String region) {
    return '$region 교통패스 준비 중';
  }

  @override
  String passCount(int count) {
    return '$count개';
  }

  @override
  String passStartComparison(String title) {
    return '$title 비교 시작';
  }

  @override
  String passSearchStation(String label) {
    return '$label역 검색';
  }

  @override
  String get passDeparture => '출발';

  @override
  String get passArrival => '도착';

  @override
  String get passFlow001 => '이동 구간';

  @override
  String get passFlow002 => '비교 결과 보기';

  @override
  String get passFlow003 => '비우기';

  @override
  String passFlow004(String arg0) {
    return '성인 일반 운임 ¥$arg0';
  }

  @override
  String get passFlow005 => '역 이름을 검색해 주세요';

  @override
  String get passFlow006 => '이동 계획을 입력해 주세요';

  @override
  String get passFlow007 => '이동 구간 추가';

  @override
  String get passFlow008 => '패스가 더 이득이에요';

  @override
  String passFlow009(String arg0) {
    return '$arg0역 선택';
  }

  @override
  String get passFlow010 => '두 역을 선택하면 운임을 자동으로 확인합니다.';

  @override
  String get passFlow011 => '예상 손익';

  @override
  String get passFlow012 => '일반 운임과 같아요';

  @override
  String get passFlow013 => '일치하는 역을 찾지 못했어요';

  @override
  String get passFlow014 => '출발·도착 바꾸기';

  @override
  String get passFlow015 => '개별 결제가 더 저렴해요';

  @override
  String get passFlow016 => '다른 표기나 초성으로 다시 검색해 주세요.';

  @override
  String get passFlow017 => '비교할 구간이 부족해요';

  @override
  String get passFlow018 => '이 구간의 운임을 확인할 수 없습니다.';

  @override
  String get passFlow019 => '찾고 싶은 역을 입력해 주세요';

  @override
  String get passFlow020 => '패스 가격';

  @override
  String passFlow021(String arg0) {
    return '교통비 기준 ¥$arg0 절약';
  }

  @override
  String get passFlow022 => '이동별 상세';

  @override
  String get passFlow023 => '패스 가격과 일반 결제 예상 합계가 같아요';

  @override
  String passFlow024(String arg0) {
    return '현재 계획에서는 ¥$arg0 차이';
  }

  @override
  String get passFlow025 => '다시 시도';

  @override
  String get passFlow026 => '패스 데이터를 불러오지 못했어요';

  @override
  String get passFlow027 => '한국어·초성·일본어·영어로 검색할 수 있습니다.';

  @override
  String get passFlow028 => '한국어·초성·일본어로 검색할 수 있습니다.';

  @override
  String passFlow029(String arg0) {
    return '$arg0회';
  }

  @override
  String get passFlow030 => '교토시영 지하철';

  @override
  String get passFlow031 => '패스 출발역 선택';

  @override
  String passFlow032(String arg0) {
    return '$arg0일권';
  }

  @override
  String get passFlow033 => '1회 늘리기';

  @override
  String get passFlow034 => '1회 줄이기';

  @override
  String passFlow035(String arg0) {
    return '$arg0 출발역';
  }

  @override
  String passFlow036(String arg0) {
    return '$arg0개 출발역';
  }

  @override
  String passFlow037(String arg0) {
    return '$arg0시간';
  }

  @override
  String passFlow038(String arg0, String arg1) {
    return '$arg0일권 $arg1엔';
  }

  @override
  String passFlow039(String arg0) {
    return '1회 ¥$arg0';
  }

  @override
  String get passFlow040 => '24시간권';

  @override
  String passFlow041(String arg0) {
    return '검색 결과 $arg0개';
  }

  @override
  String get passFlow042 => '검색어 지우기';

  @override
  String get passFlow043 => '긴테쓰 전 노선과 이가철도';

  @override
  String get passFlow044 => '나가사키 전기궤도';

  @override
  String get passFlow045 => '노선 선택';

  @override
  String get passFlow046 => '다마선';

  @override
  String get passFlow047 => '도니치카 킵';

  @override
  String get passFlow048 => '도에이 지하철';

  @override
  String get passFlow049 => '버스 예상 운임';

  @override
  String get passFlow050 => '삿포로시 지하철';

  @override
  String get passFlow051 => '실제로 개찰을 통과할 출발역과 하차역을 입력하면 운임을 자동으로 찾습니다.';

  @override
  String get passFlow052 => '에노시마선';

  @override
  String get passFlow053 => '오다와라선';

  @override
  String get passFlow054 => '오다큐 출발역을 선택해 주세요';

  @override
  String get passFlow055 => '운임 데이터를 읽지 못했습니다';

  @override
  String get passFlow056 => '유이레일';

  @override
  String get passFlow057 => '일반 결제 예상 합계';

  @override
  String get passFlow058 => '일치하는 출발역을 찾지 못했어요. 한글·초성·일본어로 다시 검색해 주세요.';

  @override
  String get passFlow059 => '철도 일반 운임';

  @override
  String get passFlow060 => '출발역 검색';

  @override
  String get passFlow061 => '한큐 전철';

  @override
  String get passFlow062 => '후쿠오카시 지하철';

  @override
  String get passFlow063 => '히로시마 전철';

  @override
  String get passFlow064 => 'JR 서일본';

  @override
  String get passFlow065 => ' 버스는 직접 입력한 운임만 반영해요.';

  @override
  String passFlow066(String arg0, String arg1) {
    return '$arg0 · $arg1개 구간 적용';
  }

  @override
  String passFlow067(String arg0) {
    return '$arg0 · 오다와라 왕복 1회 포함';
  }

  @override
  String passFlow068(String arg0) {
    return '$arg0 가격';
  }

  @override
  String passFlow069(String arg0) {
    return '$arg0 검색';
  }

  @override
  String passFlow070(String arg0) {
    return '$arg0 기준으로 삿포로시 지하철의 성인 일반 운임만 합산합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.';
  }

  @override
  String passFlow071(String arg0) {
    return '$arg0 기준으로 성인 일반 운임을 1회 ¥240씩 합산합니다. 입력한 구간 하나를 별도로 운임이 청구되는 1회 이용으로 보며, MOBIRY DAYS 할인과 자동 환승·재승차 판정은 포함하지 않습니다.';
  }

  @override
  String passFlow072(String arg0) {
    return '$arg0 기준으로 성인 IC·터치 결제 운임을 합산합니다. 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함하며, 현금·버스·소아요금은 포함하지 않습니다.';
  }

  @override
  String passFlow073(String arg0) {
    return '$arg0 선택';
  }

  @override
  String passFlow074(String arg0, String arg1) {
    return '$arg0번 이동 · $arg1';
  }

  @override
  String passFlow075(String arg0, String arg1) {
    return '$arg0시간 ¥$arg1';
  }

  @override
  String passFlow076(String arg0) {
    return '$arg0시간권';
  }

  @override
  String passFlow077(String arg0, String arg1) {
    return '$arg0시간권 $arg1엔';
  }

  @override
  String passFlow078(String arg0, String arg1) {
    return '$arg0일권 ¥$arg1';
  }

  @override
  String get passFlow079 => '1일권 · JR 파생 운임';

  @override
  String get passFlow080 => '1일권 ¥3,500 · 2일권 ¥5,000 · 환승 자동 계산';

  @override
  String get passFlow081 => '1회 예상 ¥300';

  @override
  String get passFlow082 => '24·48·72시간권 · 자동 운임';

  @override
  String get passFlow083 => '2일';

  @override
  String get passFlow084 => '2일권과 같은 나라교통 구간 및 미에교통·도바 카모메 버스 지정 구간';

  @override
  String get passFlow085 => '3일';

  @override
  String get passFlow086 => '8시간권';

  @override
  String get passFlow087 => '검증된 철도·버스 운임 데이터를 불러오는 중입니다.';

  @override
  String get passFlow088 => '검증할 패스를 선택해 주세요';

  @override
  String get passFlow089 => '결과 사용 시 주의';

  @override
  String get passFlow090 =>
      '공개된 거리·운임 규칙으로 검증한 철도 운임과 오사카 시티버스 일반 운임을 자동 합산합니다. 관광시설 무료입장 가치는 포함하지 않습니다.';

  @override
  String get passFlow091 => '공식 안내를 열 수 없어요.';

  @override
  String get passFlow092 =>
      '공식 안내에서 적용이 확인된 버스의 성인 일반 운임 합계만 입력해 주세요. 앱이 버스 적용 여부를 판정하지는 않아요.';

  @override
  String get passFlow093 => '공식 적용 구간 확인';

  @override
  String get passFlow094 => '관광시설 입장·할인 혜택은 포함하지 않습니다.';

  @override
  String get passFlow095 =>
      '관광시설 혜택, 패스 제외 버스, 특급권·좌석요금은 포함하지 않습니다. 사업자가 바뀌는 이동은 지원 역 그래프의 거리 기반 추천 경로로 계산하므로, 실제 이용 경로와 구매 전 최신 공식 조건을 확인해 주세요.';

  @override
  String get passFlow096 => '관광시설 혜택은 제외하며, 버스 대표 요금은 실제 요금과 다를 수 있습니다.';

  @override
  String get passFlow097 => '관광시설을 이용하면 추가 이득이 생길 수 있습니다.';

  @override
  String get passFlow098 => '관광특급버스';

  @override
  String get passFlow099 => '교토 버스 예상 이용';

  @override
  String get passFlow100 => '교토 지하철·버스 1일권 기준 탑승 횟수를 직접 입력해 주세요.';

  @override
  String get passFlow101 => '교토시영 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow102 => '교토시영 지하철 이동 구간을 입력해 주세요.';

  @override
  String get passFlow103 => '교토시영 지하철 일반 운임';

  @override
  String get passFlow104 =>
      '교토시영 지하철 전 구간의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.';

  @override
  String get passFlow105 =>
      '교토시영 지하철 전 구간의 성인 일반 운임만 합산합니다. 1일권은 이용일 당일 영업 종료까지 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.';

  @override
  String get passFlow106 =>
      '교토시영 지하철은 역 선택 기반 성인 일반 운임, 버스는 입력한 횟수 기반 예상 운임입니다.';

  @override
  String get passFlow107 => '교토시영 지하철은 역을 선택하면 성인 운임을 자동으로 찾습니다.';

  @override
  String get passFlow108 => '교통비만 보면 일반 결제가 저렴해요';

  @override
  String get passFlow109 => '교통비만 비교합니다';

  @override
  String passFlow110(String arg0) {
    return '교통비만으로 ¥$arg0 절약';
  }

  @override
  String get passFlow111 => '교통수단 선택';

  @override
  String get passFlow112 => '교통패스 비교 프로토타입';

  @override
  String get passFlow113 => '구간별 판정';

  @override
  String get passFlow114 =>
      '권종의 적용 범위 안에서 이동하는 구간만 계산해요. 특급권·로프웨이·할인·특전은 포함하지 않아요.';

  @override
  String get passFlow115 =>
      '긴테쓰에서 실제로 개찰을 통과할 출발역과 하차역을 입력하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow116 => '나가사키 전기궤도 1일권';

  @override
  String get passFlow117 => '나가사키 전기궤도 24시간권';

  @override
  String get passFlow118 => '나가사키 전기궤도 이동 구간을 입력해 주세요.';

  @override
  String get passFlow119 => '나가사키 전기궤도 일반 운임';

  @override
  String get passFlow120 => '나가사키 전기궤도 정류장을 선택하면 IC·터치 기준 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow121 => '나라교통: 나라공원·니시노쿄·호류지 지정 구간';

  @override
  String get passFlow122 => '나라교통: 나라공원·니시노쿄·호류지·아스카·무로·야마노베노미치 지정 구간';

  @override
  String get passFlow123 => '노면전차·버스 이용';

  @override
  String get passFlow124 => '노면전차·버스 일반 운임';

  @override
  String get passFlow125 => '데이터 준비 중';

  @override
  String get passFlow126 => '도착역';

  @override
  String get passFlow127 => '도쿄메트로';

  @override
  String get passFlow128 => '도쿠나이 패스 1일권';

  @override
  String get passFlow129 => '도쿠나이 패스 적용 JR';

  @override
  String get passFlow130 => '두 지점을 선택하면 성인 일반 운임을 확인합니다.';

  @override
  String get passFlow131 => '등산전차';

  @override
  String get passFlow132 =>
      '등산전차·케이블카·로프웨이·해적선은 정확 운임으로, 버스는 평균 운임과 횟수로 계산합니다. 로망스카 특급권은 포함하지 않습니다.';

  @override
  String get passFlow133 => '로프웨이';

  @override
  String get passFlow134 => '버스 대표 요금은 실제 이용 구간의 요금과 다를 수 있습니다.';

  @override
  String get passFlow135 => '버스 운임 (선택)';

  @override
  String get passFlow136 => '버스 운임은 예상값입니다';

  @override
  String get passFlow137 => '버스 이용 추정';

  @override
  String get passFlow138 => '버스 이용 횟수 늘리기';

  @override
  String get passFlow139 => '버스 이용 횟수 줄이기';

  @override
  String get passFlow140 => '버스는 추정 요금이며, 실제 경로·환승 운임에 따라 차이가 날 수 있습니다.';

  @override
  String get passFlow141 => '버스는 횟수 기반 예상 운임입니다';

  @override
  String get passFlow142 => '보통·쾌속';

  @override
  String get passFlow143 => '비교 제외';

  @override
  String get passFlow144 => '비교 제외 외부 운임';

  @override
  String get passFlow145 => '비교할 이동이 부족해요';

  @override
  String get passFlow146 => '삿포로시 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow147 => '삿포로시 지하철 이동 구간을 입력해 주세요.';

  @override
  String get passFlow148 => '삿포로시 지하철 일반 운임';

  @override
  String get passFlow149 =>
      '삿포로시 지하철의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.';

  @override
  String passFlow150(String arg0) {
    return '선택한 권종 안의 성인 기본 운임만 합산해요. 범위를 넘는 이동의 정산액, 특급권·로프웨이·할인·특전은 포함하지 않아요.$arg0';
  }

  @override
  String get passFlow151 =>
      '선택한 오다큐 출발역의 패스 가격과 후지사와 왕복 성인 IC 운임, 프리구간의 실제 입력 이동만 비교합니다.';

  @override
  String get passFlow152 => '성인 일반 운임만 기준으로 하코네 프리패스의 손익을 비교합니다.';

  @override
  String get passFlow153 =>
      '성인 일반 운임을 1회 ¥240으로 계산합니다. 입력한 구간 하나를 별도로 운임이 청구되는 1회 이용으로 보며, MOBIRY DAYS 할인과 자동 환승·재승차 판정은 포함하지 않습니다.';

  @override
  String get passFlow154 =>
      '성인 IC·터치 결제 기준 운임을 계산합니다. 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함하며, 현금·버스·소아요금은 포함하지 않습니다.';

  @override
  String get passFlow155 => '시모덴 버스 대표 운임';

  @override
  String get passFlow156 => '시티버스 일반 운임';

  @override
  String get passFlow157 =>
      '실제로 개찰을 통과해 하차한 역을 입력해 주세요. 추천 경로는 시간표 기반 최속 경로가 아닙니다.';

  @override
  String get passFlow158 =>
      '실제로 개찰을 통과해 하차한 역을 입력해 주세요. 확인되지 않은 운임은 계산하지 않습니다.';

  @override
  String get passFlow159 => '아직 비교할 이동이 없어요';

  @override
  String get passFlow160 => '앱을 다시 실행하거나 다시 시도해 주세요.';

  @override
  String passFlow161(String arg0) {
    return '약 ¥$arg0/회';
  }

  @override
  String get passFlow162 => '에노덴 이동 구간을 입력해 주세요.';

  @override
  String get passFlow163 => '에노덴 일반 운임';

  @override
  String get passFlow164 =>
      '에노덴 전선 15개 역의 성인 일반 운임만 합산합니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passFlow165 =>
      '에노덴 전선 내부 이동의 성인 일반 운임만 계산합니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passFlow166 => '에노덴·오다큐 프리구간 역을 검색할 수 있습니다.';

  @override
  String get passFlow167 =>
      '에노덴에서 실제로 개찰을 통과할 출발역과 하차역을 입력하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow168 => '에노시마 전철';

  @override
  String get passFlow169 => '에노시마 전철 · 에노덴';

  @override
  String get passFlow170 => '에노시마·가마쿠라 프리패스 1일권';

  @override
  String get passFlow171 => '역';

  @override
  String get passFlow172 => '역 구매 가격 · 사전 구매 시 ¥1,000 저렴';

  @override
  String get passFlow173 => '역과 운임 데이터를 준비한 뒤 다시 시도해 주세요.';

  @override
  String get passFlow174 => '예: 800';

  @override
  String get passFlow175 => '예상 비용 차이가 없습니다';

  @override
  String passFlow176(String arg0) {
    return '예상 절약액 ¥$arg0';
  }

  @override
  String get passFlow177 => '오사카 시티버스';

  @override
  String passFlow178(String arg0) {
    return '오사카 시티버스 $arg0회';
  }

  @override
  String get passFlow179 => '오사카 주유패스 1일권';

  @override
  String get passFlow180 => '오사카 주유패스 2일권';

  @override
  String get passFlow181 => '오사카·나라·교토의 긴테쓰 노선 (오사카선은 산본마쓰까지)';

  @override
  String get passFlow182 => '오사카난바–긴테쓰나라, 교토–쓰쓰이, 나가타–이코마, 도리이마에–이코마산조';

  @override
  String get passFlow183 => '오사카는 교통비만 비교합니다';

  @override
  String get passFlow184 => '오카야마·구라시키 tabiwa 구루링 패스 3일권';

  @override
  String get passFlow185 => '운영사 정보 없음';

  @override
  String passFlow186(String arg0) {
    return '유이레일 $arg0';
  }

  @override
  String get passFlow187 => '유이레일 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow188 => '유이레일 이동 구간을 입력해 주세요.';

  @override
  String get passFlow189 => '유이레일 일반 운임';

  @override
  String get passFlow190 => '유이레일의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.';

  @override
  String passFlow191(String arg0) {
    return '유이레일의 성인 일반 운임만 합산합니다. $arg0시간권은 발권 시점부터 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.';
  }

  @override
  String get passFlow192 => '유효시간 밖';

  @override
  String get passFlow193 => '유효한 이동 구간을 입력하면 판정 근거가 표시됩니다.';

  @override
  String get passFlow194 => '이 권종의 적용 범위 밖이에요. 비교 합계에서 제외합니다.';

  @override
  String get passFlow195 => '이동 계획 수정';

  @override
  String get passFlow196 => '이용 당일 이동만 입력해 주세요.';

  @override
  String passFlow197(String arg0) {
    return '이용 시작일부터 연속 $arg0일간의 이동만 입력해 주세요.';
  }

  @override
  String get passFlow198 => '이용 열차';

  @override
  String get passFlow199 => '이용 횟수';

  @override
  String get passFlow200 => '이용할 교통수단의 횟수를 입력해 주세요.';

  @override
  String get passFlow201 => '일반 1일권';

  @override
  String get passFlow202 => '일반 결제가 더 저렴해요';

  @override
  String get passFlow203 => '일반 시내버스';

  @override
  String get passFlow204 =>
      '일반 시내버스와 관광특급버스 횟수만 합산합니다. 실제 노선·사업자·조정 운임 구간·심야 할증과 패스 제외 노선은 자동 판정하지 않습니다.';

  @override
  String get passFlow205 => '일반 운임 합계';

  @override
  String get passFlow206 => '일부 특정 노선과 온디맨드 버스는 패스 대상이 아닙니다.';

  @override
  String passFlow207(String arg0, String arg1, String arg2, String arg3) {
    return '입력한 교통 이용 기준의 예상 비교입니다.\n버스는 추정 요금이며 실제 요금과 다를 수 있습니다.\n\n패스 가격 ¥$arg0\n입력 구간 운임 ¥$arg1\n버스 예상 운임 ¥$arg2\n예상 손익 ¥$arg3';
  }

  @override
  String get passFlow208 => '적용 버스 운임 (직접 입력)';

  @override
  String get passFlow209 => '적용 버스 운임 합계';

  @override
  String get passFlow210 => '적용 범위 밖 · 합계 제외';

  @override
  String get passFlow211 => '적용 철도 일반 운임';

  @override
  String get passFlow212 => '정류장별 운임이 아닌 사업자별 평균 성인 운임입니다.';

  @override
  String get passFlow213 => '주유패스 대상 일반 노선';

  @override
  String passFlow214(String arg0) {
    return '주유패스 대상 일반 노선 탑승 횟수 · 1회 ¥$arg0';
  }

  @override
  String get passFlow215 => '지원 데이터에서 경로를 확인할 수 없습니다.';

  @override
  String get passFlow216 => '지원 데이터에서 해당 역 사이의 경로와 운임을 찾지 못했습니다.';

  @override
  String get passFlow217 => '지하철 구간 또는 버스 이용 횟수를 입력해 주세요.';

  @override
  String get passFlow218 => '지하철 일반 운임';

  @override
  String get passFlow219 =>
      '지하철은 실제 개찰을 통과해 하차한 역을 입력해 주세요. 버스 운임 기준은 설정의 데이터 출처 및 운임 기준에서 확인할 수 있습니다.';

  @override
  String get passFlow220 => '참고용 자동 계산 결과';

  @override
  String passFlow221(String arg0, String arg1) {
    return '철도 $arg0역·환승 연결 $arg1개와 시티버스 일반 운임을 사용합니다. 관광시설 혜택은 포함하지 않습니다.';
  }

  @override
  String get passFlow222 => '철도 구간을 선택하거나 버스 탑승 횟수를 입력해 주세요.';

  @override
  String get passFlow223 => '출발역';

  @override
  String get passFlow224 => '출발역 ↔ 후지사와 왕복 포함';

  @override
  String get passFlow225 => '출발역과 도착역 바꾸기';

  @override
  String get passFlow226 => '출발역과 도착역을 모두 선택해 주세요.';

  @override
  String get passFlow227 => '출발역과 도착역을 선택한 이동 구간을 추가하면 손익을 계산합니다.';

  @override
  String get passFlow228 => '출발역과 도착역을 선택해 주세요';

  @override
  String passFlow229(String arg0) {
    return '출발역에 따라 $arg0일권 가격이 달라집니다.';
  }

  @override
  String get passFlow230 => '출발역에 따라 패스 가격이 달라집니다.';

  @override
  String passFlow231(String arg0) {
    return '출발역을 선택하면 $arg0일권 가격을 적용합니다.';
  }

  @override
  String get passFlow232 => '출발역을 선택하면 해당 패스 가격을 적용합니다.';

  @override
  String get passFlow233 => '케이블카';

  @override
  String get passFlow234 => '탑승 횟수';

  @override
  String get passFlow235 => '토·일·공휴일 및 12/29~1/3에만 이용할 수 있어요.';

  @override
  String get passFlow236 => '특급';

  @override
  String get passFlow237 => '특급은 보통차 지정석 기준으로 계산합니다. 버스는 1회 ¥300의 예상값입니다.';

  @override
  String passFlow238(String arg0) {
    return '패스 가격보다 ¥$arg0 적습니다.';
  }

  @override
  String get passFlow239 => '패스 적용';

  @override
  String get passFlow240 => '패스 적용 구간 일반 운임';

  @override
  String get passFlow241 => '패스 적용 구간과 운임을 입력해 주세요';

  @override
  String get passFlow242 => '패스 적용 범위를 벗어나요.';

  @override
  String get passFlow243 => '패스 적용 외';

  @override
  String get passFlow244 => '패스 출발역과 에노덴·오다큐 프리구간 이동을 입력하면 성인 IC 기준 운임을 비교합니다.';

  @override
  String get passFlow245 =>
      '패스 출발역과 후지사와 사이의 왕복 1회, 에노덴 전선과 오다큐 후지사와–가타세에노시마 구간만 계산합니다. 프리구간 밖 추가 이동, 특급·좌석요금과 할인은 포함하지 않습니다.';

  @override
  String get passFlow246 => '패스가 적용되는 이동 구간을 입력해 주세요.';

  @override
  String passFlow247(String arg0) {
    return '패스를 사면 ¥$arg0 더 들어요';
  }

  @override
  String get passFlow248 => '프로토타입';

  @override
  String get passFlow249 => '프로토타입 asset을 다시 생성한 뒤 실행해 주세요.';

  @override
  String get passFlow250 => '프리구간 내부 출발역';

  @override
  String passFlow251(String arg0) {
    return '하코네 프리패스 $arg0일권';
  }

  @override
  String get passFlow252 =>
      '한큐 전철 87개 역의 성인 일반 운임만 합산합니다. 고베고속선과 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passFlow253 =>
      '한큐 전철 내부 이동만 계산합니다. 고베고속선, 특급·좌석요금, 할인과 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passFlow254 => '한큐 전철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow255 => '한큐 전철 이동 구간을 입력해 주세요.';

  @override
  String get passFlow256 => '한큐 전철 일반 운임';

  @override
  String get passFlow257 => '해적선';

  @override
  String passFlow258(String arg0) {
    return '홋카이도 레일패스 $arg0일권';
  }

  @override
  String get passFlow259 => '확인';

  @override
  String get passFlow260 => '횟수 입력 상세';

  @override
  String get passFlow261 => '후지사와 왕복 포함';

  @override
  String get passFlow262 => '후쿠오카시 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow263 => '후쿠오카시 지하철 이동 구간을 입력해 주세요.';

  @override
  String get passFlow264 => '후쿠오카시 지하철 일반 운임';

  @override
  String get passFlow265 =>
      '후쿠오카시 지하철의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.';

  @override
  String get passFlow266 =>
      '후쿠오카시 지하철의 성인 일반 운임만 합산합니다. 1일권은 개찰 당일 첫차부터 막차까지 유효하며, 다른 회사 환승·할인은 포함하지 않습니다.';

  @override
  String get passFlow267 => '히로덴 전차 1일권';

  @override
  String get passFlow268 => '히로덴 전차 24시간권';

  @override
  String get passFlow269 => '히로덴 전차 8시간권';

  @override
  String get passFlow270 => '히로시마 전철 이동 구간을 입력해 주세요.';

  @override
  String get passFlow271 => '히로시마 전철 일반 운임';

  @override
  String get passFlow272 => '히로시마 전철 정류장을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow273 => 'JR 동일본';

  @override
  String get passFlow274 => 'JR 서일본 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow275 => 'JR 서일본 일반 운임';

  @override
  String get passFlow276 => 'JR 이동 구간 또는 노면전차·버스 이용 횟수를 입력해 주세요.';

  @override
  String get passFlow277 => 'JR 홋카이도 · 보통·쾌속';

  @override
  String get passFlow278 => 'JR 홋카이도 · 특급';

  @override
  String get passFlow279 => 'JR 홋카이도 버스';

  @override
  String get passFlow280 => 'JR 홋카이도 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.';

  @override
  String get passFlow281 =>
      'JR 홋카이도선의 성인 운임을 계산합니다. 특급은 보통차 지정석만, 버스는 1회 ¥300 예상값만 반영합니다.';

  @override
  String get passFlow282 =>
      'JR·노면전차와 선택한 시모덴 버스 횟수를 합산합니다. 관광시설 입장·렌터사이클 혜택, 특급·할인과 다른 회사 환승은 계산하지 않습니다.';

  @override
  String get passFlow283 =>
      'JR·오카야마 전기궤도는 성인 일반 운임을 합산합니다. 시모덴 버스 대표 운임은 실제 정류장별 운임과 차이가 있을 수 있으며, 관광시설·렌터사이클 혜택은 계산하지 않습니다.';

  @override
  String get passFlow284 => 'Metro ↔ 도에이 지하철';

  @override
  String get passFlow285 =>
      'Metro↔도에이 구간은 공식 지정 환승역·60분 이내 환승·70엔 할인을 전제로 계산합니다. 패스 구매 전 공식 운임과 상품 구매 조건을 다시 확인해 주세요.';

  @override
  String get passFlow286 => 'Tokyo Subway 24시간권';

  @override
  String get passFlow287 => 'Tokyo Subway 48시간권';

  @override
  String get passFlow288 => 'Tokyo Subway 72시간권';

  @override
  String get passFlow289 => 'Web 프로토타입에서 검증된 상품만 Android 앱에 반영합니다.';

  @override
  String get passSource001 => '교토시 교통국 지하철 운임';

  @override
  String get passSource002 => '교토시 오픈데이터: 京都市営地下鉄 駅間距離・運賃';

  @override
  String get passSource003 =>
      '「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 1일권은 이용일 당일 영업 종료까지 유효하며, 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.';

  @override
  String get passSource004 =>
      '「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 버스 노선·사업자·조정 운임 구간·심야 할증·제외 노선은 자동 판정하지 않습니다.';

  @override
  String get passSource005 =>
      '301개 역, 45,150개 역쌍의 성인 기본 운임 중 권종에 적용되는 구간만 합산합니다. 지정 버스는 적용을 확인한 뒤 직접 입력한 운임만 반영합니다.';

  @override
  String get passSource006 =>
      '310개 JR홋카이도 역의 성인 기본 운임을 조회합니다. 검증된 특급 역쌍은 보통차 지정석 포함 운임을 선택할 수 있고, JR홋카이도 버스는 1회 ¥300 예상값을 입력 횟수만큼 합산합니다.';

  @override
  String get passSource007 =>
      '36개 물리 역의 방향별 성인 일반 운임 1,260건을 기기 내 운임표로 조회합니다. 나카스카와바타와 하카타의 환승 노선 코드는 하나의 물리 역으로 묶어 중복 계산하지 않습니다.';

  @override
  String get passSource008 =>
      '38개 정류장의 방향별 성인 IC·터치 운임 1,406건을 기기 내 운임표로 조회합니다. 昭和町通은 赤迫 방면만 정차하므로 출발·도착 방향을 구분합니다.';

  @override
  String get passSource009 =>
      '46개 물리 역의 인접 영업거리와 공식 거리 구간 규칙으로 성인 일반 운임을 계산합니다. 삿포로와 오도리는 환승 노선이 있어도 각각 하나의 물리 역으로 계산합니다.';

  @override
  String get passSource010 =>
      '77개 정류장 중 서로 다른 두 정류장을 선택하면 성인 일반 운임 ¥240을 적용합니다. 입력한 이동 구간 하나를 별도로 운임이 청구되는 1회 이용으로 합산합니다.';

  @override
  String get passSource011 => '江ノ電1日乗車券「のりおりくん」 · 에노덴 전선';

  @override
  String get passSource012 => '교토 지하철 1일권';

  @override
  String get passSource013 => '교토 지하철 1일권 공식 안내';

  @override
  String get passSource014 => '교토 지하철·버스 1일권';

  @override
  String get passSource015 => '교토 지하철·버스 1일권 공식 안내';

  @override
  String get passSource016 => '교토시영 지하철 · 사용자 입력 버스 예상 운임';

  @override
  String get passSource017 => '교토시영 지하철 · 전 구간';

  @override
  String get passSource018 =>
      '교토시영 지하철 역간 거리와 성인 운임대로 일반 운임을 계산하고, 입력한 모든 이동의 합계를 성인 ¥800 1일권과 비교합니다.';

  @override
  String get passSource019 =>
      '교토시영 지하철은 역간 거리와 성인 운임대로 계산합니다. 버스는 일반 시내버스 ¥230·관광특급버스 ¥500의 입력 횟수만 예상 운임으로 합산합니다.';

  @override
  String get passSource020 => '교통패스별 데이터 출처';

  @override
  String get passSource021 => '긴테쓰 레일 패스';

  @override
  String get passSource022 => '나가사키 전기궤도 2026 노선·운임 안내';

  @override
  String get passSource023 => '나가사키 전기궤도 여객운송규칙';

  @override
  String get passSource024 => '나가사키 전기궤도 패스';

  @override
  String get passSource025 => '데이터 출처';

  @override
  String get passSource026 => '데이터 출처 및 운임 기준';

  @override
  String get passSource027 =>
      '도쿠나이 적용 77개 역의 영업거리와 JR 동일본 성인 IC 운임표를 바탕으로 만든 오프라인 운임표를 사용합니다.';

  @override
  String get passSource028 => '도쿠나이 패스';

  @override
  String get passSource029 => '비교할 패스를 선택하면 운임 계산 기준, 출처와 제한사항을 확인할 수 있습니다.';

  @override
  String get passSource030 => '삿포로 지하철 1일권';

  @override
  String get passSource031 => '삿포로시 지하철 1일 승차권 공식 안내';

  @override
  String get passSource032 => '삿포로시 지하철 운임 공개 데이터셋';

  @override
  String get passSource033 => '삿포로시 지하철 운임 안내';

  @override
  String get passSource034 =>
      '선택한 오다큐 발역별 패스 가격과 발역↔후지사와 왕복 성인 IC 운임, 에노덴·오다큐 프리구간의 실제 입력 운임을 합산해 비교합니다.';

  @override
  String get passSource035 =>
      '성인 1일권(¥600)과 24시간권(¥700)을 비교합니다. 운임은 IC·터치 결제 기준이며, 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함합니다. 역·노선 및 운임 규칙 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따르며, 공식 PDF 원문은 앱에 포함하지 않습니다. 현금·버스·소아요금은 계산하지 않습니다.';

  @override
  String get passSource036 =>
      '성인 기준으로 오다큐 70개 출발역의 2·3일권 가격을 조회합니다. 등산전차·케이블카·로프웨이·해적선은 정확 운임, 버스는 사업자별 평균 운임과 입력 횟수의 예상값으로 합산합니다.';

  @override
  String get passSource037 =>
      '성인 지하철 전용 1일 승차권(¥830)과 도니치카 킵(¥520)을 비교합니다. 도니치카 킵은 토·일·공휴일 및 12/29~1/3에만 이용할 수 있습니다. 운임 구간은 삿포로시 공개 데이터(CC BY 4.0)와 공식 안내를 대조했으며, 역 순서·인접 영업거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따릅니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.';

  @override
  String get passSource038 =>
      '시간표 기반 최속 경로, 관광시설 혜택, 제외 버스, 특급·좌석요금은 포함하지 않습니다. 일부 게이한 영업거리 자료는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다.';

  @override
  String get passSource039 => '시모덴 버스 운임 개정 안내';

  @override
  String get passSource040 =>
      '에노덴 15개 역의 영업거리와 성인 일반 운임 거리대 규칙을 바탕으로 두 역 사이의 운임을 계산합니다.';

  @override
  String get passSource041 => '에노덴 1일 승차권';

  @override
  String get passSource042 => '에노덴 1일 승차권 「のりおりくん」 공식 안내';

  @override
  String get passSource043 =>
      '에노덴 역·영업거리와 운임 거리대 자료를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passSource044 => '에노덴 전선 · 오다큐 후지사와–가타세에노시마';

  @override
  String get passSource045 => '에노시마·가마쿠라 프리패스';

  @override
  String get passSource046 => '에노시마·가마쿠라 프리패스 공식 안내';

  @override
  String get passSource047 =>
      '역 순서와 영업거리 기반 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 공식 역별 운임과 전 구간을 대조했습니다. OKICA 등 결제수단별 할인, 다른 회사 환승과 소아요금은 포함하지 않습니다.';

  @override
  String get passSource048 => '역 위치 지도';

  @override
  String get passSource049 =>
      '역 정보는 후쿠오카시 공개 데이터(CC BY)와 현재 공식 안내를 대조해 구성했으며, 2026-09-03 기준 성인 운임만 사용합니다. 1일권은 개찰 당일 첫차부터 막차까지 유효합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.';

  @override
  String get passSource050 =>
      '역·운임·정차역 순서 파생 데이터는 CC BY-SA 4.0 조건과 원 출처 고지를 유지합니다. 특급은 검증된 정규 열차 공통 정차역쌍에서만 선택할 수 있으며, 버스는 정확 운임이 아닌 예상값입니다. 그린차와 관광·계절·SL 열차는 포함하지 않습니다.';

  @override
  String get passSource051 =>
      '오다큐 영업거리와 운임 거리대, 에노덴 영업거리 자료를 가공해 만들었습니다. 해당 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특급·좌석요금, 할인과 프리구간 밖 추가 이동은 포함하지 않습니다.';

  @override
  String get passSource052 => '오다큐 출발역별 가격 · 하코네 지정 교통수단';

  @override
  String get passSource053 =>
      '오다큐선은 출발역↔오다와라 왕복 1회만 포함하며 로망스카 특급권은 별도입니다. 역·거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0, 구조화 식별 정보는 Wikidata CC0을 따릅니다. 버스 결과는 예상값입니다.';

  @override
  String get passSource054 => '오사카 메트로 · 사철 · 시티버스';

  @override
  String get passSource055 => '오사카 시티버스 이용 안내';

  @override
  String get passSource056 => '오사카 주유패스';

  @override
  String get passSource057 => '오사카 주유패스 공식 안내';

  @override
  String get passSource058 => '오카야마 전기궤도 운임 안내';

  @override
  String get passSource059 => '오카야마·구라시키 tabiwa 구루링 패스';

  @override
  String get passSource060 => '오카야마·구라시키 tabiwa 구루링 패스 공식 안내';

  @override
  String get passSource061 => '오키나와 도시 모노레일 · 전 노선';

  @override
  String get passSource062 => '운임 계산 기준';

  @override
  String get passSource063 => '운임과 패스 조건은 개정될 수 있으므로 구매 전 공식 안내를 확인해 주세요.';

  @override
  String get passSource064 =>
      '유이레일 19개 역의 방향별 성인 일반 운임 342건을 기기 내 운임표로 조회합니다. 24시간권 또는 48시간권 가격과 입력한 모든 이동의 합계를 비교합니다.';

  @override
  String get passSource065 => '유이레일 운임 공식 안내';

  @override
  String get passSource066 => '유이레일 패스';

  @override
  String get passSource067 => '유이레일 프리 승차권 공식 안내';

  @override
  String get passSource068 =>
      '이용내역 상세의 역 좌표는 Wikidata P625(CC0)에서 생성했습니다. 역 코드·역명·사업자·노선을 대조하며 미확인 위치는 표시하지 않습니다. 실제 이동 경로가 아닌 역 위치 참고용입니다. 지도 배경은 Google Maps가 제공하며 지도 안의 저작권 표기를 따릅니다.\nhttps://www.wikidata.org/wiki/Wikidata:Licensing';

  @override
  String get passSource069 => '일본어 위키백과: 긴테쓰·이가철도 노선 정보';

  @override
  String get passSource070 => '일본어 위키백과: 에노시마 전철선·에노시마 전철';

  @override
  String get passSource071 => '일본어 위키백과: 오다큐·에노덴 노선 정보';

  @override
  String get passSource072 => '일본어 위키백과: 오키나와 도시 모노레일선';

  @override
  String get passSource073 => '일본어 위키백과: 長崎電気軌道';

  @override
  String get passSource074 => '일본어 위키백과: 한큐 각 노선 역·영업거리';

  @override
  String get passSource075 => '長崎電気軌道 一日乗車券 · 24時間乗車券 · 노면전차 전 노선';

  @override
  String get passSource076 => '電車一日乗車券 · 디지털 8시간권 · 24시간권';

  @override
  String get passSource077 =>
      '종이 전차 1일 승차권(¥700), 디지털 8시간권(¥600), 24시간권(¥700)을 비교합니다. 정류장 식별 정보는 Wikidata CC0, 정규화한 역 코드·운임·상품 사실값은 Wikimedia 기반 CC BY-SA 4.0 조건을 유지합니다. MOBIRY DAYS의 거리별 할인, 자동 환승·재승차 판정, 버스·선박·소아요금은 포함하지 않습니다.';

  @override
  String get passSource078 => '地下鉄専用1日乗車券 · ドニチカキップ · 삿포로시 지하철 전 구간';

  @override
  String get passSource079 => '참고용 계산 결과이므로 실제 이용 전 적용 구간과 최신 운임을 확인해 주세요.';

  @override
  String get passSource080 =>
      '철도 사업자별 공개 운임 자료, 역간 거리와 환승 연결을 바탕으로 일반 운임을 계산합니다.';

  @override
  String get passSource081 => '阪急1dayパス · 한큐 전철 전 노선(고베고속선 제외)';

  @override
  String get passSource082 => '阪急1dayパス 공식 안내';

  @override
  String get passSource083 => '하코네 나비: 로프웨이·해적선 운임';

  @override
  String get passSource084 => '하코네 프리패스';

  @override
  String get passSource085 => '하코네 프리패스 공식 가격표';

  @override
  String get passSource086 => '하코네 프리패스 공식 안내';

  @override
  String get passSource087 =>
      '한큐 각 노선의 역간 영업거리 데이터를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 고베고속선, 특급·좌석요금, 할인·IC 특례와 다른 회사 환승은 포함하지 않습니다.';

  @override
  String get passSource088 => '한큐 여객영업규칙';

  @override
  String get passSource089 =>
      '한큐 전철 87개 역의 인접 역간 영업거리와 성인 보통 운임 거리대 규칙으로 계산한 일반 운임을 사용합니다.';

  @override
  String get passSource090 => '한큐패스 1일권';

  @override
  String get passSource091 => '홋카이도 레일패스';

  @override
  String get passSource092 => '홋카이도 레일패스 공식 안내';

  @override
  String get passSource093 => '확인할 점';

  @override
  String get passSource094 => '후쿠오카 지하철 1일권';

  @override
  String get passSource095 => '후쿠오카시 역 데이터 공개 데이터셋';

  @override
  String get passSource096 => '후쿠오카시 지하철';

  @override
  String get passSource097 => '후쿠오카시 지하철 1일 승차권 공식 안내';

  @override
  String get passSource098 => '후쿠오카시 지하철 운임 안내';

  @override
  String get passSource099 => '히로덴 전차 패스';

  @override
  String get passSource100 => '히로시마 전철 운임 개정 자료';

  @override
  String get passSource101 => '히로시마 전철 전차 승차권 공식 안내';

  @override
  String get passSource102 => 'JR 동일본 도쿄 23구 내 지정 구간';

  @override
  String get passSource103 => 'JR 동일본 도쿠나이 패스 공식 안내';

  @override
  String get passSource104 => 'JR 동일본 운임·요금 안내';

  @override
  String get passSource105 => 'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스';

  @override
  String get passSource106 =>
      'JR 서일본 대상 35개 역의 성인 일반 운임 1,190건을 조회합니다. 오카야마 전기궤도는 1회 ¥160을 정확히 합산하고, 시모덴 버스는 선택한 서비스별 입력 횟수와 대표 운임을 합산합니다.';

  @override
  String get passSource107 =>
      'JR 역간 거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 시모덴 버스의 고지마–구라시키·도코하이호는 대표 운임이므로 실제 정류장별 운임과 다를 수 있습니다. 관광시설·렌터사이클 혜택, 특급·할인과 다른 회사 환승은 계산하지 않습니다.';

  @override
  String get passSource108 => 'JR 홋카이도 열차 안내';

  @override
  String get passSource109 => 'JR 홋카이도선 · 5·7·10일권';

  @override
  String get passSource110 => 'KINTETSU RAIL PASS · 1일권·2일권·5일권·5일권 Plus';

  @override
  String get passSource111 => 'KINTETSU RAIL PASS 권종별 공식 안내';

  @override
  String get passSource112 => 'MOBIRY DAYS 운임 안내';

  @override
  String get passSource113 => 'ODPT 공개 교통 데이터 센터';

  @override
  String get passSource114 =>
      'ODPT 역·성인 IC 운임 데이터로 도쿄메트로와 도에이 지하철의 적용 구간 운임을 계산합니다.';

  @override
  String get passSource115 => 'Osaka Metro 운임 안내';

  @override
  String get passSource116 => 'tabiwa 상품 상세';

  @override
  String get passSource117 => 'Tokyo Metro · 도에이 지하철';

  @override
  String get passSource118 => 'Tokyo Subway Ticket 공식 안내';

  @override
  String get passSource119 =>
      'Wikidata(CC0)와 Wikipedia/Wikimedia의 영업거리 사실값(CC BY-SA 4.0)을 가공해 만든 파생 데이터입니다. 특급은 별도 특급권이 필요하며, 로프웨이·할인·특전은 계산하지 않습니다.';

  @override
  String get passMeta001 => '에노시마 전철';

  @override
  String get passMeta002 => '에노덴';

  @override
  String get passMeta003 => '오다큐 전철';

  @override
  String get passMeta004 => '오다큐 다마선';

  @override
  String get passMeta005 => '오다큐 에노시마선';

  @override
  String get passMeta006 => '오다큐 오다와라선';

  @override
  String get passMeta007 => '한큐 전철';

  @override
  String get passMeta008 => 'JR 홋카이도';

  @override
  String get passMeta009 => '교토시영 지하철';

  @override
  String get passMeta010 => '가라스마선';

  @override
  String get passMeta011 => '도자이선';

  @override
  String get passMeta012 => '오사카 메트로';

  @override
  String get passMeta013 => '오사카 시티버스';

  @override
  String get passMeta014 => '한신 전철';

  @override
  String get passMeta015 => '게이한 전철';

  @override
  String get passMeta016 => '긴테쓰';

  @override
  String get passMeta017 => '긴테쓰 전철';

  @override
  String get passMeta018 => '이가철도';

  @override
  String get passMeta019 => '난카이 전철';

  @override
  String get passMeta020 => '삿포로시 지하철';

  @override
  String get passMeta021 => '히로시마 전철';

  @override
  String get passMeta022 => '나가사키 전기궤도';

  @override
  String get passMeta023 => 'JR 서일본';

  @override
  String get passMeta024 => '유이레일';

  @override
  String get passMeta025 => '등산전차';

  @override
  String get passMeta026 => '케이블카';

  @override
  String get passMeta027 => '로프웨이';

  @override
  String get passMeta028 => '해적선';

  @override
  String get passMeta029 => '도에이 지하철';

  @override
  String get passMeta030 => '御堂筋線';

  @override
  String get passMeta031 => '今里筋線';

  @override
  String get passMeta032 => '千日前線';

  @override
  String get passMeta033 => '四つ橋線';

  @override
  String get passMeta034 => '中央線';

  @override
  String get passMeta035 => 'ニュートラム';

  @override
  String get passMeta036 => '長堀鶴見緑地線';

  @override
  String get passMeta037 => '谷町線';

  @override
  String get passMeta038 => '堺筋線';

  @override
  String get passMeta039 => '中之島線';

  @override
  String get passMeta040 => '京阪本線';

  @override
  String get passMeta041 => '南海本線';

  @override
  String get passMeta042 => '高野線';

  @override
  String get passMeta043 => '南大阪線';

  @override
  String get passMeta044 => '難波線';

  @override
  String get passMeta045 => '宝塚本線';

  @override
  String get passMeta046 => '京都本線';

  @override
  String get passMeta047 => '千里線';

  @override
  String get passMeta048 => '神戸本線';

  @override
  String get passMeta049 => '阪神なんば線';

  @override
  String get passMeta050 => '本線';

  @override
  String get passMeta051 => '도쿠나이 패스 적용 JR';

  @override
  String get passMeta052 => 'JR 동일본';

  @override
  String get passMeta053 => 'Metro ↔ 도에이 지하철';

  @override
  String get passMeta054 => '오카야마 전기궤도';

  @override
  String get passMeta055 => '시모덴 버스 고지마–구라시키';

  @override
  String get passMeta056 => '도코하이호';

  @override
  String get passMeta057 => '진즈 버스';

  @override
  String get passMeta058 => '와슈잔 석양 감상 버스';

  @override
  String get passMeta059 => '전선 균일';

  @override
  String get passMeta060 => '전 구간 대표 운임';

  @override
  String get passMeta061 => '대표 운임';

  @override
  String get passMeta062 => '금·토·일·공휴일 운행';

  @override
  String get passMeta063 => '금·토·공휴일 전날 운행';

  @override
  String get passMeta064 => '가라스마선·도자이선';
}
