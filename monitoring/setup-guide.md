# 🚀 Guia Completo de Implementação da Stack LGTM

## 📋 Índice
1. [Passos de Instalação](#passos-de-instalação)
2. [Configuração do Telegram](#configuração-do-telegram)
3. [Verificação e Testes](#verificação-e-testes)
4. [Dashboard Grafana](#dashboard-grafana)
5. [Troubleshooting](#troubleshooting)
6. [Métricas Disponíveis](#métricas-disponíveis)

---

## 🔧 Passos de Instalação

### 1. Estrutura de Diretórios
```bash
monitoring/
├── config/
│   ├── alertmanager/
│   │   └── alertmanager.yml          # ✅ NOVO
│   ├── alloy/
│   │   └── config.alloy               # ✅ ATUALIZADO
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── dashboards/
│   │   │   │   ├── dashboards.yaml
│   │   │   │   └── system-overview.json
│   │   │   └── datasources/
│   │   │       └── ds.yaml
│   │   └── provisioning/
│   ├── loki/
│   │   └── loki-config.yaml           # ✅ ATUALIZADO
│   ├── mimir/
│   │   ├── mimir-config.yaml          # ✅ ATUALIZADO
│   │   └── alerting-rules.yaml        # ✅ NOVO/MELHORADO
│   └── tempo/
│       └── tempo-config.yaml          # ✅ ATUALIZADO
└── docker-compose.yml                  # ✅ ATUALIZADO
```

### 2. Substituir os Arquivos
Copie os arquivos corrigidos para seu repositório:

```bash
# Copie os arquivos do seu editor
cp alertmanager.yml monitoring/config/alertmanager/
cp config.alloy monitoring/config/alloy/
cp alerting-rules.yaml monitoring/config/mimir/
cp loki-config.yaml monitoring/config/loki/
cp mimir-config.yaml monitoring/config/mimir/
cp tempo-config.yaml monitoring/config/tempo/
cp docker-compose.yml monitoring/
```

### 3. Criar Volumes
```bash
# Criar pastas de dados (se estiver usando volumes tipo bind)
mkdir -p /opt/homelab/data/monitoring/{loki,mimir,tempo,grafana}
chmod 777 /opt/homelab/data/monitoring/*

# OU (melhor opção) - usar Docker volumes (recomendado)
# O docker-compose já vai criar automaticamente
```

---

## 📱 Configuração do Telegram

### Passo 1: Criar Bot no Telegram

1. Abra o Telegram
2. Procure por `@BotFather`
3. Envie `/start` e depois `/newbot`
4. Escolha um nome (ex: "Homelab Alerts")
5. Escolha um username (ex: "homelab_alerts_bot")
6. **Copie o token fornecido** (será algo como `123456789:ABCdefGHIjklmnoPQRstuvWXYzabcDEF`)

### Passo 2: Obter Seu Chat ID

1. No Telegram, procure por `@userinfobot`
2. Envie `/start`
3. Você receberá seu ID de usuário (será algo como `123456789`)

**OU** (melhor para grupos):
1. Crie um grupo no Telegram
2. Adicione o bot que criou
3. Envie uma mensagem no grupo
4. Acesse: `https://api.telegram.org/bot{SEU_TOKEN}/getUpdates`
5. Procure por `"chat":{"id":` - este é seu chat_id

### Passo 3: Atualizar alertmanager.yml

```yaml
receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: '123456789:ABCdefGHIjklmnoPQRstuvWXYzabcDEF'  # Seu token
        chat_id: 123456789  # Seu chat ID
        api_url: 'https://api.telegram.org'
        send_resolved: true
```

### Passo 4: Reiniciar Alertmanager
```bash
docker-compose restart alertmanager
```

### Teste de Envio
```bash
# Abrir shell do alertmanager
docker exec -it monitoring_alertmanager sh

# Testar conectividade
curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"chat_id":"SEU_CHAT_ID","text":"teste"}' \
  https://api.telegram.org/botSEU_TOKEN/sendMessage
```

---

## ✅ Verificação e Testes

### 1. Verificar se containers estão rodando
```bash
cd monitoring/
docker-compose ps
```

Esperado:
```
NAME                      STATUS
monitoring_grafana        Up (healthy)
monitoring_loki           Up (healthy)
monitoring_mimir          Up (healthy)
monitoring_tempo          Up (healthy)
monitoring_alertmanager   Up
monitoring_alloy          Up (healthy)
```

### 2. Acessar as UIs
- **Grafana**: http://localhost:3000 (admin/admin)
- **Mimir**: http://localhost:9009/prometheus
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **Alertmanager**: http://localhost:9093
- **Alloy**: http://localhost:12345

### 3. Verificar Métricas no Grafana
1. Vá para Grafana → Explore
2. Selecione datasource "Mimir"
3. Execute a query: `up`
4. Deve retornar métricas dos componentes

### 4. Verificar Logs no Grafana
1. Vá para Grafana → Explore
2. Selecione datasource "Loki"
3. Execute a query: `{job="docker"}`
4. Deve retornar logs dos containers

### 5. Testar Alertas
```bash
# Gerar um alerta de teste (alto uso de CPU)
# Execute isso no host (pode disparar alertas):
yes > /dev/null &
# depois
kill %1
```

Verifique se recebeu notificação no Telegram!

---

## 📊 Dashboard Grafana

### Adicionar Dashboard System Overview
Já está configurado em `provisioning/dashboards/system-overview.json`

**Se quiser importar de template pronto:**
1. Grafana → Dashboards → New → Import
2. ID: `1860` (Node Exporter for Prometheus)
3. Selecionar datasource "Mimir"
4. Importar

### Criar Dashboard Custom
**Exemplo de panels úteis:**

#### Panel 1: CPU Host
```
Query: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
Legend: CPU Usage
Unit: percent (0-100)
Threshold: 80 (warning), 95 (critical)
```

#### Panel 2: Memory Host
```
Query: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
Legend: Memory Usage
Unit: percent
Threshold: 80 (warning), 95 (critical)
```

#### Panel 3: Container CPU (por container)
```
Query: sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[5m])) * 100
Legend: {{name}}
Unit: short
```

#### Panel 4: Container Memory (por container)
```
Query: sum by (name) (container_memory_usage_bytes{name!=""}) / (1024*1024)
Legend: {{name}}
Unit: bytes (short: MB)
```

#### Panel 5: Logs (Loki)
Query: `{job="docker"} | level="error" or level="ERROR"`

---

## 🔍 Troubleshooting

### ❌ "Alloy não consegue conectar ao Docker"
```bash
# Verificar permissões
ls -la /var/run/docker.sock
# Deve ser (crw-rw---- root docker)

# Se necessário, dar permissão
sudo chmod 666 /var/run/docker.sock

# Ou adicionar usuário do container ao grupo docker
docker exec monitoring_alloy usermod -aG docker nobody
```

### ❌ "Mimir não consegue conectar ao Alertmanager"
```bash
# Verificar logs
docker logs monitoring_mimir | grep -i alert

# Testando conectividade
docker exec monitoring_mimir curl -v http://alertmanager:9093/-/healthy
```

### ❌ "Nenhuma métrica aparecendo"
```bash
# Verificar se Alloy está coletando
docker logs monitoring_alloy | tail -50

# Verificar se as métricas chegam no Mimir
curl http://localhost:9009/api/v1/query?query=up

# Verificar saúde do Mimir
docker exec monitoring_mimir curl http://localhost:9009/-/ready
```

### ❌ "Alertas não estão sendo disparados"
```bash
# Verificar se regras foram carregadas no Mimir
curl http://localhost:9009/prometheus/api/v1/rules

# Ver alertas não resolvidos
curl http://localhost:9093/api/v1/alerts

# Verificar logs do Alertmanager
docker logs monitoring_alertmanager
```

### ❌ "Telegram não recebe mensagens"
```bash
# Verificar configuração do AlertManager
docker exec monitoring_alertmanager cat /etc/alertmanager/alertmanager.yml

# Testar manualmente
docker exec monitoring_alertmanager curl -X POST \
  -d 'chat_id=YOUR_CHAT_ID&text=test' \
  https://api.telegram.org/botYOUR_TOKEN/sendMessage

# Ver logs
docker logs monitoring_alertmanager | grep -i telegram
```

### ❌ "Alto uso de disco"
```bash
# Limpar dados antigos
docker-compose down

# Remover volumes
docker volume rm monitoring_loki_data monitoring_mimir_data

# Reiniciar
docker-compose up -d
```

---

## 📊 Métricas Disponíveis

### Host Metrics (node_exporter)
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemTotal_bytes` - Total memory
- `node_memory_MemAvailable_bytes` - Available memory
- `node_memory_MemFree_bytes` - Free memory
- `node_filesystem_avail_bytes` - Disk space available
- `node_filesystem_size_bytes` - Disk size
- `node_network_receive_bytes_total` - Network RX
- `node_network_transmit_bytes_total` - Network TX
- `node_load1`, `node_load5`, `node_load15` - Load average

### Container Metrics (cAdvisor)
- `container_cpu_usage_seconds_total` - CPU usage
- `container_memory_usage_bytes` - Memory usage
- `container_memory_max_usage_bytes` - Peak memory
- `container_memory_limit_bytes` - Memory limit
- `container_network_receive_bytes_total` - Network RX
- `container_network_transmit_bytes_total` - Network TX
- `container_last_seen` - Timestamp of last metric
- `container_status` - Status do container

### Aplicação Metrics (via OTLP)
Se sua aplicação exportar:
- `duration_seconds_bucket` - Latência de requests
- `requests_total` - Total de requests
- Custom metrics da sua app

---

## 🚀 Próximos Passos

1. **Implementar instrumentação em suas apps:**
   ```python
   # Flask app com OpenTelemetry
   from opentelemetry import trace, metrics
   from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
   from opentelemetry.sdk.trace import TracerProvider
   from opentelemetry.sdk.trace.export import BatchSpanProcessor
   
   trace.set_tracer_provider(TracerProvider())
   trace.get_tracer_provider().add_span_processor(
       BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo:4317"))
   )
   ```

2. **Adicionar mais alertas:** Customize `alerting-rules.yaml`

3. **Criar dashboards específicos** para cada app

4. **Implementar log levels** estruturados em suas apps

5. **Usar structured logging** (JSON) para melhor parsing

---

## 📞 Contato
Qualquer problema? Verifique os logs:
```bash
docker-compose logs -f <service_name>
```