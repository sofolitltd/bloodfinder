class Geohash {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a latitude and longitude into a geohash string.
  static String encode(double latitude, double longitude, {int precision = 9}) {
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    
    String geohash = '';
    bool isEven = true;
    int bit = 0;
    int ch = 0;
    
    while (geohash.length < precision) {
      if (isEven) {
        double mid = (minLng + maxLng) / 2.0;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        double mid = (minLat + maxLat) / 2.0;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    
    return geohash;
  }
}
