/// Converts [input] into a URL-safe slug: lowercase, non-alphanumeric runs
/// collapsed to a single hyphen, leading/trailing hyphens trimmed, and
/// capped at [maxLength] characters.
String slugify(String input, {int maxLength = 60}) {
  var slug = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  if (slug.length > maxLength) {
    slug = slug.substring(0, maxLength).replaceAll(RegExp(r'-+$'), '');
  }

  return slug;
}
