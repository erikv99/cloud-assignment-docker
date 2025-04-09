#!/bin/bash
# Basic Docker Networking Commands

echo "Start Docker Networking Commands"

# Toon alle Docker netwerken
echo "1. Lijst van alle Docker netwerken:"
docker network ls

# Maak een demonstratie netwerk
echo "2. Nieuw netwerk maken:"
docker network create multi-host-network

# Start container voor demonstratie
echo "3. Start demo container:"
docker run -d --name container1 alpine sleep 1000

# Start tweede container
echo "4. Start tweede demo container:"
docker run -d --name container2 alpine sleep 1000

# Verbind container met netwerk
echo "5. Verbind container met netwerk:"
docker network connect multi-host-network container1

# Verbind container met specifiek IP
echo "6. Verbind container met specifiek IP:"
docker network connect --ip 172.18.0.10 multi-host-network container2

# Maak netwerk aliassen
echo "7. Maak netwerk aliassen voor container:"
docker network disconnect multi-host-network container2
docker network connect --alias db --alias mysql multi-host-network container2

# Bekijk netwerk details
echo "8. Bekijk netwerk details:"
docker network inspect multi-host-network

# Ontkoppel container van netwerk
echo "9. Ontkoppel container van netwerk:"
docker network disconnect multi-host-network container1

# Maak tijdelijk netwerk voor verwijdering
echo "10. Maak tijdelijk netwerk:"
docker network create temp-network

# Verwijder netwerk
echo "11. Verwijder netwerk:"
docker network rm temp-network

# Verkrijg netwerk ID
echo "12. Verkrijg ID van multi-host-network:"
NETWORK_ID=$(docker network ls --filter name=multi-host-network -q)
echo "Netwerk ID: $NETWORK_ID"

# Verwijder netwerk met ID
echo "13. Verwijder netwerk met ID:"
docker network rm $NETWORK_ID

# Verwijder ongebruikte netwerken
echo "14. Verwijder ongebruikte netwerken:"
docker network prune -f

# Ruim demo containers op
echo "15. Ruim containers op:"
docker rm -f container1 container2

echo "Einde Docker Networking Commands"