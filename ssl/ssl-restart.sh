kubectl delete ns elma365

kubectl get namespace "elma365" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/elma365/finalize -f -

kubectl delete ns elma365-dbs
kubectl create ns elma365
kubectl create ns elma365-dbs


kubectl label ns elma365 security.deckhouse.io/pod-policy=privileged --overwrite

kubectl patch nodegroup master --type=merge -p '{"spec":{"kubelet":{"maxPods":200}}}'

kubectl create secret tls elma365-onpremise-tls --cert=/home/kind/ssl/kind.elewise.local.crt --key=/home/kind/ssl/kind.elewise.local.key -n elma365-dbs
kubectl create secret tls elma365-onpremise-tls --cert=/home/kind/ssl/kind.elewise.local.crt --key=/home/kind/ssl/kind.elewise.local.key -n elma365
kubectl create configmap elma365-onpremise-ca --from-file=elma365-onpremise-ca.pem=/home/kind/ssl/rootCA.pem -n elma365
