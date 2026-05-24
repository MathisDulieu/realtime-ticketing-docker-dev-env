# realtime-ticketing-docker-dev-env

Local development infrastructure for the Realtime Ticketing Platform. Provides Kafka, MongoDB, Nexus, Prometheus and Grafana via Docker Compose. Automatically deploys the shared library to Nexus on startup if not already present.

## Infrastructure Services

| Service       | URL                       | Username | Password | Port  |
|---------------|---------------------------|----------|----------|-------|
| Kafka         | localhost:9092            | -        | -        | 9092  |
| AKHQ          | http://localhost:8090     | -        | -        | 8090  |
| MongoDB       | mongodb://localhost:27017  | admin    | admin    | 27017 |
| Mongo Express | http://localhost:8091     | admin    | admin    | 8091  |
| Nexus         | http://localhost:8092     | admin    | admin    | 8092  |
| Prometheus    | http://localhost:9090     | -        | -        | 9090  |
| Grafana       | http://localhost:3000     | admin    | admin    | 3000  |

## Application Services

| Service              | URL                      | Port  |
|----------------------|--------------------------|-------|
| api-gateway          | http://localhost:8080    | 8080  |
| event-service        | http://localhost:8081    | 8081  |
| inventory-service    | http://localhost:8082    | 8082  |
| reservation-service  | http://localhost:8083    | 8083  |
| realtime-service     | http://localhost:8084    | 8084  |
| notification-service | http://localhost:8085    | 8085  |

## Start Infrastructure

Start the full development environment:

```bash
docker-compose up --build --force-recreate
```

Start the full development environment in detached mode:

```bash
docker-compose up -d --build --force-recreate
```

## Seed Script

Insert sample data into MongoDB:

```bash
docker-compose --profile seed run --rm mongo-seed
```

Insert sample data and clear existing data first:

```bash
docker-compose --profile seed run --rm mongo-seed sh /scripts/seed-mongo.sh --clear
```

## Deployment Report

After the infrastructure startup, a deployment report is automatically generated:

```text
deployment-report/index.html
```

Open this file in your browser to view:
- Infrastructure deployment status
- Kafka topics
- MongoDB databases and collections
- Nexus library deployment status
- Container health and startup status