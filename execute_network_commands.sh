#!/bin/bash
# Fixed Docker Networking Commands
echo "Start Docker Networking Commands"

# Toon alle Docker netwerken
echo "1. Lijst van alle Docker netwerken:"
sudo docker network ls

# Maak een demonstratie netwerk met subnet specificatie
echo "2. Nieuw netwerk maken met subnet specificatie:"
sudo docker network create multi-host-network

# Start container voor demonstratie
echo "3. Start demo container:"
sudo docker run -d --name container1 alpine sleep 1000

# Start tweede container
echo "4. Start tweede demo container:"
sudo docker run -d --name container2 alpine sleep 1000

# Verbind container met netwerk
echo "5. Verbind container met netwerk:"
sudo docker network connect multi-host-network container1

# Verbind container met specifiek IP (moet binnen subnet bereik zijn)
echo "6. Verbind container met specifiek IP:"
# First disconnect if already connected
sudo docker network disconnect multi-host-network container2 2>/dev/null || true
# Create a new network with proper subnet if needed
sudo docker network rm multi-host-network 2>/dev/null || true
sudo docker network create --subnet=172.18.0.0/16 multi-host-network
# Now connect with specific IP
sudo docker network connect --ip 172.18.0.10 multi-host-network container2

# Maak netwerk aliassen
# Eerst controleren of container al verbonden is en zo ja, ontkoppelen
echo "7. Maak netwerk aliassen voor container:"
if sudo docker network inspect multi-host-network | grep -q container2; then
  sudo docker network disconnect multi-host-network container2
fi
sudo docker network connect --alias db --alias mysql multi-host-network container2

# Bekijk netwerk details
echo "8. Bekijk netwerk details:"
sudo docker network inspect multi-host-network

# Ontkoppel container van netwerk
echo "9. Ontkoppel container van netwerk:"
sudo docker network disconnect multi-host-network container1

# Maak tijdelijk netwerk voor verwijdering
echo "10. Maak tijdelijk netwerk:"
sudo docker network create temp-network

# Verwijder netwerk
echo "11. Verwijder netwerk:"
sudo docker network rm temp-network

# Verkrijg netwerk ID
echo "12. Verkrijg ID van multi-host-network:"
NETWORK_ID=$(sudo docker network ls --filter name=multi-host-network -q)
echo "Netwerk ID: $NETWORK_ID"

# Verwijder netwerk met ID - eerst alle containers ontkoppelen
echo "13. Verwijder netwerk met ID (na ontkoppelen containers):"
sudo docker network disconnect multi-host-network container2 2>/dev/null || true
sudo docker network rm $NETWORK_ID

# Verwijder ongebruikte netwerken
echo "14. Verwijder ongebruikte netwerken:"
sudo docker network prune -f

# Ruim demo containers op
echo "15. Ruim containers op:"
sudo docker rm -f container1 container2 2>/dev/null || true

echo "Einde Docker Networking Commands"