#!/bin/bash
# Minimaal script voor de opdracht: twee MySQL servers in verschillende subnetten

# Verwijder eventuele oude containers en netwerken
sudo docker rm -f mysql1 mysql2 2>/dev/null
sudo docker network rm subnet1 subnet2 2>/dev/null

# Maak twee aparte subnetten
sudo docker network create --subnet=172.18.0.0/16 subnet1
sudo docker network create --subnet=172.19.0.0/16 subnet2

# Start eerste MySQL container in subnet1
sudo docker run -d --name mysql1 --network subnet1 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql:latest

# Start tweede MySQL container in subnet2
sudo docker run -d --name mysql2 --network subnet2 \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3307:3306 \
  mysql:latest

# Wacht even tot de containers opstarten
sleep 5

# Verkrijg IP-adressen
MYSQL1_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)
MYSQL2_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql2)

echo "MySQL1 IP: $MYSQL1_IP (subnet1)"
echo "MySQL2 IP: $MYSQL2_IP (subnet2)"

# Test connectiviteit vanaf host naar containers
echo -e "\nTest connectiviteit vanaf host naar containers:"
ping -c 1 $MYSQL1_IP && echo "Host kan MySQL1 bereiken" || echo "Host kan MySQL1 NIET bereiken"
ping -c 1 $MYSQL2_IP && echo "Host kan MySQL2 bereiken" || echo "Host kan MySQL2 NIET bereiken"

# Test of containers elkaar kunnen bereiken 
echo -e "\nTest of containers elkaar kunnen bereiken (zou moeten falen):"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 bereiken" || echo "MySQL1 kan MySQL2 NIET bereiken"

# Laat MySQL1 ook in het tweede subnet deelnemen
echo -e "\nVerbind MySQL1 ook met subnet2:"
sudo docker network connect subnet2 mysql1

# Test opnieuw of containers elkaar kunnen bereiken
echo -e "\nTest opnieuw of containers elkaar kunnen bereiken:"
sudo docker exec mysql1 ping -c 1 $MYSQL2_IP && echo "MySQL1 kan MySQL2 nu bereiken" || echo "MySQL1 kan MySQL2 nog steeds NIET bereiken"

echo -e "\nSetup voltooid!"