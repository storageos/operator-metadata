# operator-metadata

The StorageOS Operator metadata for Kubernetes and OpenShift.

## OLM Bundle

Directory `storageos2` contains [OLM](https://olm.operatorframework.io/)
metadata bundles for building versioned bundle images. These bundle images can
be built using the versioned Dockerfiles in `storageos2`. The bundle images can
be used to create index image using
[operator-registry](https://github.com/operator-framework/operator-registry)
tool, `opm`.

### Build a bundle image

Build a bundle image for `storageos2` package for version `2.2.0`:

```console
$ make bundle-build PACKAGE_NAME=storageos2 BUNDLE_VERSION=2.2.0
...
Successfully tagged storageos/operator-bundle:v2.2.0
```

### Build an index image with a bundle image

**NOTE**: The index image building tool, `opm`, requires the bundle images to
be pushed to container registry before using them for building index image.

Build an index image for the bundle image created above,
`storageos/operator-bundle:v2.2.0`:

```console
$ make index-build INDEX_BUNDLES=storageos/operator-bundle:v2.2.0
INFO[0000] building the index                            bundles="[storageos/operator-bundle:v2.2.0]"
...
INFO[0003] [docker build -f index.Dockerfile259947529 -t storageos/operator-index:test .]  bundles="[storageos/operator-bundle:v2.2.0]"
```

This will result in a new container image `storageos/operator-index:test`. This
image can be deployed in OLM cluster as a `CatalogSource` to avail it as an OLM
catalog in the cluster.

### Using the index image with OLM

**NOTE**: Use [`kubectl-operator`](https://github.com/operator-framework/kubectl-operator)
krew plugin to interact with OLM below.

To add an index image to an OLM cluster, create a `CatalogSource` referencing
the index image:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: storageos-catalog
  namespace: default
spec:
  sourceType: grpc
  image: storageos/operator-index:test
```

Once the `storageos-catalog` CatalogSource is created, it'll be available in
the operator catalog list:

```console
$ kubectl operator catalog list -A
NAME                   NAMESPACE  DISPLAY              TYPE  PUBLISHER       AGE
storageos-catalog      default                         grpc                  9s
operatorhubio-catalog  olm        Community Operators  grpc  OperatorHub.io  11m
```

The catalog runs as a static pod in the same namespace as the CatalogSource:

```console
$ kubectl get all
NAME                          READY   STATUS    RESTARTS   AGE
pod/storageos-catalog-pjp9w   1/1     Running   0          19s

NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
service/kubernetes          ClusterIP   10.96.0.1       <none>        443/TCP     17m
service/storageos-catalog   ClusterIP   10.103.44.247   <none>        50051/TCP   18s
```

List the operators available in the installed catalog:

```console
$ kubectl operator list-available -c storageos-catalog
NAME        CATALOG  CHANNEL  LATEST CSV                AGE
storageos2           stable   storageosoperator.v2.2.0  8m22s
```

Install the operator:

```console
$ kubectl operator install storageos2 --create-operator-group
operatorgroup "default" created
subscription "storageos2" created
operator "storageos2" installed; installed csv is "storageosoperator.v2.2.0"
```

Since OLM requires operators to have operator-group and if the default
namespace doesn't have one, passing `--create-operator-group` will create one.

```console
$ kubectl get all
NAME                                                                  READY   STATUS             RESTARTS   AGE
pod/5964a6e58daf6168aa74a8b1e742a0b9939604ac07f97e37aa8068fa132qfkc   0/1     Completed          0          5m21s
pod/storageos-catalog-pjp9w                                           1/1     Running            0          11m
pod/storageos-operator-5c5575cbbc-9qlnl                               1/1     Running            0          4m58s

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/kubernetes                           ClusterIP   10.96.0.1        <none>        443/TCP             28m
service/storageos-catalog                    ClusterIP   10.103.44.247    <none>        50051/TCP           11m
service/storageos-cluster-operator-metrics   ClusterIP   10.106.249.205   <none>        8383/TCP,8686/TCP   4m40s
service/storageos-scheduler-webhook          ClusterIP   10.104.214.246   <none>        443/TCP             4m38s

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/storageos-operator   1/1     1            1           4m59s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/storageos-operator-5c5575cbbc   1         1         0       4m58s

NAME                                                                        COMPLETIONS   DURATION   AGE
job.batch/5964a6e58daf6168aa74a8b1e742a0b9939604ac07f97e37aa8068fa13aa1f2   1/1           21s        5m21s
```

In the above, a `job` was created to create an operator-group for the
namespace. The operator was deployed as a `deployment`.

Get the status of the installed operator:

```console
$ kubectl operator list -A
PACKAGE     NAMESPACE  SUBSCRIPTION  INSTALLED CSV             CURRENT CSV               STATUS         AGE
storageos2  default    storageos2    storageosoperator.v2.2.0  storageosoperator.v2.2.0  AtLatestKnown  13m
```
