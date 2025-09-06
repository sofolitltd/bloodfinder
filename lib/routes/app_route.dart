class AppRoute {
  final String name;
  final String path;
  final String Function(Map<String, String>? params)? buildPath;

  const AppRoute({required this.name, required this.path, this.buildPath});

  String toPath([Map<String, String>? params]) {
    if (buildPath != null) {
      return buildPath!(params);
    }
    return path;
  }

  // All routes defined below
  static const feed = AppRoute(name: 'feed', path: '/feed');
  static const home = AppRoute(name: 'home', path: '/home');
  static const chat = AppRoute(name: 'chat', path: '/chat');
  static const account = AppRoute(name: 'account', path: '/account');
  //login
  static const login = AppRoute(name: 'login', path: '/login');
  //register
  static const register = AppRoute(name: 'register', path: '/register');
}
