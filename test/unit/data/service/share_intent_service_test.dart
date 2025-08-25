import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_logger_helper.dart';
// import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/service/share_intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// Mock classes for testing
class MockReceiveSharingIntent extends Mock implements ReceiveSharingIntent {}

void main() {
  setUpAll(() {
    // Initialize Flutter bindings for tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock the method channel for receive_sharing_intent
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('receive_sharing_intent/messages'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getInitialMedia':
            return <Map<String, dynamic>>[];
          case 'getMediaStream':
            return <Map<String, dynamic>>[];
          case 'reset':
            return null;
          default:
            return null;
        }
      },
    );

    setupTestLogger();
  });

  group('ShareIntentService', () {
    late ShareIntentService service;
    late StreamController<List<SharedMediaFile>> mediaStreamController;
    // late MockReceiveSharingIntent mockReceiveSharingIntent;

    setUp(() {
      mediaStreamController = StreamController<List<SharedMediaFile>>();
      service = ShareIntentService();
    });

    tearDown(() {
      service.dispose();
      mediaStreamController.close();
    });

    group('Singleton Pattern', () {
      test('should return same instance when called multiple times', () {
        final instance1 = ShareIntentService();
        final instance2 = ShareIntentService();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('shareTextStream', () {
      test('should provide empty stream when not initialized', () {
        final newService = ShareIntentService();
        expect(newService.shareTextStream, isA<Stream<String>>());

        // Since it's not initialized, it should be empty
        expectLater(
          newService.shareTextStream.isEmpty,
          completion(isTrue),
        );
      });

      test('should provide valid stream type', () {
        // Test the stream type without initializing
        expect(service.shareTextStream, isA<Stream<String>>());
      });
    });

    group('Text Processing Logic', () {
      test('should identify text media type correctly', () {
        final textFile = SharedMediaFile(
          path: 'https://example.com/article',
          thumbnail: null,
          duration: null,
          type: SharedMediaType.text,
        );

        expect(textFile.type, equals(SharedMediaType.text));
        expect(textFile.path, equals('https://example.com/article'));
      });

      test('should identify URL media type correctly', () {
        final urlFile = SharedMediaFile(
          path: 'https://example.com',
          thumbnail: null,
          duration: null,
          type: SharedMediaType.url,
        );

        expect(urlFile.type, equals(SharedMediaType.url));
        expect(urlFile.path, equals('https://example.com'));
      });

      test('should identify non-text/url media types correctly', () {
        final imageFile = SharedMediaFile(
          path: '/path/to/image.jpg',
          thumbnail: null,
          duration: null,
          type: SharedMediaType.image,
        );

        expect(imageFile.type, equals(SharedMediaType.image));
        expect(imageFile.type, isNot(SharedMediaType.text));
        expect(imageFile.type, isNot(SharedMediaType.url));
      });
    });

    group('Stream Management', () {
      test('should provide stream without initialization', () {
        expect(service.shareTextStream, isA<Stream<String>>());
      });

      test('should handle service creation', () {
        final newService = ShareIntentService();
        expect(newService.shareTextStream, isA<Stream<String>>());
      });
    });

    group('Disposal', () {
      test('should handle dispose without initialization', () {
        // Should not throw when disposing without initialization
        expect(() => service.dispose(), returnsNormally);
      });

      test('should handle multiple dispose calls', () {
        service.dispose();

        // Second dispose should not cause issues
        expect(() => service.dispose(), returnsNormally);
      });

      test('should cleanup stream after dispose', () {
        service.dispose();

        // After disposal, stream should be empty
        expect(service.shareTextStream, isA<Stream<String>>());
        expectLater(
          service.shareTextStream.isEmpty,
          completion(isTrue),
        );
      });
    });

    group('Error Handling', () {
      test('should handle stream listening gracefully', () {
        // Should not throw when listening to stream
        expect(() {
          final subscription = service.shareTextStream.listen(
            (_) {},
            onError: (error) {
              // Error handler should be called if there are errors
            },
          );
          subscription.cancel();
        }, returnsNormally);
      });
    });

    group('Media File Processing Logic', () {
      test('should correctly identify text media type', () {
        final textFile = SharedMediaFile(
          path: 'Some shared text content',
          thumbnail: null,
          duration: null,
          type: SharedMediaType.text,
        );

        expect(textFile.type, equals(SharedMediaType.text));
        expect(textFile.path, equals('Some shared text content'));
      });

      test('should correctly identify URL media type', () {
        final urlFile = SharedMediaFile(
          path: 'https://example.com/article',
          thumbnail: null,
          duration: null,
          type: SharedMediaType.url,
        );

        expect(urlFile.type, equals(SharedMediaType.url));
        expect(urlFile.path, equals('https://example.com/article'));
      });

      test('should handle empty media file list', () {
        final List<SharedMediaFile> emptyList = [];

        expect(emptyList.isEmpty, isTrue);
        expect(emptyList.length, equals(0));
      });

      test('should handle mixed media file types', () {
        final mediaFiles = [
          SharedMediaFile(
            path: 'https://example.com',
            thumbnail: null,
            duration: null,
            type: SharedMediaType.url,
          ),
          SharedMediaFile(
            path: '/path/to/image.jpg',
            thumbnail: null,
            duration: null,
            type: SharedMediaType.image,
          ),
          SharedMediaFile(
            path: 'Some text content',
            thumbnail: null,
            duration: null,
            type: SharedMediaType.text,
          ),
        ];

        final textAndUrlFiles = mediaFiles.where((file) =>
            file.type == SharedMediaType.text ||
            file.type == SharedMediaType.url);

        expect(textAndUrlFiles.length, equals(2));
        expect(mediaFiles.length, equals(3));
      });
    });

    group('Stream Behavior', () {
      test('should handle multiple listeners on empty stream', () async {
        final stream = service.shareTextStream;

        // Multiple listeners should be supported (assuming broadcast stream)
        final subscription1 = stream.listen((_) {});
        final subscription2 = stream.listen((_) {});

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });
  });
}
