import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class TypeFilteredConsumer<BaseType, FilterType extends BaseType> extends FilteredConsumer<BaseType> {
  TypeFilteredConsumer({Key key, @required Widget Function(BuildContext, FilterType) builder})
      : super(
          key: key,
          builder: (ctx, val) => _castBuilder<BaseType, FilterType>(ctx, val, builder),
          condition: (_, ev) => ev is FilterType,
        );

  static Widget _castBuilder<T, K extends T>(BuildContext ctx, T val, Widget Function(BuildContext, K) builder) {
    return builder(ctx, val as K);
  }
}

class FilteredConsumer<T> extends StatefulWidget implements SingleChildCloneableWidget {
  final Widget Function(BuildContext, T) builder;
  final bool Function(BuildContext, T) condition;

  const FilteredConsumer({Key key, this.builder, @required this.condition})
      : assert(condition != null),
        super(key: key);

  @override
  _FilteredConsumerState createState() => _FilteredConsumerState<T>();

  @override
  SingleChildCloneableWidget cloneWithChild(Widget child) {
    return FilteredConsumer<T>(
      key: key,
      builder: (_, __) => child,
      condition: condition,
    );
  }
}

class _FilteredConsumerState<T> extends State<FilteredConsumer<T>> {
  Widget cache;

  @override
  Widget build(BuildContext context) {
    final val = Provider.of<T>(context, listen: false);
    final shouldRebuild = cache == null || widget.condition(context, val);
    if (shouldRebuild) {
      cache = widget.builder(context, val);
    }
    return cache;
  }
}
