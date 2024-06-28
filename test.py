import json
import time
import random
import threading
import logging
from confluent_kafka import Producer

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

# Kafka broker address and topic name
bootstrap_servers = '10.10.253.111:9092,10.10.253.112:9092,10.10.253.113:9092'
topic = 'trucks'  # Define the topic name here

# Create KafkaProducer instance
conf = {'bootstrap.servers': bootstrap_servers}
producer = Producer(conf)

def generate_truck_data(truck_id):
    data = {
        'truck_id': truck_id,
        'timestamp': int(time.time()),
        'location': {
            'latitude': round(random.uniform(-90, 90), 6),
            'longitude': round(random.uniform(-180, 180), 6)
        },
        'speed': round(random.uniform(0, 120), 2),
        'fuel_level': round(random.uniform(0, 100), 2)
    }
    logging.info(f"Generated data for truck {truck_id}: {data}")
    return data

def send_truck_data(truck_id):
    data = generate_truck_data(truck_id)
    producer.produce(topic, value=json.dumps(data).encode('utf-8'))
    producer.flush()
    logging.info(f"Sent data for truck {truck_id} to topic '{topic}'")

def simulate_truck(truck_id, stop_event):
    while not stop_event.is_set():
        send_truck_data(truck_id)
        time.sleep(1)  # Adjust the sleep time as needed

if __name__ == '__main__':
    truck_count = 1  # Start with one truck
    threads = []
    stop_events = []

    logging.info("Starting truck data simulation")

    # Create and start threads
    for truck_id in range(1, truck_count + 1):
        stop_event = threading.Event()
        thread = threading.Thread(target=simulate_truck, args=(truck_id, stop_event))
        thread.start()
        threads.append(thread)
        stop_events.append(stop_event)
        logging.info(f"Started thread for truck {truck_id}")

    try:
        # Main thread continues to run, or you can add logic here
        while True:
            time.sleep(1)  # Keep the main thread alive
    except KeyboardInterrupt:
        logging.info("Stopping threads...")
        for event in stop_events:
            event.set()  # Signal all threads to stop

        for thread in threads:
            thread.join()  # Wait for all threads to finish

        logging.info("All threads stopped.")
