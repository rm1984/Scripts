#!/usr/bin/env python3

#
# SharePwd.py
# --------
# A simple Python script that, given a customer name and password, runs a
# minimal web server that serves a unique URL consisting in a page with the
# given password.
# This may be useful when somebody needs to share a password with someone else.
# As soon as the recipient reads the password, you can kill the server.
# This is not intended to be a SECURE way to share passwords, it just aims to be
# fast and straightforward.
#
# Coded by: Riccardo Mollo (riccardomollo84@gmail.com)
#

# TODO:
# allow the customer to kill the demon once he has read the password (button?)

import binascii
import hashlib
import html
import http.server
import random
import requests
import socketserver
import sys

from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from random import randint, seed

class HTTPHandler(BaseHTTPRequestHandler):
    def __init__(self, password, pwd_hash):
        self.password = password
        self.pwd_hash = pwd_hash

    def __call__(self, *args):
        super().__init__(*args)

    def do_GET(self):
        if (self.pwd_hash == self.path[1:]):
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            data = get_data(self.password)

            self.wfile.write(data.encode())

        return

def get_data(password):
    data = """
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="utf-8"/>
        <style>
    div {
        padding-top: 30px;
        text-align: center;
        font-family: Courier, Monaco, monospace;
        font-weight: bold;
        font-size: 4em;
    }
        </style>
    </head>
    <body>
        <div>""" + html.escape(password) + """</div>
    </body>
    </html>
    """

    return data

def get_hash(password, salt):
    if type(salt) is not bytes:
        salt = salt.encode('utf-8')

    hmac = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 10000)
    pwd_hash = binascii.hexlify(hmac)

    return pwd_hash.decode()

def main(argv):
    now = int(datetime.utcnow().timestamp())

    # first seed based on current UNIX timestamp
    seed(now)

    # random port
    port = randint(16383, 65535)

    # second seed based on UNIX timestamp and random port
    seed(int(now / port))

    customer = argv[0]
    password = argv[1]
    salt = str(randint(port, port * now))
    pwd_hash = get_hash(password, salt)

    try:
        handler = HTTPHandler(password, pwd_hash)
        httpd = HTTPServer(('', port), handler)

        public_ip = requests.get('https://checkip.amazonaws.com').text.strip()
        url = 'http://' + public_ip + ':' + str(port) + '/' +  pwd_hash

        print('Customer:  ' + customer)
        print('Address:   ' + url)

        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    except OSError as ex:
        print(ex)

if __name__ == '__main__':
    if len(sys.argv) == 3:
        main(sys.argv[1:])
    else:
        print("Usage: ./sharepwd.py <CUSTOMER> <PASSWORD>", file = sys.stderr)
        exit(1)
