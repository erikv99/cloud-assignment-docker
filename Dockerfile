FROM ubuntu:20.04

MAINTAINER ErikV

# Update packages en installeer nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Maak een simpel HTML-bestand
RUN echo '<html><body><h1>Docker op Proxmox Node $(hostname)</h1><p>Dit is een test container voor de portfolio-opdracht</p></body></html>' > /var/www/html/index.html

# Poort 80 openstellen
EXPOSE 80

# Nginx starten in foreground
CMD ["nginx", "-g", "daemon off;"]