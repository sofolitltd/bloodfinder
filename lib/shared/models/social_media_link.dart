class SocialMediaLink {
  final String platform;
  final String url;

  const SocialMediaLink({required this.platform, required this.url});

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) {
    return SocialMediaLink(
      platform: json['platform'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'platform': platform, 'url': url};

  static const platformOptions = [
    'Facebook',
    'WhatsApp',
    'YouTube',
    'Website',
    'Instagram',
    'Twitter / X',
    'TikTok',
    'LinkedIn',
    'Telegram',
    'Discord',
    'Snapchat',
    'Messenger',
    'Other',
  ];

  static const platformIcons = {
    'Facebook': 'facebook',
    'WhatsApp': 'whatsapp',
    'YouTube': 'youtube',
    'Website': 'web',
    'Instagram': 'instagram',
    'Twitter / X': 'twitter',
    'TikTok': 'tiktok',
    'LinkedIn': 'linkedin',
    'Telegram': 'telegram',
    'Discord': 'discord',
    'Snapchat': 'snapchat',
    'Messenger': 'messenger',
  };
}
