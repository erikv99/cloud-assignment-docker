#!/bin/bash
# Script voor twee MySQL servers in verschillende subnetten

# Verwijder eventuele oude containers en netwerken
echo "Oude containers en netwerken opruimen..."
sudo docker rm -f mysql1 mysql2 2>/dev/null
sudo docker network rm subnet1 subnet2 2>/dev/null

# Lijst alle bestaande Docker netwerken om overlap te voorkomen
echo "Bestaande Docker netwerken:"
sudo docker network ls
echo ""

# Maak twee aparte subnetten met andere IP-ranges
echo "Nieuwe subnetten aanmaken..."
sudo docker network create --subnet=192.168.100.0/24 subnet1
sudo docker network create --subnet=192.168.200.0/24 subnet2

# Controleer of de netwerken zijn aangemaakt
echo "Controleren of netwerken zijn aangemaakt:"
sudo docker network ls | grep subnet
echo ""

# Start eerste MySQL container in subnet1
echo "Starten MySQL1 in subnet1..."
sudo docker run -d --name mysql1 --network subnet1 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql:latest

# Start tweede MySQL container in subnet2
echo "Starten MySQL2 in subnet2..."
sudo docker run -d --name mysql2 --network subnet2 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3307:3306 \
  mysql:latest

# Wacht even tot de containers opstarten
echo "Wachten tot containers zijn opgestart..."
sleep 15

# Verkrijg IP-adressen
MYSQL1_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)
MYSQL2_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql2)

echo "MySQL1 IP: $MYSQL1_IP (subnet1)"
echo "MySQL2 IP: $MYSQL2_IP (subnet2)"

# Test connectiviteit vanaf host naar containers
echo -e "\nTest connectiviteit vanaf host naar containers:"
ping -c 1 $MYSQL1_IP && echo "Host kan MySQL1 bereiken" || echo "Host kan MySQL1 NIET bereiken"
ping -c 1 $MYSQL2_IP && echo "Host kan MySQL2 bereiken" || echo "Host kan MySQL2 NIET bereiken"

# Test of containers elkaar kunnen bereiken (zou moeten falen)
echo -e "\nTest of containers elkaar kunnen bereiken (zou moeten falen):"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 bereiken" || echo "MySQL1 kan MySQL2 NIET bereiken"

# Laat MySQL1 ook in het tweede subnet deelnemen
echo -e "\nVerbind MySQL1 ook met subnet2:"
sudo docker network connect subnet2 mysql1

# Test opnieuw of containers elkaar kunnen bereiken (zou moeten slagen)
echo -e "\nTest opnieuw of containers elkaar kunnen bereiken:"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 nu bereiken" || echo "MySQL1 kan MySQL2 nog steeds NIET bereiken"

# Controleer of de MySQL services draaien
echo -e "\nControleer of MySQL services draaien:"
sudo docker ps | grep mysql

echo -e "\nSetup voltooid!"