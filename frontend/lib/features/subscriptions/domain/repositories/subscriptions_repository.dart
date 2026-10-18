import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscriptions_repository.g.dart';

abstract class ISubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();

  Future<Subscription> addSubscription(Subscription subscription);

  Future<Subscription> updateSubscription(Subscription subscription);

  /// Soft delete: the API keeps the row and marks it inactive.
  Future<void> removeSubscription(int id);
}

class SubscriptionRepository implements ISubscriptionRepository {
  SubscriptionRepository({required this.client});

  final Dio client;

  @override
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final result = await client.get('subscriptions/');
      final data = result.data;
      if (data is List<dynamic>) {
        return data.map((e) => Subscription.from(e)).toList();
      }

      return [];
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  @override
  Future<Subscription> addSubscription(Subscription subscription) async {
    try {
      final result = await client.post(
        'subscriptions/',
        data: subscription.toJson(),
      );
      if (result.statusCode == 201) {
        return Subscription.from(result.data as Map<String, dynamic>);
      }

      throw Exception(
        'insert unsuccessful: ${result.statusCode} ${result.statusMessage}',
      );
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  @override
  Future<Subscription> updateSubscription(Subscription subscription) async {
    try {
      final result = await client.put(
        'subscriptions/${subscription.id}/',
        data: subscription.toJson(),
      );
      if (result.statusCode != null && result.statusCode! > 299) {
        throw Exception(
          'PUT unsuccessful: ${result.statusCode} ${result.statusMessage}',
        );
      }
      return Subscription.from(result.data as Map<String, dynamic>);
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> removeSubscription(int id) async {
    try {
      final result = await client.delete('subscriptions/$id/');
      if (result.statusCode != 204) {
        throw Exception(
          'delete unsuccessful: ${result.statusCode} ${result.statusMessage}',
        );
      }
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }
}

@riverpod
ISubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(client: ref.watch(dioClientProvider));
}
