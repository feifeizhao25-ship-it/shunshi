#!/bin/bash
# Find and delete the TXT record
RECORD_ID=$(aliyun alidns DescribeDomainRecords --DomainName shunshiapp.com --RRKeyWord "_acme-challenge" --TypeKeyWord TXT 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
records=d.get('DomainRecords',{}).get('Record',[])
for r in records:
    print(r.get('RecordId',''))
" 2>/dev/null | head -1)
if [ -n "$RECORD_ID" ]; then
  aliyun alidns DeleteDomainRecord --RecordId "$RECORD_ID" 2>/dev/null
fi
