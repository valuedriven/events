const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
    console.log("Event:", JSON.stringify(event));
    
    for (const record of event.Records) {
        try {
            const snsMessage = JSON.parse(record.body);
            const orderPayload = JSON.parse(snsMessage.Message);
            
            const billingData = {
                billing_id: `b-${orderPayload.order_id}`,
                order_id: orderPayload.order_id,
                payment_method: "CREDIT_CARD",
                transaction_status: "CREATED",
                billing_address: {
                    street: "Av. Afonso Pena, 1500",
                    city: "Belo Horizonte",
                    state: "MG",
                    zip_code: "30130-003"
                },
                installments: 1,
                paid_at: new Date().toISOString()
            };

            const putParams = {
                TableName: process.env.BILLING_TABLE,
                Item: billingData,
                ConditionExpression: "attribute_not_exists(billing_id)"
            };
            
            await docClient.send(new PutCommand(putParams));
            console.log(`Billing record created for order: ${orderPayload.order_id}`);
            
        } catch (error) {
            if (error.name === 'ConditionalCheckFailedException') {
                console.log("Record already exists. Idempotency check passed.");
            } else {
                console.error("Error processing record:", error);
                throw error; // Let SQS retry or move to DLQ
            }
        }
    }
    return {};
};
