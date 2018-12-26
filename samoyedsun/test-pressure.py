import requests, threading, signal, os

REQUEST_URL = os.getenv('REQUEST_URL')
THREAD_NUM = int(os.getenv('THREAD_NUM'))

is_running = True
def onSigTerm(signo, frame):
    global is_running
    is_running = False

def handler(a,b):
    while is_running:
        print(requests.get(REQUEST_URL).text)

def process():
    signal.signal(signal.SIGTERM, onSigTerm)

    threads = []
    for i in range(THREAD_NUM):
        threads.append(threading.Thread(target=handler, args=('hello', 0)))
    for i in range(THREAD_NUM):
        threads[i].start()
    for i in range(THREAD_NUM):
        threads[i].join()

    print('----程序安全退出----')

if __name__ == '__main__':
    process()