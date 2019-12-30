![](http://blog.bruwbird.com/content/images/2019/10/2019-10-13-20-58-50.png)

## 前提
1. GCPプロジェクト準備済
2. GCLOUDをinstall済
3. dockerをinstall済
4. kubectlをinstall済

## GKE
まずはクラスタを作る。
対象のプロジェクトが存在するconfigurationを指定する。

```sh
gcloud config configurations activate CONFIGURATION_NAME
```

続いて、空のクラスタを作成する。

```
gcloud container clusters create lnd-testnet --machine-type=n1-standard-1 --num-nodes=3 --region asia-northeast1-a
gcloud container clusters describe lnd-testnet
```

続いて、今後のローカルでのkubectlとの連携のために、credentialを渡す。

```sh
$ gcloud container clusters get-credentials lnd-simnet --zone asia-northeast1-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for test-cluster.
$ kubectl config get-contexts
```
対象のコンテキストが指定されていることを確認する。

## docker
Container Registry を認証するには、gcloud を Docker 認証ヘルパーとして使用する。

```
gcloud auth configure-docker
```

これができたら、imageをbuildし、gcrにpushする。
ホスト名と Google Cloud Platform Console のプロジェクト ID とイメージ名を組み合わせたものを指定する必要がある。

[HOSTNAME]/[PROJECT-ID]/[IMAGE]

```sh
docker build . -t  gcr.io/<PROJECT_NAME>/lnd:latest
docker build . -t  gcr.io/<PROJECT_NAME>/btcd:latest
```
下記を実行すると、下記の用にイメージが表示されるはずだ。

```sh
$ docker images
REPOSITORY                                                  TAG                 IMAGE ID            CREATED             SIZE
gcr.io/bruwbird/btcd                               latest              aaaaaaaaaaaa        25 hours ago        59.7MB
gcr.io/bruwbird/lnd                                latest              aaaaaaaaaaaa        25 hours ago        72.7MB
```

続いて、このイメージをGCRにプッシュする。

```sh
docker push gcr.io/<PROJECT_NAME>/btcd:latest
docker push gcr.io/<PROJECT_NAME>/lnd:latest
```

```sh
gcloud container images list 
```

.envをシークレットとして展開する。

```
kubectl create secret generic lnd-secret --from-env-file=.env
```

## deploy
statefulsetを利用する。

```sh
$ kubectl apply -f LND.yaml --record
statefulset.apps/lnd-btcd created
```

一定時間が経過すると、podsが作成されていることが確認できる。

```sh
$ kubectl get pods
NAME         READY     STATUS    RESTARTS   AGE
lnd-btcd-0   2/2       Running   1          99m
lnd-btcd-1   2/2       Running   0          99m
```

volumeは下記の通り。

```sh
kubectl get pvc -o wide
NAME                              STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
lndcontainer-bitcoin-lnd-btcd-0   Bound     pvc-b6c7ecca-e4ac-11e9-9cc8-42010a92001a   1Gi        RWO            standard       3m36s
lndcontainer-bitcoin-lnd-btcd-1   Bound     pvc-c91f2495-e4ac-11e9-9cc8-42010a92001a   1Gi        RWO            standard       3m5s
lndcontainer-shared-lnd-btcd-0    Bound     pvc-b6c721c1-e4ac-11e9-9cc8-42010a92001a   1Gi        RWO            standard       3m36s
lndcontainer-shared-lnd-btcd-1    Bound     pvc-c922fec9-e4ac-11e9-9cc8-42010a92001a   1Gi        RWO            standard       3m5s
```

## 動作
実際にコンテナの中に入り、動作確認をする。

```sh
kubectl exec -it lnd-btcd-0 -c lnd bash
lncli create
Input wallet password: 
Confirm password:


Do you have an existing cipher seed mnemonic you want to use? (Enter y/n): n

Your cipher seed can optionally be encrypted.
Input your passphrase if you wish to encrypt it (or press enter to proceed without a cipher seed passphrase): 

Generating fresh cipher seed...

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

---------------BEGIN LND CIPHER SEED---------------
 1. abstract   2. high       3. biology   4. slight 
 5. weekend    6. tonight    7. mystery   8. submit 
 9. easily    10. royal     11. wood     12. figure 
13. benefit   14. ordinary  15. ceiling  16. item   
17. lottery   18. next      19. opera    20. clump  
21. faith     22. copper    23. song     24. tuition
---------------END LND CIPHER SEED-----------------

!!!YOU MUST WRITE DOWN THIS SEED TO BE ABLE TO RESTORE THE WALLET!!!

lnd successfully initialized!
```

このあとの作業に使うlnd node用のGUIツールとしては、[zap](https://zap.jackmallers.com/)を推奨。

## prepare keys
tls及びmacaroonsは、lappsを稼働させるときに必要になるケースが多い。
下記のshellを実行し、tlsを再作成する。

```sh
cd lnd
./rebuild-tls.sh
```

localに落とす時は`kubectl cp`を利用する。
```sh
kubectl cp lnd-btcd-0:root/.lnd/data/chain/bitcoin/testnet/admin.macaroon ./readonly.macaroon -c lnd
kubectl cp lnd-btcd-0:root/.lnd/tls.cert ./readonly.macaroon -c lnd
```

# todo
* [ ] fix external ip