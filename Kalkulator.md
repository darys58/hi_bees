# Kalkulator pszczelarskich syropów cukrowych

## Opis

Funkcjonalność kalkulatora jest dostępna z ekranu Ustawień (Settings), pomiędzy "Parametryzacja" a "O aplikacji".

## Ekrany

### CalculatorScreen (`/calculator`)
- Lista dostępnych kalkulatorów
- Każdy kalkulator to osobny panel (Card + ListTile)

### SyrupCalculatorScreen (`/syrup-calculator`)
- Kalkulator syropu cukrowego 3:2

## Matematyka kalkulatora 3:2

Proporcja: 3 części cukru : 2 części wody (wagowo/objętościowo)
Gęstość syropu 60%: ~1.29 kg/L

### Wpisanie cukru (S kg):
```
Woda = S * 2/3 L
Masa = S + Woda = S * 5/3 kg
Objętość = Masa / 1.29 L
```

### Wpisanie wody (W L):
```
Cukier = W * 3/2 kg
Masa = Cukier + W = W * 5/2 kg
Objętość = Masa / 1.29 L
```

### Suwak objętości (V L):
```
Masa = V * 1.29 kg
Cukier = Masa * 3/5 kg
Woda = Masa * 2/5 L
```

### Suwak masy (M kg):
```
Objętość = M / 1.29 L
Cukier = M * 3/5 kg
Woda = M * 2/5 L
```

## Zakresy suwaków
- Objętość: 0 - 50 L
- Masa: 0 - 64.5 kg (~50 * 1.29)

## Klucze lokalizacji

| Klucz | PL | EN |
|-------|----|----|
| calculator | Kalkulator | Calculator |
| sugarSyrup32 | Syrop cukrowy 3:2 | Sugar syrup 3:2 |
| sugar | Cukier | Sugar |
| water | Woda | Water |
| result | Wynik | Result |
| resultLiters | Wynik w litrach | Result in liters |
| resultKilograms | Wynik w kilogramach | Result in kilograms |
| syrupCalculator | Kalkulator syropu | Syrup calculator |

## Plany rozwoju
- Kalkulator syropu 2:1
- Kalkulator syropu 1:1
