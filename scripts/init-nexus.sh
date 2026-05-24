echo 'Initializing Nexus admin password...'

INITIAL_PASSWORD=$(cat /nexus-data/admin.password 2>/dev/null || true)

if [ -z "$INITIAL_PASSWORD" ]; then
  echo 'Nexus already initialized, skipping password change.'
  exit 0
fi

STATUS=$(curl -s -o /dev/null -w '%{http_code}' -u admin:admin http://nexus:8081/service/rest/v1/status)

if [ "$STATUS" = "200" ]; then
  echo 'Nexus already uses admin/admin.'
  exit 0
fi

curl -f -X PUT -u admin:$INITIAL_PASSWORD -H 'Content-Type: text/plain' --data 'admin' http://nexus:8081/service/rest/v1/security/users/admin/change-password

echo 'Nexus admin password changed to admin.'