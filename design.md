# Design System: Futuristic Glassmorphism

## Philosophy
Aplikacja utrzymana w stylu Futuristic Glassmorphism - połączenie efektu szkła
(szklanych, półprzezroczystych powierzchni) z futurystycznymi, neonowymi akcentami.

## Kolorystyka

| Rola | Kolor | Hex | Użycie |
|------|-------|-----|--------|
| Background | Dark Navy | `#020814` | Tło główne aplikacji |
| Text Primary | White | `#FFFFFF` | Podstawowy tekst |
| Accent | Cyan | `#00F0FF` | Akcenty, przyciski, podświetlenia |
| Glass | Glass White | `#FFFFFF10` | Powierzchnie półprzezroczyste |
| Glass Hover | Glass White Hover | `#FFFFFF20` | Powierzchnie po najechaniu |
| Border | Border Glow | `#00F0FF80` | Świecące obwódki elementów |
| Error | Red | `#FF4466` | Komunikaty błędów |
| Success | Green | `#00FF88` | Sukces, osiągnięcia |
| Warning | Amber | `#FFB800` | Ostrzeżenia |

## Typografia

| Styl | Rozmiar | Font |
|------|---------|------|
| Hero | `clamp(2.5rem, 5vw, 4rem)` | Exo 2 |
| H1 | `2.25rem` (36px) | Exo 2 |
| H2 | `1.5rem` (24px) | Exo 2 |
| Body | `1rem / 1.6` (16px) | Exo 2 |
| Small | `0.875rem` (14px) | Exo 2 |
| Mono | `0.875rem` | JetBrains Mono |

## Glassmorphism Effect

```css
.glass-card {
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(0, 240, 255, 0.5);
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 240, 255, 0.1);
}
```

## Ergonomia (Fat-Finger Friendly)

- Minimalna wysokość przycisków: 56px
- Marginesy: minimum 20px
- Elementy interaktywne w zasięgu kciuka (dolna połowa ekranu)
- Odstępy między elementami: minimum 12px

## Responsywność

- **Desktop (12-34 cali)**: Dwukolumnowa/trzykolumnowa siatka
- **Telefon (5.5-6.9 cala)**: Jednokolumnowy układ pionowy
- **Tablet (7-13 cali)**: Widok dwupanelowy (lista + szczegóły)
