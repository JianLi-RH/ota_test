
# Dockerfile 在： 
https://docs.openshift.com/container-platform/4.13/updating/updating-restricted-network-cluster/restricted-network-update-osus.html#update-service-install-cli_updating-restricted-network-cluster-osus

# graph-data
quay.io/openshifttest/graph-data:latest


###############################################################################################################
######################################## 在普通环境安装OSUS Operator: ###########################################
###############################################################################################################
https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-35869

###############################################################################################################


###############################################################################################################
################################ 在disconnected环境安装OSUS Operator: ###########################################
###############################################################################################################
https://docs.openshift.com/container-platform/4.14/updating/updating_a_cluster/updating_disconnected_cluster/disconnected-update-osus.html#update-service-overview_updating-restricted-network-cluster-osus

https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-40819
 1. Disable the default catalog source
# ./oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'


https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-43326
Mirror graph-data container image to disk then to local registry by using oc

podman build -f Dockerfile -t ${LOCAL_REGISTRY}/rh-osbs/cincinnati-graph-data-container:v5.0.0
podman push ${LOCAL_REGISTRY}/rh-osbs/cincinnati-graph-data-container:v5.0.0
###############################################################################################################



###############################################################################################################
############################################# Install OSUS by cli #############################################
###############################################################################################################
https://docs.openshift.com/container-platform/4.10/updating/updating-restricted-network-cluster/restricted-network-update-osus.html
https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitems/testcase?query=OCP-35944

# OSUS Service URL:
oc get updateservice sample -n   -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}'

1. Build and mirror graph-data container image to local registry as Non-Root User
# podman build -f ./Dockerfile -t ${DIS_REGISTRY}/rh-osbs/cincinnati-graph-data-container:v4.6.0
# podman push ${DIS_REGISTRY}/rh-osbs/cincinnati-graph-data-container:v4.6.0

# 查看已安装的CatalogSource
oc get catalogsource -n openshift-marketplace
# qe-app-registry

1. 创建namaspace
oc create ns osus

2. 创建OperatorGroup
cat <<EOF > og.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: osus-og
  namespace: osus
spec:
  targetNamespaces:
  - osus
EOF

oc create -f og.yaml 

3. 创建Subscription
cat <<EOF > sub.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: osus-sub
  namespace: osus
spec:
  channel: v1
  name: cincinnati-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: update-service-operator.v5.0.0
  installPlanApproval: Manual
EOF
oc create -f sub.yaml 

# manual 的operator需要在UI上approve

# Automatic
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: update-service-subscription
spec:
  channel: v1
  installPlanApproval: "Automatic"
  source: "redhat-operators" 
  sourceNamespace: "openshift-marketplace"
  name: "cincinnati-operator"

# Create UpdateService resouce
# cat cincy.yaml 
apiVersion: cincinnati.openshift.io/v1beta1
kind: UpdateService
metadata:
  name: my-cincy
  namespace: osus
spec:
  replicas: 1
  releases: "quay.io/openshift-release-dev/ocp-release"
  graphDataImage: "quay.io/openshifttest/graph-data:v5.0.0"

# oc411 create -f cincy.yaml 
cincinnati.cincinnati.openshift.io/my-cincy created


# oc delete sub osus-sub -n osus
# oc delete csv update-service-operator.v4.6.0 -n osus
# oc delete og osus-og -n osus


# 检查 OSUS Service URL:
oc get route my-cincy-policy-engine-route -o jsonpath='{.spec.host}' -n openshift-update-service
# 也可以用下面方法获取route
route=$(oc get -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}' updateservice sample -n openshift-update-service)
while sleep 1; do POLICY_ENGINE_GRAPH_URI="$(oc -n openshift-update-service get -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}' updateservice sample)"; SCHEME="${POLICY_ENGINE_GRAPH_URI%%:*}"; if test "${SCHEME}" = http -o "${SCHEME}" = https; then break; fi; done
# 验证graphdata
curl -skH 'Accept:application/json' "$route?channel=fast-4.16" -o /dev/null -w "status: %{http_code}\n"


curl -skH 'Accept:application/json' "${route}?arch=amd64&channel=fast-4.16" | jq -r '.nodes[] | select(.version == "4.16.1").payload'


[root@localhost ~]# curl -skH 'Accept:application/json' "$url?channel=candidate-4.13"|jq .
{
  "version": 1,
  "nodes": [
    {
      "version": "4.13.5",
      "payload": "ec2-18-217-180-0.us-east-2.compute.amazonaws.com:5000/ocp-release@sha256:af19e94813478382e36ae1fa2ae7bbbff1f903dded6180f4eb0624afe6fc6cd4",
      "metadata": {
        "io.openshift.upgrades.graph.release.channels": "candidate-4.13,candidate-4.14",
        "io.openshift.upgrades.graph.release.manifestref": "sha256:af19e94813478382e36ae1fa2ae7bbbff1f903dded6180f4eb0624afe6fc6cd4",
        "url": "https://access.redhat.com/errata/RHSA-2023:4091"
      }
    }
  ],
  "edges": [],
  "conditionalEdges": []
}





# Disconnected 
# Mirror osus operator and index image to local registry
skopeo copy docker://registry-proxy.engineering.redhat.com/rh-osbs/openshift-update-service-openshift-update-service-operator:v4.6.0 docker://${DIS_REGISTRY}/rh-osbs/openshift-update-service-openshift-update-service-operator:v4.6.0 --src-tls-verify=false

podman push ${DIS_REGISTRY}/rh-osbs/osus-index:1.1
# Note: if image is available, skip the step.



# Create osus-ca cm and add it to trusted ca of proxy for cluster to access the osus route
(refer to
https://docs.openshift.com/container-platform/4.6/networking/enable-cluster-wide-proxy.html)

oc get -n openshift-ingress-operator secret router-ca -o jsonpath="{.data.tls\.crt}" | base64 -d >ca-bundle.crt
oc -n openshift-config create configmap osus-ca --from-file=ca-bundle.crt
oc patch proxy cluster --type json -p '[{"op": "add", "path": "/spec/trustedCA/name", "value": "osus-ca"}]'



############################################
# Use upshift.mirror-registry.qe.devcluster.openshift.com:5000 (dummy/dummy) as the release in update service
1
oc adm release mirror -a config.json --from=quay.io/openshift-release-dev/ocp-release:4.11.28-x86_64 \
  --to=upshift.mirror-registry.qe.devcluster.openshift.com:5000/openshift-release-dev/ocp-release \
  --to-release-image=upshift.mirror-registry.qe.devcluster.openshift.com:5000/ocp-release:4.11.28-x86_64


oc adm release mirror -a config.json --from=quay.io/openshift-release-dev/ocp-release:4.17.4-x86_64 \
  --to=quay.io/rhn_support_jianl/openshift-release-dev/ocp-release \
  --to-release-image=quay.io/rhn_support_jianl/ocp-release:4.17.4-x86_64



# 出现Auth错误的时候，是secret没有配置，或者配置的不正确：
#手动改cluster 的pull secret
oc extract secret/pull-secret -n openshift-config --confirm
#.dockerconfigjson is generated, add auth of your registry to the file， upshift 的用户名密码是dummy:dummy，需要base64加密
qe_operators_token=$(echo dummy:dummy|base64 -w 0)
art_fbc_fragments_token=$(echo ${ART_FBC_FRAGMENTS_ACCOUNT_USER}:${ART_FBC_FRAGMENTS_ACCOUNT_PASSWORD}|base64 -w 0)

jq --arg token1 "${qe_operators_token}" --arg art_token "${art_fbc_fragments_token}" '.auths += {"quay.io/openshift-qe-optional-operators":{"auth":$token1},"quay.io/openshifttest":{"auth": $token1},"quay.io/olmqe":{"auth": $token1},"quay.io/metal3-io":{"auth": $token1}, "quay.io/openshift-art":{"auth": $art_token}}' .dockerconfigjson > updated_pullsecret.json


oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=new_config_json

# 使用以下方法可以添加一个新的pull secret
$ oc registry login --registry="<registry>" --auth-basic="<username>:<password>" --to=<pull_secret_location>
$ oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=<pull_secret_location>
# 例如：
oc registry login --registry=quay.io/openshifttest/graph-data --auth-basic='rhn_support_jianl:!QAZ-pl,@)2104' --to=dockerconfigjson1111 



###############################################################################################################
################################################ 创建trusted_ca ################################################
###############################################################################################################
# quay.io的image不需要证书就能访问 

证书文件： https://gitlab.cee.redhat.com/aosqe/flexy-templates/-/blob/master/functionality-testing/certs/all-in-one.9/client_ca.crt
wget --no-check-certificate https://gitlab.cee.redhat.com/aosqe/flexy-templates/-/blob/master/functionality-testing/certs/all-in-one.9/client_ca.crt

# 方法1 （参考： https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-42669）
oc -n openshift-config create cm trusted-ca --from-file=upshift.mirror-registry.qe.devcluster.openshift.com..5000=./client_ca.crt --from-file=updateservice-registry=./client_ca.crt

# 方法2
cat <<EOF | oc -n openshift-config create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: trusted-ca
data:
  updateservice-registry: |
    -----BEGIN CERTIFICATE-----
    -----END CERTIFICATE-----
EOF

# 获取当前的ca
oc get cm -n openshift-config trusted-ca -oyaml
oc patch image.config.openshift.io cluster -p '{"spec":{"additionalTrustedCA":{"name":"trusted-ca"}}}' --type merge
# 检查patch结果：
oc get  image.config.openshift.io cluster -o json
# 删除additionalTrustedCA
oc patch image.config.openshift.io/cluster --type=json -p '[{"op": "remove","path":"/spec/additionalTrustedCA"}]'


# Query OpenShift's Update Service Endpoint
$ curl --silent --header 'Accept:application/json' 'https://api.openshift.com/api/upgrades_info/v1/graph?arch=amd64&channel=stable-4.2'\
 | jq '. as $graph | $graph.nodes | map(.version == "4.2.13") | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.])'



# 安装 CatalogSource
# https://gitlab.cee.redhat.com/aosqe/flexy-templates/-/blob/master/functionality-testing/aos-4_21/hosts/use_stage_index_catalogsource.sh



 [jianl@jianl-thinkpadt14gen4 421_2]$ oc get image.config.openshift.io/cluster -oyaml
apiVersion: config.openshift.io/v1
kind: Image
metadata:
  annotations:
    include.release.openshift.io/ibm-cloud-managed: "true"
    include.release.openshift.io/self-managed-high-availability: "true"
    release.openshift.io/create-only: "true"
  creationTimestamp: "2026-01-15T10:51:27Z"
  generation: 1
  name: cluster
  ownerReferences:
  - apiVersion: config.openshift.io/v1
    kind: ClusterVersion
    name: version
    uid: 528fc563-9673-44ea-b472-6224ae0d6299
  resourceVersion: "21411"
  uid: 8f5e7918-08f2-45d9-97d0-70307051f051
spec: {}
status:
  imageStreamImportMode: Legacy
  internalRegistryHostname: image-registry.openshift-image-registry.svc:5000
[jianl@jianl-thinkpadt14gen4 421_2]$ 


# 在connected 环境， 下面这个问题不会影响安装OSUS， 不需要trusted-ca
# image.config.openshift.io.Spec.AdditionalTrustedCA.Name not set for image name cluster
# 