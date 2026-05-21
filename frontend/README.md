1-Présentation
LabManager est une application mobile cross-platform (Android & iOS) conçue pour numériser et automatiser la gestion d'un laboratoire informatique académique au sein d'une université publique.
Elle remplace les méthodes manuelles (papier, Excel) par un système centralisé permettant de :

Réserver des postes de travail ou la salle entière
Suivre l'état des équipements en temps réel
Signaler et gérer les incidents techniques
Recevoir des notifications push automatiques


2-Fonctionnalités principales
 -Authentification :Connexion sécurisée par rôle (Étudiant / Enseignant / Admin)-Réservations : Calendrier interactif, réservation de poste ou de salle entière
 -Équipements : Inventaire numérique avec suivi d'état en temps réel
 -Incidents : Signalement de pannes avec photo, suivi par l'admin
 -Notifications : Notifications push via Firebase Cloud Messaging
 -Rapports : Statistiques d'utilisation, export PDF/CSV

3-Acteurs du système

-Étudiant : Réserve un poste, consulte le planning, signale des incidents
-Enseignant : — Réserve la salle entière, planifie des séances récurrentes
-Administrateur :— Gère tout : équipements, utilisateurs, validations, rapports


4-Stack technique
-Frontend mobile : Flutter 3.x (Dart) + Provider
-Backend API : Node.js + Express.js
-Base de données : PostgreSQL
-AuthentificationJWT : (JSON Web Token)
-Notifications push : Firebase Cloud Messaging (FCM)
-Stockage médias :Firebase Storage
-Versionnement :Git + GitHub

5-Compatibilite
Android : version 8.0 et supérieure (testé sur Nokia 3.2 — Android 10)
iOS : version 13 et supérieure (testé sur iPhone X — iOS 16.7.11)