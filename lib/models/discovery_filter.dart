class DiscoveryFilter {
  List<String> genderList;
  List<String> sizeList;
  List<String> ageList;
  List<String> speciesList;

  DiscoveryFilter({
    this.genderList = const [],
    this.sizeList = const [],
    this.ageList = const [],
    this.speciesList = const [],
  });

  DiscoveryFilter.from(DiscoveryFilter other)
      : genderList = List.from(other.genderList),
        sizeList = List.from(other.sizeList),
        ageList = List.from(other.ageList),
        speciesList = List.from(other.speciesList);

  bool get isEmpty =>
      genderList.isEmpty &&
          sizeList.isEmpty &&
          ageList.isEmpty &&
          speciesList.isEmpty;

  List<String> get gender => genderList;
  List<String> get size => sizeList;
  List<String> get age => ageList;
  List<String> get species => speciesList;

  Map<String, List<String>> toMap() {
    final map = <String, List<String>>{};
    if (genderList.isNotEmpty) map['gender'] = genderList;
    if (sizeList.isNotEmpty) map['size'] = sizeList;
    if (ageList.isNotEmpty) map['age'] = ageList;
    if (speciesList.isNotEmpty) map['species'] = speciesList;
    return map;
  }
}