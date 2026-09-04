echo === add to the crontab to start monitoring independent of your SSH session
echo crontab -e
echo 07 00 23 04 * /opt/DR_Test_Monitor/0.collect.sh
echo === To stop monitoring
echo ps -ef | grep collect
echo kill {listed process IDs}

# This is no longer required since moving from bash to python script
#sudo curl http://www.vdberg.org/~richard/tcpping -o /usr/bin/tcpping
#sudo chmod +x /usr/bin/tcpping
#chmod u+x *.sh

python3 -m venv venv
source venv/bin/activate
pip install pythonping
pip install requests
pip install dnspython
sudo setcap cap_net_raw+ep "$(readlink -f "$PWD/venv/bin/python3")"
