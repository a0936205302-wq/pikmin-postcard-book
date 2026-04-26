import 'package:flutter_test/flutter_test.dart';

import 'package:pikmin_postcard_book/models/postcard.dart';

void main() {
  test('Postcard coordinatesText formats latitude and longitude', () {
    const postcard = Postcard(
      id: 'abc123',
      name: 'Taipei Station',
      category: PostcardCategory.mushroom,
      owned: false,
      lat: 25.0478,
      lng: 121.517,
      imageBytes: null,
      thumbnailBytes: null,
      imageUrl: 'https://example.com/postcard.jpg',
      createdAt: null,
    );

    expect(postcard.coordinatesText, '25.0478000000, 121.5170000000');
  });
}
