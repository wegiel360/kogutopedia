# Kogutopedia

Dziennik / pamiętnik domowego dróbku ze szczególnym uwzględnieniem koguta Tomka.

## Opis

Kogutopedia to wieloplatformowa aplikacja (Android, Linux, Windows) pozwalająca na
prowadzenie dziennika aktywności Twoich kurczaków. Głównym bohaterem jest kogut Tomek,
ale aplikacja wspiera wiele ptaków (Marek, Kasia i inne).

## Funkcje

- **Dziennik aktywności** - Dodawanie wpisów z tytułem, opisem, zdjęciami i filmami
- **Multi-Character** - Obsługa wielu kurczaków z możliwością dodawania własnych imion
- **Media** - Zdjęcia (kadrowanie, kompresja do WebP) i krótkie filmy (do 30s)
- **Statystyki** - Licznik dni z Tomkiem (seria która nigdy nie resetuje się do zera)
- **Gamifikacja** - Codzienne wyzwania, osiągnięcia i medale
- **Dashboard** - Przegląd aktywności, galeria multimediów
- **Responsywne UI** - Dostosowanie do telefonów, tabletów i desktopów
- **Futuristic Glassmorphism** - Nowoczesny design z efektem szkła

## Wymagania

- Flutter SDK 3.16+
- Dart 3.0+
- Android SDK (dla buildów Android)
- Visual Studio / GTK (dla buildów Windows/Linux)

## Instalacja

```bash
git clone https://github.com/wegiel360/kogutopedia.git
cd kogutopedia
flutter pub get
flutter run
```

## Budowanie

```bash
# Android
flutter build apk --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

## Wersjonowanie

- **v0.0.1 - v0.0.9** (Alpha): Eksperymenty, fundamenty, testy stabilności
- **v0.1 - v0.9.9** (Beta): Stabilizacja funkcji, hotfixy
- **v1.0+** (Release): Pełnoprawna wersja stabilna

## Autor

wegiel360

## Licencja

MIT
