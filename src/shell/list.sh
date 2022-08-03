export filename="response-list.json"
echo "deleting " $filename
rm -f $filename
curl \
-X GET http://localhost:12773/common/list/data.test \
-o $filename \
--user "_system:SYS"