import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/services/portfolio_write_queue.dart';

void main() {
  test('writes run in FIFO order, never concurrently', () async {
    final queue = PortfolioWriteQueue();
    final gate = Completer<void>();
    final events = <String>[];
    final first = queue.run(() async {
      events.add('first-start');
      await gate.future;
      events.add('first-end');
    });
    final second = queue.run(() async {
      events.add('second-start');
      events.add('second-end');
    });
    await Future<void>.delayed(Duration.zero);
    expect(events, ['first-start']);
    gate.complete();
    await Future.wait([first, second]);
    expect(events, [
      'first-start', 'first-end', 'second-start', 'second-end',
    ]);
  });

  test('a failed write does not block later writes', () async {
    final queue = PortfolioWriteQueue();
    await expectLater(queue.run<void>(() async {
      throw StateError('simulated storage error');
    }), throwsStateError);
    expect(await queue.run(() async => 42), 42);
  });

  test('prepared journal rolls back; committed journal is retained', () {
    expect(shouldRollbackRestoreJournal('prepared'), isTrue);
    expect(shouldRollbackRestoreJournal('committed'), isFalse);
  });
}
