#!/bin/sh

MONGO_URL="mongodb://admin:admin@mongodb:27017/?authSource=admin"
CLEAR=false

for arg in "$@"
do
  case $arg in
    --clear)
      CLEAR=true
      shift
      ;;
  esac
done

echo "Waiting for MongoDB..."

until mongosh "$MONGO_URL" --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
  echo "MongoDB not ready yet, retrying in 5s..."
  sleep 5
done

seed_collection() {
  DATABASE=$1
  COLLECTION=$2
  FILE=$3

  if [ "$CLEAR" = true ]; then
    mongosh "$MONGO_URL" --quiet --eval "db.getSiblingDB('$DATABASE').$COLLECTION.deleteMany({})" > /dev/null
    echo "[$DATABASE/$COLLECTION] Cleared"
  fi

  mongoimport \
    --uri "$MONGO_URL" \
    --db "$DATABASE" \
    --collection "$COLLECTION" \
    --file "$FILE" \
    --jsonArray \
    --mode upsert \
    --upsertFields _id

  if [ $? -ne 0 ]; then
    echo "[$DATABASE/$COLLECTION] Seed failed"
    exit 1
  fi

  echo "[$DATABASE/$COLLECTION] Seeded from $FILE"
}

seed_collection "event-service" "events" "/seed-data/events.json"
seed_collection "inventory-service" "inventories" "/seed-data/inventories.json"
seed_collection "reservation-service" "reservations" "/seed-data/reservations.json"

echo "Done."