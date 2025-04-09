#!/bin/bash
# Script voor twee MySQL servers in verschillende subnetten

# Verwijder eventuele oude containers
echo "Oude containers opruimen..."
sudo docker rm -f mysql1 mysql2 2>/dev/null

# Verwijder eventuele oude testnetwerken
echo "Oude testnetwerken opruimen..."
sudo docker network rm mysql_net1 mysql_net2 2>/dev/null

# Maak twee nieuwe netwerken met niet-overlappende subnetten
echo "Nieuwe netwerken aanmaken..."
sudo docker network create --subnet=10.10.10.0/24 mysql_net1
sudo docker network create --subnet=10.20.20.0/24 mysql_net2

# Start eerste MySQL container in mysql_net1
echo "MySQL1 starten in mysql_net1..."
sudo docker run -d --name mysql1 --network mysql_net1 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql:latest

# Start tweede MySQL container in mysql_net2
echo "MySQL2 starten in mysql_net2..."
sudo docker run -d --name mysql2 --network mysql_net2 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3307:3306 \
  mysql:latest

# Wacht even tot de containers opstarten
echo "Wachten tot containers zijn opgestart..."
sleep 10

# Verkrijg IP-adressen
MYSQL1_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)
MYSQL2_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql2)

echo "MySQL1 IP: $MYSQL1_IP (mysql_net1)"
echo "MySQL2 IP: $MYSQL2_IP (mysql_net2)"

# Test connectiviteit vanaf host naar containers
echo -e "\nTest connectiviteit vanaf host naar containers:"
ping -c 1 $MYSQL1_IP && echo "Host kan MySQL1 bereiken" || echo "Host kan MySQL1 NIET bereiken"
ping -c 1 $MYSQL2_IP && echo "Host kan MySQL2 bereiken" || echo "Host kan MySQL2 NIET bereiken"

# Test of containers elkaar kunnen bereiken (zou moeten falen)
echo -e "\nTest of containers elkaar kunnen bereiken (zou moeten falen):"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 bereiken" || echo "MySQL1 kan MySQL2 NIET bereiken"

# Verbind MySQL1 met het tweede netwerk
echo -e "\nVerbind MySQL1 ook met mysql_net2:"
sudo docker network connect mysql_net2 mysql1

# Test opnieuw of containers elkaar kunnen bereiken
echo -e "\nTest opnieuw of containers elkaar kunnen bereiken:"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 nu bereiken" || echo "MySQL1 kan MySQL2 nog steeds NIET bereiken"

# Controleer of de MySQL services draaien
echo -e "\nControleer of MySQL services draaien:"
sudo docker ps | grep mysql

echo -e "\nSetup voltooid!"