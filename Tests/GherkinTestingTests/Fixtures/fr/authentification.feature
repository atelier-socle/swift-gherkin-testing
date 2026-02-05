# language: fr
Fonctionnalité: Authentification
  En tant qu'utilisateur enregistré
  Je veux me connecter à mon compte

  Scénario: Connexion réussie
    Soit un utilisateur enregistré
    Quand il entre ses identifiants
    Alors il voit le tableau de bord

  Scénario: Mot de passe invalide
    Soit un utilisateur enregistré
    Quand il entre un mauvais mot de passe
    Alors il voit un message d'erreur
