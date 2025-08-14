
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // Check internet connection
    if (await networkInfo.isConnected) {
      try {
        // Register with remote data source (Firebase)
        final userModel = await remoteDataSource.registerWithEmail(
          email: email,
          password: password,
          name: name,
        );

        // Cache user locally for offline access
        await localDataSource.cacheUser(userModel);

        // Return success with User entity
        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error during registration: ${e.toString()}'));
      }
    } else {
      // No internet connection
      return const Left(ConnectionFailure('No internet connection available'));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Login with remote data source
        final userModel = await remoteDataSource.loginWithEmail(
          email: email,
          password: password,
        );

        // Cache user locally
        await localDataSource.cacheUser(userModel);

        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error during login: ${e.toString()}'));
      }
    } else {
      // Try to get cached user for offline login (limited functionality)
      try {
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null && cachedUser.email == email) {
          // Note: We can't verify password offline, so this is just basic cached access
          return Right(cachedUser);
        } else {
          return const Left(ConnectionFailure('No internet connection and no valid cached user'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.loginWithGoogle();
        
        // Cache user locally
        await localDataSource.cacheUser(userModel);

        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error during Google login: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required for Google sign-in'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // First try to get user from remote (if connected)
      if (await networkInfo.isConnected) {
        try {
          final remoteUser = await remoteDataSource.getCurrentUser();
          if (remoteUser != null) {
            // Update cache with latest data
            await localDataSource.cacheUser(remoteUser);
            return Right(remoteUser);
          }
        } on AuthException catch (e) {
          // If remote fails, fall back to cache
          print('Remote getCurrentUser failed: ${e.message}, trying cache...');
        }
      }

      // Fallback to cached user
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting current user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Always clear local data first
      await localDataSource.clearAllAuthData();

      // Try to logout from remote if connected
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
          // Don't fail logout if remote logout fails
          print('Remote logout failed: ${e.toString()}, but local data cleared');
        }
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure('Failed to clear local data: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error during logout: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPasswordResetEmail(email);
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error sending password reset: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required for password reset'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendEmailVerification();
        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error sending email verification: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required for email verification'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedUser = await remoteDataSource.updateProfile(
          name: name,
          profileImageUrl: profileImageUrl,
        );

        // Update cache
        await localDataSource.cacheUser(updatedUser);

        return Right(updatedUser);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error updating profile: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required to update profile'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (await networkInfo.isConnected) {
      try {
        // Delete from remote first
        await remoteDataSource.deleteAccount();
        
        // Clear local data
        await localDataSource.clearAllAuthData();

        return const Right(null);
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Unexpected error deleting account: ${e.toString()}'));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required to delete account'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      // Check if we have a current user (either remote or cached)
      final userResult = await getCurrentUser();
      return userResult.fold(
        (failure) => false,
        (user) => user != null,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    // Return the stream from remote data source
    // This will emit changes when user logs in/out
    return remoteDataSource.authStateChanges;
  }
}