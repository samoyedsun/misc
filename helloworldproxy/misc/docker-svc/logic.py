import logging, docker

class Logic():
    def __init__(self):
        self.image_name = "samoyedsun/ssproxy:latest"
        self.client = docker.DockerClient(base_url="tcp://52.53.154.184:2375", version="auto")

    def imageUpdate(self):
        for image in self.client.images.list():
            print("remove:", image.tags, image.id)
            self.client.images.remove(image.id, force=True)
        image = self.client.images.pull(self.image_name)
        print("pull:", image.tags)

    def serviceStart(self, port, instance, ss_pass, ss_mode):
        name = str(instance) + "-" + str(port)
        env_info = [
            "SS_PASS=" + ss_pass,
            "SS_MODE=" + ss_mode
            ]
        port_info = {"13003/tcp" : port}
        container = self.client.containers.run(image = self.image_name, 
                                            environment = env_info, 
                                            detach = True,
                                            remove = True,
                                            ports = port_info,
                                            name = name)
        print("run:", container.name)
        print("log:\n", container.logs().decode("ascii"))

    def serviceStop(self, port, instance):
        name = str(instance) + "-" + str(port)
        container = self.client.containers.get(name)
        container.stop()
        print("stop:", container.name)


'''
import socket, struct
ip = '52.53.154.184'
int_ip = socket.ntohl(struct.unpack("I",socket.inet_aton(str(ip)))[0])
print(int_ip)
str_ip = socket.inet_ntoa(struct.pack('I',socket.htonl(int_ip)))
print(str_ip)
'''