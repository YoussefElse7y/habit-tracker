// File: core/widgets/base_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

/// Base cubit class that provides common functionality for all cubits
/// This eliminates duplicate code patterns and provides consistent behavior
abstract class BaseCubit<T> extends Cubit<T> {
  BaseCubit(T initialState) : super(initialState);

  /// Safely emit a state only if the cubit is not closed
  @override
  void emit(T state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  /// Safely emit multiple states in sequence
  void emitSequence(List<T> states) {
    for (final state in states) {
      if (!isClosed) {
        super.emit(state);
      } else {
        break;
      }
    }
  }

  /// Check if the cubit is still active
  bool get isActive => !isClosed;

  /// Utility method to handle async operations with proper error handling
  Future<void> safeAsyncOperation(
    Future<void> Function() operation, {
    required T loadingState,
    required T Function(String error) errorState,
    T? successState,
  }) async {
    try {
      emit(loadingState);
      await operation();
      if (successState != null && !isClosed) {
        emit(successState);
      }
    } catch (e) {
      if (!isClosed) {
        emit(errorState(e.toString()));
      }
    }
  }

  /// Utility method to handle async operations that return a result
  Future<void> safeAsyncOperationWithResult<TResult>(
    Future<TResult> Function() operation, {
    required T loadingState,
    required T Function(String error) errorState,
    required T Function(TResult result) successState,
  }) async {
    try {
      emit(loadingState);
      final result = await operation();
      if (!isClosed) {
        emit(successState(result));
      }
    } catch (e) {
      if (!isClosed) {
        emit(errorState(e.toString()));
      }
    }
  }
}