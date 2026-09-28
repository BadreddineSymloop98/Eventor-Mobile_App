/// Which language's copy a bilingual form is showing — P7's and P11's
/// `English | عربي` control. The app's own language is a separate thing: an
/// English-speaking provider still writes the Arabic title.
enum ContentLanguage {
  english('en'),
  arabic('ar');

  const ContentLanguage(this.code);

  /// `en` / `ar`, as `LocalizedText.of` takes it.
  final String code;
}
