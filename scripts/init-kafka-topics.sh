echo 'Waiting for Kafka...'

until kafka-topics --bootstrap-server kafka:29092 --list > /dev/null 2>&1; do
  echo 'Kafka not ready yet, retrying in 5s...'
  sleep 5
done

echo 'Kafka is ready. Creating topics...'

kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_reservation_created --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_reservation_confirmed --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_reservation_cancelled --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_reservation_failed --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_inventory_updated --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_inventory_low_stock --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_inventory_sold_out --partitions 1 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --if-not-exists --topic json_realtime_notification_send --partitions 1 --replication-factor 1

echo 'Kafka topics initialized.'