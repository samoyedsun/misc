#!/usr/bin/python
#coding:utf-8

import logon
import logging

class Logic():
    def __init__(self):
        self.process = {}
        self.process["/create"] = logon.create
        self.process["/entry"] = logon.entry
        
    def dispatch(self, path, args):
        logging.basicConfig(filename='log.log',level=logging.DEBUG)
        logging.debug('路径:%s, 消息:%s', path, str(args))
        if (not self.process.has_key(path)):
			return {'code':501, "err":"client error operate"}
        return self.process[path](args)
