export filename="response-import-3-xml.json"
echo "deleting " $filename
rm -f $filename
curl -d "@../data/data-import-3.xml" \
-H "Content-Type: plain/text" \
-X POST http://localhost:12773/common/importxml \
-o $filename \
--user "_system:SYS"