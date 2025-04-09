#!/bin/bash

NODE1_IP="10.24.30.150"
NODE2_IP="10.24.30.151"
NODE3_IP="10.24.30.152"
SSH_USER="secure_user"
SSH_PASS="password"

# Controleer of sshpass is geïnstalleerd
if ! command -v sshpass &> /dev/null; then
    echo "sshpass is niet geïnstalleerd. Installeren..."
    sudo apt-get update && sudo apt-get install -y sshpass
fi

# Stap 6: Run Docker Container op alle nodes
for IP in $NODE1_IP $NODE2_IP $NODE3_IP; do
    echo "Stap 6: Run Docker Container op node: $IP"
    # Pull MySQL image
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker pull mysql"
    
    # Run MySQL container
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker run -d -p 0.0.0.0:80:80 mysql:latest"
    
    # Lijst van containers weergeven
    echo "Docker containers op node $IP:"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker ps -a"
done

# Stap 7: Create Swarm op elke node (3 aparte swarms)
# Zorg ervoor dat nodes eventuele bestaande swarms verlaten
for IP in $NODE1_IP $NODE2_IP $NODE3_IP; do
    echo "Eventuele bestaande swarm verlaten op node: $IP"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker swarm leave -f || true"
done

# Initialiseer een aparte swarm op elke node (elke node wordt een manager)
for IP in $NODE1_IP $NODE2_IP $NODE3_IP; do
    echo "Stap 7: Initialiseren van Docker Swarm op node: $IP"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker swarm init --advertise-addr $IP"
    
    # Controleer swarm status
    echo "Swarm status op node $IP:"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker node ls"
    
    # Creëer HelloWorld service zoals in de opdracht
    echo "HelloWorld service creëren op node $IP:"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker service create --name HelloWorld alpine ping docker.com"
    
    # Controleer services
    echo "Services op node $IP:"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "sudo docker service ls"
done

echo "Drie aparte Docker Swarms zijn succesvol geïnitialiseerd met elk hun eigen manager node!"
echo "Op elke node is een MySQL container gestart en een HelloWorld service gecreëerd."