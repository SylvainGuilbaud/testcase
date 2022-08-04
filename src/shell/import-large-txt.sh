export filename="response-import-large-txt.json"
echo "deleting " $filename
rm -f $filename
curl -d "@data-import-large.json" \
-H "Content-Type: application/json" \
-X POST http://localhost:12773/common/import \
-o $filename \
--user "_system:SYS"