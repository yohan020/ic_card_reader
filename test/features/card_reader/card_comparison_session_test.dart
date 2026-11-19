import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_comparison_session.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';

void main() {
  test(
    'Suica shorthand changes only display names, not the family identity',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      for (var i = 0; i < 3; i++) {
        final card = session.accept(
          _scan('suica-$i', 100, brand: CardBrandIdentity.suicaFamily),
        );
        expect(card.name, i == 0 ? '스이카' : '스이카$i');
        expect(card.brandIdentity, CardBrandIdentity.suicaFamily);
      }
      session.rename(1, '내 카드');
      expect(
        session
            .accept(_scan('suica-0', 200, brand: CardBrandIdentity.suicaFamily))
            .name,
        '내 카드',
      );
    },
  );
  test(
    'brand names use independent suffixes and the same card never consumes one',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      session.accept(_scan('a', 900, brand: CardBrandIdentity.icoca));
      session.accept(_scan('b', 800, brand: CardBrandIdentity.icoca));
      session.accept(_scan('c', 700, brand: CardBrandIdentity.pasmo));
      session.accept(_scan('a', 1000, brand: CardBrandIdentity.icoca));
      session.accept(_scan('d', 600, brand: CardBrandIdentity.icoca));
      session.accept(_scan('e', 500, brand: CardBrandIdentity.pasmo));
      expect(session.cards.map((card) => card.name), [
        '이코카',
        '이코카1',
        '파스모',
        '이코카2',
        '파스모1',
      ]);
      expect(session.cards.first.balance, 1000);
      expect(session.cards.first.result.brandIdentity, CardBrandIdentity.icoca);
      expect(session.cards.first.result.comparisonToken, isNull);
      expect(session.cards.first.result.diagnosticReport, isNull);
    },
  );

  test(
    'renames and deletion preserve identities, suffixes and collision avoidance',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final a = session.accept(_scan('a', 100, brand: CardBrandIdentity.icoca));
      session.rename(a.id, '이코카1');
      final b = session.accept(_scan('b', 200, brand: CardBrandIdentity.icoca));
      expect(b.name, '이코카2');
      session.remove(b.id);
      expect(
        session.accept(_scan('c', 300, brand: CardBrandIdentity.icoca)).name,
        '이코카3',
      );
      final updated = session.accept(_scan('a', 400));
      expect(updated.name, '이코카1');
      expect(updated.isNameCustomized, isTrue);
      expect(updated.brandIdentity, CardBrandIdentity.icoca);
      expect(updated.balance, 400);
    },
  );

  test('late identification upgrades only automatic unknown names', () {
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    final a = session.accept(_scan('a', 100));
    final b = session.accept(_scan('b', 200));
    session.rename(b.id, '엄마 카드');
    expect(
      session.accept(_scan('a', 300, brand: CardBrandIdentity.pasmo)).name,
      '파스모',
    );
    final updated = session.accept(
      _scan('b', 400, brand: CardBrandIdentity.pasmo),
    );
    expect(updated.name, '엄마 카드');
    expect(updated.brandIdentity, CardBrandIdentity.pasmo);
    expect(updated.id, b.id);
    expect(session.cards.first.id, a.id);
    expect(
      session.accept(_scan('c', 500, brand: CardBrandIdentity.pasmo)).name,
      '파스모2',
    );
  });

  test(
    'first known brand survives missing or contradictory optional metadata',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      session.accept(_scan('a', 100, brand: CardBrandIdentity.toica));
      for (final brand in [null, CardBrandIdentity.icoca]) {
        final updated = session.accept(_scan('a', 200, brand: brand));
        expect(updated.name, '토이카');
        expect(updated.brandIdentity, CardBrandIdentity.toica);
      }
    },
  );

  test('all supported names stay coarse, and clear resets brand suffixes', () {
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    for (final brand in CardBrandIdentity.values) {
      final card = session.accept(_scan(brand.name, 100, brand: brand));
      expect(card.name, brand.label);
      expect(card.brandIdentity, brand);
    }
    expect(session.cards.length, 10);
    expect(session.cards.first.name, '스이카');
    session.clear();
    expect(
      session.accept(_scan('new', 200, brand: CardBrandIdentity.icoca)).name,
      '이코카',
    );
    expect(session.cards.single.id, 1);
  });

  test(
    'unknown fallback avoids custom name collisions without consuming brand numbers',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final first = session.accept(_scan('a', 100));
      session.rename(first.id, '카드 2');
      expect(session.accept(_scan('b', 100)).name, '카드 3');
      expect(session.accept(_scan('c', 100)).name, '카드 4');
      expect(
        session.accept(_scan('d', 100, brand: CardBrandIdentity.icoca)).name,
        '이코카',
      );
    },
  );

  test(
    'rejected updates and capacity limits do not consume names or overwrite brand',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      for (var i = 0; i < 10; i++) {
        session.accept(_scan('$i', 100, brand: CardBrandIdentity.icoca));
      }
      expect(
        () =>
            session.accept(_scan('extra', 100, brand: CardBrandIdentity.icoca)),
        throwsA(isA<CardComparisonException>()),
      );
      expect(
        () => session.accept(
          _scan('wrong', 100, brand: CardBrandIdentity.pasmo),
          replacingId: 1,
        ),
        throwsA(isA<CardComparisonException>()),
      );
      session.remove(2);
      expect(
        session
            .accept(_scan('extra', 200, brand: CardBrandIdentity.icoca))
            .name,
        '이코카10',
      );
      expect(session.cards.first.name, '이코카');
      expect(session.cards.first.brandIdentity, CardBrandIdentity.icoca);
    },
  );
  test(
    'identity is repeatable only within one session and contains no raw IDm',
    () {
      final first = CardComparisonSession();
      final other = CardComparisonSession();
      addTearDown(first.dispose);
      addTearDown(other.dispose);
      final idm = List.generate(8, (i) => i + 1);
      final token = comparisonTokenFor(idm, first.sessionKey);
      expect(token, comparisonTokenFor(idm, first.sessionKey));
      expect(token, isNot(comparisonTokenFor(idm, other.sessionKey)));
      expect(token.length, 64);
      final key = first.sessionKey;
      first.clear();
      expect(first.sessionKey, isNot(key));
      expect(comparisonTokenFor(idm, first.sessionKey), isNot(token));
      expect(
        () => comparisonTokenFor([], first.sessionKey),
        throwsArgumentError,
      );
    },
  );

  test(
    'same card updates balance and detail snapshot, preserving name and order',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final a = session.accept(_scan('a', 1200));
      session.accept(_scan('b', 800));
      session.rename(a.id, '엄마 카드');
      final updated = session.accept(_scan('a', 0));
      expect(updated.id, a.id);
      expect(session.cards.map((e) => e.name), ['엄마 카드', '카드 2']);
      expect(updated.balance, 0);
      expect(updated.result.comparisonToken, isNull);
      expect(updated.result.blocks.first.bytes[10], 0);
    },
  );

  test('equal balances on different cards are not merged', () {
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    session.accept(_scan('a', 900));
    session.accept(_scan('b', 900));
    expect(session.cards.length, 2);
  });

  test(
    'missing balance or identity and wrong targeted card never overwrite data',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final a = session.accept(_scan('a', 900));
      expect(
        () => session.accept(_scan('b', 100), replacingId: a.id),
        throwsA(isA<CardComparisonException>()),
      );
      expect(
        () => session.accept(
          CardScanResult(
            scannedAt: DateTime(2026),
            blocks: const [],
            comparisonToken: 'a',
          ),
        ),
        throwsA(isA<CardComparisonException>()),
      );
      expect(
        () => session.accept(
          CardScanResult(
            scannedAt: DateTime(2026),
            blocks: _scan('b', 100).blocks,
          ),
        ),
        throwsA(isA<CardComparisonException>()),
      );
      expect(session.cards.single.balance, 900);
      expect(session.cards.single.name, '카드 1');
    },
  );

  test('ten-card limit still allows updates, deletion and new additions', () {
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    for (var i = 0; i < 10; i++) {
      session.accept(_scan('$i', 100));
    }
    expect(
      () => session.accept(_scan('eleven', 100)),
      throwsA(isA<CardComparisonException>()),
    );
    session.accept(_scan('0', 200), replacingId: 1);
    expect(session.cards.first.balance, 200);
    session.remove(2);
    expect(session.accept(_scan('new', 300)).name, '카드 11');
    expect(session.cards.length, 10);
  });

  test(
    'empty rename is ignored and snapshots do not alias mutable source bytes',
    () {
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final scan = _scan('a', 1200);
      final a = session.accept(scan);
      session.rename(a.id, '   ');
      scan.blocks.first.bytes[10] = 0;
      expect(session.cards.single.name, '카드 1');
      expect(session.cards.single.result.blocks.first.bytes[10], 1200 & 255);
      session.clear();
      expect(session.cards, isEmpty);
      session.dispose();
      expect(session.cards, isEmpty);
      expect(session.sessionKey.every((v) => v == 0), isTrue);
      expect(() => session.accept(_scan('a', 100)), throwsStateError);
    },
  );
}

CardScanResult _scan(String token, int balance, {CardBrandIdentity? brand}) {
  final bytes = Uint8List(16)
    ..[0] = 0x16
    ..[1] = 0x01
    ..[10] = balance & 255
    ..[11] = balance >> 8;
  return CardScanResult(
    scannedAt: DateTime(2026, 10, 23),
    blocks: [RawHistoryBlock(index: 0, bytes: bytes)],
    comparisonToken: token,
    brandIdentity: brand,
  );
}
