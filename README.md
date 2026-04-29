# Balance Connectée

Application Android Flutter permettant de piloter une balance connectée via Bluetooth Classic (modules HC-05/HC-06 reliés à un Arduino).

## Fonctionnalités

- **Connexion Bluetooth** – sélection parmi les appareils couplés
- **Calibration en deux étapes**
  1. Remise à zéro (envoi `0`) → attente de la réponse Arduino
  2. Tare (envoi `1`) → confirmation « balance prête »
- **Prise de mesure** (envoi `2`) – la mesure reçue est chiffrée en AES puis encodée en Base64
- **Déchiffrement AES** (CBC ou ECB, clé configurable) + décodage Base64
- **Stockage local** (SQLite) – les mesures sont conservées hors-ligne, sans internet
- **Suppression automatique de la plus ancienne** quand le nombre maximum est atteint
- **Bouton « Supprimer la plus ancienne »** pour retirer manuellement la valeur la plus vieille
- **Courbe du poids** – graphique interactif de l'évolution des mesures dans le temps
- **Paramètres** – clé AES, vecteur d'initialisation, mode (CBC/ECB), nombre max de mesures

## Protocole Arduino

| Commande envoyée | Réponse attendue | Signification |
|-----------------|-----------------|---------------|
| `0\n` | Texte contenant « REFERENCE » / « POSE » / … | Placer la masse de référence |
| `1\n` | Texte contenant « PRET » / « OK » / … | Balance tarée et prête |
| `2\n` | `<base64(AES(valeur_en_grammes))>\n` | Mesure chiffrée |

## Installation

Prérequis : [Flutter SDK ≥ 3.0](https://docs.flutter.dev/get-started/install)

```bash
flutter pub get
flutter run
```

## Structure du projet

```
lib/
├── main.dart                   # Point d'entrée + navigation
├── models/
│   └── measurement.dart        # Modèle de mesure
├── services/
│   ├── bluetooth_service.dart  # Connexion BT + protocole
│   ├── crypto_service.dart     # AES + Base64
│   ├── storage_service.dart    # SQLite local
│   └── settings_service.dart  # Paramètres persistants
├── screens/
│   ├── home_screen.dart        # Connexion + calibration + mesure
│   ├── device_list_screen.dart # Sélection de l'appareil BT
│   ├── measurements_screen.dart# Liste des mesures
│   ├── chart_screen.dart       # Courbe du poids
│   └── settings_screen.dart   # Configuration AES
└── widgets/
    ├── measurement_tile.dart   # Tuile de mesure
    ├── weight_chart.dart       # Graphique fl_chart
    └── connection_status_card.dart
```

## Permissions Android

L'application demande au runtime :
- `BLUETOOTH_CONNECT` (Android 12+)
- `BLUETOOTH_SCAN` (Android 12+)
- `BLUETOOTH` + `ACCESS_FINE_LOCATION` (Android ≤ 11)
