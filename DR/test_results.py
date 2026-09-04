import glob, json
from datetime import datetime
from datetime import timedelta

outages = {}
start = 1776852770

tests = {}
with open ('0.tests.json') as f:
# Sample
# [
#  {   "id": "T110",   "method": "ping",   "target1": "10.165.250.254",   "target2": "",   "tag": "Ping_Int_admin_gw",   "description": "Ping Internal F22 admin subnet default gateway" },
#  {   "id": "T210",   "method": "tcpping",   "target1": "10.91.0.52",   "target2": "445",   "tag": "TCPing_Azure_AD_DC",   "description": "Tcping.sh Azure AD DC" }
# ]
  tests_list = json.load(f)
  for test in tests_list:
    id = test['id']
    tests[id] = test

log_files = glob.glob("T*.log")
for log_file in log_files:
  test = log_file.split(".")[0]
  with open (log_file) as f:
    lines_str = f.read()
    lines = lines_str.split("\n")
    last_check_int = 0
    outage_start_int = 0
    for line in lines:
      if line != '':
        try:
          current_int = int(line)
        except:
          current_int = 0
        if current_int > start and last_check_int and current_int - last_check_int > 20:
          outage_start_int = last_check_int
          outage_end_int = current_int
          outage_date = datetime.fromtimestamp(outage_start_int).strftime('%Y-%m-%d')
          outage_start = datetime.fromtimestamp(outage_start_int).strftime('%H:%M:%S')
          outage_end = datetime.fromtimestamp(outage_end_int).strftime('%H:%M:%S')
          outage_len = outage_end_int - outage_start_int
          outage_record = { "start_int": outage_start_int,"date": outage_date,"start": outage_start, "end": outage_end, "length": outage_len, "test": test }
          outage_tag = f"{outage_start_int}_{test}"
          outages[outage_tag] = outage_record
        last_check_int = current_int
with open ( "outages.csv", "w" ) as f:
  f.write ("Tag,ID,Test,Major,Date,Start,End,Length Sec\n")
  for tag in sorted(outages):
    id = outages[tag]['test']
    test = ''
    if id in tests: test = tests[id]['tag']
    major = ''
    if outages[tag]['length'] > 60:
      major = 'Yes'
    length = str(timedelta(seconds=outages[tag]['length']))
    f.write (f"{tag},{id},{test},{major},{outages[tag]['date']},{outages[tag]['start']},{outages[tag]['end']},{length}\n")
        
