const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB();

exports.handler = async (event) => {
    console.log('Lambda started.');

    // Check if there is an S3 event
    if (event.Records && event.Records.length > 0) {
        // Extract the S3 object key (file name)
        const s3ObjectKey = event.Records[0].s3.object.key;

        // Log the file name
        console.log('File added to S3:', s3ObjectKey);

        // Construct the URL to the S3 object
        const s3Bucket = event.Records[0].s3.bucket.name;
        const s3ObjectURL = `https://${s3Bucket}.s3.amazonaws.com/${s3ObjectKey}`;

        // Check if an item with the same id already exists in DynamoDB
        const queryParams = {
            TableName: 's3_to_dynamodb',
            KeyConditionExpression: 'id = :id',
            ExpressionAttributeValues: {
                ':id': { S: s3ObjectKey },
            },
        };

        try {
            const queryResult = await dynamoDb.query(queryParams).promise();

            // If the query result is non-empty, an item with the same id already exists
            if (queryResult.Items && queryResult.Items.length > 0) {
                console.log('Item with the same id already exists. Skipping insertion.');
            } else {
                // Insert the item into DynamoDB
                const putParams = {
                    TableName: 's3_to_dynamodb',
                    Item: {
                        'id': { S: s3ObjectKey },
                        'timestamp': { N: Date.now().toString() },
                        'data': { S: s3ObjectURL },
                    },
                };

                await dynamoDb.putItem(putParams).promise();
                console.log('Item inserted into DynamoDB.');
            }
        } catch (error) {
            console.error('Error checking or inserting item into DynamoDB:', error);
            throw error;
        }
    }

    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!!'),
    };
    return response;
};
