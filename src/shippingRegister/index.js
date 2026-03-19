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
            
            const shippingData = {
                tracking_number: `TRK-${orderPayload.order_id}-LOG`,
                order_id: orderPayload.order_id,
                carrier: "LogiSpeed",
                estimated_delivery: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                shipping_address: {
                    receiver_name: `Customer ${orderPayload.customer_id}`,
                    street: "Av. Afonso Pena, 1500",
                    city: "Belo Horizonte",
                    state: "MG"
                },
                package_details: {
                    weight_kg: 1.5,
                    dimensions: "30x20x10"
                }
            };

            const putParams = {
                TableName: process.env.SHIPPING_TABLE,
                Item: shippingData,
                ConditionExpression: "attribute_not_exists(tracking_number)"
            };
            
            await docClient.send(new PutCommand(putParams));
            console.log(`Shipping record created for order: ${orderPayload.order_id}`);
            
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
