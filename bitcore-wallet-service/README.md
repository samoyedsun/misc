Launch service:

step 1, you need to start a mongodb service by following command.
```bash
docker run -it -d -p 27017:27017 --name mongodb mongo
```

step 2, you need to clone repo for bitcore.
```
git clone git@github.com:bitpay/bitcore.git
```

step 3, you need to run container by following command.
```bash
docker run -it -d -v ${PWD}/bitcore/packages/bitcore-wallet-service:/bws -p 3232:3232 -p 3380:3380 --link mongodb:db --name bws node:10
```

step 4, you need to enter container and modify /bws/src/config.ts
```bash
docker exec -it bws bash
```
```txt
change 'mongodb://localhost:27017/bws' to 'mongodb://db:27017/bws'
change 'socketApiKey' to '8e0a45e97d169c285d05d56c275b3a6e9b27c2222928c12b2452e10fa0562b77'
```

step 5, you need to install and start your bitcore-wallet-service in /bws
```bash
rm package-lock.json
npm install && npm audit fix
npm start
```

if you want to stop your bitcore-wallet-service, you can execute following command in /bws
```bash
npm stop
```
