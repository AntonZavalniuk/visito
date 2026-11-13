import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/core/widgets/country_status_tag.dart';
import 'package:visito/models/country.dart';

Country _c({bool un = false, bool obs = false, bool disp = false}) => Country(
  isoCode: 'XX',
  name: 'Test',
  unMember: un,
  unObserver: obs,
  disputed: disp,
  polygons: [
    [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
  ],
);

void main() {
  test('labelFor picks DISP, UN, OBS or nothing', () {
    expect(CountryStatusTag.labelFor(_c(disp: true)), 'DISP');
    expect(CountryStatusTag.labelFor(_c(un: true)), 'UN');
    expect(CountryStatusTag.labelFor(_c(obs: true)), 'OBS');
    expect(CountryStatusTag.labelFor(_c()), isNull);
    // DISP wins over the other flags.
    expect(CountryStatusTag.labelFor(_c(disp: true, un: true)), 'DISP');
  });

  test('the UN badge can be hidden', () {
    expect(
      CountryStatusTag.labelFor(_c(un: true), showUnMember: false),
      isNull,
    );
    expect(
      CountryStatusTag.labelFor(_c(obs: true), showUnMember: false),
      'OBS',
    );
  });

  testWidgets('renders the label text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CountryStatusTag(country: _c(disp: true))),
    );
    expect(find.text('DISP'), findsOneWidget);
  });
}
