const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB();

exports.handler = async (event) => {
    console.log('Lambda started');

    // Check if there is an S3 event
    if (event.Records && event.Records.length > 0) {
        const s3ObjectKey = event.Records[0].s3.object.key;
        const s3Bucket = event.Records[0].s3.bucket.name;
        const s3Region = event.Records[0].awsRegion;

        console.log('File added to S3:', s3ObjectKey, 'in bucket:', s3Bucket);

        const s3ObjectInfo = await s3.headObject({ Bucket: s3Bucket, Key: s3ObjectKey }).promise();
        const creationTime = s3ObjectInfo.LastModified;

        console.log('File creation time:', creationTime);

        // Construct the URL to the S3 object
        const fileUrl = `https://${s3Bucket}.s3.${s3Region}.amazonaws.com/${s3ObjectKey}`;
        console.log('File URL:', fileUrl);

        // Add data to DynamoDB with the URL in the 'data' field
        const dynamoParams = {
            TableName: "s3_to_dynamodb",  // Use the actual DynamoDB table name
            Item: {
                'id': { S: s3ObjectKey }, // Assuming 'id' is your hash key
                'timestamp': { N: creationTime.getTime().toString() }, // Assuming 'timestamp' is your range key
                'data': { S: fileUrl }
            }
        };

        await dynamodb.putItem(dynamoParams).promise();

        console.log('Data added to DynamoDB');

        // You can continue with additional processing or return a response as needed.
    }

    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!!'),
    };
    return response;
};
