class Profile {
  final String id;
  final String name;
  final String? shell;
  final List<String> shellArgs;
  final String themeId;
  final String fontFamily;
  final double fontSize;
  final bool enableRtl;
  final int scrollbackLines;

  const Profile({
    required this.id,
    required this.name,
    this.shell,
    this.shellArgs = const [],
    this.themeId = 'catppuccin_mocha',
    this.fontFamily = 'Menlo',
    this.fontSize = 14,
    this.enableRtl = false,
    this.scrollbackLines = 10000,
  });

  Profile copyWith({
    String? name,
    String? shell,
    List<String>? shellArgs,
    String? themeId,
    String? fontFamily,
    double? fontSize,
    bool? enableRtl,
    int? scrollbackLines,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      shell: shell ?? this.shell,
      shellArgs: shellArgs ?? this.shellArgs,
      themeId: themeId ?? this.themeId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      enableRtl: enableRtl ?? this.enableRtl,
      scrollbackLines: scrollbackLines ?? this.scrollbackLines,
    );
  }
}

class DefaultProfiles {
  static const defaultProfile = Profile(
    id: 'default',
    name: 'Default',
    themeId: 'catppuccin_mocha',
    fontFamily: 'Menlo',
    fontSize: 14,
  );

  static const persianProfile = Profile(
    id: 'persian',
    name: 'Persian',
    themeId: 'catppuccin_mocha',
    fontFamily: 'Menlo',
    fontSize: 14,
    enableRtl: true,
  );

  static const all = [defaultProfile, persianProfile];
}
