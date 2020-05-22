# just builds a json payload of IPs for terraform.
import json
import sys
import urllib.request as request

try:
    r = json.loads(
        request.urlopen(
            request.Request("https://ip-ranges.amazonaws.com/ip-ranges.json")
        )
        .read()
        .decode("utf-8")
    )
    data = {}
    for idx, range in enumerate(r["prefixes"]):
        if range["region"] != "us-west-2" or range["service"] != "EC2":
            continue
        data[range["ip_prefix"]] = str(idx)  # dummy data, doesn't matter.
    print(json.dumps(data))
except Exception as e:
    print(e, file=sys.stderr)
