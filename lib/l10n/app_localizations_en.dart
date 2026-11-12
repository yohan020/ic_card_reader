// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Japan IC Card Reader';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get tools => 'Tools';

  @override
  String get settings => 'Settings';

  @override
  String get homeTitle => 'IC Card Reader';

  @override
  String get scanPrompt => 'Scan your IC card';

  @override
  String get homeNfcHint =>
      'Hold your card against the back of your phone to read recent transactions.';

  @override
  String get scanCard => 'Scan IC card';

  @override
  String get compareBalances => 'Compare card balances';

  @override
  String get whereToTap => 'Where do I hold my card?';

  @override
  String get noReadableHistory => 'No readable transactions';

  @override
  String get noReadableHistoryHint =>
      'No transactions could be displayed. The information available depends on the card and its records.';

  @override
  String get nfcStartRetry =>
      'Couldn’t start NFC. Move the card away, then scan again.';

  @override
  String get notice => 'Notice';

  @override
  String get recentHistory => 'Recent transactions';

  @override
  String get viewAll => 'View all';

  @override
  String get noScannedCard => 'No card scanned yet.';

  @override
  String get noHistoryFound => 'No transactions to display for this card.';

  @override
  String get balanceAfterLabel => 'Balance after';

  @override
  String get supportedCards => 'Supported cards';

  @override
  String get supportedCardsHint =>
      'Suica, PASMO, ICOCA and other interoperable Japanese transit IC cards';

  @override
  String get pitapaLimit =>
      'PiTaPa postpaid and some transactions may not be supported.';

  @override
  String get localCardData => 'Card data is processed on this device';

  @override
  String stationCode(String code) {
    return 'Station code $code';
  }

  @override
  String get entryStationUnknown =>
      'An entry was detected, but the station name is unknown.';

  @override
  String get tripInProgress => 'Trip in progress';

  @override
  String enteredAt(String station) {
    return 'Entered at $station.';
  }

  @override
  String get newVersion => 'Update available';

  @override
  String get newVersionHint => 'Get the latest features and improvements.';

  @override
  String get opening => 'Opening';

  @override
  String get update => 'Update';

  @override
  String get cancelScan => 'Cancel scan';

  @override
  String get scanTitle => 'Scan card';

  @override
  String get holdTransitCard => 'Hold your transit card near the phone';

  @override
  String get holdCardStill => 'Hold your card close and keep it still';

  @override
  String get scanWaitHint =>
      'Hold one card against the NFC area on the back of your phone until the scan finishes.';

  @override
  String get scanTimeElapsed => 'Scan time elapsed';

  @override
  String scanTimeLeft(int seconds) {
    return 'Time left: ${seconds}s';
  }

  @override
  String get retryWithoutClosing =>
      'If the scan fails, you can try again without closing the app.';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get cardRead => 'Card scanned';

  @override
  String brandCardRead(String brand) {
    return '$brand card scanned';
  }

  @override
  String get blocksRead => 'Blocks read';

  @override
  String get decodedRecords => 'Records decoded';

  @override
  String get needsReview => 'Needs review';

  @override
  String get someDataUnconfirmed => 'Some details are unavailable';

  @override
  String get someDataUnconfirmedHint =>
      'The card records were read successfully, but some station or transaction details aren’t recognized yet.';

  @override
  String get historyOnDevice =>
      'Scanned transactions are displayed on this device';

  @override
  String get idmNotStored => 'The raw card IDm is not stored or displayed.';

  @override
  String get viewHistory => 'View transactions';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get unavailableAmount => 'Unavailable';

  @override
  String get unknownBus => 'Unknown bus operator';

  @override
  String get refund => 'Refund';

  @override
  String get adjustment => 'Fare adjustment';

  @override
  String get unknownTransaction => 'Unknown transaction type';

  @override
  String get stationUnavailable => 'Station unknown';

  @override
  String get nfcSettingsError =>
      'Couldn’t open NFC settings. Check NFC in your phone’s settings.';

  @override
  String get sessionCleared => 'Session history cleared.';

  @override
  String get updateStartError =>
      'Couldn’t start the update. Try again in a moment.';

  @override
  String get checkingNfc => 'Checking NFC';

  @override
  String get nfcOn => 'NFC is on';

  @override
  String get turnNfcOn => 'Turn on NFC';

  @override
  String get nfcUnsupported => 'This device doesn’t support NFC scanning';

  @override
  String get nfcUnknown => 'Couldn’t check NFC status';

  @override
  String get openNfcSettings => 'Open NFC settings';

  @override
  String get checkAgain => 'Check again';

  @override
  String get couldNotStartNfc => 'Couldn’t start NFC';

  @override
  String get nfcUnsupportedHint =>
      'Use an Android device that supports NFC-F (FeliCa).';

  @override
  String get nfcEnabledHint =>
      'Make sure NFC is on. On Samsung devices with an NFC mode setting, choose standard mode and try again.';

  @override
  String get checkCardSupport => 'Check whether your card is supported';

  @override
  String get checkCardSupportHint =>
      'Scan one supported card at a time, such as Suica, PASMO or ICOCA. Your phone must support NFC-F (FeliCa).';

  @override
  String get scanTimedOut => 'Scan timed out';

  @override
  String get scanTimedOutHint =>
      'Take the card out of your wallet and try a few spots on the back of your phone. Card type and NFC-F support can affect scanning.';

  @override
  String get cardConnectionLost => 'The card connection was interrupted';

  @override
  String get cardConnectionLostHint =>
      'Hold one card close to the NFC area and keep it still until the scan finishes.';

  @override
  String get couldNotReadCard => 'Couldn’t read the card';

  @override
  String get couldNotReadCardHint =>
      'Try scanning again. This error doesn’t mean your card or its balance is damaged.';

  @override
  String get scanFailed => 'Couldn’t complete the scan';

  @override
  String get scanFailedHint =>
      'Move the card away, then try again. If it still fails, check your NFC settings and supported cards.';

  @override
  String get scanHelp => 'Scan help';

  @override
  String get dismissNotice => 'Dismiss notice';

  @override
  String get howToScan => 'How to scan a card';

  @override
  String get closeHelp => 'Close help';

  @override
  String get holdOneCard =>
      'Hold one transit card against the back of your phone.';

  @override
  String get prepareOneCard => 'Get one card ready';

  @override
  String get prepareOneCardHint =>
      'Take one physical transit card out of your wallet. On Samsung devices, check that NFC is in standard mode if available.';

  @override
  String get tapScanHold => 'Tap Scan and hold the card in place';

  @override
  String get tapScanHoldHint =>
      'Once the scan screen opens, hold the card over the NFC area on the back of your phone. Its location varies by device.';

  @override
  String get waitForScan => 'Keep the card still until the scan finishes';

  @override
  String get waitForScanHint =>
      'If nothing happens, shift the card slightly or remove a thick case or metal accessory, then try again.';

  @override
  String get deviceRequirements => 'Device requirements';

  @override
  String get felicaRequired =>
      'Your device must support NFC-F (FeliCa). Having NFC turned on doesn’t guarantee support.';

  @override
  String get readOnlyPhysicalCard =>
      'These steps are for physical cards. The app can’t top up a card or change its records.';

  @override
  String get close => 'Close';

  @override
  String get placementSemantics =>
      'Example showing one physical transit card held against the back of a phone';

  @override
  String get nfcPlacementVaries => 'The NFC area varies by device';

  @override
  String get noMatchingHistory => 'No transactions match this filter.';

  @override
  String get unknownTotalExplanation =>
      'Unknown transaction types are not included in totals.';

  @override
  String get topUpTotalExplanation =>
      'Only confirmed top-ups count. They are not included in spending.';

  @override
  String get spendingTotalExplanation =>
      'Top-ups, special transactions and amounts that can’t be verified are excluded.';

  @override
  String unknownRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unknown records',
      one: '$count unknown record',
    );
    return '$_temp0';
  }

  @override
  String get noTopUpTotal => 'No top-ups to add up';

  @override
  String get noSpendingTotal => 'No spending to add up';

  @override
  String totalCount(int included, int excluded) {
    return 'Included: $included · Excluded: $excluded';
  }

  @override
  String recentTotalHint(String explanation) {
    return 'Totals only include recent records read from the card.\n$explanation';
  }

  @override
  String get currentBalance => 'Current card balance';

  @override
  String currentBrandBalance(String brand) {
    return 'Current $brand balance';
  }

  @override
  String get balanceAfterScan => 'Shown after scanning';

  @override
  String get initialBalanceBasis => 'From the initial balance record';

  @override
  String get latestBalanceBasis => 'From the latest record';

  @override
  String get noDisplayableHistory => 'No transactions to display for this card';

  @override
  String get noHistoryYet => 'No transactions yet';

  @override
  String get initialBalanceOnly => 'Only the initial balance was found.';

  @override
  String get scanFromHome => 'Scan an IC card from Home.';

  @override
  String balanceValue(String amount) {
    return 'Balance $amount';
  }

  @override
  String get historyDetail => 'Transaction details';

  @override
  String get boarding => 'Boarding';

  @override
  String get alighting => 'Alighting';

  @override
  String balanceAfterValue(String amount) {
    return 'Balance after: $amount';
  }

  @override
  String get cantCalculateAmount => 'Amount unavailable';

  @override
  String get icaZeroAmount =>
      'This ICa record stores ¥0, so no transaction amount is shown.';

  @override
  String get multipleStationCandidates => 'More than one station matches';

  @override
  String get stationInfoNeedsReview => 'Some stations couldn’t be identified';

  @override
  String get multipleStationHint =>
      'We couldn’t identify a single station. Use the report button below to tell us which station it was.';

  @override
  String get stationInfoNeedsReviewHint =>
      'Some station names couldn’t be identified. Use the report button below to tell us the correct names.';

  @override
  String get details => 'Details';

  @override
  String get transactionType => 'Transaction type';

  @override
  String get boardingStation => 'Boarding station';

  @override
  String get alightingStation => 'Alighting station';

  @override
  String get busOperator => 'Bus operator';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get combinedCash => 'Partly paid in cash';

  @override
  String get transactionTime => 'Transaction time';

  @override
  String get topUpMethod => 'Top-up method';

  @override
  String get topUpLocation => 'Top-up location';

  @override
  String get processingLocation => 'Processing location';

  @override
  String get processingDetail => 'Processing details';

  @override
  String get unknown => 'Unknown';

  @override
  String get balance => 'Balance';

  @override
  String get reportTransaction => 'Report a problem with this transaction';

  @override
  String get stationNotRegistered => 'Station not in database';

  @override
  String get spendingTotal => 'Total spent';

  @override
  String get topUpTotal => 'Total topped up';

  @override
  String get unknownRecords => 'Unknown records';

  @override
  String get all => 'All';

  @override
  String get transport => 'Transit';

  @override
  String get purchases => 'Purchases';

  @override
  String get topUp => 'Top-up';

  @override
  String get unconfirmed => 'Unknown';

  @override
  String get checkAmount => 'Amount needs review';

  @override
  String get oldestRecord =>
      'This is the oldest record on the card. There is no earlier balance to calculate the amount.';

  @override
  String get noDecrease =>
      'The balance didn’t decrease. This could be a top-up or refund, so it isn’t shown as spending.';

  @override
  String get notEnoughBalances =>
      'There aren’t enough balance records to calculate the amount.';

  @override
  String get unknownTransactionSummary => 'Unknown transaction type';

  @override
  String get busOrTram => 'Bus or tram ride';

  @override
  String get railRide => 'Train ride';

  @override
  String get busRide => 'Bus ride';

  @override
  String get purchase => 'Purchase';

  @override
  String get gateWindow => 'Fare gate assistance';

  @override
  String get unknownType => 'Unknown type';

  @override
  String get ticketMachine => 'Ticket machine';

  @override
  String get stationGateTerminal => 'Fare gate terminal';

  @override
  String get stationTerminal => 'Station terminal';

  @override
  String get mobile => 'Mobile';

  @override
  String get mobileBenefit => 'Mobile reward';

  @override
  String get storeTerminal => 'Store terminal';

  @override
  String get ticketMachineTopUp => 'Ticket machine top-up';

  @override
  String ticketMachineTopUpAt(String station) {
    return 'Ticket machine top-up · $station';
  }

  @override
  String get gateTerminalTopUp => 'Fare gate terminal top-up';

  @override
  String topUpAt(String station) {
    return 'Top-up · $station';
  }

  @override
  String get stationTerminalTopUp => 'Station terminal top-up';

  @override
  String get mobileBenefitTopUp => 'Mobile reward top-up';

  @override
  String get mobileTopUp => 'Mobile top-up';

  @override
  String get storeTopUp => 'In-store top-up';

  @override
  String get cardTopUp => 'Card top-up';

  @override
  String get unknownBusOperator => 'Unknown bus operator';

  @override
  String get purchaseWithCash => 'Purchase · partly paid in cash';

  @override
  String gateWindowAt(String station) {
    return 'Fare gate assistance · $station';
  }

  @override
  String get displaySettings => 'Display';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get stationNames => 'Station names';

  @override
  String get stationNamesHint => 'Korean names are shown where available.';

  @override
  String get stationFallbackHint =>
      'Japanese names are shown when a verified name isn’t available.';

  @override
  String get japanese => 'Japanese';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get both => 'Korean + Japanese';

  @override
  String get appLanguage => 'App language';

  @override
  String get deviceLanguage => 'Device language';

  @override
  String get appInfo => 'About the app';

  @override
  String get appVersion => 'App version';

  @override
  String get dataSources => 'Data sources and fare rules';

  @override
  String get dataSourcesHint =>
      'Fare data, licenses and coverage for transit passes';

  @override
  String get appUpdate => 'App update';

  @override
  String get openSource => 'Open-source licenses';

  @override
  String get privacyData => 'Privacy and data';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyHint => 'How NFC and report data are handled';

  @override
  String get clearCurrentHistory => 'Clear current history';

  @override
  String get nothingToClear => 'No transactions to clear.';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
    );
    return '$_temp0';
  }

  @override
  String get support => 'Support';

  @override
  String get cardSupport => 'Card scanning support';

  @override
  String get cardSupportHint => 'Report scanning or card identification issues';

  @override
  String get developerTools => 'Developer tools';

  @override
  String get cardDiagnostics => 'Card brand diagnostics';

  @override
  String get cardDiagnosticsHint =>
      'Select or enter a brand and check its metadata';

  @override
  String get japanIcCards => 'Interoperable Japanese transit IC cards';

  @override
  String get checkingUpdates => 'Checking for updates…';

  @override
  String get automaticUpdateCheck =>
      'The app checks for updates when it opens.';

  @override
  String get appUpToDate => 'You’re using the latest version.';

  @override
  String get updateShownOnHome => 'The new version is shown on Home.';

  @override
  String get updateStatusUnavailable => 'Couldn’t check for updates right now.';

  @override
  String get clearHistoryQuestion => 'Clear current history?';

  @override
  String get clearHistoryHint =>
      'This removes the transactions and raw records from the current session.';

  @override
  String get physicalCardUnchanged => 'The data on your card won’t change.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get cancel => 'Cancel';

  @override
  String get comparePasses => 'Compare transit passes';

  @override
  String get comparePassesHint => 'Compare pass prices with estimated fares';

  @override
  String get contactlessRoutes => 'Contactless routes';

  @override
  String get contactlessRoutesHint =>
      'Check tap-to-ride support by operator and line';

  @override
  String get findLockers => 'Find coin lockers';

  @override
  String get findLockersHint => 'Find lockers at major stations and airports';

  @override
  String get comparisonUnavailable =>
      'Card comparison isn’t available with this scanning method.';

  @override
  String comparisonUpdated(String card) {
    return 'Updated the balance for $card.';
  }

  @override
  String comparisonAdded(String card) {
    return 'Added $card.';
  }

  @override
  String get checkNfcSettings => 'Check NFC in your phone’s settings.';

  @override
  String get scanStillEnding =>
      'The scan is still closing. Try again in a moment.';

  @override
  String get renameCard => 'Rename card';

  @override
  String get cardName => 'Card name';

  @override
  String get enterCardName => 'Enter a name.';

  @override
  String get saveName => 'Save';

  @override
  String get comparisonHelpHint =>
      'Scan up to 10 cards, one at a time. Tap a card to see its transactions.\n\nBalances are from the last scan and don’t refresh automatically. Scan a card again to update its entry.\n\nThe comparison is cleared when you exit it or the app closes. This doesn’t change the transactions shown on Home.';

  @override
  String get exitComparison => 'Exit comparison';

  @override
  String get comparisonHelp => 'Comparison help';

  @override
  String comparingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards in comparison',
      one: '$count card in comparison',
    );
    return '$_temp0';
  }

  @override
  String get deleteAll => 'Clear all';

  @override
  String get tapCardHistory => 'Tap a card to view its transactions.';

  @override
  String get addCardsToCompare => 'Add cards to compare';

  @override
  String get scanOneAtATime => 'Scan one card at a time.';

  @override
  String cardMenu(String card) {
    return 'Menu for $card';
  }

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Remove';

  @override
  String get addCard => 'Add card';

  @override
  String get comparisonLimit =>
      'You can compare up to 10 cards. Use a card’s menu to scan it again.';

  @override
  String checkedAt(String date) {
    return 'Scanned $date';
  }

  @override
  String get exitComparisonQuestion => 'Exit balance comparison?';

  @override
  String get exitComparisonHint =>
      'The cards and transactions in this comparison aren’t saved and will be cleared when you exit.';

  @override
  String get exit => 'Exit';

  @override
  String get clearComparisonQuestion => 'Clear the comparison list?';

  @override
  String get clearComparisonHint =>
      'This removes the cards and transactions from the comparison.';

  @override
  String get balancesUnchanged => 'The balances on your cards won’t change.';

  @override
  String get mapOffline => 'Check your connection, then refresh the map.';

  @override
  String get mapStationsUnavailable =>
      'The map isn’t available because the station locations couldn’t be found.';

  @override
  String get mapConfigUnavailable =>
      'The map isn’t configured for this device. Station details are shown above.';

  @override
  String get mapPreparationFailed =>
      'Couldn’t load the map. Try again in a moment.';

  @override
  String get stationLocations => 'Station locations';

  @override
  String get mapLegend => 'Blue: boarding · Red: alighting';

  @override
  String get mapCandidates =>
      'Possible locations for station groups and segments';

  @override
  String get mapLoading => 'Loading map…';

  @override
  String get refreshMap => 'Refresh map';

  @override
  String get mapAttribution => 'Station coordinates: Wikidata · CC0';

  @override
  String mapBoth(String station) {
    return 'Boarding and alighting · $station';
  }

  @override
  String mapBoarding(String station) {
    return 'Boarding · $station';
  }

  @override
  String mapAlighting(String station) {
    return 'Alighting · $station';
  }

  @override
  String mapCandidateRole(String role) {
    return 'Possible $role point';
  }

  @override
  String get comparisonUnidentified =>
      'Couldn’t identify the card. Scan it again.';

  @override
  String get comparisonBalanceUnavailable =>
      'Couldn’t read the balance. Scan the card again.';

  @override
  String get comparisonDifferentCard =>
      'This is a different card. Scan the original card again.';

  @override
  String get comparisonAtLimit => 'You can compare up to 10 cards.';

  @override
  String defaultCardName(String number) {
    return 'Card $number';
  }

  @override
  String get reportTitle => 'Report an issue';

  @override
  String get reportQuestion => 'What information is incorrect?';

  @override
  String get reportChooseClosest => 'Choose the option that fits best.';

  @override
  String get reportStationIssue => 'Missing or incorrect station information';

  @override
  String get reportKoreanNameIssue => 'Request an English station name';

  @override
  String get reportBusIssue => 'Missing or incorrect bus operator';

  @override
  String get reportTypeIssue => 'Incorrect transaction type';

  @override
  String get reportAmountIssue => 'Incorrect amount or balance';

  @override
  String get reportOther => 'Other';

  @override
  String get reportNext => 'Next';

  @override
  String get reportWhichKoreanStation => 'Which station needs an English name?';

  @override
  String get reportWhichStation => 'Which station is affected?';

  @override
  String get reportChooseStations => 'Choose the boarding or alighting station';

  @override
  String get reportCorrectBoarding => 'Correct boarding station';

  @override
  String get reportCorrectAlighting => 'Correct alighting station';

  @override
  String get reportCorrectType => 'Correct transaction type';

  @override
  String get reportChooseType => 'Choose a type';

  @override
  String get reportCustomType => 'Custom transaction type';

  @override
  String get reportTicketExample => 'e.g. Ticket purchase';

  @override
  String get reportTransactionType => 'Transaction type';

  @override
  String get reportKoreanBoarding => 'Boarding station in English';

  @override
  String get reportKoreanAlighting => 'Alighting station in English';

  @override
  String get reportOptionalDetails => 'Additional details (optional)';

  @override
  String get reportDetailsHint =>
      'Add any helpful details. Do not include personal information.';

  @override
  String get reportBack => 'Back';

  @override
  String get reportReview => 'Review';

  @override
  String get reportReviewTitle => 'Review before sending';

  @override
  String get reportIssueType => 'Issue type';

  @override
  String get reportAffectedStation => 'Affected station';

  @override
  String get reportNotSelected => 'Not selected';

  @override
  String get reportSuggestedType => 'Suggested transaction type';

  @override
  String get reportActualBus => 'Actual bus operator';

  @override
  String get reportBusArea => 'Operating city or region';

  @override
  String get reportSuggestedKoreanBoarding =>
      'Suggested boarding name in English';

  @override
  String get reportNoInput => 'Not provided';

  @override
  String get reportParsedBoardingLine => 'Detected boarding line';

  @override
  String get reportSuggestedKoreanAlighting =>
      'Suggested alighting name in English';

  @override
  String get reportParsedAlightingLine => 'Detected alighting line';

  @override
  String get reportSelectedRecord => 'Selected record';

  @override
  String get reportTypeAmount => 'Type / amount';

  @override
  String get reportUsageDate => 'Date of use';

  @override
  String get reportAnonymousRecord => 'Anonymous raw record';

  @override
  String get reportPrivacy => 'Privacy';

  @override
  String get reportRecordPrivacy =>
      'Your card IDm is not included. Only the selected record, the station, city, line, bus operator, operating area or transaction type you enter, and your report details are prepared for sending.';

  @override
  String get reportSendConsent => 'I agree to send the information above.';

  @override
  String get reportSendFailedTitle => 'Couldn’t send your report';

  @override
  String get reportSendAnonymous => 'Send anonymously';

  @override
  String get reportUnexpectedError =>
      'An unexpected error occurred. Please try again later.';

  @override
  String get reportStationRequired => 'Choose the affected station.';

  @override
  String get reportTypeRequired => 'Choose the correct transaction type.';

  @override
  String get reportCorrectStationInfo => 'Correct station information';

  @override
  String get reportBusInfo => 'Bus operator information';

  @override
  String get reportSuggestKorean => 'Suggest an English station name';

  @override
  String get reportDetails => 'Additional details';

  @override
  String get reportStationGuide =>
      'Enter the station name and city or region. Add the line name only if you know it.';

  @override
  String get reportTypeGuide =>
      'Choose a type from the list, or enter one if it is not listed.';

  @override
  String get reportBusGuide =>
      'Enter the actual bus operator and its operating city or region.';

  @override
  String get reportKoreanGuide =>
      'Choose the boarding station, alighting station, or both. Enter the English spelling only if you know it.';

  @override
  String get reportGeneralGuide =>
      'Any details you know can help us improve how records are interpreted.';

  @override
  String get reportNoCustomInput => 'No custom type provided';

  @override
  String get reportStationName => 'Station name';

  @override
  String get reportCity => 'City or region';

  @override
  String get reportOptionalLine => 'Line name (optional)';

  @override
  String get reportKoreanName => 'English name';

  @override
  String get reportKoreanExample => 'e.g. Shibuya (leave blank if unsure)';

  @override
  String get reportBusOperator => 'Bus operator';

  @override
  String get reportSelectKoreanStation =>
      'Choose the station to add an English name for.';

  @override
  String get reportSelectIncorrectStation =>
      'Choose the station with missing or incorrect information.';

  @override
  String get reportSelectCorrectType => 'Choose the correct transaction type';

  @override
  String get reportCustomTypeGuide =>
      'If the type is not listed, you can enter it yourself.';

  @override
  String get reportBoarding => 'Boarding station';

  @override
  String get reportAlighting => 'Alighting station';

  @override
  String get reportBothStations => 'Both boarding and alighting stations';

  @override
  String get reportRail => 'Rail travel';

  @override
  String get reportBus => 'Bus travel';

  @override
  String get reportPurchase => 'Purchase';

  @override
  String get reportCharge => 'Top-up';

  @override
  String get reportGateWindow => 'Gate or ticket counter transaction';

  @override
  String get reportRefund => 'Refund';

  @override
  String get reportAdjustment => 'Fare adjustment';

  @override
  String get reportCustomOption => 'Not listed / enter manually';

  @override
  String get reportSelectedHistory => 'Selected transaction';

  @override
  String get reportUnknownBus => 'Unknown bus operator';

  @override
  String get reportUnknownType => 'Unknown transaction type';

  @override
  String get reportAmountUnavailable => 'Unavailable';

  @override
  String get reportNeedsReview => 'Needs review';

  @override
  String get reportDiagnosticsUnsupported =>
      'Card diagnostics are not supported by this reader.';

  @override
  String get reportScanPrompt =>
      'Hold one card against the NFC area on the back of your phone.';

  @override
  String get reportDiagnosticsReady =>
      'Diagnostic information is ready. Nothing has been sent to the server.';

  @override
  String get reportDiagnosticsCancelled => 'Diagnostics cancelled.';

  @override
  String get reportEnableNfc => 'Turn on NFC and try again.';

  @override
  String get reportDiagnosticsTimeout =>
      'The scan timed out. Run diagnostics again.';

  @override
  String get reportMetadataFailed =>
      'Couldn’t read the metadata. You can still send a report with only a minimal error code and your description.';

  @override
  String get reportDiagnosticsFailed =>
      'Couldn’t complete diagnostics. Please try again.';

  @override
  String get reportViewPayload => 'View all data to be sent';

  @override
  String get reportPayloadNotice =>
      'Only the data below will be sent. Opening this screen does not send anything.';

  @override
  String get reportClose => 'Close';

  @override
  String get reportSupportReceived => 'Your inquiry has been received';

  @override
  String get reportSupportPrivacy =>
      'Your card IDm, balance and transaction history were not sent.';

  @override
  String get reportConnectionRetry =>
      'Couldn’t send. Check your connection and try again.';

  @override
  String get reportCardSupport => 'Card recognition support';

  @override
  String get reportUnreadableQuestion => 'Having trouble reading a card?';

  @override
  String get reportSupportIntro =>
      'Report card reading or brand identification problems.\nThis does not change records from normal scans.';

  @override
  String get reportSupportTopic => 'Inquiry type';

  @override
  String get reportOptionalBrand => 'Card brand (optional)';

  @override
  String get reportBrandExample => 'e.g. Kitaca · Leave blank if unsure';

  @override
  String get reportOptionalProblem => 'Problem description (optional)';

  @override
  String get reportProblemHint => 'What went wrong?';

  @override
  String get reportNoPersonalInfo =>
      'Do not enter your name, card number or contact details.';

  @override
  String get reportMinimalDiagnostics => 'Minimal diagnostics';

  @override
  String get reportDiagnosticsPrivacy =>
      'We check only system codes, manufacturer information (PMm), the presence of selected services and communication error codes.\nWe do not collect a full card dump, service contents, IDm, card number, balance or transaction history.';

  @override
  String get reportScanConsent => 'I agree to the minimal diagnostic check.';

  @override
  String get reportCheckingCard => 'Checking card…';

  @override
  String get reportDiagnosticScan => 'Scan card for diagnostics';

  @override
  String get reportCancelDiagnostics => 'Cancel diagnostics';

  @override
  String get reportReviewPayload => 'Review data to be sent';

  @override
  String get reportSendInquiry => 'Send inquiry';

  @override
  String get reportSupportRetention =>
      'Your inquiry, minimal diagnostics, app/OS versions, report ID and consent version are sent to Supabase to improve card recognition.\nResolved inquiries are deleted after one year; inquiries under review are retained. An anonymous authentication ID is used to limit submissions.';

  @override
  String get reportSupportConsent => 'I agree to send this inquiry.';

  @override
  String get reportSupportUnavailable =>
      'The inquiry service is not available. Contact us using the email address in Settings.';

  @override
  String get reportSending => 'Sending…';

  @override
  String get reportAgreeSend => 'Agree and send';

  @override
  String get reportEmailContact =>
      'For a personal reply: iccardreader10@gmail.com';

  @override
  String get reportReadingError => 'Card reading error';

  @override
  String get reportBrandProblem => 'Card brand identification';

  @override
  String get reportChooseTopic => 'Choose an inquiry type';

  @override
  String get reportReportReceived => 'Your report has been received';

  @override
  String get reportReportPrivacy =>
      'Your card IDm and other transaction records were not sent.';

  @override
  String get reportReceiptUnknown =>
      'Couldn’t confirm receipt of your inquiry. Please try again.';

  @override
  String get reportSupportRateLimit =>
      'Too many inquiries. Please try again in 10 minutes.';

  @override
  String get reportSupportRestricted =>
      'Sending inquiries is restricted. Contact us using the email address in Settings.';

  @override
  String get reportInvalidDiagnostics =>
      'Couldn’t validate the data. Please run diagnostics again.';

  @override
  String get reportSupportConnection =>
      'Couldn’t connect to the inquiry service. Please try again later.';

  @override
  String get reportCheckConnection =>
      'Check your internet connection and try again.';

  @override
  String get reportReportNotReceived =>
      'Couldn’t submit your report. Please try again later.';

  @override
  String get reportInvalidResponse =>
      'Couldn’t verify the server response. Please try again later.';

  @override
  String get reportAnonymousConnection =>
      'Couldn’t start an anonymous connection. Check your internet connection.';

  @override
  String get reportAlreadyReceived => 'This report has already been received.';

  @override
  String get reportReportRateLimit =>
      'Too many reports in a short time. Please try again in 10 minutes.';

  @override
  String get reportReportRestricted =>
      'Sending reports is restricted. Contact us using the email address in Settings.';

  @override
  String get reportInvalidReport =>
      'Couldn’t validate your report. Please check what you entered.';

  @override
  String get reportServerConnection =>
      'Couldn’t connect to the server. Please try again later.';

  @override
  String get reportReportUnavailable =>
      'The report service is not configured. Please check the app settings.';

  @override
  String get reportUnreadableDescription => 'I can’t read my card';

  @override
  String get reportBrandDescription => 'The card brand is missing or incorrect';

  @override
  String reportStep(int step) {
    return 'Step $step of 3';
  }

  @override
  String reportRequiredField(String label) {
    return 'Enter $label.';
  }

  @override
  String get reportReceiptHelp =>
      'We’ll review your report and use it\nto improve the app.';

  @override
  String get reportReceiptId => 'Report ID';

  @override
  String get reportDone => 'Done';

  @override
  String get privacyOverviewTitle =>
      'Card information is normally processed on your device';

  @override
  String get privacyOverviewBody =>
      'Recent transit card records are read using NFC and displayed on screen. They are not retained after the app closes. The raw card IDm is used only temporarily during NFC communication and is not stored, displayed or transmitted.';

  @override
  String get privacyNfcTitle => '1. Why we use NFC';

  @override
  String get privacyNfcBody =>
      'NFC permission is used to read records and identify the type of Japanese transit IC card when you start a scan. In a separate card recognition inquiry, only minimal metadata is checked with your consent. The app does not write to or modify your card.';

  @override
  String get privacyOnDeviceTitle => '2. Information processed on your device';

  @override
  String get privacyOnDeviceBody =>
      'The app interprets and displays the original 16-byte records, dates, transaction types, station codes and names, amounts and balances from recent transactions on your device. Records are not stored permanently. Scanning another card in the normal scan flow replaces the current results.\n\nThe multiple-card balance comparison feature keeps the names, balances, check times and records of up to 10 cards only in the comparison screen’s memory. To distinguish cards, it uses a session-only comparison value created with a random key for each comparison session; the raw IDm is not retained. Comparison values, keys and card names are not saved to files or transmitted to a server. They are cleared when the comparison ends or the app process exits. Deleting an individual card also removes its comparison information. A comparison scan does not change the existing card results on the home screen.';

  @override
  String get privacyReportsTitle => '3. Information sent with an issue report';

  @override
  String get privacyReportsBody =>
      'Issue reports are optional. Only after you review the preview and give your consent does the app send the selected transaction’s raw record, codes and interpreted information, date, amount and balance, the station, city, line or bus operator, operating city/region and description you enter, app, parser and station data versions, platform and OS version to Supabase. This information is used to improve the app.\n\nA separate card recognition inquiry is different from a transaction report. With your consent to a diagnostic scan, the app checks only system codes, manufacturer information (PMm), the presence of selected permitted services and communication error codes on your device. Only after you review the data, purpose and retention period and give separate, explicit consent are these minimal diagnostics, the card type and description you enter, app/OS versions, report ID and consent document version sent to Supabase. They are used to improve card identification and reading errors. A full card dump, service contents, balance and transaction history are not included in this inquiry. The app does not retain the inquiry contents after you leave the screen.';

  @override
  String get privacyNotSentTitle => '4. Information not included in reports';

  @override
  String get privacyNotSentBody =>
      'The raw card IDm, other unselected transaction records, your name, email address, unique device identifiers, current location and travel route are not included in report data.';

  @override
  String get privacyServicesTitle => '5. External processing services';

  @override
  String get privacyServicesBody =>
      'Issue reports use Supabase’s anonymous authentication, server and database services. An anonymous authentication ID is used only within the server to limit submissions to five per 10 minutes and block abusive reports. It is not an email address, card IDm or unique device ID. It is not shown in the app and is used with report information only on the access-restricted server. Reports are processed through Supabase infrastructure. Technical information associated with network connections may be processed under the service’s operating policies.';

  @override
  String get privacyMapsTitle => '5-1. Google Maps';

  @override
  String get privacyMapsBody =>
      'When you open rail transaction details, a Google Maps SDK map is displayed automatically if the app confirms an internet connection, station locations and map configuration. Possible locations are shown for station groups and segments. The area around the stations and their coordinates are used in map requests. Google may process IP addresses, device, OS and SDK information, SDK-specific pseudonymous identifiers, diagnostics and usage information. The app does not request current-location permission or pass your card IDm, card number, balance or raw transaction records to the map SDK. Google’s Privacy Policy (https://policies.google.com/privacy) applies. If an internet connection cannot be confirmed, the map is not displayed; you can retry using Refresh map after connecting. Connection status is checked on your device using Android network capability information, without contacting a separate connectivity-check server. Stopping or refreshing a map does not cancel or delete requests already made. Card reading and the transaction list remain available without a map connection. The app does not separately store map usage history. Google’s retention and deletion rules are governed by its policies.';

  @override
  String get privacyStationDataTitle => '6. Station code data';

  @override
  String get privacyStationDataBody =>
      'Station names are looked up using licensed Yoiko station code data bundled with the app. Lookups take place on your device; card records are not sent to an external server to identify station names. You can find the terms of use under Data sources and fare rules in Settings.';

  @override
  String get privacyRetentionTitle => '7. Retention and deletion';

  @override
  String get privacyRetentionBody =>
      'The app does not permanently store records read from your card. Optional reports that have been applied or rejected, together with their review histories, are retained for one year after resolution and then deleted by a monthly automatic task. Inquiries still under review are not automatically deleted, to avoid accidental loss. Information used to block abusive reports is retained only for server security. Where retention is required by law, information may be kept for the required period.';

  @override
  String get privacyContactTitle => '8. Policy changes and contact';

  @override
  String get privacyContactBody =>
      'If our data processing practices change, we will update this policy and its effective date. For requests to access or delete your information, app errors, usage questions or other inquiries, contact iccardreader10@gmail.com. Public policy: https://yohan020.github.io/ic_card_reader/privacy-en.html';

  @override
  String get privacyEffectiveDate => 'Effective date: October 27, 2026';

  @override
  String get passRegionHokkaido => 'Hokkaido';

  @override
  String get passRegionTohoku => 'Tohoku';

  @override
  String get passRegionKanto => 'Tokyo & Kanto';

  @override
  String get passRegionChubu => 'Chubu';

  @override
  String get passRegionKansai => 'Kansai';

  @override
  String get passRegionChugoku => 'Chugoku';

  @override
  String get passRegionShikoku => 'Shikoku';

  @override
  String get passRegionKyushu => 'Kyushu';

  @override
  String get passRegionOkinawa => 'Okinawa';

  @override
  String get passRegionHokkaidoHint => 'Sapporo, Hakodate and more';

  @override
  String get passRegionTohokuHint => 'Sendai, Aomori and more';

  @override
  String get passRegionKantoHint => 'Passes for Tokyo and Kanagawa';

  @override
  String get passRegionChubuHint => 'Nagoya, Hokuriku and more';

  @override
  String get passRegionKansaiHint => 'Passes for Osaka, Kyoto and Nara';

  @override
  String get passRegionChugokuHint => 'Hiroshima, Okayama and more';

  @override
  String get passRegionShikokuHint => 'Matsuyama, Takamatsu and more';

  @override
  String get passRegionKyushuHint => 'Passes for Fukuoka';

  @override
  String get passRegionOkinawaHint => 'Naha and Okinawa';

  @override
  String get passTitle => 'Compare transit passes';

  @override
  String get passIntro =>
      'Compare regular fares with pass prices based on your travel plan.';

  @override
  String get passCalculationBasis => 'Calculation basis';

  @override
  String get passCalculationNotice =>
      'Only journeys covered by the available data are calculated. Unknown fares are excluded. Check the official product conditions and fares before buying.';

  @override
  String get passSapporo => 'Sapporo Subway One-Day Ticket';

  @override
  String get passSapporoScope => 'Sapporo City Subway · All sections';

  @override
  String get passSubwayDescription =>
      'Compare with regular fares across the subway network.';

  @override
  String get passSapporoPeriod => '1 day · ¥830';

  @override
  String get passHokkaido => 'Hokkaido Rail Pass';

  @override
  String get passHokkaidoScope => 'JR Hokkaido lines · Ordinary reserved seats';

  @override
  String get passHokkaidoDescription =>
      'Compare 5-, 7- and 10-day passes with estimated rail and bus fares.';

  @override
  String get passHokkaidoFive => '5 days · ¥23,000';

  @override
  String get passHokkaidoSeven => '7 days · ¥29,000';

  @override
  String get passHokkaidoTen => '10 days · ¥38,000';

  @override
  String get passTokyoScope => 'Tokyo Metro · Toei Subway';

  @override
  String get passTokyoDescription =>
      'Compare the value of 24-, 48- and 72-hour tickets.';

  @override
  String get passHours24 => '24 hours';

  @override
  String get passHours48 => '48 hours';

  @override
  String get passHours72 => '72 hours';

  @override
  String get passEnokama => 'Enoshima-Kamakura Freepass';

  @override
  String get passEnokamaScope => 'Enoden · Odakyu Railway';

  @override
  String get passEnokamaDescription =>
      'Compare prices by starting station with fares in the free-travel area.';

  @override
  String get passEnokamaPeriod => '1 day · Price varies by starting station';

  @override
  String get passEnoden => 'Enoden One-Day Pass';

  @override
  String get passEnodenScope =>
      'Enoshima Electric Railway · All Enoden sections';

  @override
  String get passEnodenDescription =>
      'Compare regular fares for journeys within Enoden.';

  @override
  String get passEnodenPeriod => '1 day · ¥800';

  @override
  String get passHakone => 'Hakone Freepass';

  @override
  String get passHakoneScope =>
      '70 Odakyu starting stations · Hakone transport';

  @override
  String get passHakoneDescription =>
      'Compare adult prices by starting station with local Hakone fares.';

  @override
  String get passDaysTwo => '2 days';

  @override
  String get passDaysThree => '3 days';

  @override
  String get passTokunai => 'Tokunai Pass';

  @override
  String get passTokunaiScope =>
      'Designated JR sections within Tokyo’s 23 wards';

  @override
  String get passTokunaiDescription =>
      'Compare the one-day pass with regular fares on covered JR sections.';

  @override
  String get passTokunaiPeriod => '1 day · ¥870';

  @override
  String get passKyotoSubway => 'Kyoto Subway One-Day Pass';

  @override
  String get passKyotoSubwayScope => 'Kyoto Municipal Subway · All sections';

  @override
  String get passOsaka => 'Osaka Amazing Pass';

  @override
  String get passOsakaScope => 'Osaka Metro · Private railways · City buses';

  @override
  String get passOsakaDescription =>
      'Compare 1- and 2-day passes with regular fares, including transfers.';

  @override
  String get passOsakaOne => '1 day · ¥3,500';

  @override
  String get passOsakaTwo => '2 days · ¥5,000';

  @override
  String get passKyotoBus => 'Kyoto Subway & Bus One-Day Pass';

  @override
  String get passKyotoBusScope =>
      'Kyoto Municipal Subway · Estimated bus fares';

  @override
  String get passKyotoBusDescription =>
      'Compare automatically calculated subway fares and estimated bus costs.';

  @override
  String get passKyotoBusPeriod => '1 day · ¥1,100';

  @override
  String get passHankyu => 'Hankyu One-Day Pass';

  @override
  String get passHankyuScope => 'All Hankyu Railway lines';

  @override
  String get passHankyuDescription =>
      'Compare regular fares for journeys within Hankyu Railway.';

  @override
  String get passHankyuPeriod => '1 day · ¥1,300';

  @override
  String get passKintetsu => 'KINTETSU RAIL PASS';

  @override
  String get passKintetsuScope => 'Kintetsu Railway · Iga Railway · Cable cars';

  @override
  String get passKintetsuDescription =>
      'Compare regular fares within each pass’s coverage.';

  @override
  String get passDaysOne => '1 day';

  @override
  String get passDaysFive => '5 days';

  @override
  String get passDaysFivePlus => '5 days Plus';

  @override
  String get passOkayama => 'Okayama & Kurashiki tabiwa Gururin Pass';

  @override
  String get passOkayamaScope =>
      'JR West · Okayama Electric Tramway · Shimoden Bus';

  @override
  String get passOkayamaDescription =>
      'Compare the 3-day pass with rail, tram and bus fares.';

  @override
  String get passOkayamaPeriod => '3 days · ¥3,800';

  @override
  String get passHiroden => 'Hiroden Tram Pass';

  @override
  String get passHirodenScope => 'Hiroshima Electric Railway · All tram lines';

  @override
  String get passHirodenDescription =>
      'Compare regular fares with 1-day, 8-hour and 24-hour passes.';

  @override
  String get passHirodenOne => '1 day · ¥700';

  @override
  String get passHirodenEight => '8 hours · ¥600';

  @override
  String get passHirodenTwentyFour => '24 hours · ¥700';

  @override
  String get passNagasaki => 'Nagasaki Electric Tramway Pass';

  @override
  String get passNagasakiScope => 'Nagasaki Electric Tramway · All tram lines';

  @override
  String get passNagasakiDescription =>
      'Compare IC/contactless regular fares with 1-day and 24-hour passes.';

  @override
  String get passNagasakiOne => '1 day · ¥600';

  @override
  String get passFukuoka => 'Fukuoka City Subway One-Day Pass';

  @override
  String get passFukuokaScope => 'Fukuoka City Subway · 3 lines';

  @override
  String get passFukuokaPeriod => '1 day · ¥640';

  @override
  String get passYui => 'Yui Rail Pass';

  @override
  String get passYuiScope => 'Okinawa Urban Monorail · All lines';

  @override
  String get passYuiDescription =>
      'Compare 24- and 48-hour passes with regular Yui Rail fares.';

  @override
  String get passYuiOne => '24 hours · ¥1,000';

  @override
  String get passYuiTwo => '48 hours · ¥1,800';

  @override
  String get passChooseRegion => 'Choose a region\nto compare passes';

  @override
  String get passChooseRegionHint =>
      'Choose where you’re travelling to see available transit passes.';

  @override
  String get passComingSoon => 'Coming soon';

  @override
  String get passStepSelect => 'Choose pass';

  @override
  String get passStepPlan => 'Plan travel';

  @override
  String get passStepResult => 'Results';

  @override
  String get passSelectStation => 'Choose station';

  @override
  String get passRemoveSegment => 'Remove journey';

  @override
  String get passEstimateNote =>
      'An estimated comparison based on the journeys you entered.';

  @override
  String passChooseInRegion(String region) {
    return 'Choose a transit pass\nfor $region';
  }

  @override
  String passViewRegion(String region, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transit passes',
      one: '1 transit pass',
    );
    return 'View $_temp0 for $region';
  }

  @override
  String passRegionComingSoon(String region) {
    return 'Transit passes for $region are coming soon';
  }

  @override
  String passCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passes',
      one: '1 pass',
    );
    return '$_temp0';
  }

  @override
  String passStartComparison(String title) {
    return 'Compare $title';
  }

  @override
  String passSearchStation(String label) {
    return 'Search $label station';
  }

  @override
  String get passDeparture => 'Departure';

  @override
  String get passArrival => 'Arrival';

  @override
  String get passFlow001 => 'Journeys';

  @override
  String get passFlow002 => 'View comparison';

  @override
  String get passFlow003 => 'Clear';

  @override
  String passFlow004(String arg0) {
    return 'Adult regular fare ¥$arg0';
  }

  @override
  String get passFlow005 => 'Search for a station';

  @override
  String get passFlow006 => 'Enter your travel plan';

  @override
  String get passFlow007 => 'Add journey';

  @override
  String get passFlow008 => 'The pass saves you money';

  @override
  String passFlow009(String arg0) {
    return 'Choose $arg0 station';
  }

  @override
  String get passFlow010 =>
      'Choose two stations to see the fare automatically.';

  @override
  String get passFlow011 => 'Estimated savings';

  @override
  String get passFlow012 => 'The cost is the same';

  @override
  String get passFlow013 => 'No matching stations found';

  @override
  String get passFlow014 => 'Swap departure and arrival';

  @override
  String get passFlow015 => 'Paying separately costs less';

  @override
  String get passFlow016 => 'Try another spelling or Korean initials.';

  @override
  String get passFlow017 => 'Not enough journeys to compare';

  @override
  String get passFlow018 => 'The fare for this journey is unavailable.';

  @override
  String get passFlow019 => 'Enter the station you’re looking for';

  @override
  String get passFlow020 => 'Pass price';

  @override
  String passFlow021(String arg0) {
    return 'Save ¥$arg0 on transport';
  }

  @override
  String get passFlow022 => 'Journey details';

  @override
  String get passFlow023 =>
      'The pass price equals the estimated pay-as-you-go total';

  @override
  String passFlow024(String arg0) {
    return 'A difference of ¥$arg0 for this plan';
  }

  @override
  String get passFlow025 => 'Try again';

  @override
  String get passFlow026 => 'Couldn’t load pass data';

  @override
  String get passFlow027 =>
      'Search in Korean, Japanese or English, or use Korean initials.';

  @override
  String get passFlow028 =>
      'Search in Korean or Japanese, or use Korean initials.';

  @override
  String passFlow029(String arg0) {
    return '$arg0 rides';
  }

  @override
  String get passFlow030 => 'Kyoto Municipal Subway';

  @override
  String get passFlow031 => 'Choose the pass starting station';

  @override
  String passFlow032(String arg0) {
    return '$arg0-day pass';
  }

  @override
  String get passFlow033 => 'Add one ride';

  @override
  String get passFlow034 => 'Remove one ride';

  @override
  String passFlow035(String arg0) {
    return '$arg0 starting station';
  }

  @override
  String passFlow036(String arg0) {
    return '$arg0 starting stations';
  }

  @override
  String passFlow037(String arg0) {
    return '$arg0 hours';
  }

  @override
  String passFlow038(String arg0, String arg1) {
    return '$arg0-day pass, ¥$arg1';
  }

  @override
  String passFlow039(String arg0) {
    return '¥$arg0 per ride';
  }

  @override
  String get passFlow040 => '24-hour pass';

  @override
  String passFlow041(String arg0) {
    return '$arg0 search results';
  }

  @override
  String get passFlow042 => 'Clear search';

  @override
  String get passFlow043 => 'All Kintetsu lines and Iga Railway';

  @override
  String get passFlow044 => 'Nagasaki Electric Tramway';

  @override
  String get passFlow045 => 'Choose a line';

  @override
  String get passFlow046 => 'Tama Line';

  @override
  String get passFlow047 => 'Donichika Ticket';

  @override
  String get passFlow048 => 'Toei Subway';

  @override
  String get passFlow049 => 'Estimated bus fare';

  @override
  String get passFlow050 => 'Sapporo City Subway';

  @override
  String get passFlow051 =>
      'Enter the stations where you will actually enter and exit the gates to look up the fare automatically.';

  @override
  String get passFlow052 => 'Enoshima Line';

  @override
  String get passFlow053 => 'Odawara Line';

  @override
  String get passFlow054 => 'Choose an Odakyu starting station';

  @override
  String get passFlow055 => 'Couldn’t read fare data';

  @override
  String get passFlow056 => 'Yui Rail';

  @override
  String get passFlow057 => 'Estimated pay-as-you-go total';

  @override
  String get passFlow058 =>
      'No matching starting stations found. Try Korean, Japanese or Korean initials.';

  @override
  String get passFlow059 => 'Regular rail fares';

  @override
  String get passFlow060 => 'Search starting stations';

  @override
  String get passFlow061 => 'Hankyu Railway';

  @override
  String get passFlow062 => 'Fukuoka City Subway';

  @override
  String get passFlow063 => 'Hiroshima Electric Railway';

  @override
  String get passFlow064 => 'JR West';

  @override
  String get passFlow065 => ' Only bus fares you enter manually are included.';

  @override
  String passFlow066(String arg0, String arg1) {
    return '$arg0 · $arg1 journeys covered';
  }

  @override
  String passFlow067(String arg0) {
    return '$arg0 · One round trip to Odawara included';
  }

  @override
  String passFlow068(String arg0) {
    return '$arg0 price';
  }

  @override
  String passFlow069(String arg0) {
    return 'Search $arg0';
  }

  @override
  String passFlow070(String arg0) {
    return 'Adds adult regular fares on Sapporo City Subway based on $arg0. Transfers to other operators, discounts and child fares are excluded.';
  }

  @override
  String passFlow071(String arg0) {
    return 'Adds adult regular fares of ¥240 per ride based on $arg0. Each journey entered is treated as a separately charged ride. MOBIRY DAYS discounts and automatic transfer or reboarding detection are excluded.';
  }

  @override
  String passFlow072(String arg0) {
    return 'Adds adult IC/contactless fares based on $arg0. Includes the transfer discount for using the same card within 30 minutes at designated stops. Cash fares, buses and child fares are excluded.';
  }

  @override
  String passFlow073(String arg0) {
    return 'Choose $arg0';
  }

  @override
  String passFlow074(String arg0, String arg1) {
    return 'Journey $arg0 · $arg1';
  }

  @override
  String passFlow075(String arg0, String arg1) {
    return '$arg0 hours, ¥$arg1';
  }

  @override
  String passFlow076(String arg0) {
    return '$arg0-hour pass';
  }

  @override
  String passFlow077(String arg0, String arg1) {
    return '$arg0-hour pass, ¥$arg1';
  }

  @override
  String passFlow078(String arg0, String arg1) {
    return '$arg0-day pass, ¥$arg1';
  }

  @override
  String get passFlow079 => '1 day · Derived JR fares';

  @override
  String get passFlow080 =>
      '1 day ¥3,500 · 2 days ¥5,000 · Automatic transfer calculation';

  @override
  String get passFlow081 => 'Estimated ¥300 per ride';

  @override
  String get passFlow082 => '24 / 48 / 72 hours · Automatic fares';

  @override
  String get passFlow083 => '2 days';

  @override
  String get passFlow084 =>
      'The same Nara Kotsu sections as the 2-day pass, plus designated Mie Kotsu and Toba City Kamome Bus sections';

  @override
  String get passFlow085 => '3 days';

  @override
  String get passFlow086 => '8-hour pass';

  @override
  String get passFlow087 => 'Loading verified rail and bus fare data.';

  @override
  String get passFlow088 => 'Choose a pass to test';

  @override
  String get passFlow089 => 'Before using these results';

  @override
  String get passFlow090 =>
      'Automatically adds rail fares verified against published distance and fare rules, and regular Osaka City Bus fares. The value of free admission to attractions is excluded.';

  @override
  String get passFlow091 => 'Couldn’t open the official information.';

  @override
  String get passFlow092 =>
      'Enter only the total adult regular fares for buses confirmed as covered in the official information. The app does not determine bus coverage.';

  @override
  String get passFlow093 => 'Check official coverage';

  @override
  String get passFlow094 =>
      'Admission and discount benefits at attractions are excluded.';

  @override
  String get passFlow095 =>
      'Attraction benefits, buses outside the pass coverage, limited express tickets and seat charges are excluded. Journeys involving different operators use a recommended route based on distances in the supported station graph. Check your actual route and the latest official conditions before buying.';

  @override
  String get passFlow096 =>
      'Attraction benefits are excluded. Representative bus fares may differ from actual fares.';

  @override
  String get passFlow097 =>
      'Visiting attractions may provide additional value.';

  @override
  String get passFlow098 => 'Sightseeing limited express bus';

  @override
  String get passFlow099 => 'Estimated Kyoto bus use';

  @override
  String get passFlow100 =>
      'Enter the number of rides for the Kyoto Subway & Bus One-Day Pass.';

  @override
  String get passFlow101 =>
      'Choose Kyoto Municipal Subway stations to look up adult regular fares automatically.';

  @override
  String get passFlow102 => 'Enter your Kyoto Municipal Subway journeys.';

  @override
  String get passFlow103 => 'Kyoto Municipal Subway regular fares';

  @override
  String get passFlow104 =>
      'Calculates adult regular fares across Kyoto Municipal Subway only. Transfers to other operators and discounts are excluded.';

  @override
  String get passFlow105 =>
      'Adds adult regular fares across Kyoto Municipal Subway only. The one-day pass is valid until the end of service on the day of use. Transfers to other operators and discounts are excluded.';

  @override
  String get passFlow106 =>
      'Subway fares are adult regular fares based on selected stations. Bus fares are estimates based on the number of rides entered.';

  @override
  String get passFlow107 =>
      'Choose Kyoto Municipal Subway stations to look up adult fares automatically.';

  @override
  String get passFlow108 => 'Paying separately costs less for transport alone';

  @override
  String get passFlow109 => 'Transport costs only';

  @override
  String passFlow110(String arg0) {
    return 'Save ¥$arg0 on transport alone';
  }

  @override
  String get passFlow111 => 'Choose a transport mode';

  @override
  String get passFlow112 => 'Transit pass comparison prototype';

  @override
  String get passFlow113 => 'Coverage by journey';

  @override
  String get passFlow114 =>
      'Only journeys within this pass’s coverage are calculated. Limited express tickets, ropeways, discounts and other benefits are excluded.';

  @override
  String get passFlow115 =>
      'Enter the Kintetsu stations where you will actually enter and exit the gates to look up adult regular fares automatically.';

  @override
  String get passFlow116 => 'Nagasaki Electric Tramway One-Day Pass';

  @override
  String get passFlow117 => 'Nagasaki Electric Tramway 24-Hour Pass';

  @override
  String get passFlow118 => 'Enter your Nagasaki Electric Tramway journeys.';

  @override
  String get passFlow119 => 'Nagasaki Electric Tramway regular fares';

  @override
  String get passFlow120 =>
      'Choose Nagasaki Electric Tramway stops to look up adult IC/contactless regular fares automatically.';

  @override
  String get passFlow121 =>
      'Nara Kotsu: designated Nara Park, Nishinokyo and Horyuji sections';

  @override
  String get passFlow122 =>
      'Nara Kotsu: designated Nara Park, Nishinokyo, Horyuji, Asuka, Muro and Yamanobe-no-Michi sections';

  @override
  String get passFlow123 => 'Tram and bus rides';

  @override
  String get passFlow124 => 'Regular tram and bus fares';

  @override
  String get passFlow125 => 'Preparing data';

  @override
  String get passFlow126 => 'Arrival station';

  @override
  String get passFlow127 => 'Tokyo Metro';

  @override
  String get passFlow128 => 'Tokunai One-Day Pass';

  @override
  String get passFlow129 => 'JR sections covered by the Tokunai Pass';

  @override
  String get passFlow130 =>
      'Choose two locations to see the adult regular fare.';

  @override
  String get passFlow131 => 'Hakone Tozan Railway';

  @override
  String get passFlow132 =>
      'Railway, cable car, ropeway and sightseeing cruise use exact fares. Bus costs use average fares and ride counts. Romancecar limited express tickets are excluded.';

  @override
  String get passFlow133 => 'Ropeway';

  @override
  String get passFlow134 =>
      'Representative bus fares may differ from the fares for your actual journeys.';

  @override
  String get passFlow135 => 'Bus fare (optional)';

  @override
  String get passFlow136 => 'Bus fares are estimates';

  @override
  String get passFlow137 => 'Estimated bus use';

  @override
  String get passFlow138 => 'Add a bus ride';

  @override
  String get passFlow139 => 'Remove a bus ride';

  @override
  String get passFlow140 =>
      'Bus fares are estimates and may differ depending on your actual route and transfer fares.';

  @override
  String get passFlow141 => 'Bus fares are estimated from ride counts';

  @override
  String get passFlow142 => 'Local / Rapid';

  @override
  String get passFlow143 => 'Excluded from comparison';

  @override
  String get passFlow144 => 'Fares outside coverage, excluded from comparison';

  @override
  String get passFlow145 => 'Not enough travel to compare';

  @override
  String get passFlow146 =>
      'Choose Sapporo City Subway stations to look up adult regular fares automatically.';

  @override
  String get passFlow147 => 'Enter your Sapporo City Subway journeys.';

  @override
  String get passFlow148 => 'Sapporo City Subway regular fares';

  @override
  String get passFlow149 =>
      'Calculates adult regular fares on Sapporo City Subway only. Transfers to other operators and discounts are excluded.';

  @override
  String passFlow150(String arg0) {
    return 'Adds adult basic fares within the selected pass coverage only. Fare adjustments for travel beyond that area, limited express tickets, ropeways, discounts and other benefits are excluded.$arg0';
  }

  @override
  String get passFlow151 =>
      'Compares the pass price from your chosen Odakyu station with the adult IC round-trip fare to Fujisawa and the journeys you enter within the free-travel area.';

  @override
  String get passFlow152 =>
      'Compares the value of the Hakone Freepass using adult regular fares only.';

  @override
  String get passFlow153 =>
      'Calculates adult regular fares at ¥240 per ride. Each journey entered is treated as a separately charged ride. MOBIRY DAYS discounts and automatic transfer or reboarding detection are excluded.';

  @override
  String get passFlow154 =>
      'Calculates adult IC/contactless fares. Includes the transfer discount for using the same card within 30 minutes at designated stops. Cash fares, buses and child fares are excluded.';

  @override
  String get passFlow155 => 'Representative Shimoden Bus fares';

  @override
  String get passFlow156 => 'Regular city bus fares';

  @override
  String get passFlow157 =>
      'Enter the station where you will actually exit the gates. The recommended route is not the fastest route based on a timetable.';

  @override
  String get passFlow158 =>
      'Enter the station where you will actually exit the gates. Unverified fares are not calculated.';

  @override
  String get passFlow159 => 'No journeys to compare yet';

  @override
  String get passFlow160 => 'Restart the app or try again.';

  @override
  String passFlow161(String arg0) {
    return 'Approx. ¥$arg0 per ride';
  }

  @override
  String get passFlow162 => 'Enter your Enoden journeys.';

  @override
  String get passFlow163 => 'Enoden regular fares';

  @override
  String get passFlow164 =>
      'Adds adult regular fares across all 15 Enoden stations only. Other benefits, discounts and transfers to other operators are excluded.';

  @override
  String get passFlow165 =>
      'Calculates adult regular fares for journeys within Enoden only. Other benefits, discounts and transfers to other operators are excluded.';

  @override
  String get passFlow166 =>
      'Search for stations in the Enoden and Odakyu free-travel area.';

  @override
  String get passFlow167 =>
      'Enter the Enoden stations where you will actually enter and exit the gates to look up adult regular fares automatically.';

  @override
  String get passFlow168 => 'Enoshima Electric Railway';

  @override
  String get passFlow169 => 'Enoshima Electric Railway · Enoden';

  @override
  String get passFlow170 => 'Enoshima-Kamakura One-Day Freepass';

  @override
  String get passFlow171 => 'Station';

  @override
  String get passFlow172 =>
      'Station purchase price · ¥1,000 less when bought in advance';

  @override
  String get passFlow173 =>
      'Prepare the station and fare data, then try again.';

  @override
  String get passFlow174 => 'e.g. 800';

  @override
  String get passFlow175 => 'No difference in estimated cost';

  @override
  String passFlow176(String arg0) {
    return 'Estimated savings ¥$arg0';
  }

  @override
  String get passFlow177 => 'Osaka City Bus';

  @override
  String passFlow178(String arg0) {
    return 'Osaka City Bus · $arg0 rides';
  }

  @override
  String get passFlow179 => 'Osaka Amazing Pass · 1 day';

  @override
  String get passFlow180 => 'Osaka Amazing Pass · 2 days';

  @override
  String get passFlow181 =>
      'Kintetsu lines in Osaka, Nara and Kyoto (Osaka Line as far as Sanbonmatsu)';

  @override
  String get passFlow182 =>
      'Osaka-Namba–Kintetsu-Nara, Kyoto–Tsutsui, Nagata–Ikoma, Toriimae–Ikoma-sanjō';

  @override
  String get passFlow183 => 'For Osaka, only transport costs are compared';

  @override
  String get passFlow184 => 'Okayama & Kurashiki tabiwa Gururin Pass · 3 days';

  @override
  String get passFlow185 => 'Operator information unavailable';

  @override
  String passFlow186(String arg0) {
    return 'Yui Rail · $arg0';
  }

  @override
  String get passFlow187 =>
      'Choose Yui Rail stations to look up adult regular fares automatically.';

  @override
  String get passFlow188 => 'Enter your Yui Rail journeys.';

  @override
  String get passFlow189 => 'Yui Rail regular fares';

  @override
  String get passFlow190 =>
      'Calculates adult regular fares on Yui Rail only. Transfers to other operators and discounts are excluded.';

  @override
  String passFlow191(String arg0) {
    return 'Adds adult regular fares on Yui Rail only. The $arg0-hour pass is valid from the time of issue. Transfers to other operators and discounts are excluded.';
  }

  @override
  String get passFlow192 => 'Outside the validity period';

  @override
  String get passFlow193 =>
      'Enter valid journeys to see the basis for the comparison.';

  @override
  String get passFlow194 =>
      'Outside this pass’s coverage. Excluded from the comparison total.';

  @override
  String get passFlow195 => 'Edit travel plan';

  @override
  String get passFlow196 => 'Enter only journeys made on the day of use.';

  @override
  String passFlow197(String arg0) {
    return 'Enter only journeys within $arg0 consecutive days from the first day of use.';
  }

  @override
  String get passFlow198 => 'Train type';

  @override
  String get passFlow199 => 'Ride count';

  @override
  String get passFlow200 =>
      'Enter the number of rides for each transport mode.';

  @override
  String get passFlow201 => 'Standard one-day pass';

  @override
  String get passFlow202 => 'Paying separately costs less';

  @override
  String get passFlow203 => 'Regular city bus';

  @override
  String get passFlow204 =>
      'Adds only regular city bus and sightseeing limited express bus ride counts. Actual routes, operators, adjusted-fare sections, late-night surcharges and routes excluded from the pass are not determined automatically.';

  @override
  String get passFlow205 => 'Regular fare total';

  @override
  String get passFlow206 =>
      'Some specific routes and on-demand buses are not covered by the pass.';

  @override
  String passFlow207(String arg0, String arg1, String arg2, String arg3) {
    return 'An estimated comparison based on the journeys you entered.\nBus fares are estimates and may differ from actual fares.\n\nPass price ¥$arg0\nJourney fares ¥$arg1\nEstimated bus fares ¥$arg2\nEstimated savings ¥$arg3';
  }

  @override
  String get passFlow208 => 'Covered bus fares (enter manually)';

  @override
  String get passFlow209 => 'Covered bus fare total';

  @override
  String get passFlow210 => 'Outside coverage · Excluded from total';

  @override
  String get passFlow211 => 'Covered regular rail fares';

  @override
  String get passFlow212 =>
      'These are average adult fares by operator, not stop-specific fares.';

  @override
  String get passFlow213 => 'Regular routes covered by the Amazing Pass';

  @override
  String passFlow214(String arg0) {
    return 'Rides on regular routes covered by the Amazing Pass · ¥$arg0 per ride';
  }

  @override
  String get passFlow215 => 'No route found in the supported data.';

  @override
  String get passFlow216 =>
      'No route or fare found between these stations in the supported data.';

  @override
  String get passFlow217 => 'Enter subway journeys or the number of bus rides.';

  @override
  String get passFlow218 => 'Regular subway fares';

  @override
  String get passFlow219 =>
      'Enter the subway station where you will actually exit the gates. Bus fare assumptions are explained under Data sources and fare rules in Settings.';

  @override
  String get passFlow220 => 'Automatically calculated reference result';

  @override
  String passFlow221(String arg0, String arg1) {
    return 'Uses $arg0 rail stations, $arg1 transfer connections and regular city bus fares. Attraction benefits are excluded.';
  }

  @override
  String get passFlow222 =>
      'Choose rail journeys or enter the number of bus rides.';

  @override
  String get passFlow223 => 'Departure station';

  @override
  String get passFlow224 =>
      'One round trip between your starting station and Fujisawa included';

  @override
  String get passFlow225 => 'Swap departure and arrival stations';

  @override
  String get passFlow226 => 'Choose both departure and arrival stations.';

  @override
  String get passFlow227 =>
      'Add journeys with departure and arrival stations to calculate savings.';

  @override
  String get passFlow228 => 'Choose departure and arrival stations';

  @override
  String passFlow229(String arg0) {
    return 'The $arg0-day pass price varies by starting station.';
  }

  @override
  String get passFlow230 => 'The pass price varies by starting station.';

  @override
  String passFlow231(String arg0) {
    return 'Choose a starting station to apply the $arg0-day pass price.';
  }

  @override
  String get passFlow232 =>
      'Choose a starting station to apply its pass price.';

  @override
  String get passFlow233 => 'Cable car';

  @override
  String get passFlow234 => 'Number of rides';

  @override
  String get passFlow235 =>
      'Available only on Saturdays, Sundays, public holidays and December 29–January 3.';

  @override
  String get passFlow236 => 'Limited express';

  @override
  String get passFlow237 =>
      'Limited express fares use ordinary reserved seats. Bus fares are estimated at ¥300 per ride.';

  @override
  String passFlow238(String arg0) {
    return '¥$arg0 less than the pass price.';
  }

  @override
  String get passFlow239 => 'Covered by pass';

  @override
  String get passFlow240 => 'Regular fares for covered journeys';

  @override
  String get passFlow241 => 'Enter covered journeys and fares';

  @override
  String get passFlow242 => 'Outside the pass coverage.';

  @override
  String get passFlow243 => 'Not covered by pass';

  @override
  String get passFlow244 =>
      'Choose the pass starting station and journeys in the Enoden/Odakyu free-travel area to compare adult IC fares.';

  @override
  String get passFlow245 =>
      'Calculates one round trip between the pass starting station and Fujisawa, all Enoden sections and the Odakyu Fujisawa–Katase-Enoshima section only. Additional journeys outside the free-travel area, limited express tickets, seat charges and discounts are excluded.';

  @override
  String get passFlow246 => 'Enter journeys covered by the pass.';

  @override
  String passFlow247(String arg0) {
    return 'The pass costs ¥$arg0 more';
  }

  @override
  String get passFlow248 => 'Prototype';

  @override
  String get passFlow249 =>
      'Regenerate the prototype assets before running the app.';

  @override
  String get passFlow250 => 'Starting station within the free-travel area';

  @override
  String passFlow251(String arg0) {
    return 'Hakone Freepass · $arg0 days';
  }

  @override
  String get passFlow252 =>
      'Adds adult regular fares for 87 Hankyu Railway stations only. The Kobe Rapid Transit Line and transfers to other operators are excluded.';

  @override
  String get passFlow253 =>
      'Calculates journeys within Hankyu Railway only. The Kobe Rapid Transit Line, limited express tickets, seat charges, discounts and transfers to other operators are excluded.';

  @override
  String get passFlow254 =>
      'Choose Hankyu Railway stations to look up adult regular fares automatically.';

  @override
  String get passFlow255 => 'Enter your Hankyu Railway journeys.';

  @override
  String get passFlow256 => 'Hankyu Railway regular fares';

  @override
  String get passFlow257 => 'Hakone Sightseeing Cruise';

  @override
  String passFlow258(String arg0) {
    return 'Hokkaido Rail Pass · $arg0 days';
  }

  @override
  String get passFlow259 => 'OK';

  @override
  String get passFlow260 => 'Ride count details';

  @override
  String get passFlow261 => 'Fujisawa round trip included';

  @override
  String get passFlow262 =>
      'Choose Fukuoka City Subway stations to look up adult regular fares automatically.';

  @override
  String get passFlow263 => 'Enter your Fukuoka City Subway journeys.';

  @override
  String get passFlow264 => 'Fukuoka City Subway regular fares';

  @override
  String get passFlow265 =>
      'Calculates adult regular fares on Fukuoka City Subway only. Transfers to other operators and discounts are excluded.';

  @override
  String get passFlow266 =>
      'Adds adult regular fares on Fukuoka City Subway only. The one-day pass is valid from the first to the last train on the day you use the gates. Transfers to other operators and discounts are excluded.';

  @override
  String get passFlow267 => 'Hiroden Tram One-Day Pass';

  @override
  String get passFlow268 => 'Hiroden Tram 24-Hour Pass';

  @override
  String get passFlow269 => 'Hiroden Tram 8-Hour Pass';

  @override
  String get passFlow270 => 'Enter your Hiroshima Electric Railway journeys.';

  @override
  String get passFlow271 => 'Hiroshima Electric Railway regular fares';

  @override
  String get passFlow272 =>
      'Choose Hiroshima Electric Railway stops to look up adult regular fares automatically.';

  @override
  String get passFlow273 => 'JR East';

  @override
  String get passFlow274 =>
      'Choose JR West stations to look up adult regular fares automatically.';

  @override
  String get passFlow275 => 'JR West regular fares';

  @override
  String get passFlow276 => 'Enter JR journeys or tram and bus ride counts.';

  @override
  String get passFlow277 => 'JR Hokkaido · Local / Rapid';

  @override
  String get passFlow278 => 'JR Hokkaido · Limited express';

  @override
  String get passFlow279 => 'JR Hokkaido Bus';

  @override
  String get passFlow280 =>
      'Choose JR Hokkaido stations to look up adult regular fares automatically.';

  @override
  String get passFlow281 =>
      'Calculates adult fares on JR Hokkaido lines. Includes only ordinary reserved seats for limited express trains and estimated bus fares of ¥300 per ride.';

  @override
  String get passFlow282 =>
      'Adds JR and tram fares and the selected Shimoden Bus ride counts. Attraction admission, bicycle-rental benefits, limited express charges, discounts and transfers to other operators are excluded.';

  @override
  String get passFlow283 =>
      'Adds adult regular fares for JR and Okayama Electric Tramway. Representative Shimoden Bus fares may differ from actual stop-specific fares. Attraction and bicycle-rental benefits are excluded.';

  @override
  String get passFlow284 => 'Metro ↔ Toei Subway';

  @override
  String get passFlow285 =>
      'Metro↔Toei journeys assume officially designated transfer stations, a transfer within 60 minutes and a ¥70 discount. Recheck official fares and purchase conditions before buying a pass.';

  @override
  String get passFlow286 => 'Tokyo Subway 24-Hour Ticket';

  @override
  String get passFlow287 => 'Tokyo Subway 48-Hour Ticket';

  @override
  String get passFlow288 => 'Tokyo Subway 72-Hour Ticket';

  @override
  String get passFlow289 =>
      'Only products verified in the web prototype are included in the Android app.';

  @override
  String get passSource001 => 'Kyoto City Transportation Bureau subway fares';

  @override
  String get passSource002 => 'Kyoto Open Data: 京都市営地下鉄 駅間距離・運賃';

  @override
  String get passSource003 =>
      'Adapted from 京都市営地下鉄 駅間距離・運賃 (Kyoto City), CC BY 4.0. The one-day pass is valid until the end of service on the day of use. Transfers to other operators, discounts and child fares are excluded.';

  @override
  String get passSource004 =>
      'Adapted from 京都市営地下鉄 駅間距離・運賃 (Kyoto City), CC BY 4.0. Bus routes, operators, variable-fare sections, late-night surcharges and excluded routes are not checked automatically.';

  @override
  String get passSource005 =>
      'Only journeys covered by the selected pass are included, using adult basic fares for 301 stations and 45,150 station pairs. Designated buses use only fares entered manually after confirming eligibility.';

  @override
  String get passSource006 =>
      'Looks up adult basic fares for 310 JR Hokkaido stations. Verified limited-express station pairs offer ordinary-car reserved-seat fares. JR Hokkaido Bus uses an estimate of ¥300 per ride, multiplied by the number entered.';

  @override
  String get passSource007 =>
      'Looks up 1,260 directional adult regular fares between 36 physical stations on the device. Interchange line codes at Nakasu-Kawabata and Hakata are grouped into one physical station to avoid duplicate calculations.';

  @override
  String get passSource008 =>
      'Looks up 1,406 directional adult IC/contactless fares between 38 stops on the device. Showamachi-dori serves only the Akasako direction, so departure and arrival directions are distinguished.';

  @override
  String get passSource009 =>
      'Calculates adult regular fares using adjacent operating distances between 46 physical stations and official distance bands. Sapporo and Odori each count as one physical station, regardless of interchange lines.';

  @override
  String get passSource010 =>
      'Applies the adult regular fare of ¥240 when two different stops among 77 stops are selected. Each journey entered counts as one separately charged ride.';

  @override
  String get passSource011 =>
      'Enoden 1-Day Pass “Noriorikun” · Entire Enoden line';

  @override
  String get passSource012 => 'Kyoto Subway One-Day Pass';

  @override
  String get passSource013 => 'Kyoto Subway One-Day Pass: official information';

  @override
  String get passSource014 => 'Kyoto Subway & Bus One-Day Pass';

  @override
  String get passSource015 =>
      'Kyoto Subway & Bus One-Day Pass: official information';

  @override
  String get passSource016 =>
      'Kyoto Municipal Subway · User-entered estimated bus fares';

  @override
  String get passSource017 => 'Kyoto Municipal Subway · All sections';

  @override
  String get passSource018 =>
      'Calculates Kyoto Municipal Subway regular fares using station distances and adult fare bands, then compares the total of all entered journeys with the ¥800 adult one-day pass.';

  @override
  String get passSource019 =>
      'Subway fares use Kyoto Municipal Subway station distances and adult fare bands. Bus estimates use only the ride counts entered: ¥230 for regular city buses and ¥500 for sightseeing express buses.';

  @override
  String get passSource020 => 'Data sources by transit pass';

  @override
  String get passSource021 => 'KINTETSU RAIL PASS';

  @override
  String get passSource022 =>
      'Nagasaki Electric Tramway: 2026 routes and fares';

  @override
  String get passSource023 =>
      'Nagasaki Electric Tramway: passenger transport rules';

  @override
  String get passSource024 => 'Nagasaki Electric Tramway Pass';

  @override
  String get passSource025 => 'Data sources';

  @override
  String get passSource026 => 'Data sources & fare basis';

  @override
  String get passSource027 =>
      'Uses an offline fare table derived from operating distances between 77 Tokunai Pass stations and JR East adult IC fare tables.';

  @override
  String get passSource028 => 'Tokunai Pass';

  @override
  String get passSource029 =>
      'Select a pass to see how fares are calculated, along with sources and limitations.';

  @override
  String get passSource030 => 'Sapporo Subway One-Day Ticket';

  @override
  String get passSource031 =>
      'Sapporo Subway One-Day Pass: official information';

  @override
  String get passSource032 => 'Sapporo subway fares: open dataset';

  @override
  String get passSource033 => 'Sapporo subway fares';

  @override
  String get passSource034 =>
      'Compares the selected Odakyu departure-station pass price with the adult IC round-trip fare to Fujisawa and fares for entered journeys within the Enoden/Odakyu free area.';

  @override
  String get passSource035 =>
      'Compares the adult one-day pass (¥600) and 24-hour pass (¥700). Fares are based on IC/contactless payment, including eligible same-card transfers within 30 minutes at designated stops. Derived station, line and fare-rule data follows Wikipedia contributors’ CC BY-SA 4.0 terms; official PDF originals are not bundled. Cash, bus and child fares are excluded.';

  @override
  String get passSource036 =>
      'Looks up adult two- and three-day pass prices from 70 Odakyu departure stations. Mountain railway, cable car, ropeway and sightseeing cruise fares are exact; bus totals are estimates using each operator’s average fare and entered ride counts.';

  @override
  String get passSource037 =>
      'Compares the adult subway one-day pass (¥830) with the Donichika Ticket (¥520). Donichika is valid only on Saturdays, Sundays, public holidays and December 29–January 3. Fare bands were checked against Sapporo City open data (CC BY 4.0) and official guidance. Derived station-order and adjacent-distance data follows Wikipedia contributors’ CC BY-SA 4.0 terms. Transfers to other operators, discounts and child fares are excluded.';

  @override
  String get passSource038 =>
      'Timetable-based fastest routes, attraction benefits, excluded buses, limited-express and seat charges are excluded. Some Keihan operating-distance data follows Wikipedia contributors’ CC BY-SA 4.0 terms.';

  @override
  String get passSource039 => 'Shimoden Bus fare revision notice';

  @override
  String get passSource040 =>
      'Calculates fares between two stations using operating distances for Enoden’s 15 stations and adult regular-fare distance bands.';

  @override
  String get passSource041 => 'Enoden One-Day Pass';

  @override
  String get passSource042 =>
      'Enoden One-Day Pass “Noriorikun”: official information';

  @override
  String get passSource043 =>
      'Adapted from Enoden station, operating-distance and fare-band data. The derived fare data follows Wikipedia contributors’ CC BY-SA 4.0 terms. Benefits, discounts and transfers to other operators are excluded.';

  @override
  String get passSource044 =>
      'Entire Enoden line · Odakyu Fujisawa–Katase-Enoshima';

  @override
  String get passSource045 => 'Enoshima-Kamakura Freepass';

  @override
  String get passSource046 =>
      'Enoshima-Kamakura Freepass: official information';

  @override
  String get passSource047 =>
      'Derived station-order and operating-distance data follows Wikipedia contributors’ CC BY-SA 4.0 terms. Fares were checked against official station fares across the network. OKICA and other payment-specific discounts, transfers to other operators and child fares are excluded.';

  @override
  String get passSource048 => 'Station location map';

  @override
  String get passSource049 =>
      'Station information was checked against Fukuoka City open data (CC BY) and current official guidance. Adult fares as of September 3, 2026 are used. The one-day pass is valid from the first to last train on the day of entry. Transfers to other operators, discounts and child fares are excluded.';

  @override
  String get passSource050 =>
      'Derived station, fare and stop-order data retains CC BY-SA 4.0 terms and original attribution. Limited-express options are available only for verified station pairs served by regular trains. Bus amounts are estimates, not exact fares. Green Cars and sightseeing, seasonal and steam trains are excluded.';

  @override
  String get passSource051 =>
      'Adapted from Odakyu operating distances and fare bands, and Enoden operating-distance data. The derived data follows Wikipedia contributors’ CC BY-SA 4.0 terms. Limited-express and seat charges, discounts and extra travel outside the free area are excluded.';

  @override
  String get passSource052 =>
      'Odakyu departure-station prices · Designated Hakone transport';

  @override
  String get passSource053 =>
      'The Odakyu section includes only one return trip between the departure station and Odawara. Romancecar limited-express tickets are extra. Derived station/distance data follows Wikipedia contributors’ CC BY-SA 4.0 terms; structured identifiers follow Wikidata CC0. Bus results are estimates.';

  @override
  String get passSource054 => 'Osaka Metro · Private railways · City buses';

  @override
  String get passSource055 => 'Osaka City Bus information';

  @override
  String get passSource056 => 'Osaka Amazing Pass';

  @override
  String get passSource057 => 'Osaka Amazing Pass: official information';

  @override
  String get passSource058 => 'Okayama Electric Tramway fares';

  @override
  String get passSource059 => 'Okayama & Kurashiki tabiwa Gururin Pass';

  @override
  String get passSource060 =>
      'Okayama-Kurashiki tabiwa Gururin Pass: official information';

  @override
  String get passSource061 => 'Okinawa Urban Monorail · All lines';

  @override
  String get passSource062 => 'Fare calculation basis';

  @override
  String get passSource063 =>
      'Fares and pass conditions may change. Check official information before purchasing.';

  @override
  String get passSource064 =>
      'Looks up 342 directional adult regular fares between Yui Rail’s 19 stations on the device. Compares all entered journeys with the price of a 24-hour or 48-hour pass.';

  @override
  String get passSource065 => 'Yui Rail fares: official information';

  @override
  String get passSource066 => 'Yui Rail Pass';

  @override
  String get passSource067 =>
      'Yui Rail unlimited-ride tickets: official information';

  @override
  String get passSource068 =>
      'Station coordinates in journey details were generated from Wikidata P625 (CC0). Station codes, names, operators and lines are cross-checked; unverified locations are not displayed. These are reference station locations, not actual travel routes. Google Maps provides the map background, subject to its displayed attribution.\nhttps://www.wikidata.org/wiki/Wikidata:Licensing';

  @override
  String get passSource069 =>
      'Japanese Wikipedia: Kintetsu and Iga Railway lines';

  @override
  String get passSource070 =>
      'Japanese Wikipedia: Enoshima Electric Railway and its line';

  @override
  String get passSource071 => 'Japanese Wikipedia: Odakyu and Enoden lines';

  @override
  String get passSource072 => 'Japanese Wikipedia: Okinawa Urban Monorail line';

  @override
  String get passSource073 => 'Japanese Wikipedia: 長崎電気軌道';

  @override
  String get passSource074 =>
      'Japanese Wikipedia: Hankyu station and operating-distance data';

  @override
  String get passSource075 =>
      'Nagasaki Electric Tramway · One-day and 24-hour passes · All tram lines';

  @override
  String get passSource076 =>
      'Tram one-day ticket · Digital 8-hour and 24-hour passes';

  @override
  String get passSource077 =>
      'Compares the paper tram one-day ticket (¥700), digital 8-hour pass (¥600) and 24-hour pass (¥700). Stop identifiers follow Wikidata CC0; normalized station codes, fares and product facts retain Wikimedia-based CC BY-SA 4.0 terms. MOBIRY DAYS distance discounts, automatic transfer/reboarding decisions, buses, ferries and child fares are excluded.';

  @override
  String get passSource078 =>
      'Subway One-Day Pass · Donichika Ticket · All Sapporo subway lines';

  @override
  String get passSource079 =>
      'Results are estimates for reference. Check coverage and current fares before travelling.';

  @override
  String get passSource080 =>
      'Calculates regular fares using published operator fares, distances between stations and interchange connections.';

  @override
  String get passSource081 =>
      'Hankyu 1day Pass · All Hankyu lines (excluding the Kobe Kosoku Line)';

  @override
  String get passSource082 => 'Hankyu 1day Pass: official information';

  @override
  String get passSource083 =>
      'Hakone Navi: ropeway and sightseeing cruise fares';

  @override
  String get passSource084 => 'Hakone Freepass';

  @override
  String get passSource085 => 'Hakone Freepass: official price list';

  @override
  String get passSource086 => 'Hakone Freepass: official information';

  @override
  String get passSource087 =>
      'Adapted from operating distances between adjacent stations on Hankyu lines. The derived fare data follows Wikipedia contributors’ CC BY-SA 4.0 terms. The Kobe Kosoku Line, limited-express and seat charges, discounts, special IC rules and transfers to other operators are excluded.';

  @override
  String get passSource088 => 'Hankyu passenger business rules';

  @override
  String get passSource089 =>
      'Uses regular fares calculated from adjacent operating distances between 87 Hankyu stations and adult ordinary-fare distance bands.';

  @override
  String get passSource090 => 'Hankyu One-Day Pass';

  @override
  String get passSource091 => 'Hokkaido Rail Pass';

  @override
  String get passSource092 => 'Hokkaido Rail Pass: official information';

  @override
  String get passSource093 => 'Things to check';

  @override
  String get passSource094 => 'Fukuoka City Subway One-Day Pass';

  @override
  String get passSource095 => 'Fukuoka City station open dataset';

  @override
  String get passSource096 => 'Fukuoka City Subway';

  @override
  String get passSource097 =>
      'Fukuoka City Subway One-Day Pass: official information';

  @override
  String get passSource098 => 'Fukuoka City Subway fares';

  @override
  String get passSource099 => 'Hiroden Tram Pass';

  @override
  String get passSource100 => 'Hiroshima Electric Railway fare revision';

  @override
  String get passSource101 =>
      'Hiroshima Electric Railway tram passes: official information';

  @override
  String get passSource102 =>
      'Designated JR East services within Tokyo’s 23 wards';

  @override
  String get passSource103 => 'JR East Tokunai Pass: official information';

  @override
  String get passSource104 => 'JR East fare and charge information';

  @override
  String get passSource105 =>
      'JR West · Okayama Electric Tramway · Shimoden Bus';

  @override
  String get passSource106 =>
      'Looks up 1,190 adult regular fares between 35 eligible JR West stations. Okayama Electric Tramway is added at the exact fare of ¥160 per ride. Shimoden Bus uses entered ride counts and representative fares for the selected service.';

  @override
  String get passSource107 =>
      'Derived JR station-distance data follows Wikipedia contributors’ CC BY-SA 4.0 terms. Shimoden Bus Kojima–Kurashiki and Tokohai-go use representative fares, which may differ by stop. Attraction and bicycle-rental benefits, limited-express services, discounts and transfers to other operators are excluded.';

  @override
  String get passSource108 => 'JR Hokkaido train information';

  @override
  String get passSource109 => 'JR Hokkaido lines · 5-, 7- and 10-day passes';

  @override
  String get passSource110 =>
      'KINTETSU RAIL PASS · 1-day, 2-day, 5-day and 5-day Plus';

  @override
  String get passSource111 =>
      'KINTETSU RAIL PASS: official information by type';

  @override
  String get passSource112 => 'MOBIRY DAYS fares';

  @override
  String get passSource113 => 'ODPT Public Transportation Open Data Center';

  @override
  String get passSource114 =>
      'Calculates covered Tokyo Metro and Toei Subway fares using ODPT station and adult IC-fare data.';

  @override
  String get passSource115 => 'Osaka Metro fares';

  @override
  String get passSource116 => 'tabiwa product details';

  @override
  String get passSource117 => 'Tokyo Metro · Toei Subway';

  @override
  String get passSource118 => 'Tokyo Subway Ticket: official information';

  @override
  String get passSource119 =>
      'Derived from Wikidata (CC0) and Wikipedia/Wikimedia operating-distance facts (CC BY-SA 4.0). Limited-express services require a separate ticket. Ropeways, discounts and benefits are excluded.';

  @override
  String get passMeta001 => 'Enoshima Electric Railway';

  @override
  String get passMeta002 => 'Enoden';

  @override
  String get passMeta003 => 'Odakyu Railway';

  @override
  String get passMeta004 => 'Odakyu Tama Line';

  @override
  String get passMeta005 => 'Odakyu Enoshima Line';

  @override
  String get passMeta006 => 'Odakyu Odawara Line';

  @override
  String get passMeta007 => 'Hankyu Railway';

  @override
  String get passMeta008 => 'JR Hokkaido';

  @override
  String get passMeta009 => 'Kyoto Municipal Subway';

  @override
  String get passMeta010 => 'Karasuma Line';

  @override
  String get passMeta011 => 'Tozai Line';

  @override
  String get passMeta012 => 'Osaka Metro';

  @override
  String get passMeta013 => 'Osaka City Bus';

  @override
  String get passMeta014 => 'Hanshin Railway';

  @override
  String get passMeta015 => 'Keihan Railway';

  @override
  String get passMeta016 => 'Kintetsu Railway';

  @override
  String get passMeta017 => 'Kintetsu Railway';

  @override
  String get passMeta018 => 'Iga Railway';

  @override
  String get passMeta019 => 'Nankai Railway';

  @override
  String get passMeta020 => 'Sapporo City Subway';

  @override
  String get passMeta021 => 'Hiroshima Electric Railway';

  @override
  String get passMeta022 => 'Nagasaki Electric Tramway';

  @override
  String get passMeta023 => 'JR West';

  @override
  String get passMeta024 => 'Yui Rail';

  @override
  String get passMeta025 => 'Hakone Tozan Railway';

  @override
  String get passMeta026 => 'Cable car';

  @override
  String get passMeta027 => 'Ropeway';

  @override
  String get passMeta028 => 'Hakone Sightseeing Cruise';

  @override
  String get passMeta029 => 'Toei Subway';

  @override
  String get passMeta030 => 'Midosuji Line';

  @override
  String get passMeta031 => 'Imazatosuji Line';

  @override
  String get passMeta032 => 'Sennichimae Line';

  @override
  String get passMeta033 => 'Yotsubashi Line';

  @override
  String get passMeta034 => 'Chuo Line';

  @override
  String get passMeta035 => 'New Tram';

  @override
  String get passMeta036 => 'Nagahori Tsurumi-ryokuchi Line';

  @override
  String get passMeta037 => 'Tanimachi Line';

  @override
  String get passMeta038 => 'Sakaisuji Line';

  @override
  String get passMeta039 => 'Nakanoshima Line';

  @override
  String get passMeta040 => 'Keihan Main Line';

  @override
  String get passMeta041 => 'Nankai Main Line';

  @override
  String get passMeta042 => 'Koya Line';

  @override
  String get passMeta043 => 'Minami Osaka Line';

  @override
  String get passMeta044 => 'Namba Line';

  @override
  String get passMeta045 => 'Takarazuka Main Line';

  @override
  String get passMeta046 => 'Kyoto Main Line';

  @override
  String get passMeta047 => 'Senri Line';

  @override
  String get passMeta048 => 'Kobe Main Line';

  @override
  String get passMeta049 => 'Hanshin Namba Line';

  @override
  String get passMeta050 => 'Main Line';

  @override
  String get passMeta051 => 'JR sections covered by the Tokunai Pass';

  @override
  String get passMeta052 => 'JR East';

  @override
  String get passMeta053 => 'Metro ↔ Toei Subway';

  @override
  String get passMeta054 => 'Okayama Electric Tramway';

  @override
  String get passMeta055 => 'Shimoden Bus: Kojima–Kurashiki';

  @override
  String get passMeta056 => 'Tokohai-go';

  @override
  String get passMeta057 => 'Jeans Bus';

  @override
  String get passMeta058 => 'Washuzan Sunset Bus';

  @override
  String get passMeta059 => 'Flat fare across the line';

  @override
  String get passMeta060 => 'Representative fare for the full route';

  @override
  String get passMeta061 => 'Representative fare';

  @override
  String get passMeta062 =>
      'Runs on Fridays, Saturdays, Sundays and public holidays';

  @override
  String get passMeta063 =>
      'Runs on Fridays, Saturdays and days before public holidays';

  @override
  String get passMeta064 => 'Karasuma / Tozai lines';
}
