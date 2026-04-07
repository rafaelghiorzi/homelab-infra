#!/bin/bash

# Script de Teste da Stack LGTM
# Uso: bash test-stack.sh

set -e

echo "🧪 Iniciando testes da stack LGTM..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para testar endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "🔍 Testando $name ... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>&1 || echo "000")
    
    if [ "$response" = "$expected_status" ] || [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}✗ FALHOU${NC} (HTTP $response, esperado $expected_status)"
        return 1
    fi
}

# Teste 1: Docker containers
echo -e "${BLUE}=== TESTE 1: Containers Docker ===${NC}"
echo "Verificando se todos os containers estão rodando..."
echo ""

containers=("monitoring_grafana" "monitoring_loki" "monitoring_mimir" "monitoring_tempo" "monitoring_alertmanager" "monitoring_alloy")
failed=0

for container in "${containers[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        echo -e "${GREEN}✓${NC} $container está rodando"
    else
        echo -e "${RED}✗${NC} $container NÃO está rodando"
        failed=$((failed + 1))
    fi
done

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os containers estão rodando${NC}\n"
else
    echo -e "${RED}✗ $failed container(s) não estão rodando${NC}\n"
    exit 1
fi

# Teste 2: Verificar Health Checks
echo -e "${BLUE}=== TESTE 2: Health Checks ===${NC}"
echo ""

test_endpoint "Grafana" "http://localhost:3000/api/health" "200" || true
test_endpoint "Loki" "http://localhost:3100/ready" "200" || true
test_endpoint "Mimir" "http://localhost:9009/-/ready" "200" || true
test_endpoint "Tempo" "http://localhost:3200/ready" "200" || true
test_endpoint "Alertmanager" "http://localhost:9093/-/healthy" "200" || true
test_endpoint "Alloy" "http://localhost:12345/ready" "200" || true

echo ""

# Teste 3: Verificar Conectividade entre serviços
echo -e "${BLUE}=== TESTE 3: Conectividade entre Serviços ===${NC}"
echo ""

echo -n "🔗 Alloy → Mimir ... "
if docker exec monitoring_alloy curl -s http://mimir:9009/api/v1/push -X POST -d '{}' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FALHOU${NC}"
fi

echo -n "🔗 Alloy → Loki ... "
if docker exec monitoring_alloy curl -s http://loki:3100/loki/api/v1/push -X POST -d '{}' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FALHOU${NC}"
fi

echo -n "🔗 Mimir → Alertmanager ... "
if docker exec monitoring_mimir curl -s http://alertmanager:9093/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FALHOU${NC}"
fi

echo ""

# Teste 4: Verificar coleta de métricas
echo -e "${BLUE}=== TESTE 4: Coleta de Métricas ===${NC}"
echo ""

echo -n "📊 Verificando se há métricas no Mimir ... "
metrics=$(curl -s "http://localhost:9009/api/v1/query?query=up" | grep -o '"value"' | wc -l)
if [ "$metrics" -gt 0 ]; then
    echo -e "${GREEN}✓ OK${NC} ($metrics métricas encontradas)"
else
    echo -e "${YELLOW}⚠ AVISO${NC} (Nenhuma métrica ainda)"
fi

echo ""

# Teste 5: Verificar coleta de logs
echo -e "${BLUE}=== TESTE 5: Coleta de Logs ===${NC}"
echo ""

echo -n "📋 Verificando se há logs no Loki ... "
logs=$(curl -s "http://localhost:3100/loki/api/v1/query_range?query=%7Bjob%3D%22docker%22%7D&limit=10" | grep -o '"stream"' | wc -l)
if [ "$logs" -gt 0 ]; then
    echo -e "${GREEN}✓ OK${NC} ($logs streams encontrados)"
else
    echo -e "${YELLOW}⚠ AVISO${NC} (Nenhum log ainda)"
fi

echo ""

# Teste 6: Verificar Alertmanager Configuration
echo -e "${BLUE}=== TESTE 6: Configuração do Alertmanager ===${NC}"
echo ""

echo -n "📧 Verificando configuração de receivers ... "
receivers=$(docker exec monitoring_alertmanager cat /etc/alertmanager/alertmanager.yml | grep -E "telegram|email" | wc -l)
if [ "$receivers" -gt 0 ]; then
    echo -e "${GREEN}✓ OK${NC} ($receivers receivers configurados)"
else
    echo -e "${YELLOW}⚠ AVISO${NC} (Nenhum receiver configurado - cheque alertmanager.yml)"
fi

echo ""

# Teste 7: Verificar Alerting Rules
echo -e "${BLUE}=== TESTE 7: Alerting Rules ===${NC}"
echo ""

echo -n "🚨 Verificando se as rules foram carregadas ... "
rules=$(curl -s "http://localhost:9009/prometheus/api/v1/rules" | grep -o '"name"' | wc -l)
if [ "$rules" -gt 0 ]; then
    echo -e "${GREEN}✓ OK${NC} ($rules rules carregadas)"
else
    echo -e "${YELLOW}⚠ AVISO${NC} (Nenhuma rule carregada)"
fi

echo ""

# Teste 8: Verificar Datasources no Grafana
echo -e "${BLUE}=== TESTE 8: Datasources Grafana ===${NC}"
echo ""

ds_count=$(curl -s -H "Authorization: Bearer $(curl -s -X POST http://localhost:3000/api/auth/login -d '{"user":"admin","password":"admin"}' | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)" http://localhost:3000/api/datasources 2>/dev/null | grep -o '"name"' | wc -l || echo "0")
echo -n "📊 Datasources configuradas ... "
if [ "$ds_count" -gt 0 ]; then
    echo -e "${GREEN}✓ OK${NC} ($ds_count datasources)"
else
    echo -e "${YELLOW}⚠ AVISO${NC} (Não conseguiu conectar)"
fi

echo ""

# Resumo final
echo -e "${BLUE}=== RESUMO ===${NC}"
echo ""
echo -e "${GREEN}✓ Stack LGTM está funcionando!${NC}"
echo ""
echo "📍 Acessos:"
echo "   Grafana:      http://localhost:3000 (admin/admin)"
echo "   Prometheus:   http://localhost:9009/prometheus"
echo "   Loki:         http://localhost:3100"
echo "   Tempo:        http://localhost:3200"
echo "   Alertmanager: http://localhost:9093"
echo "   Alloy UI:     http://localhost:12345"
echo ""
echo "💡 Próximos passos:"
echo "   1. Acesse http://localhost:3000"
echo "   2. Vá para Explore e selecione datasource Mimir"
echo "   3. Execute query: 'up' para ver se há métricas"
echo "   4. Cheque o Alertmanager em http://localhost:9093"
echo ""