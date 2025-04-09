# Meerdere Subnetten Creëren met Docker





Docker maakt het mogelijk om containers in verschillende subnetten te plaatsen voor betere controle over netwerkverkeer en beveiliging.





## Hoe Meerdere Subnetten Creëren





Je kunt custom bridge networks maken met specifieke subnetten:





```bash


# Subnet 1 aanmaken


docker network create --subnet=172.18.0.0/16 subnet1





# Subnet 2 aanmaken


docker network create --subnet=172.19.0.0/16 subnet2


```





## Containers in Specifieke Subnetten Plaatsen





Bij het starten van een container kun je specificeren in welk netwerk deze moet draaien:





```bash


# Container in subnet1 plaatsen


docker run --name container1 --network subnet1 image:tag





# Container in subnet2 plaatsen


docker run --name container2 --network subnet2 image:tag


```





## Waarom is Dit Nuttig?





1. **Verbeterde beveiliging**: Containers in verschillende subnetten kunnen standaard niet met elkaar communiceren, wat zorgt voor isolatie.





2. **Gecontroleerde communicatie**: Je kunt expliciet bepalen welke containers met elkaar mogen communiceren door ze aan meerdere netwerken te koppelen.





3. **Netwerksegmentatie**: Je kunt verschillende applicatielagen (database, backend, frontend) in aparte netwerken scheiden.





4. **IP-adresbeheer**: Voorkomt IP-conflicten door verschillende ranges te gebruiken voor verschillende toepassingen.





5. **Multi-tenant omgevingen**: Ideaal voor het hosten van verschillende applicaties of diensten voor verschillende klanten.





## Connectiviteit tussen Subnetten





Standaard kunnen containers in verschillende subnetten niet met elkaar communiceren. Om dit mogelijk te maken:





```bash


# Container aan een extra netwerk koppelen


docker network connect subnet2 container1


```





Dit laat één container in meerdere subnetten deelnemen, waardoor communicatie tussen de subnetten mogelijk wordt.
