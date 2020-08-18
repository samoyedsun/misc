#!/usr/bin/python
#coding:utf-8

import MySQLdb

class db():
    cxn = None
    cur = None
    def create(self):
        self.cxn = MySQLdb.connect(host='47.254.25.104', \
                user='root', \
                passwd='QWEzxc123!', \
                db="ssweb")
        self.cur = self.cxn.cursor()
        return self.cur
    def close(self):
        self.cur.close()
        self.cxn.commit()
        self.cxn.close()


def init():
    cxn = MySQLdb.connect(host='47.254.25.104', \
                user='root', \
                passwd='QWEzxc123!')
    cur = cxn.cursor()
    cur.execute('create database if not exists ssweb')
    cur.execute('use ssweb')
    cur.execute('create table if not exists user(\
            uid int primary key auto_increment,\
            username varchar(20) not null,\
            password varchar(20) not null,\
            port int,\
            mode varchar(20) not null,\
            hiredate timestamp)')
    cur.close()
    cxn.commit()
    cxn.close()

def calc_count():
    dbobj = db()
    cur = dbobj.create()
    cur.execute('select count(u.uid) from user u')
    count = 0
    for row in cur.fetchone():
        count = row
    dbobj.close()
    return count

def create_account(username, password, port, mode):
    dbobj = db()
    cur = dbobj.create()
    cur.execute('insert into user(username, password, port, mode, hiredate)\
            value(\'' + username + '\',\'' + password + '\',' + port + ',\'' + mode + '\'' + ',now())')
    dbobj.close()

def load_by_username(username):
    dbobj = db()
    cur = dbobj.create()
    cur.execute('select username, password, port, mode, hiredate from user\
            where username = \'' + username + '\'')
    row = cur.fetchall()
    dbobj.close()
    return row

def load_all_user():
    dbobj = db()
    cur = dbobj.create()
    cur.execute('select username, password, port, mode, hiredate from user')
    row = cur.fetchall()
    dbobj.close()
    return row
