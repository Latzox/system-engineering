from azure.storage.queue import QueueServiceClient
import json

# Replace with your Azure Storage account connection string
CONNECTION_STRING = "<Your_Connection_String>"

# Queue name
QUEUE_NAME = "sensorqueue"

def main():
    try:
        # Create a QueueServiceClient
        queue_service_client = QueueServiceClient.from_connection_string(CONNECTION_STRING)

        # Create the queue
        print("Creating queue...")
        queue_client = queue_service_client.get_queue_client(QUEUE_NAME)
        queue_client.create_queue()
        print(f"Queue '{QUEUE_NAME}' created successfully!\n")

        # Simulate sensor data
        sensor_data = [
            {"sensor_id": "temp-01", "timestamp": "2024-12-30T10:00:00Z", "type": "temperature", "value": 22.5},
            {"sensor_id": "moist-02", "timestamp": "2024-12-30T10:00:05Z", "type": "moisture", "value": 45},
            {"sensor_id": "humid-03", "timestamp": "2024-12-30T10:00:10Z", "type": "humidity", "value": 55},
        ]

        # Add sensor data to the queue
        print("Adding sensor data to the queue...")
        for data in sensor_data:
            message = json.dumps(data)  # Convert dictionary to JSON string
            queue_client.send_message(message)
            print(f"Sent sensor data: {data}")
        print()

        # Peek messages (does not dequeue them)
        print("Peeking at messages in the queue...")
        messages = queue_client.peek_messages(max_messages=5)
        for msg in messages:
            print(f"Peeked Message: {msg.content}")
        print()

        # Retrieve and process sensor data
        print("Retrieving and processing sensor data...")
        messages = queue_client.receive_messages(messages_per_page=5)
        for msg in messages:
            sensor_reading = json.loads(msg.content)  # Parse JSON string back to dictionary
            print(f"Processing sensor data: {sensor_reading}")

            # Example processing logic
            if sensor_reading["type"] == "moisture" and sensor_reading["value"] < 40:
                print(f"ALERT: Low moisture detected by {sensor_reading['sensor_id']}! Triggering irrigation system.")

            # Delete the message after processing
            queue_client.delete_message(msg)
        print()

        # Delete the queue
        print("Deleting the queue...")
        queue_client.delete_queue()
        print(f"Queue '{QUEUE_NAME}' deleted successfully!\n")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
