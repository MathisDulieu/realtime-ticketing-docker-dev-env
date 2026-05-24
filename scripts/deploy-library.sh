STATUS_FILE=/reports/library-deployer.status

if ! command -v curl > /dev/null 2>&1; then
  apk add --no-cache curl
fi

echo 'Waiting for Nexus to be ready...'

until curl -s -o /dev/null -w '%{http_code}' http://nexus:8081/service/rest/v1/status | grep -q '200'; do
  echo 'Nexus not ready yet, retrying in 5s...'
  sleep 5
done

echo 'Nexus is ready.'

SEARCH_URL="http://nexus:8081/service/rest/v1/search?repository=maven-releases&group=com.mathisdulieu.ticketing&name=realtime-ticketing-library&version=$LIBRARY_VERSION"

echo 'Checking if library already exists in Nexus...'

RESPONSE=$(curl -s -u $NEXUS_USERNAME:$NEXUS_PASSWORD "$SEARCH_URL")

if echo "$RESPONSE" | grep -q 'realtime-ticketing-library'; then
  echo 'FOUND_IN_NEXUS|Library already exists in Nexus, deployment skipped.' > $STATUS_FILE
  echo '[OK] Library already exists in Nexus, deployment skipped.'
  exit 0
fi

echo 'Library not found in Nexus, deploying...'

cd /tmp/library

if mvn deploy --no-transfer-progress -DskipTests -s /root/.m2/settings.xml -Plocal; then
  echo 'DEPLOYED_TO_NEXUS|Library was not present and has been deployed successfully.' > $STATUS_FILE
  echo '[OK] Library deployed successfully to Nexus.'
  exit 0
else
  echo 'DEPLOYMENT_FAILED|Library was not present but Maven deployment failed.' > $STATUS_FILE
  echo '[KO] Maven deployment failed.'
  exit 1
fi