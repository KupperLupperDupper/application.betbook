import 'package:betbook/data/repositories/tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagRepository.fold', () {
    test('is case-insensitive and trims', () {
      expect(TagRepository.fold('Poker'), 'poker');
      expect(TagRepository.fold('  Poker  '), 'poker');
      expect(TagRepository.fold('POKER'), TagRepository.fold('poker'));
    });

    test('folds Danish letters', () {
      expect(TagRepository.fold('FODBOLD'), 'fodbold');
      expect(TagRepository.fold('Bånd'), 'bånd');
    });
  });
}
