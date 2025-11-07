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
  static const profile = AppRoute(name: 'profile', path: '/profile');

  //chat
  static const chat = AppRoute(name: 'chat', path: '/chats');
  static const archive = AppRoute(name: 'archive', path: '/archive');

  //
  static const community = AppRoute(name: 'community', path: '/community');
  static const communityDetails = AppRoute(
    name: 'community-details',
    path: '/community-details',
  );

  //login
  static const login = AppRoute(name: 'login', path: '/login');

  //register
  static const registration = AppRoute(name: 'register', path: '/register');

  //reset
  static const forgotPassword = AppRoute(
    name: 'forgotPassword',
    path: '/forgotPassword',
  );

  //
  static const bloodRequest = AppRoute(
    name: 'blood-request',
    path: '/blood-request',
  );
  static const bloodBank = AppRoute(name: 'blood-bank', path: '/blood-bank');

  static const emergencyDonor = AppRoute(
    name: 'emergency-donor',
    path: '/emergency-donor',
  );

  static const donationHistory = AppRoute(
    name: 'donation-history',
    path: '/donation-history',
  );

  //
  static const bloodRequestHistory = AppRoute(
    name: 'blood-request-history',
    path: '/blood-request-history',
  );
}
