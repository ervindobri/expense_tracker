// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscriptions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptions)
const subscriptionsProvider = SubscriptionsProvider._();

final class SubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          FutureOr<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $FutureProvider<List<Subscription>> {
  const SubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Subscription>> create(Ref ref) {
    return subscriptions(ref);
  }
}

String _$subscriptionsHash() => r'8470487cf53b2a0f32fe3e26f33facb4416ddc96';

/// Active subscriptions, soonest renewal first.

@ProviderFor(activeSubscriptions)
const activeSubscriptionsProvider = ActiveSubscriptionsProvider._();

/// Active subscriptions, soonest renewal first.

final class ActiveSubscriptionsProvider
    extends
        $FunctionalProvider<
          List<Subscription>,
          List<Subscription>,
          List<Subscription>
        >
    with $Provider<List<Subscription>> {
  /// Active subscriptions, soonest renewal first.
  const ActiveSubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSubscriptionsHash();

  @$internal
  @override
  $ProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Subscription> create(Ref ref) {
    return activeSubscriptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Subscription> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Subscription>>(value),
    );
  }
}

String _$activeSubscriptionsHash() =>
    r'90cac9f565a31bc4204b98adcaef0dbde3cbcf8a';

@ProviderFor(inactiveSubscriptions)
const inactiveSubscriptionsProvider = InactiveSubscriptionsProvider._();

final class InactiveSubscriptionsProvider
    extends
        $FunctionalProvider<
          List<Subscription>,
          List<Subscription>,
          List<Subscription>
        >
    with $Provider<List<Subscription>> {
  const InactiveSubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inactiveSubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inactiveSubscriptionsHash();

  @$internal
  @override
  $ProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Subscription> create(Ref ref) {
    return inactiveSubscriptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Subscription> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Subscription>>(value),
    );
  }
}

String _$inactiveSubscriptionsHash() =>
    r'1464e80054f43a7a55cfcb373a2ef4f96c01bd0e';

@ProviderFor(renewingSoon)
const renewingSoonProvider = RenewingSoonProvider._();

final class RenewingSoonProvider
    extends
        $FunctionalProvider<
          List<Subscription>,
          List<Subscription>,
          List<Subscription>
        >
    with $Provider<List<Subscription>> {
  const RenewingSoonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renewingSoonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renewingSoonHash();

  @$internal
  @override
  $ProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Subscription> create(Ref ref) {
    return renewingSoon(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Subscription> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Subscription>>(value),
    );
  }
}

String _$renewingSoonHash() => r'a83223e772712c1b713b02495a8fc152fe630110';

@ProviderFor(subscriptionSummary)
const subscriptionSummaryProvider = SubscriptionSummaryProvider._();

final class SubscriptionSummaryProvider
    extends
        $FunctionalProvider<
          SubscriptionSummary,
          SubscriptionSummary,
          SubscriptionSummary
        >
    with $Provider<SubscriptionSummary> {
  const SubscriptionSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionSummaryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionSummary> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionSummary create(Ref ref) {
    return subscriptionSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionSummary>(value),
    );
  }
}

String _$subscriptionSummaryHash() =>
    r'694515c6a11ac9173e822e9c76a74ed816d945fc';
