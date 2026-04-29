# Balance Connectée

Application Flutter/Dart de balance connectée via Bluetooth à une carte Arduino.

## Fonctionnalités

- 🔵 **Connexion Bluetooth** à un appareil Arduino appairé
- ⚖️ **Zéro kg** : règle le zéro de la balance
- 🔧 **Tarage** : tare la balance avec une masse de référence
- 📏 **Mesure** : récupère le poids chiffré (AES + Base64), le déchiffre et l'affiche
- 💾 **Historique** : stocke jusqu'à 50 mesures localement (FIFO)
- 📈 **Courbe du poids** : graphique de l'évolution dans le temps

## Protocole Bluetooth Arduino

| Commande envoyée | Action Arduino         | Réponse Arduino             |
|-----------------|------------------------|-----------------------------|
| `"0"`           | Règle le zéro          | message texte de confirmation |
| `"1"`           | Demande de tarage      | `"balance prete"`           |
| `"2"`           | Demande de mesure      | mesure chiffrée (AES-ECB + Base64) |

## Structure du projet

```
lib/
├── main.dart
├── models/
│   └── mesure.dart               # Modèle de données
├── services/
│   ├── bluetooth_service.dart    # Communication BT avec Arduino
│   ├── crypto_service.dart       # Déchiffrement AES + Base64
│   └── storage_service.dart      # Stockage local (SharedPreferences)
├── screens/
│   ├── home_screen.dart          # Connexion + commandes balance
│   ├── historique_screen.dart    # Liste des mesures
│   └── courbe_screen.dart        # Graphique d'évolution
└── widgets/
    └── mesure_card.dart          # Carte d'affichage d'une mesure
android/
└── app/src/main/AndroidManifest.xml  # Permissions Bluetooth Android
```

## Stack technique

| Dépendance | Version | Rôle |
|------------|---------|------|
| `flutter_bluetooth_serial` | ^0.4.0 | Communication Bluetooth |
| `encrypt` | ^5.0.3 | Déchiffrement AES + Base64 |
| `fl_chart` | ^0.68.0 | Graphique d'évolution |
| `shared_preferences` | ^2.2.3 | Stockage local |
| `permission_handler` | ^11.3.0 | Permissions Bluetooth Android |
| `intl` | ^0.19.0 | Formatage dates |

## Chiffrement

L'Arduino encode la mesure en **AES-ECB** puis en **Base64**. La clé partagée est `1234567890123456` (16 octets). À modifier dans `lib/services/crypto_service.dart` pour une utilisation en production.

## Installation

```bash
flutter pub get
flutter run
```

> ⚠️ L'application nécessite un appareil Android avec Bluetooth classique (Bluetooth Serial / SPP). Le Bluetooth BLE n'est pas supporté.

## Permissions Android

Les permissions suivantes sont déclarées dans `AndroidManifest.xml` :
- `BLUETOOTH` / `BLUETOOTH_ADMIN` (Android ≤ 11)
- `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` (Android 12+)
- `ACCESS_FINE_LOCATION` (requis pour le scan BT sur certains appareils)
