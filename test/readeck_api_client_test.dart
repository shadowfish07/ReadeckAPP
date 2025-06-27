import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import '../lib/data/service/readeck_api_client.dart';
import '../lib/domain/model/bookmark.dart';
import '../lib/domain/model/collection.dart';
import '../lib/domain/model/tag.dart';

// Generate mocks for dependencies
@GenerateMocks([Dio])
import 'readeck_api_client_test.mocks.dart';

void main() {
  group('ReadeckApiClient', () {
    late ReadeckApiClient apiClient;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiClient = ReadeckApiClient(mockDio);
    });

    tearDown(() {
      reset(mockDio);
    });

    group('getBookmarks', () {
      test('should return list of bookmarks with all parameters', () async {
        // Arrange
        final responseData = {
          'bookmarks': [
            {
              'id': '1',
              'url': 'https://example.com',
              'title': 'Example',
              'description': 'Test bookmark',
              'tags': ['test', 'example'],
              'collection_id': 'col1',
              'archived': false,
              'created_at': '2023-01-01T00:00:00.000Z',
              'updated_at': '2023-01-01T00:00:00.000Z',
            },
            {
              'id': '2',
              'url': 'https://flutter.dev',
              'title': 'Flutter',
              'description': 'Flutter framework',
              'tags': ['flutter', 'development'],
              'collection_id': null,
              'archived': false,
              'created_at': '2023-01-02T00:00:00.000Z',
              'updated_at': '2023-01-02T00:00:00.000Z',
            },
          ]
        };

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        final result = await apiClient.getBookmarks(
          page: 1,
          limit: 10,
          search: 'flutter',
          tags: ['development'],
          collectionId: 'col1',
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals('1'));
        expect(result[0].url, equals('https://example.com'));
        expect(result[0].title, equals('Example'));
        expect(result[0].tags, equals(['test', 'example']));
        expect(result[1].id, equals('2'));
        expect(result[1].url, equals('https://flutter.dev'));

        verify(mockDio.get('/bookmarks', queryParameters: {
          'page': 1,
          'limit': 10,
          'search': 'flutter',
          'tags': 'development',
          'collection_id': 'col1',
        })).called(1);
      });

      test('should return bookmarks with minimal parameters', () async {
        // Arrange
        final responseData = {
          'bookmarks': [
            {
              'id': '1',
              'url': 'https://example.com',
              'title': null,
              'description': null,
              'tags': <String>[],
              'collection_id': null,
              'archived': false,
              'created_at': '2023-01-01T00:00:00.000Z',
              'updated_at': '2023-01-01T00:00:00.000Z',
            },
          ]
        };

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, equals('1'));
        expect(result[0].title, isNull);
        expect(result[0].tags, isEmpty);

        verify(mockDio.get('/bookmarks', queryParameters: {})).called(1);
      });

      test('should handle empty bookmarks list', () async {
        // Arrange
        final responseData = {'bookmarks': <Map<String, dynamic>>[]};

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result, isEmpty);
      });

      test('should handle multiple tags correctly', () async {
        // Arrange
        final responseData = {'bookmarks': <Map<String, dynamic>>[]};

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        await apiClient.getBookmarks(tags: ['tag1', 'tag2', 'tag3']);

        // Assert
        verify(mockDio.get('/bookmarks', queryParameters: {
          'tags': 'tag1,tag2,tag3',
        })).called(1);
      });

      test('should handle empty tags list', () async {
        // Arrange
        final responseData = {'bookmarks': <Map<String, dynamic>>[]};

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        await apiClient.getBookmarks(tags: []);

        // Assert
        verify(mockDio.get('/bookmarks', queryParameters: {})).called(1);
      });

      test('should throw DioException on network error', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getBookmark', () {
      test('should return single bookmark by id', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': 'Example',
          'description': 'Test bookmark',
          'tags': ['test'],
          'collection_id': 'col1',
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.get('/bookmarks/1'))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks/1'),
                ));

        // Act
        final result = await apiClient.getBookmark('1');

        // Assert
        expect(result.id, equals('1'));
        expect(result.url, equals('https://example.com'));
        expect(result.title, equals('Example'));
        verify(mockDio.get('/bookmarks/1')).called(1);
      });

      test('should throw DioException when bookmark not found', () async {
        // Arrange
        when(mockDio.get('/bookmarks/nonexistent'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmark('nonexistent'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('createBookmark', () {
      test('should create bookmark with all parameters', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': 'Example',
          'description': 'Test bookmark',
          'tags': ['test', 'example'],
          'collection_id': 'col1',
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/bookmarks', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        final result = await apiClient.createBookmark(
          url: 'https://example.com',
          title: 'Example',
          description: 'Test bookmark',
          tags: ['test', 'example'],
          collectionId: 'col1',
        );

        // Assert
        expect(result.id, equals('1'));
        expect(result.url, equals('https://example.com'));
        expect(result.title, equals('Example'));

        verify(mockDio.post('/bookmarks', data: {
          'url': 'https://example.com',
          'title': 'Example',
          'description': 'Test bookmark',
          'tags': ['test', 'example'],
          'collection_id': 'col1',
        })).called(1);
      });

      test('should create bookmark with minimal parameters', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': null,
          'description': null,
          'tags': <String>[],
          'collection_id': null,
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/bookmarks', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        final result = await apiClient.createBookmark(url: 'https://example.com');

        // Assert
        expect(result.id, equals('1'));
        expect(result.url, equals('https://example.com'));

        verify(mockDio.post('/bookmarks', data: {
          'url': 'https://example.com',
        })).called(1);
      });

      test('should not include empty tags in request', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': null,
          'description': null,
          'tags': <String>[],
          'collection_id': null,
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/bookmarks', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        await apiClient.createBookmark(url: 'https://example.com', tags: []);

        // Assert
        verify(mockDio.post('/bookmarks', data: {
          'url': 'https://example.com',
        })).called(1);
      });

      test('should throw DioException on validation error', () async {
        // Arrange
        when(mockDio.post('/bookmarks', data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              response: Response(
                statusCode: 400,
                data: {'error': 'Invalid URL'},
                requestOptions: RequestOptions(path: '/bookmarks'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.createBookmark(url: 'invalid-url'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('updateBookmark', () {
      test('should update bookmark with all parameters', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': 'Updated Title',
          'description': 'Updated description',
          'tags': ['updated', 'tags'],
          'collection_id': 'col2',
          'archived': true,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
        };

        when(mockDio.put('/bookmarks/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks/1'),
                ));

        // Act
        final result = await apiClient.updateBookmark(
          '1',
          title: 'Updated Title',
          description: 'Updated description',
          tags: ['updated', 'tags'],
          collectionId: 'col2',
          archived: true,
        );

        // Assert
        expect(result.id, equals('1'));
        expect(result.title, equals('Updated Title'));
        expect(result.archived, isTrue);

        verify(mockDio.put('/bookmarks/1', data: {
          'title': 'Updated Title',
          'description': 'Updated description',
          'tags': ['updated', 'tags'],
          'collection_id': 'col2',
          'archived': true,
        })).called(1);
      });

      test('should update bookmark with minimal parameters', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': 'Updated Title',
          'description': null,
          'tags': <String>[],
          'collection_id': null,
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
        };

        when(mockDio.put('/bookmarks/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks/1'),
                ));

        // Act
        final result = await apiClient.updateBookmark('1', title: 'Updated Title');

        // Assert
        expect(result.title, equals('Updated Title'));

        verify(mockDio.put('/bookmarks/1', data: {
          'title': 'Updated Title',
        })).called(1);
      });

      test('should handle empty update data', () async {
        // Arrange
        final bookmarkData = {
          'id': '1',
          'url': 'https://example.com',
          'title': 'Original Title',
          'description': null,
          'tags': <String>[],
          'collection_id': null,
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.put('/bookmarks/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks/1'),
                ));

        // Act
        await apiClient.updateBookmark('1');

        // Assert
        verify(mockDio.put('/bookmarks/1', data: {})).called(1);
      });

      test('should throw DioException when bookmark not found', () async {
        // Arrange
        when(mockDio.put('/bookmarks/nonexistent', data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.updateBookmark('nonexistent', title: 'New Title'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('deleteBookmark', () {
      test('should delete bookmark successfully', () async {
        // Arrange
        when(mockDio.delete('/bookmarks/1'))
            .thenAnswer((_) async => Response(
                  statusCode: 204,
                  requestOptions: RequestOptions(path: '/bookmarks/1'),
                ));

        // Act
        await apiClient.deleteBookmark('1');

        // Assert
        verify(mockDio.delete('/bookmarks/1')).called(1);
      });

      test('should throw DioException when bookmark not found', () async {
        // Arrange
        when(mockDio.delete('/bookmarks/nonexistent'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/bookmarks/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.deleteBookmark('nonexistent'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getTags', () {
      test('should return list of tags', () async {
        // Arrange
        final responseData = {
          'tags': [
            {'id': '1', 'name': 'flutter', 'count': 5},
            {'id': '2', 'name': 'dart', 'count': 3},
          ]
        };

        when(mockDio.get('/tags'))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/tags'),
                ));

        // Act
        final result = await apiClient.getTags();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].name, equals('flutter'));
        expect(result[1].name, equals('dart'));
        verify(mockDio.get('/tags')).called(1);
      });

      test('should return empty list when no tags', () async {
        // Arrange
        final responseData = {'tags': <Map<String, dynamic>>[]};

        when(mockDio.get('/tags'))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/tags'),
                ));

        // Act
        final result = await apiClient.getTags();

        // Assert
        expect(result, isEmpty);
      });

      test('should throw DioException on network error', () async {
        // Arrange
        when(mockDio.get('/tags'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/tags'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () => apiClient.getTags(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getCollections', () {
      test('should return list of collections', () async {
        // Arrange
        final responseData = {
          'collections': [
            {
              'id': '1',
              'name': 'Development',
              'description': 'Programming resources',
              'created_at': '2023-01-01T00:00:00.000Z',
              'updated_at': '2023-01-01T00:00:00.000Z',
            },
            {
              'id': '2',
              'name': 'Design',
              'description': null,
              'created_at': '2023-01-02T00:00:00.000Z',
              'updated_at': '2023-01-02T00:00:00.000Z',
            },
          ]
        };

        when(mockDio.get('/collections'))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/collections'),
                ));

        // Act
        final result = await apiClient.getCollections();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].name, equals('Development'));
        expect(result[0].description, equals('Programming resources'));
        expect(result[1].name, equals('Design'));
        expect(result[1].description, isNull);
        verify(mockDio.get('/collections')).called(1);
      });

      test('should return empty list when no collections', () async {
        // Arrange
        final responseData = {'collections': <Map<String, dynamic>>[]};

        when(mockDio.get('/collections'))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/collections'),
                ));

        // Act
        final result = await apiClient.getCollections();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('createCollection', () {
      test('should create collection with all parameters', () async {
        // Arrange
        final collectionData = {
          'id': '1',
          'name': 'Development',
          'description': 'Programming resources',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/collections', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: collectionData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/collections'),
                ));

        // Act
        final result = await apiClient.createCollection(
          name: 'Development',
          description: 'Programming resources',
        );

        // Assert
        expect(result.id, equals('1'));
        expect(result.name, equals('Development'));
        expect(result.description, equals('Programming resources'));

        verify(mockDio.post('/collections', data: {
          'name': 'Development',
          'description': 'Programming resources',
        })).called(1);
      });

      test('should create collection with minimal parameters', () async {
        // Arrange
        final collectionData = {
          'id': '1',
          'name': 'Development',
          'description': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/collections', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: collectionData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/collections'),
                ));

        // Act
        final result = await apiClient.createCollection(name: 'Development');

        // Assert
        expect(result.name, equals('Development'));
        expect(result.description, isNull);

        verify(mockDio.post('/collections', data: {
          'name': 'Development',
        })).called(1);
      });

      test('should throw DioException on validation error', () async {
        // Arrange
        when(mockDio.post('/collections', data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/collections'),
              response: Response(
                statusCode: 400,
                data: {'error': 'Name is required'},
                requestOptions: RequestOptions(path: '/collections'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.createCollection(name: ''),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('updateCollection', () {
      test('should update collection with all parameters', () async {
        // Arrange
        final collectionData = {
          'id': '1',
          'name': 'Updated Development',
          'description': 'Updated description',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
        };

        when(mockDio.put('/collections/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: collectionData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/collections/1'),
                ));

        // Act
        final result = await apiClient.updateCollection(
          '1',
          name: 'Updated Development',
          description: 'Updated description',
        );

        // Assert
        expect(result.name, equals('Updated Development'));
        expect(result.description, equals('Updated description'));

        verify(mockDio.put('/collections/1', data: {
          'name': 'Updated Development',
          'description': 'Updated description',
        })).called(1);
      });

      test('should update collection with minimal parameters', () async {
        // Arrange
        final collectionData = {
          'id': '1',
          'name': 'Updated Development',
          'description': 'Original description',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
        };

        when(mockDio.put('/collections/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: collectionData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/collections/1'),
                ));

        // Act
        final result = await apiClient.updateCollection('1', name: 'Updated Development');

        // Assert
        expect(result.name, equals('Updated Development'));

        verify(mockDio.put('/collections/1', data: {
          'name': 'Updated Development',
        })).called(1);
      });

      test('should handle empty update data', () async {
        // Arrange
        final collectionData = {
          'id': '1',
          'name': 'Original Name',
          'description': 'Original description',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.put('/collections/1', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: collectionData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/collections/1'),
                ));

        // Act
        await apiClient.updateCollection('1');

        // Assert
        verify(mockDio.put('/collections/1', data: {})).called(1);
      });

      test('should throw DioException when collection not found', () async {
        // Arrange
        when(mockDio.put('/collections/nonexistent', data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/collections/nonexistent'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/collections/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.updateCollection('nonexistent', name: 'New Name'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('deleteCollection', () {
      test('should delete collection successfully', () async {
        // Arrange
        when(mockDio.delete('/collections/1'))
            .thenAnswer((_) async => Response(
                  statusCode: 204,
                  requestOptions: RequestOptions(path: '/collections/1'),
                ));

        // Act
        await apiClient.deleteCollection('1');

        // Assert
        verify(mockDio.delete('/collections/1')).called(1);
      });

      test('should throw DioException when collection not found', () async {
        // Arrange
        when(mockDio.delete('/collections/nonexistent'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/collections/nonexistent'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/collections/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.deleteCollection('nonexistent'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle server errors (500)', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              response: Response(
                statusCode: 500,
                data: {'error': 'Internal server error'},
                requestOptions: RequestOptions(path: '/bookmarks'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle unauthorized access (401)', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              response: Response(
                statusCode: 401,
                data: {'error': 'Unauthorized'},
                requestOptions: RequestOptions(path: '/bookmarks'),
              ),
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle connection timeouts', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle receive timeouts', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              type: DioExceptionType.receiveTimeout,
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle malformed JSON responses', () async {
        // Arrange
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/bookmarks'),
              type: DioExceptionType.unknown,
              error: FormatException('Invalid JSON'),
            ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<DioException>()),
        );
      });

      test('should handle null response data', () async {
        // Arrange - Simulate a case where response.data might be null
        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: null,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act & Assert
        expect(
          () => apiClient.getBookmarks(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle very large tag lists', () async {
        // Arrange
        final largeTags = List.generate(100, (i) => 'tag$i');
        final responseData = {'bookmarks': <Map<String, dynamic>>[]};

        when(mockDio.get('/bookmarks', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        await apiClient.getBookmarks(tags: largeTags);

        // Assert
        verify(mockDio.get('/bookmarks', queryParameters: {
          'tags': largeTags.join(','),
        })).called(1);
      });

      test('should handle special characters in URLs and titles', () async {
        // Arrange
        const specialUrl = 'https://example.com/test?query=hello world&foo=bar';
        const specialTitle = 'Test & Development "Guide" [2023]';
        
        final bookmarkData = {
          'id': '1',
          'url': specialUrl,
          'title': specialTitle,
          'description': null,
          'tags': <String>[],
          'collection_id': null,
          'archived': false,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-01T00:00:00.000Z',
        };

        when(mockDio.post('/bookmarks', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: bookmarkData,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/bookmarks'),
                ));

        // Act
        await apiClient.createBookmark(url: specialUrl, title: specialTitle);

        // Assert
        verify(mockDio.post('/bookmarks', data: {
          'url': specialUrl,
          'title': specialTitle,
        })).called(1);
      });
    });
  });
}