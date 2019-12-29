#!/bin/bash
IP=$(kubectl get services | grep lnd-btcd-s | awk '{print $4}')
kubectl exec lnd-btcd-0 -c lnd -- rm /root/.lnd/tls.cert
kubectl exec lnd-btcd-0 -c lnd -- rm /root/.lnd/tls.key
# kubectl exec lnd-pod -- cat server.json > tmp.json
cat server.json >> tmp.json
sed -i  "bak" "s/address/$IP/g" tmp.json
kubectl cp tmp.json lnd-btcd-0:/server.new.json -c lnd
rm tmp.json
kubectl exec lnd-btcd-0 -c lnd -- sh -c 'cfssl gencert -initca server.new.json | cfssljson -bare ca -'
kubectl exec lnd-btcd-0 -c lnd -- sh -c 'cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=config.json server.new.json | cfssljson -bare server'
kubectl exec lnd-btcd-0 -c lnd -- sh -c 'mv /server.pem /root/.lnd/tls.cert'
kubectl exec lnd-btcd-0 -c lnd -- sh -c 'mv /server-key.pem /root/.lnd/tls.key'
kubectl delete pod lnd-btcd-0