/// Tolerant JSON accessors shared by the provider clients.
Map<String, dynamic> asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<dynamic> asList(Object? value) => value is List<dynamic> ? value : const <dynamic>[];

List<String> asStringList(Object? value) =>
    asList(value).whereType<String>().toList(growable: false);

String asString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

int asInt(Object? value) => value is num ? value.toInt() : 0;
