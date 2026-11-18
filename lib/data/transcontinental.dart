/// Which continents a transcontinental country is counted in.
enum TranscontinentalChoice { both, europe, asia }

/// A country spanning Europe and Asia whose continent the user can choose.
class TranscontinentalSpec {
  const TranscontinentalSpec(this.code, this.name);

  final String code;
  final String name;
}

const List<TranscontinentalSpec> transcontinentalSpecs = [
  TranscontinentalSpec('RU', 'Russia'),
  TranscontinentalSpec('TR', 'Turkey'),
  TranscontinentalSpec('CY', 'Cyprus'),
];
