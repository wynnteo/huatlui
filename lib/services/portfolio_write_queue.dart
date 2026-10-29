import 'dart:async';

/// A small FIFO queue for all writes to the local portfolio boxes.
class PortfolioWriteQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final completed = Completer<void>();
    _tail = completed.future;
    await previous;
    try {
      return await operation();
    } finally {
      completed.complete();
    }
  }
}

/// The undo record is authoritative until the replacement is committed.
/// A committed marker must never roll back the new portfolio.
bool shouldRollbackRestoreJournal(Object? state) => state == 'prepared';
