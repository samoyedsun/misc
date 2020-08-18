#!/usr/bin/python
#coding:utf-8

import db
import os
import re
import logging
import datetime

def create(args):
    logging.basicConfig(filename='log.log',level=logging.DEBUG)
    logging.debug('创建')
    username = args['username']
    password = args['password']
    if not re.search('^[a-zA-Z]{1}\w*$', username):
        return {'code':204, 'err':"username format is not correct!"}
    if not re.search('^[a-zA-Z]{1}\w*$', password):
        return {'code':205, 'err':"password format is not correct!"}
    if db.load_by_username(username):
        return {'code':201, 'err':"user already exists!"}
    port = str(13000 + db.calc_count())
    mode = "aes-256-cfb"
    logging.debug('username:%s, password:%s, port:%s, mode:%s', \
            username, password, port, mode)
    os.system("sh startss.sh " + port + " " + password + " " + mode)
    db.create_account(username, password, port, mode)
    return {'code':200, 'err':"success"}

def entry(args):
    logging.basicConfig(filename='log.log',level=logging.DEBUG)
    logging.debug('进入')
    username = args['username']
    password = args['password']
    row = db.load_by_username(username)
    if not row:
        return {'code':202, 'err':"user not exists!"}
    row = row[0]
    if (password != row[1]):
        return {'code':203, 'err':'password error!'}
    time = row[4].strftime("%Y-%m-%d@%H:%M:%S")
    logging.debug('username:%s, password:%s, port:%s, mode:%s, time:%s', \
            username, password, row[2], row[3], time)
    info = {'username':row[0], 'password':row[1], 'port':row[2], 'mode':row[3], 'time':time}
    return {'code':200, 'err':'success', 'data':info}
