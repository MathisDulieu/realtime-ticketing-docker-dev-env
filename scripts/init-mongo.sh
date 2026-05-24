echo 'Waiting for MongoDB...'

until mongosh mongodb://admin:admin@mongodb:27017/admin --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
  echo 'MongoDB not ready yet, retrying in 5s...'
  sleep 5
done

echo 'MongoDB is ready. Initializing databases...'

mongosh mongodb://admin:admin@mongodb:27017/admin --quiet --eval "
db.getSiblingDB('reservation-service').createCollection('reservations');
db.getSiblingDB('inventory-service').createCollection('inventories');
db.getSiblingDB('event-service').createCollection('events');
"

echo 'MongoDB databases initialized.'