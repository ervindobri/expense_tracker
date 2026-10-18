// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscriptions_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionRepository)
const subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          ISubscriptionRepository,
          ISubscriptionRepository,
          ISubscriptionRepository
        >
    with $Provider<ISubscriptionRepository> {
  const SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ISubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ISubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'2ddd251a733924111b9bf8207d6080c460a0b55a';
