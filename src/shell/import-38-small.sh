export filename="response-import-38-small.json"
echo "deleting " $filename
rm -f $filename
curl -d "@data-38-small.json" \
-H "Content-Type: application/json" \
-X POST http://localhost:12773/common/import \
-o $filename \
--user "_system:SYS"