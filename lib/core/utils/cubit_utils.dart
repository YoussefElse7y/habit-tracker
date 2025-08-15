// File: core/utils/cubit_utils.dart

import 'package:flutter_bloc/flutter_bloc.dart';

/// Utility class for common cubit operations
/// This helps eliminate duplicate code patterns across different cubits
class CubitUtils {
  /// Safely emit a state only if the cubit is not closed
  static void safeEmit<T>(Cubit<T> cubit, T state) {
    if (!cubit.isClosed) {
      cubit.emit(state);
    }
  }

  /// Safely emit multiple states in sequence
  static void safeEmitSequence<T>(Cubit<T> cubit, List<T> states) {
    for (final state in states) {
      if (!cubit.isClosed) {
        cubit.emit(state);
      } else {
        break;
      }
    }
  }

  /// Check if a cubit is still active
  static bool isActive<T>(Cubit<T> cubit) => !cubit.isClosed;

  /// Utility method to handle async operations with proper error handling
  static Future<void> safeAsyncOperation<T>(
    Cubit<T> cubit,
    Future<void> Function() operation, {
    required T loadingState,
    required T Function(String error) errorState,
    T? successState,
  }) async {
    try {
      safeEmit(cubit, loadingState);
      await operation();
      if (successState != null && isActive(cubit)) {
        safeEmit(cubit, successState);
      }
    } catch (e) {
      if (isActive(cubit)) {
        safeEmit(cubit, errorState(e.toString()));
      }
    }
  }

  /// Utility method to handle async operations that return a result
  static Future<void> safeAsyncOperationWithResult<T, TResult>(
    Cubit<T> cubit,
    Future<TResult> Function() operation, {
    required T loadingState,
    required T Function(String error) errorState,
    required T Function(TResult result) successState,
  }) async {
    try {
      safeEmit(cubit, loadingState);
      final result = await operation();
      if (isActive(cubit)) {
        safeEmit(cubit, successState(result));
      }
    } catch (e) {
      if (isActive(cubit)) {
        safeEmit(cubit, errorState(e.toString()));
      }
    }
  }

  /// Utility method to handle async operations with Result pattern (dartz)
  static Future<void> safeAsyncOperationWithResultPattern<T, TResult>(
    Cubit<T> cubit,
    Future<Either<Failure, TResult>> Function() operation, {
    required T loadingState,
    required T Function(String error) errorState,
    required T Function(TResult result) successState,
  }) async {
    try {
      safeEmit(cubit, loadingState);
      final result = await operation();
      result.fold(
        (failure) {
          if (isActive(cubit)) {
            safeEmit(cubit, errorState(failure.message));
          }
        },
        (success) {
          if (isActive(cubit)) {
            safeEmit(cubit, successState(success));
          }
        },
      );
    } catch (e) {
      if (isActive(cubit)) {
        safeEmit(cubit, errorState(e.toString()));
      }
    }
  }

  /// Debounce function to prevent rapid state emissions
  static Timer? debounce<T>(
    Cubit<T> cubit,
    T state,
    Duration duration,
  ) {
    return Timer(duration, () {
      if (isActive(cubit)) {
        safeEmit(cubit, state);
      }
    });
  }

  /// Throttle function to limit state emissions
  static bool _throttleMap = <Cubit, DateTime>{};
  static bool throttle<T>(
    Cubit<T> cubit,
    Duration duration,
  ) {
    final now = DateTime.now();
    final lastEmit = _throttleMap[cubit];
    
    if (lastEmit == null || now.difference(lastEmit) >= duration) {
      _throttleMap[cubit] = now;
      return true;
    }
    return false;
  }
}

/// Import for the Failure class from dartz
import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import 'dart:async';