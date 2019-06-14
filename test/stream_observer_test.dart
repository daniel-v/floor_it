import 'dart:async';

import 'package:floor_it/stream_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

main() {
  group('StreamObserver', () {
    testWidgets('onWaiting displayed', (tester) async {
      final widget = StreamObserver<String>(
        stream: Stream.empty(),
        onSuccess: (_, __) => Text(''),
        onWaiting: (_) => Text('waiting'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      expect(find.text('waiting'), findsOneWidget);
    });
    testWidgets('onSuccess displayed', (tester) async {
      final widget = StreamObserver<String>(
        stream: Stream.fromIterable(['success']),
        onSuccess: (_, data) => Text('$data'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      await tester.pump();
      expect(find.text('success'), findsOneWidget);
    });
    testWidgets('onError displayed', (tester) async {
      final widget = StreamObserver<String>(
        stream: Stream.fromFuture(Future.error('dang!')),
        onSuccess: (_, __) => Text(''),
        onError: (err) => Text('$err'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      await tester.pump();
      expect(find.text('dang!'), findsOneWidget);
    });
    testWidgets('onWaiting then onSuccess displayed', (tester) async {
      final widget = StreamObserver<String>(
        stream: Stream.fromIterable(['success']),
        onWaiting: (_) => Text('waiting'),
        onSuccess: (_, data) => Text('$data'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      expect(find.text('waiting'), findsOneWidget);
      await tester.pump();
      expect(find.text('success'), findsOneWidget);
    });
    testWidgets('onWaiting then onError displayed', (tester) async {
      final widget = StreamObserver<String>(
        stream: Stream.fromFuture(Future.error('dang!')),
        onWaiting: (_) => Text('waiting'),
        onSuccess: (_, data) {},
        onError: (err) => Text('$err'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      expect(find.text('waiting'), findsOneWidget);
      await tester.pump();
      expect(find.text('dang!'), findsOneWidget);
    });
    testWidgets('onWaiting displayed when closing stream', (tester) async {
      final stream = PublishSubject<String>();
      final widget = StreamObserver<String>(
        stream: stream,
        onWaiting: (state) => Text('$state'),
        onSuccess: (_, __) {},
      );
      await tester.pumpWidget(wrapInApp(widget));
      expect(find.text('ConnectionState.waiting'), findsOneWidget);
      await stream.close();
      await tester.pump();
      expect(find.text('ConnectionState.done'), findsOneWidget);
    });
  });
  group('StreamObserver custom', () {
    testWidgets('custom', (tester) async {
      final widget = StreamObserver<String>.custom(
        stream: Stream.fromIterable(['a']),
        transformer: (s) => s.map((v) => '$v$v'),
        onSuccess: (_, data) => Text('$data'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      await tester.pump();
      expect(find.text('aa'), findsOneWidget);
    });
    testWidgets('distinct', (tester) async {
      final subject = PublishSubject<int>();
      int cbCount = 0;
      final widget = StreamObserver<int>.distinct(
        stream: subject,
        onSuccess: (_, data) {
          ++cbCount;
          return Text('$data');
        },
        onWaiting: (_) => Text('waiting'),
      );
      await tester.pumpWidget(wrapInApp(widget));
      subject.add(1);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(cbCount, 1);
      // readd the same value
      subject.add(1);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(cbCount, 1);
      // change value
      subject.add(2);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(cbCount, 2);
      await subject.close();
    });
  });
}

Widget wrapInApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      body: widget,
    ),
  );
}
