import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../transaction_history/data/transit_history_parser.dart';
import 'card_brand_identity.dart';
import 'card_scan_result.dart';
import 'raw_history_block.dart';

/// No stable digest of the IDm is retained. A new random key changes the token.
String comparisonTokenFor(List<int> idm, List<int> sessionKey) {
  if (idm.length != 8 || sessionKey.length != 32) {
    throw ArgumentError('Invalid comparison identity input lengths');
  }
  return Hmac(sha256, sessionKey).convert(idm).toString();
}

enum CardComparisonFailure {
  unidentified,
  balanceUnavailable,
  differentCard,
  limit,
}

class CardComparisonException implements Exception {
  const CardComparisonException(this.kind, this.message);
  final CardComparisonFailure kind;
  final String message;
  @override
  String toString() => message;
}

class ComparedCard {
  const ComparedCard._({
    required this.id,
    required this.name,
    required this.balance,
    required this.result,
    this.isNameCustomized = false,
    required String token,
  }) : _token = token;

  final int id;
  final String name;
  final int balance;
  final CardScanResult result;
  final bool isNameCustomized;
  CardBrandIdentity? get brandIdentity => result.brandIdentity;
  final String _token;
}

/// Route-owned memory only; deliberately has no persistence or JSON API.
class CardComparisonSession {
  static const maxCards = 10;
  final _cards = <ComparedCard>[];
  final _nextBrandSuffix = <CardBrandIdentity, int>{};
  Uint8List _key = _newKey();
  int _nextId = 1;
  bool _disposed = false;

  static Uint8List _newKey() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  List<ComparedCard> get cards => List.unmodifiable(_cards);
  List<int> get sessionKey => List.unmodifiable(_key);

  ComparedCard accept(CardScanResult result, {int? replacingId}) {
    if (_disposed) throw StateError('Comparison session is closed');
    final token = result.comparisonToken;
    if (token == null || token.isEmpty) {
      throw const CardComparisonException(
        CardComparisonFailure.unidentified,
        '카드를 구분하지 못했어요. 다시 스캔해 주세요.',
      );
    }
    final balance = const TransitHistoryParser().currentBalance(result.blocks);
    if (balance == null) {
      throw const CardComparisonException(
        CardComparisonFailure.balanceUnavailable,
        '잔액을 확인하지 못했어요. 카드를 다시 스캔해 주세요.',
      );
    }
    final index = _cards.indexWhere((card) => card._token == token);
    if (replacingId != null) {
      final target = _cards.indexWhere((card) => card.id == replacingId);
      if (target < 0 || index != target) {
        throw const CardComparisonException(
          CardComparisonFailure.differentCard,
          '선택한 카드와 다른 카드예요. 기존 카드를 다시 대 주세요.',
        );
      }
    }
    if (index < 0 && _cards.length >= maxCards) {
      throw const CardComparisonException(
        CardComparisonFailure.limit,
        '카드는 최대 10장까지 비교할 수 있어요.',
      );
    }
    final previous = index < 0 ? null : _cards[index];
    final id = previous?.id ?? _nextId++;
    // A later optional lookup failure must not erase an established display.
    // If two successful lookups disagree, retain the first known brand rather
    // than silently changing an existing card's identity or customized name.
    final brand = previous?.brandIdentity ?? result.brandIdentity;
    final newlyIdentified = previous?.brandIdentity == null && brand != null;
    // Count a newly identified card even when its custom name is preserved.
    final generatedName = previous == null || newlyIdentified
        ? _automaticName(brand, id)
        : null;
    final name = previous?.isNameCustomized == true
        ? previous!.name
        : generatedName ?? previous!.name;
    // Retain coarse display metadata and copied history, never the HMAC token
    // or diagnostic payload in a detail snapshot.
    final snapshot = CardScanResult(
      scannedAt: result.scannedAt,
      blocks: List.unmodifiable([
        for (final block in result.blocks)
          RawHistoryBlock(
            index: block.index,
            format: block.format,
            bytes: Uint8List.fromList(block.bytes),
          ),
      ]),
      currentGateTravel: result.currentGateTravel,
      brandIdentity: brand,
    );
    final card = ComparedCard._(
      id: id,
      name: name,
      balance: balance,
      result: snapshot,
      isNameCustomized: previous?.isNameCustomized ?? false,
      token: token,
    );
    if (index < 0) {
      _cards.add(card);
    } else {
      _cards[index] = card;
    }
    return card;
  }

  String _automaticName(CardBrandIdentity? brand, int id) {
    final occupied = _cards
        .where((card) => card.id != id)
        .map((card) => card.name)
        .toSet();
    if (brand == null) {
      var number = id;
      while (occupied.contains('카드 $number')) {
        number++;
      }
      return '카드 $number';
    }
    var suffix = _nextBrandSuffix[brand] ?? 0;
    String candidate() => suffix == 0 ? brand.label : '${brand.label}$suffix';
    while (occupied.contains(candidate())) {
      suffix++;
    }
    final name = candidate();
    _nextBrandSuffix[brand] = suffix + 1;
    return name;
  }

  void rename(int id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.runes.length > 24) return;
    final index = _cards.indexWhere((card) => card.id == id);
    if (index < 0) return;
    final card = _cards[index];
    _cards[index] = ComparedCard._(
      id: card.id,
      name: trimmed,
      balance: card.balance,
      result: card.result,
      isNameCustomized: true,
      token: card._token,
    );
  }

  void remove(int id) => _cards.removeWhere((card) => card.id == id);

  void clear() {
    _cards.clear();
    _nextBrandSuffix.clear();
    _key.fillRange(0, _key.length, 0);
    if (!_disposed) _key = _newKey();
    _nextId = 1;
  }

  void dispose() {
    _disposed = true;
    clear();
  }
}
