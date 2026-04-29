# Balance Connect-E

Application web qui remplace l'application MIT App Inventor d'une balance connectée Bluetooth.

## Fonctionnement

| Bloc App Inventor | Équivalent web |
|---|---|
| `Screen1.Initialize` | `screenInitialize()` – charge la liste depuis `localStorage`, initialise la clé AES |
| `ListPicker1.BeforePicking / AfterPicking` | Bouton **Se connecter** → `navigator.bluetooth.requestDevice()` |
| `BREAK.Click` | Bouton **Déconnecter** |
| `Horloge1.Timer` | `setInterval(onTimer, 500)` |
| `AES1.DecryptData` | `aesDecrypt()` via CryptoJS (mode ECB, clé `B7a6l5a4n3c2e1co`) |
| `TinyDB1.StoreValue / GetValue` | `localStorage` |
| `Liste.Click` | Bouton **Ajouter à la liste** |
| `Vider_liste.Click` | Bouton **Vider la liste** |

## Protocole BLE attendu

L'appareil (balance) envoie des trames via le **Nordic UART Service** :

```
#<données AES chiffrées en Base64>#
```

Après déchiffrement AES-ECB, le message doit commencer par `ENC` suivi de la valeur de poids, par exemple : `ENC75.3 kg`.

## Lancer l'application

Ouvrir `index.html` dans **Chrome** ou **Edge** (navigateurs supportant la Web Bluetooth API).  
Sur mobile Android, utiliser Chrome ≥ 56.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | Structure HTML de l'interface |
| `style.css` | Styles de l'application |
| `app.js` | Logique Bluetooth, AES, timer, persistance |
