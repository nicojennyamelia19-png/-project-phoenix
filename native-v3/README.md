# Project Phoenix V3 Native

Application iPhone SwiftUI conçue pour fonctionner avec Apple Santé, Apple Watch et WorkoutKit.

## Fonctions déjà codées

- Autorisation Apple Santé.
- Import des entraînements de l’Apple Watch et des apps qui écrivent dans Apple Santé.
- Identification de la source Adidas / Runtastic lorsqu’elle est fournie par HealthKit.
- Détection automatique de la séance prévue du jour.
- Durée, distance, allure, calories, fréquence cardiaque moyenne, pas, sommeil, fréquence cardiaque au repos et VO₂ max.
- Lecture et affichage du parcours GPS HealthKit sur MapKit.
- Envoi d’une séance simple ou fractionnée vers l’app Exercice de l’Apple Watch avec WorkoutKit.
- Programmation de la séance du jour à 18 h.
- Annonces vocales iPhone en français.
- Recettes, hydratation et constructeur d’assiette.
- Profils amis CloudKit avec code d’invitation. Seules les statistiques d’entraînement non médicales sont partagées.

## Important concernant Adidas Running

Project Phoenix ne se connecte pas directement au compte Adidas. Il lit les séances qu’Adidas Running écrit dans Apple Santé. Sur l’iPhone, autoriser Adidas Running à écrire les entraînements dans Santé, puis autoriser Project Phoenix à lire les entraînements.

## Générer le projet Xcode

Le dépôt utilise XcodeGen afin que le projet soit reproductible :

```bash
brew install xcodegen
cd native-v3
xcodegen generate
open ProjectPhoenixV3.xcodeproj
```

## Mise sur iPhone sans posséder de Mac

La voie prévue dans ce dépôt est Codemagic + TestFlight.

1. S’inscrire à l’Apple Developer Program.
2. Dans Apple Developer, créer l’identifiant `com.nicolasfontaine.projectphoenix`.
3. Activer HealthKit et iCloud/CloudKit sur cet identifiant.
4. Créer le conteneur iCloud `iCloud.com.nicolasfontaine.projectphoenix` et l’associer à l’identifiant.
5. Dans App Store Connect, créer une app avec le même Bundle ID.
6. Connecter le dépôt GitHub à Codemagic.
7. Ajouter une intégration App Store Connect nommée `project-phoenix-asc` avec une clé API App Store Connect.
8. Lancer le workflow `phoenix-v3-testflight` sur la branche `phoenix-v3-native`.
9. Installer la build depuis l’app TestFlight sur l’iPhone.

Le premier lancement sur un vrai iPhone demandera les autorisations Apple Santé. Les données HealthKit ne sont pas disponibles dans le simulateur comme sur un appareil réel.

## Confidentialité

Les données de santé restent dans HealthKit et sont lues uniquement après autorisation. Le profil partagé avec les amis ne contient ni poids, ni sommeil, ni fréquence cardiaque, ni parcours GPS.
