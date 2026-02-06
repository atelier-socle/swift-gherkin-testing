# language: fr
@auth
Fonctionnalité: Authentification
  Les utilisateurs peuvent se connecter.

  Scénario: Connexion réussie
    Soit l'application est lancée
    Quand l'utilisateur entre "alice" et "secret123"
    Alors il devrait voir le tableau de bord
