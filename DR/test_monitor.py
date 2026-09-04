import os, json, time, requests, ssl, urllib3
import socket
# python3 -m pip install pythonping
from pythonping import ping
# python3 -m pip install dnspython
import dns.resolver

from concurrent.futures import ThreadPoolExecutor, as_completed
MAX_WORKERS = 20

os.environ['PYTHONWARNINGS']="ignore:Unverified HTTPS request"
ctx = ssl._create_unverified_context()
urllib3.disable_warnings()

def cstamp(test_id):
  epoch = int(time.time())
  with open (test_id, 'w') as f:
    f.write(str(epoch))
  with open (test_id + '.log', 'a') as f:
    f.write(str(epoch) + '\n')


def cping(test_id, target):
  try:
    response = ping(target, count=1, timeout=1 )
    if response.success():
      cstamp(test_id)
  except:
    do_nothing = True


def ctcpping(test_id, target, port):
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.settimeout(1)
  try:
    s.connect((target, int(port)))
    s.close()
    cstamp(test_id)
  except:
    do_nothing = True


def cdns(test_id, target, server):
  my_resolver = dns.resolver.Resolver(configure=False)
  my_resolver.nameservers = [server]
  my_resolver.timeout = 1
  my_resolver.lifetime = 1
  try:
    response = my_resolver.resolve(target, 'A')
    cstamp(test_id)
  except:
    do_nothing = True


def cget(test_id, target):
  try:
    r = requests.get(target, verify=False, allow_redirects=False, timeout=1)
    if r.status_code == 200 or r.status_code == 302 or r.status_code == 303:
      cstamp(test_id)
  except:
    do_nothing = True


def run_test( test_id ):
  global tests
  test = tests[test_id]
  method = test['method']
  target1 = test['target1']
  target2 = test['target2']
  if   method == 'ping':    cping(test_id, target1)
  elif method == 'tcpping': ctcpping(test_id, target1, target2)
  elif method == 'dns':     cdns(test_id, target1, target2)
  elif method == 'get':     cget(test_id, target1)
  else:
    do_nothing = True

run_count = 0
while True:
  if run_count % 20 == 0:
    #refresh test cases
    tests={}
    with open ('0.tests.json') as f:
            # Sample
            # [
            #  {   "id": "T110",   "method": "ping",   "target1": "10.165.250.254",   "target2": "",   "tag": "Ping_Int_admin_gw",   "description": "Ping Internal F22 admin subnet default gateway" },
            #  {   "id": "T210",   "method": "tcpping",   "target1": "10.91.0.52",   "target2": "445",   "tag": "TCPing_Azure_AD_DC",   "description": "Tcping.sh Azure AD DC" }
            # ]
      tests_list = json.load(f)
      for test in tests_list:
        test_id = test['id']
        tests[test_id] = test
#  run_test('T110')
#  run_test('T410')
  futures = []
  with ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
    epoch = int(time.time())
    local_time = time.strftime("%Y%m%d-%H%m%S", time.localtime(epoch))
    print (local_time, flush=True)
    for test_id in tests:
      futures.append(ex.submit(run_test, test_id))
    for fut in as_completed(futures):
      run_completed = True
  time.sleep (3)
  run_count += 1

