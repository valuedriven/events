# Arquitetura do Projeto - Events

Este documento descreve a arquitetura baseada em eventos (Event-Driven Architecture) implementada na AWS utilizando Terraform.

## Diagrama de Componentes

```mermaid
graph TD
    Client[Cliente / Postman] -->|POST /orders| APIG[API Gateway]
    
    subgraph "Processamento de Pedidos"
        APIG -->|Invoca| CO_Lambda[Lambda: CreateOrder]
        CO_Lambda -->|Persiste| DB_Orders[(DynamoDB: Orders)]
        CO_Lambda -->|Publica Evento| SNS_Orders[SNS Topic: orders_topic]
        CO_Lambda -.->|DLQ| SQS_CreateOrder_DLQ[create_order_dlq]
    end

    subgraph "Mensageria e Assinaturas"
        SNS_Orders -->|Assina| SQS_Billing[SQS: billing_queue]
        SNS_Orders -->|Assina| SQS_Inventory[SQS: inventory_queue]
        SNS_Orders -->|Assina| SQS_Shipping[SQS: shipping_queue]
        
        SQS_Billing -.->|DLQ| SQS_Billing_DLQ[billing_dlq]
        SQS_Inventory -.->|DLQ| SQS_Inventory_DLQ[inventory_dlq]
        SQS_Shipping -.->|DLQ| SQS_Shipping_DLQ[shipping_dlq]
    end

    subgraph "Consumidores (Workers)"
        SQS_Billing -->|Trigger| BR_Lambda[Lambda: BillingRegister]
        SQS_Inventory -->|Trigger| IR_Lambda[Lambda: InventoryRegister]
        SQS_Shipping -->|Trigger| SR_Lambda[Lambda: ShippingRegister]
    end

    subgraph "Persistência de Domínio"
        BR_Lambda -->|Grava| DB_Billing[(DynamoDB: Billing)]
        IR_Lambda -->|Grava| DB_Inventory[(DynamoDB: Inventory)]
        SR_Lambda -->|Grava| DB_Shipping[(DynamoDB: Shipping)]
    end

    %% Estilização
    classDef aws fill:#f9f,stroke:#333,stroke-width:2px;
    classDef database fill:#00f2ff,stroke:#005b61,stroke-width:2px;
    classDef messaging fill:#fff4dd,stroke:#d4a017,stroke-width:2px;
    
    class DB_Orders,DB_Billing,DB_Inventory,DB_Shipping database;
    class SNS_Orders,SQS_Billing,SQS_Inventory,SQS_Shipping,SQS_Billing_DLQ,SQS_Inventory_DLQ,SQS_Shipping_DLQ,SQS_CreateOrder_DLQ messaging;
```

## Descrição dos Fluxos

1.  **Ingress**: O cliente envia uma requisição POST para o **API Gateway**.
2.  **Orquestração Inicial**: A Lambda `CreateOrder` valida os dados, salva o estado inicial no DynamoDB (`Orders`) e dispara uma notificação para o tópico SNS `orders_topic`.
3.  **Fan-out**: O SNS distribui a mensagem para três filas SQS distintas (`billing`, `inventory`, `shipping`), permitindo o processamento paralelo e assíncrono.
4.  **Resiliência**: O sistema utiliza Dead Letter Queues (DLQ) para garantir que nenhuma mensagem/evento seja perdido. A Lambda `CreateOrder` redireciona erros de processamento críticos para sua própria DLQ, enquanto cada fila de domínio (`billing`, `inventory`, `shipping`) possui sua própria DLQ para capturar falhas após 3 tentativas.
5.  **Execução em Background**: Lambdas dedicadas consomem as mensagens de suas respectivas filas e atualizam as tabelas de domínio no DynamoDB.

## Tecnologias Utilizadas

- **IaaS**: Terraform
- **Compute**: AWS Lambda (Node.js 22.x)
- **API**: AWS API Gateway (REST)
- **Mensageria**: AWS SNS e AWS SQS
- **Banco de Dados**: AWS DynamoDB (NoSQL)
- **CI/CD**: GitHub Actions
