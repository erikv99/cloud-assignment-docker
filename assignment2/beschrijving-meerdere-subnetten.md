#!/bin/bash

# Opruimen
echo "Opruimen van bestaande containers en netwerken..."
sudo docker rm -f mysql1 mysql2 2>/dev/null
sudo docker network rm mysql_net1 mysql_net2 2>/dev/null

# Toon alle netwerken en hun subnetten
echo "Bestaande Docker netwerken en hun subnetten:"
for net in $(sudo docker network ls -q); do
  name=$(sudo docker network inspect $net -f '{{.Name}}')
  subnet=$(sudo docker network inspect $net -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
  echo "$name: $subnet"
done

# Maak netwerken zonder subnet specificatie (laat Docker het kiezen)
echo "Netwerken aanmaken zonder subnet specificatie..."
sudo docker network create mysql_net1
sudo docker network create mysql_net2

# Controleer of de netwerken zijn aangemaakt
echo "Controle van aangemaakte netwerken:"
sudo docker network ls | grep mysql_net

# Start containers
echo "Start MySQL containers..."
sudo docker run -d --name mysql1 --network mysql_net1 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql:latest

sudo docker run -d --name mysql2 --network mysql_net2 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3307:3306 \
  mysql:latest

# Wacht tot de containers opstarten
echo "Wachten tot MySQL is opgestart..."
sleep 15

# Toon IP-adressen
MYSQL1_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)
MYSQL2_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql2)

if [ -z "$MYSQL1_IP" ] || [ -z "$MYSQL2_IP" ]; then
  echo "Kon geen IP-adressen verkrijgen. Containers opstarten mislukt?"
  echo "Container status:"
  sudo docker ps -a | grep mysql
  exit 1
fi

echo "MySQL1 IP: $MYSQL1_IP (mysql_net1)"
echo "MySQL2 IP: $MYSQL2_IP (mysql_net2)"

# Test bereikbaarheid
echo "Test of MySQL1 MySQL2 kan bereiken (zou moeten falen)..."
sudo docker exec mysql1 ping -c 2 $MYSQL2_IP || echo "MySQL1 kan MySQL2 niet bereiken (verwacht resultaat)"

# Verbind MySQL1 met het tweede netwerk
echo "Verbind MySQL1 met mysql_net2..."
sudo docker network connect mysql_net2 mysql1

# Test opnieuw
echo "Test opnieuw of MySQL1 MySQL2 kan bereiken (zou moeten slagen)..."
sudo docker exec mysql1 ping -c 2 $MYSQL2_IP && echo "MySQL1 kan MySQL2 nu bereiken!"

echo "Setup voltooid!"