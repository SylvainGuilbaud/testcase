export filename="response-add.json"
echo "deleting " $filename
rm -f $filename
curl -d '{"filename":"/tmp/IRIS.pdf"}' \
-H "Content-Type: application/json" \
-X POST http://localhost:12773/common/add \
-o $filename \
--user "_system:SYS"