# 🚀 Setup organizado do homelab

## **1. Preparação inicial do sistema**

Antes de tudo, garanta que o sistema está atualizado:

```bash
sudo apt update && sudo apt upgrade -y
```

Adicionar `dias ALL=(ALL) NOPASSWD:ALL` no final do visudo

```bash
sudo visudo
```


---

## **2. Instalar e configurar SSH (acesso remoto)**

Isso vem primeiro para garantir que você consiga acessar a máquina remotamente caso algo dê errado depois.

```bash
sudo apt install ssh -y
sudo systemctl start ssh
sudo systemctl enable ssh
```

---

## **3. Configurar Firewall (segurança básica)**

Agora que o SSH já está ativo, você pode proteger a máquina:

```bash
sudo ufw enable
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
```

---

## **4. Instalar Git e clonar o repositório**

Com acesso e segurança configurados, você baixa sua infra:

```bash
sudo apt-get install git -y

cd /opt/
sudo mkdir -p homelab
sudo chown -R $USER:$USER /opt/homelab
sudo chown -R dias:dias /opt/homelab

cd /opt/homelab
git clone https://github.com/rafaelghiorzi/homelab-infra
```

Adicionar os secrets no servidor

```env
UPLOAD_LOCATION= /opt/homelab/data/immich/library
DB_DATA_LOCATION= /opt/homelab/data/immich/postgres
IMMICH_VERSION=v2
DB_PASSWORD=16181512
DB_USERNAME=postgres
DB_DATABASE_NAME=immich

POSTGRES_PASSWORD=16181512
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
NEXTCLOUD_DATA= /opt/homelab/data/nextcloud/library
POSTGRES_DATA= /opt/homelab/data/nextcloud/postgres
```

```bash
mkdir /opt/homelab/secrets
nano /opt/homelab/secrets/.env
```


---

## **5. Instalar Docker (base para containers)**

Docker é dependência central, então vem antes de runners ou serviços.

```bash
sudo apt install ca-certificates curl -y

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Adicionar repositório:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Instalar Docker:

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

### **5.1 Testar Docker**

```bash
sudo systemctl status docker
```

(opcional, mas recomendado)

```bash
sudo usermod -aG docker $USER
sudo usermod -aG docker dias
```

---

## **6. Instalar GitHub Actions Runner**

Agora que Docker já está pronto, você instala o runner:

```bash
sudo mkdir -p /opt/actions-runner
sudo chown -R $USER:$USER /opt/actions-runner

cd /opt/actions-runner
```

Baixar:

```bash
curl -o actions-runner-linux-x64-2.333.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.333.1/actions-runner-linux-x64-2.333.1.tar.gz
tar xzf ./actions-runner-linux-x64-2.333.1.tar.gz
```

Configurar:

```bash
./config.cmd --url https://github.com/rafaelghiorzi/homelab-infra --token APOYEHG2WFRA6IESESTFIRTJ2WH34
```

Instalar como serviço:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo systemctl enable actions.runner.rafaelghiorzi-homelab-infra.ghiorzi-homelab.service
```

---

## **7. Instalar Cloudflare Tunnel (acesso externo seguro)**

Por último, exposição externa — só depois de tudo funcionando.

```bash
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
```

```bash
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
```

```bash
sudo apt-get update && sudo apt-get install cloudflared
```

```bash
cloudflared tunnel login
```

```bash
cloudflared tunnel create <NAME>
```

This part is manual, after creating the tunnel and getting the id, modify the /cloudflare/config.yml in the repo to match the ip, and modify it on github aswell

```bash
nano /opt/homelab/homelab-infra/cloudflare/config.yml
sudo cloudflared --config /opt/homelab/homelab-infra/cloudflare/config.yml service install
systemctl start cloudflared
systemctl restart cloudflared
```

