// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportNotifier)
const reportProvider = ReportNotifierProvider._();

final class ReportNotifierProvider
    extends $NotifierProvider<ReportNotifier, int> {
  const ReportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportNotifierHash();

  @$internal
  @override
  ReportNotifier create() => ReportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$reportNotifierHash() => r'1f01a58872cb92c5f66124ea4672b145f5093fb6';

abstract class _$ReportNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
