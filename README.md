1-PRESENTATION PROJET 
LabManager est une application mobile développée pour Android, destinée à améliorer la gestion d'un laboratoire informatique universitaire.
Elle remplace les méthodes manuelles (papier, Excel) par un système centralisé permettant de :

-Réserver des postes de travail ou la salle entière
-Consulter le planning du laboratoire
-Suivre l'état des équipements en temps réel
-Signaler et gérer les incidents techniques
-Recevoir des notifications push automatiques


2-FONCTIONNALITES PRINCIPALES
 A-Authentification :
 -Connexion sécurisée par rôle (Étudiant / Enseignant / Admin)
 B-Réservations : 
 -Calendrier interactif,
 -réservation de poste ou de salle entière
 C-Équipements : 
 -Gestion des équipements informatiques
 -Suivi de l'état des équipements
 D-Incidents : 
 -Signalement des incidents techniques
 -Suivi et traitement des incidents
 E-Notifications : 
 -Notifications push via Firebase Cloud Messaging
 F-Rapports et Statistiques


3-ACTEURS DU SYSTEMES
-Étudiant : Réserve un poste, consulte le planning, signale des incidents
-Enseignant : — Réserve la salle entière, planifie des séances récurrentes
-Administrateur :— Gère tout : équipements, utilisateurs, validations, rapports


4-STACK TECHNIQUE
-Frontend mobile : Flutter (Dart) 
-Backend API : Node.js + Express.js
-Base de données : PostgreSQL
-AuthentificationJWT : (JSON Web Token)
-Notifications push : Firebase Cloud Messaging (FCM)
-Versionnement :Git + GitHub

5-COMPATIBILITE
Android 8.0 (API 26) ou supérieur
Application testée sur Nokia 3.2 (Android 10)
