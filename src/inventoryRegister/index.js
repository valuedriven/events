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
            
            // simple shelf allocation logic
            const shelves = ["A-12-04", "B-03-01", "C-01-09", "D-05-12"];
            const reservationItems = orderPayload.items.map(item => ({
                product_id: item.product_id,
                status: "RESERVED",
                shelf_location: shelves[Math.floor(Math.random() * shelves.length)]
            }));

            const inventoryData = {
                reservation_id: `inv-${orderPayload.order_id}`,
                order_id: orderPayload.order_id,
                warehouse_id: "WH-SOUTH-01",
                items: reservationItems,
                last_updated: new Date().toISOString()
            };

            const putParams = {
                TableName: process.env.INVENTORY_TABLE,
                Item: inventoryData,
                ConditionExpression: "attribute_not_exists(reservation_id)"
            };
            
            await docClient.send(new PutCommand(putParams));
            console.log(`Inventory record created for order: ${orderPayload.order_id}`);
            
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
