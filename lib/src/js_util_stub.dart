// Stub implementations for non-web platforms so analysis passes.
// On web this file will be replaced by the real `dart:js_util` library
// via a conditional import.

bool hasProperty(Object? o, String name) => false;

dynamic callMethod(Object? o, String method, List<dynamic> args) => null;

void setProperty(Object? o, String name, Object? value) {}

T allowInterop<T>(T f) => f;
