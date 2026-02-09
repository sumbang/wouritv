class LangueSingleton {

    static final LangueSingleton _singleton = LangueSingleton._internal();

    String _langue = "";
    int init = 0;

    get getLangue => _langue;

     get getInit => init;

    void setLangue(choix) {
      _langue = choix;
    }

    
    void setInit(choix1) {
      init = choix1;
    }

    factory LangueSingleton() {
      return _singleton;
    }

    LangueSingleton._internal();

}