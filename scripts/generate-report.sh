REPORT_FILE=/reports/index.html
STATUS_FILE=/reports/library-deployer.status

rm -f /reports/*.html

START_TIME=$(date +%s)
MAX_WAIT_SECONDS=180

is_finished() {
  for SERVICE in kafka-topic-init mongo-init nexus-init library-deployer; do
    STATUS=$(docker inspect -f '{{.State.Status}}' "$SERVICE" 2>/dev/null || echo missing)

    if [ "$STATUS" != "exited" ]; then
      return 1
    fi
  done

  AKHQ_STATUS=$(docker inspect -f '{{.State.Status}}' akhq 2>/dev/null || echo missing)

  if [ "$AKHQ_STATUS" != "running" ]; then
    return 1
  fi

  return 0
}

while true; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  if is_finished; then
    break
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT_SECONDS" ]; then
    break
  fi

  sleep 5
done

GENERATED_AT_EPOCH=$(date +%s)

if [ -f "$STATUS_FILE" ]; then
  LIBRARY_STATUS=$(cut -d '|' -f 1 "$STATUS_FILE")
  LIBRARY_MESSAGE=$(cut -d '|' -f 2- "$STATUS_FILE")
else
  LIBRARY_STATUS='UNKNOWN'
  LIBRARY_MESSAGE='No library-deployer status file found.'
fi

KAFKA_TOPICS=$(docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | sort)

MONGO_INFO=$(docker exec mongodb mongosh mongodb://admin:admin@localhost:27017/admin --quiet --eval "
const dbs = ['reservation-service', 'inventory-service', 'event-service'];
for (const dbName of dbs) {
  const cols = db.getSiblingDB(dbName).getCollectionNames().join(', ');
  print(dbName + '|' + cols);
}
" 2>/dev/null)

cat > "$REPORT_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Deployment Report</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f6f7fb; color: #1f2937; }
    main { max-width: 1100px; margin: 40px auto; padding: 0 24px; }
    h1 { margin: 0; font-size: 32px; }
    h2 { margin: 0 0 16px; font-size: 22px; }
    .date { color: #6b7280; margin-top: 8px; }
    .card, .section { background: white; border-radius: 14px; padding: 20px; box-shadow: 0 8px 24px rgba(0,0,0,.06); border: 1px solid #e5e7eb; margin-bottom: 24px; }
    .label { color: #6b7280; font-size: 14px; margin-bottom: 8px; }
    .value { font-size: 20px; font-weight: 700; }
    .muted { color: #6b7280; font-size: 14px; margin-top: 8px; }
    table { width: 100%; border-collapse: collapse; background: white; border-radius: 14px; overflow: hidden; border: 1px solid #e5e7eb; }
    th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid #e5e7eb; font-size: 14px; }
    th { background: #f9fafb; color: #374151; }
    tr:last-child td { border-bottom: none; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; }
    .badge-ok { background: #dcfce7; color: #166534; }
    .badge-ko { background: #fee2e2; color: #991b1b; }
    .badge-warn { background: #fef3c7; color: #92400e; }
    .list { display: grid; gap: 8px; }
    .list-item { padding: 10px 12px; border-radius: 10px; background: #f9fafb; border: 1px solid #e5e7eb; font-size: 14px; }
    .mono { font-family: Consolas, monospace; }
  </style>
</head>
<body>
  <main>
    <header class="section">
      <h1>Deployment Report</h1>
      <div class="date">Generated at: <span id="generated-at"></span></div>
    </header>

    <section class="card">
      <div class="label">Nexus library</div>
      <div class="value">$LIBRARY_STATUS</div>
      <div class="muted">$LIBRARY_MESSAGE</div>
    </section>

    <section class="section">
      <h2>Services</h2>
      <table>
        <thead>
          <tr>
            <th>Service</th>
            <th>Deployment status</th>
            <th>Container status</th>
            <th>Health</th>
            <th>Exit code</th>
          </tr>
        </thead>
        <tbody>
EOF

for SERVICE in zookeeper kafka kafka-topic-init akhq mongodb mongo-init mongo-express nexus nexus-init library-deployer prometheus grafana; do
  STATUS=$(docker inspect -f '{{.State.Status}}' "$SERVICE" 2>/dev/null || echo missing)
  EXIT_CODE=$(docker inspect -f '{{.State.ExitCode}}' "$SERVICE" 2>/dev/null || echo unknown)
  HEALTH=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$SERVICE" 2>/dev/null || echo none)

  if [ "$HEALTH" = "healthy" ]; then
    DEPLOYMENT_STATUS="OK"
    BADGE="badge-ok"
  elif [ "$HEALTH" = "starting" ]; then
    DEPLOYMENT_STATUS="KO"
    BADGE="badge-ko"
  elif [ "$HEALTH" = "unhealthy" ]; then
    DEPLOYMENT_STATUS="KO"
    BADGE="badge-ko"
  elif [ "$STATUS" = "running" ] && [ "$HEALTH" = "none" ]; then
    DEPLOYMENT_STATUS="OK"
    BADGE="badge-ok"
  elif [ "$STATUS" = "exited" ] && [ "$EXIT_CODE" = "0" ]; then
    DEPLOYMENT_STATUS="COMPLETED"
    BADGE="badge-ok"
  elif [ "$STATUS" = "exited" ]; then
    DEPLOYMENT_STATUS="KO"
    BADGE="badge-ko"
  elif [ "$STATUS" = "created" ]; then
    DEPLOYMENT_STATUS="NOT STARTED"
    BADGE="badge-warn"
  else
    DEPLOYMENT_STATUS="KO"
    BADGE="badge-ko"
  fi

  cat >> "$REPORT_FILE" <<EOF
          <tr>
            <td>$SERVICE</td>
            <td><span class="badge $BADGE">$DEPLOYMENT_STATUS</span></td>
            <td>$STATUS</td>
            <td>$HEALTH</td>
            <td>$EXIT_CODE</td>
          </tr>
EOF
done

cat >> "$REPORT_FILE" <<EOF
        </tbody>
      </table>
    </section>

    <section class="section">
      <h2>Kafka topics</h2>
      <div class="list">
EOF

if [ -n "$KAFKA_TOPICS" ]; then
  echo "$KAFKA_TOPICS" | while IFS= read -r TOPIC; do
    if [ -n "$TOPIC" ]; then
      cat >> "$REPORT_FILE" <<EOF
        <div class="list-item mono">$TOPIC</div>
EOF
    fi
  done
else
  cat >> "$REPORT_FILE" <<EOF
        <div class="list-item">No Kafka topics found.</div>
EOF
fi

cat >> "$REPORT_FILE" <<EOF
      </div>
    </section>

    <section class="section">
      <h2>Mongo databases</h2>
      <div class="list">
EOF

if [ -n "$MONGO_INFO" ]; then
  echo "$MONGO_INFO" | while IFS= read -r LINE; do
    DB_NAME=$(echo "$LINE" | cut -d '|' -f 1)
    COLLECTIONS=$(echo "$LINE" | cut -d '|' -f 2-)

    if [ -n "$DB_NAME" ]; then
      cat >> "$REPORT_FILE" <<EOF
        <div class="list-item">
          <strong>$DB_NAME</strong>
          <div class="muted">Collections: <span class="mono">$COLLECTIONS</span></div>
        </div>
EOF
    fi
  done
else
  cat >> "$REPORT_FILE" <<EOF
        <div class="list-item">No Mongo databases found.</div>
EOF
fi

cat >> "$REPORT_FILE" <<EOF
      </div>
    </section>
  </main>

  <script>
    const generatedAt = new Date($GENERATED_AT_EPOCH * 1000);
    document.getElementById('generated-at').textContent = generatedAt.toLocaleString();
  </script>
</body>
</html>
EOF

echo "Deployment report generated: /reports/index.html"