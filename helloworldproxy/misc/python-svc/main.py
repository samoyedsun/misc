#!/usr/bin/python
#coding:utf-8

from BaseHTTPServer import BaseHTTPRequestHandler
from logic import Logic
import urlparse
import urllib
import json
import db
import os

class GetHandler(BaseHTTPRequestHandler):
    def fill_cross_domain(self):
        self.send_header("Content-type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*") 
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Credentials", "true")

    def is_json(self, input):
        try:
            json.loads(input)
        except ValueError:
            return False
        return True
        
    def byteify(self, input):
        if isinstance(input, dict):
            return {self.byteify(key):self.byteify(value) for key,value in input.iteritems()}
        elif isinstance(input, list):
            return [self.byteify(element) for element in input]
        elif isinstance(input, unicode):
            return input.encode('utf-8')
        else:
            return input

    def do_POST(self):
        headers = {}
        for name, value in self.headers.items():
            headers[name] = value.rstrip()
        length = int(self.headers['content-length'])
        data = self.rfile.read(length)
        args = None
        if data and self.is_json(data):
            args = json.loads(data)
            args = self.byteify(args)
        parsed_path = urlparse.urlparse(self.path)
        logicObj = Logic()
        ret = logicObj.dispatch(parsed_path.path, args)
        ret = ret or {}
        ret['code'] = ret.has_key('code') and ret['code'] or 500
        ret['err'] = ret.has_key('err') and ret['err'] or 'server inner error'
        content = json.dumps(ret)
        self.send_response(200)
        self.fill_cross_domain()
        self.end_headers()
        self.wfile.write(content)
        

    def do_GET(self):
        parsed_path = urlparse.urlparse(self.path)
        message_parts = [
                'CLIENT VALUES:',
                'client_address=%s (%s)' % (self.client_address,
                                            self.address_string()),
                'command=%s' % self.command,
                'path=%s' % self.path,
                'real path=%s' % parsed_path.path,
                'query=%s' % parsed_path.query,
                'request_version=%s' % self.request_version,
                '',
                'SERVER VALUES:',
                'server_version=%s' % self.server_version,
                'sys_version=%s' % self.sys_version,
                'protocol_version=%s' % self.protocol_version,
                '',
                'HEADERS RECEIVED:',
                ]
        for name, value in sorted(self.headers.items()):
            message_parts.append('%s=%s' % (name, value.rstrip()))
        message_parts.append('')
        content = '\r\n'.join(message_parts)
        self.send_response(200)
        self.fill_cross_domain()
        self.end_headers()
        self.wfile.write(content)
        return

def close(sig, frame):
    row = db.load_all_user()
    if row:
        command = "sh stopss.sh"
        for item in row:
            command += " " + str(item[2])
        os.system(command)

def start():
    db.init()
    row = db.load_all_user()
    if row:
        for item in row:
            command = "sh startss.sh " + str(item[2]) + " " + item[1] + " " + item[3]
            os.system(command)
    import signal
    signal.signal(signal.SIGTERM, close)
    from BaseHTTPServer import HTTPServer
    server = HTTPServer(('', 8080), GetHandler)
    print 'Starting server, use <Ctrl-C> to stop'
    server.serve_forever()

start()

