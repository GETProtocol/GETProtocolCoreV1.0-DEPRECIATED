## Engine Documenation
The engine is the logic board of the GET Protocol. It's main function is to read messages sent by ticketeers, interpret and check these messages and forward it to the appropriate . 

![Image of derivation](../markdown_images/custody_queue.png)

#### Message types 

### Example usage

Scenario: A user, Bob, creates a new account with a ticketeer. Bob needs to be assigned a wallet so that his account/address can own NFTs (and other digital assets). 

| Step | Description |
| ------ | ------ | 
| 0 | Bob creates an account with a ticketeer. This means Bob needs to be assigned a wallet to store his digital assets. | 
| 1. | The tickeer pushes/writes a standardized 'new user' message to a SQS queue of the GET Protocol. | 
| 2. | A lambda worker of the engine reads the message from the queue. | 
| 3. | The new user message is checked/interpreted. Depending on the message forwarded to an SQS queue. | 
| 4. | The engine writes a message to the SQS qeueu to create a new user for custodial. | 
| 5. | A worker of custody reads the message from the queue. | 
| 6. | Custody will now seed/create a new keypair and store it in a secured database.  | 
| 7. | The UUID pointing to the public and private key of the created wallet is returned. | 
| 8. | UUID of create wallet is returned to the engine via SQS or API/callback. Part 1 | 
| 9. | UUID of create wallet is returned to the engine via SQS or API/callback. Part 2  | 
| 10. | UUID of create wallet is returned to the ticketeer via API/callback.| 
| 11. | Ticketeer receives the UUID (or error message) of the created wallet. | 
| 12. | Ticketeer stores the UUID in the database (associated with the user). | 


