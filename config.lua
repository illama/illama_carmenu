Config = {}

-- Seuil de vitesse considéré comme "à l'arrêt" (en m/s)
Config.StationarySpeedThreshold = 0.5

-- Distance maximale entre le joueur et le véhicule pour valider le changement (en mètres)
Config.MaxDistanceVehicle = 5.0

-- Dictionnaire des noms de sièges par modèle de véhicule
Config.VehicleSeatNames = {
    [GetHashKey("adder")] = {
        [-1] = "Siège conducteur (Adder)",
        [0] = "Siège passager avant (Adder)"
    },
    [GetHashKey("t20")] = {
        [-1] = "Siège conducteur (T20)",
        [0] = "Siège passager avant (T20)"
    },
    [GetHashKey("stretch")] = {
        [-1] = "Conducteur (Stretch)",
        [0] = "Passager avant (Stretch)",
        [1] = "Arrière gauche (Stretch)",
        [2] = "Arrière droit (Stretch)"
    }
    -- Ajoutez d'autres véhicules si nécessaire
}
