apt update -y
apt upgrade -y
apt install ubuntu-desktop -y
echo "tty -s&&mesg n || true" > /root/.profile
