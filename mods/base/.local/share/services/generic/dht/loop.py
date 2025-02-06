# https://learn.adafruit.com/dht-humidity-sensing-on-raspberry-pi-with-gdocs-logging/python-setup

# SPDX-FileCopyrightText: 2021 ladyada for Adafruit Industries
# SPDX-License-Identifier: MIT

import time
import board
import adafruit_dht
import subprocess
import requests
import json
import platform

# Initial the dht device, with data pin connected to:
dhtDevice = adafruit_dht.DHT22(board.D4)

# you can pass DHT22 use_pulseio=False if you wouldn't like to use pulseio.
# This may be necessary on a Linux single board computer like the Raspberry Pi,
# but it will not work in CircuitPython.
# dhtDevice = adafruit_dht.DHT22(board.D18, use_pulseio=False)

def get_env(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    return result.stdout

while True:
    try:
        token = get_env("sat-auth-header")
        base_url = get_env("sat-base-url")

        temperature_c = dhtDevice.temperature
        humidity = dhtDevice.humidity

        print("Temp: {:.1f} C    Humidity: {}% ".format(
                temperature_c, humidity
            )
        )

        url = base_url + '/api/probes/measurements'

        body = {
            "code": platform.node(),
            "value": temperature_c,
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }

        response = requests.post(url, json=body, headers=headers)

    except RuntimeError as error:
        print(error.args[0])
        time.sleep(2.0)
        continue
    except Exception as error:
        dhtDevice.exit()
        raise error

    time.sleep(2.0)

