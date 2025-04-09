#!/bin/bash
# Opruimen
echo "Opruimen..."
sudo docker rm -f mysql1 mysql2 2>/dev/null
sudo docker network rm mysql_net1 mysql_net2 2>/dev/null

# Wacht even om er zeker van te zijn dat alles is opgeruimd
sleep 4

# Maak twee netwerken
echo "Netwerken aanmaken..."
sudo docker network create mysql_net1
sudo docker network create mysql_net2

# Start containers in aparte netwerken
echo "MySQL containers starten..."
sudo docker run -d --name mysql1 --network mysql_net1 \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_ROOT_HOST='%' \
  -p 3306:3306 \
  mysql:latest

sudo docker run -d --name mysql2 --network mysql_net2 \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_ROOT_HOST='%' \
  -p 3307:3306 \
  mysql:latest

# Controleer of containers actief zijn
echo "Controleren of containers actief zijn..."
if ! sudo docker ps | grep -q mysql1; then
  echo "FOUT: mysql1 container draait niet! Logs volgen:"
  sudo docker logs mysql1
  exit 1
fi

if ! sudo docker ps | grep -q mysql2; then
  echo "FOUT: mysql2 container draait niet! Logs volgen:"
  sudo docker logs mysql2
  exit 1
fi

echo "Beide containers draaien correct."

# Wacht tot MySQL volledig is opgestart
echo "Wachten tot MySQL volledig is opgestart..."
max_tries=30
count=0
while ! sudo docker exec mysql1 mysqladmin -uroot -ppassword ping --silent &>/dev/null; do
  sleep 2
  count=$((count + 1))
  echo "Wachten op MySQL1... ($count/$max_tries)"
  if [ $count -ge $max_tries ]; then
    echo "Timeout bij wachten op MySQL1!"
    sudo docker logs mysql1
    exit 1
  fi
done

count=0
while ! sudo docker exec mysql2 mysqladmin -uroot -ppassword ping --silent &>/dev/null; do
  sleep 2
  count=$((count + 1))
  echo "Wachten op MySQL2... ($count/$max_tries)"
  if [ $count -ge $max_tries ]; then
    echo "Timeout bij wachten op MySQL2!"
    sudo docker logs mysql2
    exit 1
  fi
done

echo "MySQL servers zijn volledig opgestart."

# Toon IP-adressen
MYSQL1_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)
MYSQL2_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql2)
echo "MySQL1 IP: $MYSQL1_IP (mysql_net1)"
echo "MySQL2 IP: $MYSQL2_IP (mysql_net2)"

# Test 1: Kan MySQL1 MySQL2 bereiken? (moet mislukken omdat ze in verschillende netwerken zitten)
echo "Test 1: Kan MySQL1 MySQL2 bereiken? (zou moeten mislukken)"
if timeout 3 sudo docker exec mysql1 mysql -h$MYSQL2_IP -uroot -ppassword --connect-timeout=3 -e "SELECT 1" &>/dev/null; then
  echo "Onverwacht: MySQL1 kan MySQL2 al bereiken!"
else
  echo "MySQL1 kan MySQL2 niet bereiken (verwacht resultaat)."
fi

# Test 2: Kan VM de containers bereiken?
echo "Test 2: Kan de VM de containers bereiken?"
# Eerst de poorten testen met netcat
echo "Test poortbereikbaarheid vanaf VM:"
timeout 3 nc -z -v 127.0.0.1 3306 &>/dev/null && echo "Poort 3306 (MySQL1) is bereikbaar!" || echo "Poort 3306 (MySQL1) is NIET bereikbaar."
timeout 3 nc -z -v 127.0.0.1 3307 &>/dev/null && echo "Poort 3307 (MySQL2) is bereikbaar!" || echo "Poort 3307 (MySQL2) is NIET bereikbaar."

# Als mysql client beschikbaar is, test dan ook de daadwerkelijke MySQL verbinding
if command -v mysql &> /dev/null; then
  echo "Test MySQL verbinding vanaf VM:"
  timeout 3 mysql -h127.0.0.1 -P3306 -uroot -ppassword --connect-timeout=3 -e "SELECT 'VM kan MySQL1 bereiken'" &>/dev/null && echo "VM kan MySQL1 bereiken via MySQ>  timeout 3 mysql -h127.0.0.1 -P3307 -uroot -ppassword --connect-timeout=3 -e "SELECT 'VM kan MySQL2 bereiken'" &>/dev/null && echo "VM kan MySQL2 bereiken via MySQ>else
  echo "MySQL client niet gevonden op VM, alleen poorttest uitgevoerd."
fi

# Verbind MySQL1 met het tweede netwerk
echo "MySQL1 verbinden met mysql_net2 netwerk..."
sudo docker network connect mysql_net2 mysql1

# Toon nieuwe netwerkinfo
echo "MySQL1 netwerk informatie na verbinding met beide netwerken:"
sudo docker inspect -f '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}: {{$conf.IPAddress}} {{end}}' mysql1

# Haal specifiek het IP in het mysql_net2 netwerk op
MYSQL1_NET2_IP=$(sudo docker inspect -f '{{index .NetworkSettings.Networks "mysql_net2" "IPAddress"}}' mysql1)
MYSQL2_NET2_IP=$(sudo docker inspect -f '{{index .NetworkSettings.Networks "mysql_net2" "IPAddress"}}' mysql2)
echo "MySQL1 IP in mysql_net2: $MYSQL1_NET2_IP"
echo "MySQL2 IP in mysql_net2: $MYSQL2_NET2_IP"

sleep 6

echo "Test 3: Kan MySQL1 nu MySQL2 bereiken via het gedeelde netwerk?"
if timeout 3 sudo docker exec mysql1 mysql -h$MYSQL2_NET2_IP -uroot -ppassword --connect-timeout=3 -e "SELECT 1" &>/dev/null; then
  echo "Succes! MySQL1 kan MySQL2 nu bereiken via het gedeelde netwerk!"
else
  echo "MySQL1 kan MySQL2 nog steeds niet bereiken."
  echo "Debug info volgt..."
  sudo docker exec mysql1 ping -c 3 $MYSQL2_NET2_IP 2>/dev/null || echo "Ping van MySQL1 naar MySQL2 mislukt."
fi

echo "Docker Netwerk Test Script Voltooid!"
