# 🚀 TrackNow AWS Architecture - Infrastructure as Code (IaC)

**Bootcamp Cloud & DevOps - Grupo 1 - CLC14 - IMPACTA**

Código Terraform completo para provisionar a arquitetura AWS Multi-AZ da plataforma TrackNow de rastreamento de entregas B2B.

## 📋 Visão Geral

Este repositório contém toda a infraestrutura como código (IaC) necessária para implantar a arquitetura TrackNow na AWS. A solução utiliza **Terraform** para automação de infraestrutura, garantindo:

- ✅ **Reprodutibilidade**: Mesma arquitetura em qualquer ambiente
- ✅ **Versionamento**: Controle de versão de infraestrutura
- ✅ **Escalabilidade**: Fácil ajuste de recursos conforme demanda
- ✅ **Segurança**: Boas práticas de segurança AWS implementadas
- ✅ **Documentação**: Código bem estruturado e comentado

## 🏗️ Arquitetura Implementada

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS CLOUD (us-east-1)                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ INTERNET EDGE (Route 53, WAF, CloudFront)             │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ VPC TrackNow (10.0.0.0/16) - Multi-AZ (3 AZs)        │ │
│  │                                                         │ │
│  │  ┌─────────────┬─────────────┬─────────────┐          │ │
│  │  │  Public 1a  │  Public 1b  │  Public 1c  │          │ │
│  │  │ (Bastion)   │ (Bastion)   │ (Bastion)   │          │ │
│  │  │   + ALB     │   + ALB     │   + ALB     │          │ │
│  │  └─────────────┴─────────────┴─────────────┘          │ │
│  │           ↓              ↓              ↓              │ │
│  │  ┌─────────────┬─────────────┬─────────────┐          │ │
│  │  │ Private 1a  │ Private 1b  │ Private 1c  │          │ │
│  │  │ (EC2 App)   │ (EC2 App)   │ (EC2 App)   │          │ │
│  │  │ (EBS)       │ (EBS)       │ (EBS)       │          │ │
│  │  └─────────────┴─────────────┴─────────────┘          │ │
│  │           ↓              ↓              ↓              │ │
│  │  ┌─────────────┬─────────────┬─────────────┐          │ │
│  │  │  DB 1a      │  DB 1b      │  DB 1c      │          │ │
│  │  │ (Aurora)    │ (Aurora)    │ (Aurora)    │          │ │
│  │  │ (Redis)     │ (Redis)     │ (Redis)     │          │ │
│  │  └─────────────┴─────────────┴─────────────┘          │ │
│  │                                                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  SERVICES: IAM, KMS, CloudWatch, S3, Backup, SES            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Estrutura de Arquivos

```
bootcamp_iac/
├── main.tf                  # Configuração principal do Terraform
├── provider.tf              # Configuração do provider AWS
├── variables.tf             # Variáveis de entrada
├── vpc.tf                   # VPC, subnets, Internet Gateway, NAT Gateway
├── security_groups.tf       # Security Groups (não listado, implementado em vpc.tf)
├── bastion.tf               # EC2 Bastion Host
├── ec2.tf                   # EC2 instances de aplicação com auto-scaling
├── alb.tf                   # Application Load Balancer
├── rds.tf                   # Aurora PostgreSQL Multi-AZ
├── redis.tf                 # ElastiCache Redis
├── s3.tf                    # S3 buckets para backups
├── app_rds_s3_cf.tf         # CloudFront, AppConfig, RDS config
├── waf_route53.tf           # AWS WAF e Route 53
├── route.tf                 # Route tables e routes
├── .github/workflows/       # GitHub Actions CI/CD
│   └── terraform.yml        # Pipeline de deployment
├── .gitignore               # Arquivos a ignorar no Git
└── README.md                # Este arquivo
```

## 🔧 Componentes Terraform

### 1. **main.tf** - Configuração Principal
Define o backend do Terraform (state file) e configurações gerais.

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 2. **provider.tf** - Provider AWS
Configura a região AWS e credenciais.

```hcl
provider "aws" {
  region = var.aws_region
}
```

### 3. **variables.tf** - Variáveis de Entrada
Define todas as variáveis customizáveis da infraestrutura.

**Principais variáveis:**
- `aws_region`: Região AWS (padrão: us-east-1)
- `environment`: Ambiente (dev, staging, prod)
- `app_name`: Nome da aplicação (TrackNow)
- `instance_type`: Tipo de instância EC2 (t3.medium)
- `db_allocated_storage`: Armazenamento RDS (100 GB)
- `db_engine_version`: Versão Aurora PostgreSQL (15.2)

### 4. **vpc.tf** - Rede Virtual
Provisiona VPC Multi-AZ com subnets públicas, privadas e de banco de dados.

**Recursos criados:**
- VPC (10.0.0.0/16)
- 3 Subnets públicas (10.0.1.x, 10.0.2.x, 10.0.3.x)
- 3 Subnets privadas de app (10.0.11.x, 10.0.12.x, 10.0.13.x)
- 3 Subnets privadas de DB (10.0.21.x, 10.0.22.x, 10.0.23.x)
- Internet Gateway
- 3 NAT Gateways (1 por AZ para saída segura)
- Route tables e associações

### 5. **bastion.tf** - Bastion Host
EC2 instance para acesso SSH seguro à infraestrutura privada.

**Configuração:**
- Tipo: t3.micro (elegível para free tier)
- AMI: Amazon Linux 2
- Security Group: SSH (22) apenas de IPs autorizados
- Chave SSH: Importada do arquivo local

### 6. **ec2.tf** - Instâncias de Aplicação
EC2 instances com auto-scaling para a aplicação TrackNow.

**Configuração:**
- Tipo: t3.medium (2 vCPU, 4 GB RAM)
- AMI: Amazon Linux 2 com Docker pré-instalado
- Auto-scaling: 2-6 instâncias
- Triggers: CPU > 70% (scale-up), CPU < 30% (scale-down)
- Health checks: ALB com intervalo de 30s

### 7. **alb.tf** - Application Load Balancer
Balanceador de carga para distribuição de tráfego.

**Configuração:**
- Tipo: Application Load Balancer
- Protocolo: HTTP/HTTPS (porta 80/443)
- Target Group: EC2 instances na porta 8080
- Health checks: GET /health a cada 30s

### 8. **rds.tf** - Aurora PostgreSQL
Banco de dados gerenciado Multi-AZ com replicas de leitura.

**Configuração:**
- Engine: Aurora PostgreSQL 15.2
- Cluster: 1 Primary + 2 Read Replicas
- Backup: Automático diário com retenção de 7 dias
- Failover: Automático em ~30 segundos
- Criptografia: KMS
- Backup window: 03:00-04:00 UTC

### 9. **redis.tf** - ElastiCache Redis
Cache distribuído para sessões e dados quentes.

**Configuração:**
- Engine: Redis 7.0
- Cluster: 1 Primary + 2 Replicas
- Node type: cache.t3.micro
- Automatic failover: Habilitado
- Encryption: TLS em trânsito

### 10. **s3.tf** - S3 Buckets
Armazenamento para backups e logs.

**Buckets criados:**
- `tracknow-backups-{account-id}`: Backups de RDS/EBS
- `tracknow-logs-{account-id}`: Logs de aplicação
- Versionamento: Habilitado
- Replicação: Entre regiões (opcional)

### 11. **app_rds_s3_cf.tf** - CloudFront & AppConfig
CDN para distribuição de conteúdo estático.

**Configuração:**
- Origin: S3 bucket
- Cache: 1 dia para objetos estáticos
- Compression: Gzip habilitado
- HTTPS: Obrigatório

### 12. **waf_route53.tf** - WAF & Route 53
Proteção de aplicação e DNS.

**Configuração WAF:**
- Rate limiting: 2000 requisições/5 minutos
- IP reputation list: Bloqueio de IPs maliciosos
- Geo-blocking: Opcional por país

**Configuração Route 53:**
- Health checks: Monitoramento de ALB
- Failover: Automático entre regiões (opcional)

### 13. **route.tf** - Route Tables
Definição de rotas de rede.

**Rotas:**
- Públicas: 0.0.0.0/0 → Internet Gateway
- Privadas: 0.0.0.0/0 → NAT Gateway

## 🚀 Como Usar

### Pré-requisitos

```bash
# Instalar Terraform
brew install terraform  # macOS
# ou
choco install terraform  # Windows
# ou
apt-get install terraform  # Linux

# Instalar AWS CLI
pip install awscli

# Configurar credenciais AWS
aws configure
# Digite: Access Key ID, Secret Access Key, Region (us-east-1)
```

### 1. Clonar o Repositório

```bash
git clone https://github.com/marciomoreira-mba/bootcamp_iac.git
cd bootcamp_iac
```

### 2. Preparar Variáveis

Criar arquivo `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
environment    = "prod"
app_name       = "tracknow"
instance_type  = "t3.medium"
db_allocated_storage = 100
```

### 3. Inicializar Terraform

```bash
terraform init
```

Isso irá:
- Baixar providers AWS
- Criar diretório `.terraform/`
- Inicializar backend

### 4. Validar Configuração

```bash
terraform validate
```

Verifica sintaxe e referências.

### 5. Planejar Deployment

```bash
terraform plan -out=tfplan
```

Mostra todos os recursos que serão criados/modificados/destruídos.

### 6. Aplicar Configuração

```bash
terraform apply tfplan
```

Provisiona toda a infraestrutura na AWS.

**Tempo estimado**: 15-20 minutos

### 7. Verificar Outputs

```bash
terraform output
```

Mostra informações importantes:
- ALB DNS name
- RDS endpoint
- Redis endpoint
- Bastion IP

## 📊 Outputs Importantes

Após deployment bem-sucedido, você receberá:

```
Outputs:

alb_dns_name = "tracknow-alb-123456.us-east-1.elb.amazonaws.com"
rds_endpoint = "tracknow-cluster.cluster-c9akciq32.us-east-1.rds.amazonaws.com"
redis_endpoint = "tracknow-redis.abc123.ng.0001.use1.cache.amazonaws.com"
bastion_ip = "54.123.45.67"
s3_backup_bucket = "tracknow-backups-123456789012"
```

## 🔐 Segurança

### Boas Práticas Implementadas

1. **Isolamento de Rede**
   - EC2s em subnets privadas
   - Acesso apenas via ALB
   - Bastion Host para SSH

2. **Criptografia**
   - RDS criptografado com KMS
   - Redis com TLS
   - S3 com SSE-KMS

3. **Acesso Controlado**
   - Security Groups restritivos
   - IAM roles com least privilege
   - SSH apenas via Bastion

4. **Monitoramento**
   - CloudWatch métricas
   - Alarmes para anomalias
   - Logs centralizados

## 💰 Custo Estimado

| Serviço | Quantidade | Custo/mês |
|---------|-----------|-----------|
| EC2 t3.medium | 2-6 | $100-300 |
| RDS Aurora | 3 nodes | $150-200 |
| ElastiCache Redis | 3 nodes | $80-120 |
| ALB | 1 | $16 |
| NAT Gateway | 3 | $96 |
| CloudFront | - | $20-50 |
| S3 | - | $10-20 |
| CloudWatch | - | $15-30 |
| Outros | - | $20-40 |
| **TOTAL** | | **$507-780** |

*Valores aproximados para produção. Consulte AWS Pricing Calculator para valores precisos.*

## 🔄 CI/CD com GitHub Actions

O repositório inclui pipeline automático em `.github/workflows/terraform.yml`:

**Triggers:**
- Push na branch `main`
- Pull requests

**Passos:**
1. Checkout código
2. Setup Terraform
3. Validar sintaxe
4. Executar `terraform plan`
5. Comentar plano no PR
6. Aplicar (apenas em merge para main)

## 📈 Monitoramento & Observabilidade

### CloudWatch Dashboards

Criar dashboard com métricas:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name TrackNow \
  --dashboard-body file://dashboard.json
```

### Alarmes Críticos

```bash
# CPU alta
aws cloudwatch put-metric-alarm \
  --alarm-name tracknow-cpu-high \
  --metric-name CPUUtilization \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## 🔄 Disaster Recovery

### Backup Manual

```bash
# RDS
aws rds create-db-snapshot \
  --db-cluster-identifier tracknow-cluster \
  --db-cluster-snapshot-identifier tracknow-backup-$(date +%Y%m%d)

# EBS
aws ec2 create-snapshot \
  --volume-id vol-xxxxx \
  --description "TrackNow backup"
```

### Restore de Snapshot

```bash
# RDS
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier tracknow-restored \
  --snapshot-identifier tracknow-backup-20260209

# EBS
aws ec2 create-volume \
  --snapshot-id snap-xxxxx \
  --availability-zone us-east-1a
```

## 🐛 Troubleshooting

### Erro: "Access Denied"
```bash
# Verificar credenciais AWS
aws sts get-caller-identity

# Verificar permissões IAM
aws iam get-user
```

### Erro: "Subnet not found"
```bash
# Listar subnets
aws ec2 describe-subnets --region us-east-1

# Verificar VPC
aws ec2 describe-vpcs --region us-east-1
```

### Erro: "RDS cluster already exists"
```bash
# Listar clusters
aws rds describe-db-clusters --region us-east-1

# Destruir cluster
terraform destroy -target=aws_rds_cluster.tracknow
```

## 📚 Documentação Adicional

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Architecture Best Practices](https://docs.aws.amazon.com/architecture/)
- [Aurora PostgreSQL Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [ElastiCache Redis Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)

## 🤝 Contribuindo

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Changelog

### v1.0 - 2026-02-09
- ✅ Arquitetura Multi-AZ completa
- ✅ Aurora PostgreSQL com replicas
- ✅ ElastiCache Redis distribuído
- ✅ Auto-scaling configurado
- ✅ WAF e Route 53
- ✅ CloudFront CDN
- ✅ S3 para backups
- ✅ GitHub Actions CI/CD

## 📄 Licença

Este projeto é parte do Bootcamp Cloud & DevOps - IMPACTA.

## 👥 Autores

- **Grupo 1** - CLC14 - Bootcamp IMPACTA
- Marcio Moreira (marciomoreira-mba)
- Marcio Filho (marciomfilho)

## 📞 Suporte

Para dúvidas ou problemas:
1. Abra uma issue no GitHub
2. Consulte a documentação AWS
3. Entre em contato com o time de DevOps

---

**Última atualização**: 09 de Fevereiro de 2026  
**Versão**: 1.0  
**Status**: Production Ready  
**Terraform Version**: >= 1.0  
**AWS Provider**: >= 5.0
