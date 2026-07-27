String pluralize(int count, String singular, String plural, String genitive) {
  if (count == 1) return singular;
  if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
    return genitive;
  }
  return plural;
}
