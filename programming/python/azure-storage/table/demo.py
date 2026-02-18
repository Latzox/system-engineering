from azure.data.tables import TableServiceClient, TableEntity
import os

# Set up connection to Azure Table Storage
CONNECTION_STRING = "<your_connection_string>"  # Replace with your connection string
TABLE_NAME = "Inventory"

def create_table_service():
    return TableServiceClient.from_connection_string(CONNECTION_STRING)

def create_table(service):
    try:
        print(f"Creating table '{TABLE_NAME}'...")
        table_client = service.create_table(TABLE_NAME)
        print(f"Table '{TABLE_NAME}' created successfully.")
        return table_client
    except Exception as e:
        print(f"Table creation failed: {e}")
        return service.get_table_client(TABLE_NAME)

# Add an inventory item
def add_item(table_client, partition_key, row_key, name, quantity, price):
    item = {
        "PartitionKey": partition_key,
        "RowKey": row_key,
        "Name": name,
        "Quantity": quantity,
        "Price": price
    }
    table_client.create_entity(entity=item)
    print(f"Item '{name}' added successfully.")

# Retrieve all inventory items
def list_items(table_client):
    print("\nListing all inventory items:")
    items = table_client.list_entities()
    for item in items:
        print(item)

# Update an inventory item
def update_item(table_client, partition_key, row_key, new_quantity):
    item = table_client.get_entity(partition_key, row_key)
    item["Quantity"] = new_quantity
    table_client.update_entity(entity=item, mode="Merge")
    print(f"Item '{item['Name']}' updated successfully.")

# Delete an inventory item
def delete_item(table_client, partition_key, row_key):
    table_client.delete_entity(partition_key, row_key)
    print(f"Item with PartitionKey='{partition_key}' and RowKey='{row_key}' deleted successfully.")

if __name__ == "__main__":
    # Initialize Table Storage service
    service = create_table_service()

    # Create or access the table
    table_client = create_table(service)

    # Demonstration
    add_item(table_client, "Electronics", "1", "Laptop", 50, 1200.00)
    add_item(table_client, "Electronics", "2", "Smartphone", 200, 800.00)

    list_items(table_client)

    update_item(table_client, "Electronics", "1", 45)

    list_items(table_client)

    delete_item(table_client, "Electronics", "2")

    list_items(table_client)
