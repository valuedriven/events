# AWS Event-Driven Architecture (Order Processing)

Este projeto implementa uma arquitetura orientada a eventos para processamento de pedidos utilizando **Terraform**, **AWS Lambda (Node.js 22)**, **SNS**, **SQS** e **DynamoDB**.

## Arquitetura

O fluxo principal (Evento `OrderCreated`) funciona da seguinte forma:

1.  **API Gateway**: Recebe uma requisição `POST /orders`.
2.  **Order Lambda (`createOrder`)**: Valida o payload, persiste no DynamoDB (`Order`) e publica um evento no **SNS Topic** (`orders_topic`).
3.  **Fan-out (SNS -> SQS)**: O tópico SNS envia a mensagem para três filas SQS distintas:
    *   `billing_queue`
    *   `inventory_queue`
    *   `shipping_queue`
4.  **Consumidores (Lambdas)**:
    *   **Billing**: Cria o registro de faturamento.
    *   **Inventory**: Reserva itens no estoque.
    *   **Shipping**: Gera dados de rastreio para envio.

### Características Principais
- **Idempotência**: Todas as Lambdas utilizam `ConditionExpression` do DynamoDB para evitar duplicidade.
- **Resiliência**: Filas de Dead Letter (DLQ) configuradas para tratamento de falhas.
- **Filtros SNS**: Assinaturas SQS utilizam `FilterPolicy` com `MessageAttributes`.
- **Infrastructure as Code**: Todo o ambiente é versionado via Terraform.
- **CI/CD**: Pipeline do GitHub Actions para validação e provisionamento automático.

## Estrutura do Projeto

```text
.
├── .github/workflows/      # Pipeline de CI/CD (GitHub Actions)
├── data/                   # Massa de dados gerada (seed_data.json)
├── infra/terraform/        # Arquivos Terraform (módulos e main)
│   ├── modules/
│   │   ├── api_gateway/    # Configuração do API Gateway
│   │   ├── compute/        # Definição das Lambdas e gatilhos
│   │   ├── database/       # Tabelas DynamoDB
│   │   └── messaging/      # Tópico SNS e Filas SQS
├── scripts/                # Scripts utilitários (ex: gerador de dados)
└── src/                    # Código fonte das funções Lambda
```

## Pré-requisitos

1. **AWS CLI** configurado e autenticado.
2. **Terraform** v1.0+ instalado.
3. **Node.js 22** (se quiser rodar testes locais ou scripts).

## Como Implantar

### Via GitHub Actions
1. Adicione os Segredos no repositório GitHub:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN` (obrigatório para Learner Labs)
2. Faça push para a branch `main`.

### Manual (Terraform)
```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

## Testando a Solução

Após o deploy, você receberá a `api_endpoint`. Use o arquivo `data/seed_data.json` para realizar chamadas:

```bash
curl -X POST <API_ENDPOINT>/orders \
     -H "Content-Type: application/json" \
     -d @data/seed_data.json # (enviar um item do array)
```

## Observações do Desenvolvedor
- Este projeto foi desenhado para o ambiente **AWS Learner Labs**, utilizando o `LabRole` predefinido.
- A região padrão é `us-east-1`.
