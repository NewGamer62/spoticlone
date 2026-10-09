# SpotiClone 🎵

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-black?logo=windows&logoColor=white)](https://github.com/NewGamer62/spoticlone)
[![License: MIT](https://img.shields.io/badge/License-MIT-1DB954.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)]()
[![Clean--Room](https://img.shields.io/badge/Clean--Room-Verified-success.svg)]()

> **SpotiClone** est un lecteur de musique multiplateforme open-source pour Windows et Android, conçu selon une méthodologie clean-room stricte. Il offre une expérience audio fluide et réactive sans publicité, sans DRM et sans compte payant obligatoire.

---

## 📸 Aperçu de l'Interface

```
+-----------------------------------------------------------------------------------------+
| [SpotiClone]               |  Recherche, Accueil & Découvertes  | File d'attente (Queue) |
|                            |------------------------------------|-----------------------|
|  * Accueil                 |  [Good evening]                    | 1. Midnight City      |
|  * Rechercher              |  [Made For You]                    | 2. Cyberpunk Horizon  |
|  * Bibliothèque            |  +---------+  +---------+          | 3. Coffee in Paris    |
|                            |  | Top Hits|  | Lo-Fi   |          |                       |
| -------------------------- |  +---------+  +---------+          | Paroles (LRC Sync)    |
| PLAYLISTS                  |                                    | "Midnight city lights |
|  - Synthwave Retrowave     |  Titres Populaires (Grid & List)   |  calling out our name"|
|  - Deep Focus & Flow       |  1. Midnight City Lights - 03:45   |                       |
+-----------------------------------------------------------------------------------------+
| [Cover] Titre • Artiste    |   [Shuffle] [Prev] (Play) [Next] [Repeat]   | [Mic] [Vol: ===-]   |
|                            |   01:15  ==========================  03:45  |                       |
+-----------------------------------------------------------------------------------------+
```

---

## ⚡ Pitch Fonctionnel & Valeur Ajoutée

Spotify Premium restreint l'écoute hors-ligne, impose un chiffrement DRM propriétaire et enferme les utilisateurs dans un écosystème fermé.
**SpotiClone** résout ces contraintes :
- 🎧 **Streaming illimité & gratuit** : Extraction dynamique des flux audio haute fidélité (320 kbps) sans coupure publicitaire.
- 📱💻 **Multiplateforme adaptatif 100% natif** : Un seul codebase Flutter pour Windows (Win32/C++) et Android, optimisé pour 60/120 FPS.
- 🗄️ **Local-First & Souveraineté des données** : Favoris, playlists personnalisées et historique stockés localement sur votre appareil sans compte requis.
- 🎤 **Paroles synchronisées en direct** : Visualisation karaoké dynamique (format LRC) avec navigation instantanée au clic sur les versets.
- 🔄 **Portabilité totale** : Exportation et importation de vos bibliothèques en format JSON ouvert en un clic.

---

## 🛠️ Stack Technique

| Composant | Technologie | Justification |
| :--- | :--- | :--- |
| **Framework UI** | [Flutter 3.38+](https://flutter.dev) | Rendu natif GPU multiplateforme haute performance, 95%+ de code partagé. |
| **State Management** | [Flutter Riverpod 3](https://riverpod.dev) | Architecture découplée, réactive, sans boilerplate et hautement testable. |
| **Moteur Audio** | `just_audio` & `audio_session` | Faible latence, gestion des interruptions et contrôles multimédia système. |
| **Flux & Extraction** | `youtube_explode_dart` | Recherche audio mondiale et streaming libre sans clé API propriétaire. |
| **Stockage Local** | JSON Local-First & SQLite | Persistance sans dépendance à un serveur cloud, fonctionnement hors-ligne instantané. |
| **Méthodologie** | `replica-skill` | Cycle complet en 11 étapes (Recon, Architect, Design, Build, Test, Sweep, Diff). |

---

## 🚀 Démarrage Rapide

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.38 ou supérieur)
- Git

### Démarrage Automatisé (Recommandé sur Windows)

Exécutez simplement le script PowerShell à la racine : il inspecte votre environnement, installe les outils C++ manquants si nécessaire, résout les dépendances et démarre l'application :

```powershell
.\setup.ps1
```

### Lancement Manuel

```bash
# 1. Cloner le dépôt
git clone https://github.com/NewGamer62/spoticlone.git
cd spoticlone

# 2. Récupérer les dépendances
flutter pub get

# 3. Lancer l'application sur votre plateforme cible
flutter run -d windows   # Pour Windows Desktop
flutter run -d android   # Pour smartphone/tablette Android
```

---

## 🧪 Tests & Qualité

Pour exécuter la suite de tests automatisés et l'analyse de code statique :

```bash
# Vérifier la propreté du code (Zéro avertissement)
flutter analyze

# Lancer la suite de tests unitaires et de widgets
flutter test

# Valider la parité des fonctionnalités (Replica Tool)
python ../.gemini/config/skills/replica-skill/replica-diff/parity.py replica/features.csv
```

---

## ⚖️ Conformité Clean-Room

Ce projet a été développé selon les principes stricts du *clean-room reverse-engineering* :
- Aucun code source propriétaire ou binaire décompilé de Spotify n'a été utilisé.
- Aucun logo, marque déposée ou asset sous copyright n'est inclus.
- Conforme aux règles d'audit du script `sweep.py` du pack `replica-skill`.

---

## 📄 Licence

Distribué sous licence **MIT**. Voir [LICENSE](LICENSE) pour plus d'informations.
Créé par [NewGamer62](https://github.com/NewGamer62).
