// Archivo de abstracción obligatorio para engañar de forma segura al compilador móvil
String registerWebGlFactory(
        void Function() onReset, void Function() onRelease) =>
    '';
void updateWebGlEngine(double lat, double lng, bool snap) {}
void triggerWebGlReset() {}
