# https://learn.adafruit.com/dht-humidity-sensing-on-raspberry-pi-with-gdocs-logging/python-setup

import time
import board
import adafruit_dht
import subprocess
import requests
from requests.exceptions import (ConnectTimeout, ReadTimeout)
import platform

# Initial the dht device, with data pin connected to:
dhtDevice = adafruit_dht.DHT22(board.D4)

# you can pass DHT22 use_pulseio=False if you wouldn't like to use pulseio.
# This may be necessary on a Linux single board computer like the Raspberry Pi,
# but it will not work in CircuitPython.
# dhtDevice = adafruit_dht.DHT22(board.D18, use_pulseio=False)

def get_env(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    result.check_returncode()

    return result.stdout.strip()

def send(temp):
    try:
        base_url = get_env("sat-base-url")
        token = get_env("sat-auth-token")

    except subprocess.CalledProcessError as e:
        print('Configuration error: {}'.format(e.stderr))
        return
    
    url = base_url + '/api/probes/measurements'

    body = {
        "code": platform.node(),
        "value": temp,
    }

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Bearer {token}"
    }

    try:
        response = requests.post(url, json=body, headers=headers, timeout=30)

    except (ConnectTimeout, ReadTimeout):
        print('Connection timeout')
        return

    if response.status_code != 200:
        print("POST to {} failed, status: {}".format(url, response.status_code))

while True:
    try:
        temperature_c = dhtDevice.temperature
        # temperature_c = 20.4

    except RuntimeError as error:
        print(error.args[0])
        time.sleep(2.0)
        continue
    except Exception as error:
        dhtDevice.exit()
        raise error

    print("Temp: {:.1f} C".format(temperature_c))

    send(temperature_c)

    time.sleep(2.0)

