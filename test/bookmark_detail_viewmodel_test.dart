import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/foundation.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/domain/use_cases/label_use_cases.dart';
import 'package:result_dart/result_dart.dart';

// Mock classes for testing
class MockBookmarkRepository extends Mock implements BookmarkRepository {}
class MockBookmarkOperationUseCases extends Mock implements BookmarkOperationUseCases {}
class MockBookmarkUseCases extends Mock implements BookmarkUseCases {}
class MockLabelUseCases extends Mock implements LabelUseCases {}

// Create a concrete implementation for testing bookmark detail functionality
class BookmarkDetailViewModel extends ChangeNotifier {
  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final BookmarkUseCases _bookmarkUseCases;
  final LabelUseCases _labelUseCases;
  
  Bookmark? _bookmark;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;
  
  // Temporary edit values
  String _editTitle = '';
  String _editUrl = '';
  String _editDescription = '';
  List<String> _editTags = [];

  BookmarkDetailViewModel({
    required BookmarkRepository bookmarkRepository,
    required BookmarkOperationUseCases bookmarkOperationUseCases,
    required BookmarkUseCases bookmarkUseCases,
    required LabelUseCases labelUseCases,
    Bookmark? bookmark,
  }) : _bookmarkRepository = bookmarkRepository,
       _bookmarkOperationUseCases = bookmarkOperationUseCases,
       _bookmarkUseCases = bookmarkUseCases,
       _labelUseCases = labelUseCases,
       _bookmark = bookmark {
    if (bookmark != null) {
      _initializeEditValues();
    }
  }

  // Getters
  Bookmark? get bookmark => _bookmark;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get error => _error;
  String get title => _isEditing ? _editTitle : (_bookmark?.title ?? '');
  String get url => _isEditing ? _editUrl : (_bookmark?.url ?? '');
  String get description => _isEditing ? _editDescription : (_bookmark?.description ?? '');
  List<String> get tags => _isEditing ? _editTags : (_bookmark?.labels?.map((l) => l.name).toList() ?? []);

  void _initializeEditValues() {
    if (_bookmark != null) {
      _editTitle = _bookmark!.title;
      _editUrl = _bookmark!.url;
      _editDescription = _bookmark!.description ?? '';
      _editTags = _bookmark!.labels?.map((l) => l.name).toList() ?? [];
    }
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    if (_isEditing) {
      _initializeEditValues();
    } else {
      _initializeEditValues(); // Reset to original values
    }
    notifyListeners();
  }

  void updateTitle(String title) {
    if (_isEditing) {
      _editTitle = title;
      notifyListeners();
    }
  }

  void updateUrl(String url) {
    if (_isEditing) {
      _editUrl = url;
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_isEditing) {
      _editDescription = description;
      notifyListeners();
    }
  }

  void updateTags(List<String> tags) {
    if (_isEditing) {
      _editTags = List.from(tags);
      notifyListeners();
    }
  }

  bool validateTitle(String title) {
    return title.trim().isNotEmpty;
  }

  bool validateUrl(String url) {
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$', caseSensitive: false);
    return url.isNotEmpty && urlRegex.hasMatch(url);
  }

  bool validateTags(List<String> tags) {
    return tags.every((tag) => tag.trim().isNotEmpty);
  }

  List<String> getValidationErrors() {
    final errors = <String>[];
    if (!validateTitle(_editTitle)) {
      errors.add('Title cannot be empty');
    }
    if (!validateUrl(_editUrl)) {
      errors.add('Invalid URL format');
    }
    if (!validateTags(_editTags)) {
      errors.add('Tags cannot be empty');
    }
    return errors;
  }

  Future<void> saveChanges() async {
    if (!_isEditing) return;

    final errors = getValidationErrors();
    if (errors.isNotEmpty) {
      _error = errors.join(', ');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate saving bookmark with updated values
      final result = await _bookmarkOperationUseCases.updateBookmark(
        _bookmark!.id,
        title: _editTitle,
        url: _editUrl,
        description: _editDescription,
      );

      result.fold(
        (updatedBookmark) {
          _bookmark = updatedBookmark;
          _isEditing = false;
          _error = null;
        },
        (error) {
          _error = error.toString();
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBookmark() async {
    if (_bookmark == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookmarkOperationUseCases.deleteBookmark(_bookmark!.id);
      result.fold(
        (success) {
          // Navigation would happen here in real app
        },
        (error) {
          _error = error.toString();
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmarkMarked() async {
    if (_bookmark == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _bookmarkOperationUseCases.toggleBookmarkMarked(_bookmark!);
      result.fold(
        (updatedBookmark) {
          _bookmark = updatedBookmark;
        },
        (error) {
          _error = error.toString();
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmarkArchived() async {
    if (_bookmark == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _bookmarkOperationUseCases.toggleBookmarkArchived(_bookmark!);
      result.fold(
        (updatedBookmark) {
          _bookmark = updatedBookmark;
        },
        (error) {
          _error = error.toString();
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookmark(String bookmarkId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookmark = _bookmarkUseCases.getBookmark(bookmarkId);
      if (_bookmark != null) {
        _initializeEditValues();
      } else {
        _error = 'Bookmark not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

void main() {
  group('BookmarkDetailViewModel Tests', () {
    late BookmarkDetailViewModel viewModel;
    late MockBookmarkRepository mockBookmarkRepository;
    late MockBookmarkOperationUseCases mockBookmarkOperationUseCases;
    late MockBookmarkUseCases mockBookmarkUseCases;
    late MockLabelUseCases mockLabelUseCases;
    late Bookmark testBookmark;

    setUp(() {
      mockBookmarkRepository = MockBookmarkRepository();
      mockBookmarkOperationUseCases = MockBookmarkOperationUseCases();
      mockBookmarkUseCases = MockBookmarkUseCases();
      mockLabelUseCases = MockLabelUseCases();
      
      testBookmark = Bookmark(
        id: '1',
        title: 'Test Bookmark',
        url: 'https://example.com',
        description: 'Test description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isMarked: false,
        isArchived: false,
        labels: [],
      );

      viewModel = BookmarkDetailViewModel(
        bookmarkRepository: mockBookmarkRepository,
        bookmarkOperationUseCases: mockBookmarkOperationUseCases,
        bookmarkUseCases: mockBookmarkUseCases,
        labelUseCases: mockLabelUseCases,
        bookmark: testBookmark,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize with provided bookmark', () {
        expect(viewModel.bookmark, equals(testBookmark));
        expect(viewModel.title, equals(testBookmark.title));
        expect(viewModel.url, equals(testBookmark.url));
        expect(viewModel.description, equals(testBookmark.description));
        expect(viewModel.tags, equals([]));
      });

      test('should initialize with null bookmark', () {
        final nullViewModel = BookmarkDetailViewModel(
          bookmarkRepository: mockBookmarkRepository,
          bookmarkOperationUseCases: mockBookmarkOperationUseCases,
          bookmarkUseCases: mockBookmarkUseCases,
          labelUseCases: mockLabelUseCases,
        );
        
        expect(nullViewModel.bookmark, isNull);
        expect(nullViewModel.title, equals(''));
        expect(nullViewModel.url, equals(''));
        expect(nullViewModel.description, equals(''));
        expect(nullViewModel.tags, equals([]));
        
        nullViewModel.dispose();
      });

      test('should not be in editing mode initially', () {
        expect(viewModel.isEditing, isFalse);
      });

      test('should not be loading initially', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('should have no error initially', () {
        expect(viewModel.error, isNull);
      });
    });

    group('Edit Mode Tests', () {
      test('should enter edit mode when toggleEditMode is called', () {
        viewModel.toggleEditMode();
        expect(viewModel.isEditing, isTrue);
      });

      test('should exit edit mode when toggleEditMode is called twice', () {
        viewModel.toggleEditMode();
        viewModel.toggleEditMode();
        expect(viewModel.isEditing, isFalse);
      });

      test('should reset changes when exiting edit mode without saving', () {
        viewModel.toggleEditMode();
        viewModel.updateTitle('Modified Title');
        viewModel.toggleEditMode();
        expect(viewModel.title, equals(testBookmark.title));
      });

      test('should notify listeners when entering/exiting edit mode', () {
        var notificationCount = 0;
        viewModel.addListener(() => notificationCount++);
        
        viewModel.toggleEditMode();
        expect(notificationCount, equals(1));
        
        viewModel.toggleEditMode();
        expect(notificationCount, equals(2));
      });

      test('should initialize edit values correctly when entering edit mode', () {
        viewModel.toggleEditMode();
        expect(viewModel.title, equals(testBookmark.title));
        expect(viewModel.url, equals(testBookmark.url));
        expect(viewModel.description, equals(testBookmark.description ?? ''));
      });
    });

    group('Field Update Tests', () {
      setUp(() {
        viewModel.toggleEditMode();
      });

      test('should update title when in edit mode', () {
        const newTitle = 'Updated Title';
        viewModel.updateTitle(newTitle);
        expect(viewModel.title, equals(newTitle));
      });

      test('should update URL when in edit mode', () {
        const newUrl = 'https://updated.com';
        viewModel.updateUrl(newUrl);
        expect(viewModel.url, equals(newUrl));
      });

      test('should update description when in edit mode', () {
        const newDescription = 'Updated description';
        viewModel.updateDescription(newDescription);
        expect(viewModel.description, equals(newDescription));
      });

      test('should update tags when in edit mode', () {
        final newTags = ['updated', 'tags'];
        viewModel.updateTags(newTags);
        expect(viewModel.tags, equals(newTags));
      });

      test('should not update fields when not in edit mode', () {
        viewModel.toggleEditMode(); // Exit edit mode
        const originalTitle = 'Test Bookmark';
        
        viewModel.updateTitle('Should not update');
        expect(viewModel.title, equals(originalTitle));
      });

      test('should notify listeners when fields are updated', () {
        var notificationCount = 0;
        viewModel.addListener(() => notificationCount++);
        
        viewModel.updateTitle('New Title');
        expect(notificationCount, equals(1));
        
        viewModel.updateUrl('https://new.com');
        expect(notificationCount, equals(2));
        
        viewModel.updateDescription('New description');
        expect(notificationCount, equals(3));
        
        viewModel.updateTags(['new', 'tags']);
        expect(notificationCount, equals(4));
      });
    });

    group('Validation Tests', () {
      test('should validate title is not empty', () {
        expect(viewModel.validateTitle('Valid Title'), isTrue);
        expect(viewModel.validateTitle(''), isFalse);
        expect(viewModel.validateTitle('   '), isFalse);
        expect(viewModel.validateTitle('A'), isTrue);
      });

      test('should validate URL format', () {
        expect(viewModel.validateUrl('https://example.com'), isTrue);
        expect(viewModel.validateUrl('http://example.com'), isTrue);
        expect(viewModel.validateUrl('https://sub.example.com/path?query=1'), isTrue);
        expect(viewModel.validateUrl('invalid-url'), isFalse);
        expect(viewModel.validateUrl(''), isFalse);
        expect(viewModel.validateUrl('example.com'), isFalse);
        expect(viewModel.validateUrl('ftp://example.com'), isFalse);
        expect(viewModel.validateUrl('https://'), isFalse);
      });

      test('should validate tags are not empty when provided', () {
        expect(viewModel.validateTags(['valid', 'tags']), isTrue);
        expect(viewModel.validateTags([]), isTrue);
        expect(viewModel.validateTags(['valid']), isTrue);
        expect(viewModel.validateTags(['', 'valid']), isFalse);
        expect(viewModel.validateTags(['valid', '   ']), isFalse);
        expect(viewModel.validateTags(['   ']), isFalse);
      });

      test('should return validation errors for invalid data', () {
        viewModel.toggleEditMode();
        viewModel.updateTitle('');
        viewModel.updateUrl('invalid-url');
        viewModel.updateTags(['', 'valid']);
        
        final errors = viewModel.getValidationErrors();
        expect(errors, contains('Title cannot be empty'));
        expect(errors, contains('Invalid URL format'));
        expect(errors, contains('Tags cannot be empty'));
      });

      test('should return empty errors for valid data', () {
        viewModel.toggleEditMode();
        viewModel.updateTitle('Valid Title');
        viewModel.updateUrl('https://example.com');
        viewModel.updateTags(['valid', 'tags']);
        
        final errors = viewModel.getValidationErrors();
        expect(errors, isEmpty);
      });
    });

    group('Save Tests', () {
      setUp(() {
        viewModel.toggleEditMode();
      });

      test('should save bookmark successfully with valid data', () async {
        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Success(testBookmark));

        viewModel.updateTitle('Updated Title');
        viewModel.updateUrl('https://updated.com');
        await viewModel.saveChanges();

        verify(mockBookmarkOperationUseCases.updateBookmark(
          testBookmark.id,
          title: 'Updated Title',
          url: 'https://updated.com',
          description: '',
        )).called(1);
        expect(viewModel.isEditing, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should not save bookmark with invalid data', () async {
        viewModel.updateTitle('');
        await viewModel.saveChanges();

        verifyNever(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        ));
        expect(viewModel.isEditing, isTrue);
        expect(viewModel.error, isNotNull);
        expect(viewModel.error, contains('Title cannot be empty'));
      });

      test('should handle save errors gracefully', () async {
        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Failure(Exception('Save failed')));

        viewModel.updateTitle('Valid Title');
        viewModel.updateUrl('https://valid.com');
        await viewModel.saveChanges();

        expect(viewModel.error, contains('Save failed'));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isEditing, isTrue);
      });

      test('should show loading state during save', () async {
        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return Success(testBookmark);
        });

        viewModel.updateTitle('Valid Title');
        viewModel.updateUrl('https://valid.com');
        
        final future = viewModel.saveChanges();
        expect(viewModel.isLoading, isTrue);
        
        await future;
        expect(viewModel.isLoading, isFalse);
      });

      test('should not save when not in edit mode', () async {
        viewModel.toggleEditMode(); // Exit edit mode
        
        await viewModel.saveChanges();
        
        verifyNever(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        ));
      });
    });

    group('Delete Tests', () {
      test('should delete bookmark successfully', () async {
        when(mockBookmarkOperationUseCases.deleteBookmark(testBookmark.id))
            .thenAnswer((_) async => Success(true));

        await viewModel.deleteBookmark();

        verify(mockBookmarkOperationUseCases.deleteBookmark(testBookmark.id)).called(1);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle delete errors gracefully', () async {
        when(mockBookmarkOperationUseCases.deleteBookmark(testBookmark.id))
            .thenAnswer((_) async => Failure(Exception('Delete failed')));

        await viewModel.deleteBookmark();

        expect(viewModel.error, contains('Delete failed'));
        expect(viewModel.isLoading, isFalse);
      });

      test('should show loading state during delete', () async {
        when(mockBookmarkOperationUseCases.deleteBookmark(testBookmark.id))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return Success(true);
        });

        final future = viewModel.deleteBookmark();
        expect(viewModel.isLoading, isTrue);
        
        await future;
        expect(viewModel.isLoading, isFalse);
      });

      test('should not delete when bookmark is null', () async {
        final nullViewModel = BookmarkDetailViewModel(
          bookmarkRepository: mockBookmarkRepository,
          bookmarkOperationUseCases: mockBookmarkOperationUseCases,
          bookmarkUseCases: mockBookmarkUseCases,
          labelUseCases: mockLabelUseCases,
        );

        await nullViewModel.deleteBookmark();

        verifyNever(mockBookmarkOperationUseCases.deleteBookmark(any));
        
        nullViewModel.dispose();
      });
    });

    group('Bookmark Operations Tests', () {
      test('should toggle bookmark marked status successfully', () async {
        when(mockBookmarkOperationUseCases.toggleBookmarkMarked(testBookmark))
            .thenAnswer((_) async => Success(testBookmark.copyWith(isMarked: true)));

        await viewModel.toggleBookmarkMarked();

        verify(mockBookmarkOperationUseCases.toggleBookmarkMarked(testBookmark)).called(1);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle toggle marked errors gracefully', () async {
        when(mockBookmarkOperationUseCases.toggleBookmarkMarked(testBookmark))
            .thenAnswer((_) async => Failure(Exception('Toggle failed')));

        await viewModel.toggleBookmarkMarked();

        expect(viewModel.error, contains('Toggle failed'));
        expect(viewModel.isLoading, isFalse);
      });

      test('should toggle bookmark archived status successfully', () async {
        when(mockBookmarkOperationUseCases.toggleBookmarkArchived(testBookmark))
            .thenAnswer((_) async => Success(testBookmark.copyWith(isArchived: true)));

        await viewModel.toggleBookmarkArchived();

        verify(mockBookmarkOperationUseCases.toggleBookmarkArchived(testBookmark)).called(1);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle toggle archived errors gracefully', () async {
        when(mockBookmarkOperationUseCases.toggleBookmarkArchived(testBookmark))
            .thenAnswer((_) async => Failure(Exception('Archive failed')));

        await viewModel.toggleBookmarkArchived();

        expect(viewModel.error, contains('Archive failed'));
        expect(viewModel.isLoading, isFalse);
      });

      test('should not toggle operations when bookmark is null', () async {
        final nullViewModel = BookmarkDetailViewModel(
          bookmarkRepository: mockBookmarkRepository,
          bookmarkOperationUseCases: mockBookmarkOperationUseCases,
          bookmarkUseCases: mockBookmarkUseCases,
          labelUseCases: mockLabelUseCases,
        );

        await nullViewModel.toggleBookmarkMarked();
        await nullViewModel.toggleBookmarkArchived();

        verifyNever(mockBookmarkOperationUseCases.toggleBookmarkMarked(any));
        verifyNever(mockBookmarkOperationUseCases.toggleBookmarkArchived(any));
        
        nullViewModel.dispose();
      });
    });

    group('Load Bookmark Tests', () {
      test('should load bookmark successfully', () async {
        when(mockBookmarkUseCases.getBookmark('test-id'))
            .thenReturn(testBookmark);

        await viewModel.loadBookmark('test-id');

        verify(mockBookmarkUseCases.getBookmark('test-id')).called(1);
        expect(viewModel.bookmark, equals(testBookmark));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
      });

      test('should handle bookmark not found', () async {
        when(mockBookmarkUseCases.getBookmark('invalid-id'))
            .thenReturn(null);

        await viewModel.loadBookmark('invalid-id');

        expect(viewModel.bookmark, isNull);
        expect(viewModel.error, equals('Bookmark not found'));
        expect(viewModel.isLoading, isFalse);
      });

      test('should handle load errors gracefully', () async {
        when(mockBookmarkUseCases.getBookmark('error-id'))
            .thenThrow(Exception('Load failed'));

        await viewModel.loadBookmark('error-id');

        expect(viewModel.error, contains('Load failed'));
        expect(viewModel.isLoading, isFalse);
      });

      test('should show loading state during load', () async {
        when(mockBookmarkUseCases.getBookmark('slow-id'))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return testBookmark;
        });

        final future = viewModel.loadBookmark('slow-id');
        expect(viewModel.isLoading, isTrue);
        
        await future;
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('Error Handling Tests', () {
      test('should set and clear errors correctly', () {
        expect(viewModel.error, isNull);
        
        viewModel.setError('Test error');
        expect(viewModel.error, equals('Test error'));
        
        viewModel.clearError();
        expect(viewModel.error, isNull);
      });

      test('should notify listeners when error is set', () {
        var notificationCount = 0;
        viewModel.addListener(() => notificationCount++);
        
        viewModel.setError('Test error');
        expect(notificationCount, equals(1));
        
        viewModel.clearError();
        expect(notificationCount, equals(2));
      });

      test('should clear error when successful operation occurs', () async {
        viewModel.setError('Test error');
        expect(viewModel.error, isNotNull);

        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Success(testBookmark));

        viewModel.toggleEditMode();
        viewModel.updateTitle('Valid Title');
        viewModel.updateUrl('https://valid.com');
        await viewModel.saveChanges();

        expect(viewModel.error, isNull);
      });
    });

    group('Edge Cases and Stress Tests', () {
      test('should handle very long titles', () {
        viewModel.toggleEditMode();
        final longTitle = 'A' * 1000;
        viewModel.updateTitle(longTitle);
        expect(viewModel.title, equals(longTitle));
        expect(viewModel.validateTitle(longTitle), isTrue);
      });

      test('should handle special characters in fields', () {
        viewModel.toggleEditMode();
        const specialTitle = 'Title with 特殊字符 and émojis 🔖';
        const specialDescription = 'Description with newlines\nand\ttabs';
        viewModel.updateTitle(specialTitle);
        viewModel.updateDescription(specialDescription);
        expect(viewModel.title, equals(specialTitle));
        expect(viewModel.description, equals(specialDescription));
      });

      test('should handle empty and whitespace-only inputs', () {
        viewModel.toggleEditMode();
        viewModel.updateTitle('   ');
        viewModel.updateUrl('   ');
        viewModel.updateDescription('   ');
        
        expect(viewModel.validateTitle(viewModel.title), isFalse);
        expect(viewModel.validateUrl(viewModel.url), isFalse);
      });

      test('should handle duplicate tags', () {
        viewModel.toggleEditMode();
        viewModel.updateTags(['tag1', 'tag2', 'tag1', 'tag2']);
        expect(viewModel.tags, equals(['tag1', 'tag2', 'tag1', 'tag2']));
      });

      test('should handle large tag lists', () {
        viewModel.toggleEditMode();
        final largeTags = List.generate(100, (i) => 'tag$i');
        viewModel.updateTags(largeTags);
        expect(viewModel.tags.length, equals(100));
        expect(viewModel.validateTags(largeTags), isTrue);
      });

      test('should handle rapid successive operations', () {
        viewModel.toggleEditMode();
        for (int i = 0; i < 100; i++) {
          viewModel.updateTitle('Title $i');
        }
        expect(viewModel.title, equals('Title 99'));
      });

      test('should handle state consistency during concurrent operations', () async {
        viewModel.toggleEditMode();
        viewModel.updateTitle('Test Title');
        viewModel.updateUrl('https://test.com');

        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Success(testBookmark);
        });

        when(mockBookmarkOperationUseCases.toggleBookmarkMarked(any))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Success(testBookmark);
        });

        // Start multiple operations simultaneously
        final futures = [
          viewModel.saveChanges(),
          viewModel.toggleBookmarkMarked(),
        ];

        await Future.wait(futures);
        
        // Should not crash and maintain consistent state
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('State Management Tests', () {
      test('should maintain state consistency during rapid field updates', () {
        viewModel.toggleEditMode();
        
        viewModel.updateTitle('Title 1');
        viewModel.updateUrl('https://url1.com');
        viewModel.updateTitle('Title 2');
        viewModel.updateUrl('https://url2.com');
        viewModel.updateTitle('Title 3');
        
        expect(viewModel.title, equals('Title 3'));
        expect(viewModel.url, equals('https://url2.com'));
        expect(viewModel.isEditing, isTrue);
      });

      test('should handle dispose properly', () {
        viewModel.dispose();
        expect(() => viewModel.addListener(() {}), throwsA(isA<FlutterError>()));
      });

      test('should not notify listeners after dispose', () {
        var notificationCount = 0;
        viewModel.addListener(() => notificationCount++);
        
        viewModel.dispose();
        
        // These should not crash or notify after dispose
        expect(() => viewModel.setError('test'), returnsNormally);
        expect(notificationCount, equals(0));
      });

      test('should handle multiple listeners correctly', () {
        var count1 = 0;
        var count2 = 0;
        var count3 = 0;
        
        viewModel.addListener(() => count1++);
        viewModel.addListener(() => count2++);
        viewModel.addListener(() => count3++);
        
        viewModel.toggleEditMode();
        
        expect(count1, equals(1));
        expect(count2, equals(1));
        expect(count3, equals(1));
      });
    });

    group('Performance Tests', () {
      test('should handle multiple rapid field updates efficiently', () {
        viewModel.toggleEditMode();
        
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          viewModel.updateTitle('Title $i');
          viewModel.updateUrl('https://url$i.com');
          viewModel.updateDescription('Description $i');
        }
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(viewModel.title, equals('Title 999'));
        expect(viewModel.url, equals('https://url999.com'));
        expect(viewModel.description, equals('Description 999'));
      });

      test('should handle large data sets efficiently', () {
        viewModel.toggleEditMode();
        
        final largeDescription = 'A' * 10000;
        final largeTags = List.generate(1000, (i) => 'tag$i');
        
        final stopwatch = Stopwatch()..start();
        viewModel.updateDescription(largeDescription);
        viewModel.updateTags(largeTags);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(viewModel.description.length, equals(10000));
        expect(viewModel.tags.length, equals(1000));
      });
    });

    group('Integration Tests', () {
      test('should handle complete workflow: edit -> validate -> save', () async {
        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Success(testBookmark.copyWith(
          title: 'Updated Title',
          url: 'https://updated.com',
        )));

        // Start editing
        expect(viewModel.isEditing, isFalse);
        viewModel.toggleEditMode();
        expect(viewModel.isEditing, isTrue);

        // Update fields
        viewModel.updateTitle('Updated Title');
        viewModel.updateUrl('https://updated.com');
        viewModel.updateDescription('Updated description');
        
        // Validate
        expect(viewModel.getValidationErrors(), isEmpty);
        
        // Save
        await viewModel.saveChanges();
        
        // Verify final state
        expect(viewModel.isEditing, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
        expect(viewModel.bookmark?.title, equals('Updated Title'));
      });

      test('should handle complete workflow: edit -> validate -> error -> fix -> save', () async {
        viewModel.toggleEditMode();
        
        // Set invalid data
        viewModel.updateTitle('');
        viewModel.updateUrl('invalid');
        
        // Try to save (should fail validation)
        await viewModel.saveChanges();
        expect(viewModel.error, isNotNull);
        expect(viewModel.isEditing, isTrue);
        
        // Fix the data
        viewModel.updateTitle('Valid Title');
        viewModel.updateUrl('https://valid.com');
        
        when(mockBookmarkOperationUseCases.updateBookmark(
          any,
          title: anyNamed('title'),
          url: anyNamed('url'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Success(testBookmark));
        
        // Save again (should succeed)
        await viewModel.saveChanges();
        expect(viewModel.error, isNull);
        expect(viewModel.isEditing, isFalse);
      });
    });
  });
}