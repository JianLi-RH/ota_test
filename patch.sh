oc patch clusterversion version --type json -p '[{"op": "add", "path": "/spec/channel", "value": "channel-a"}, {"op": "add", "path": "/spec/upstream", "value": "https://raw.githubusercontent.com/JianLi-RH/ota/refs/heads/main/OCP-77520.json"}]'


oc patch clusterversion version --type json -p '[{"op": "add", "path": "/spec/channel", "value": "candidate-4.13"}]'

oc patch clusterversion version --type=merge -p '{"spec": {"overrides":[{"kind": "Deployment", "name": "network-operator", "namespace": "openshift-network-operator", "unmanaged": true, "group": "apps"}]}}'
oc patch clusterversion version --type=json -p '[{"op": "remove","path":"/spec/overrides"}]'


oc -n openshift-config-managed patch configmap admin-gates --type=json -p='[{"op": "remove", "path": "/data/ack-4.8-dummy"}]'


oc patch clusterversion version --type=json -p '[{"op": "remove","path":"/spec/channel"}]'


oc413 adm upgrade channel candidate-4.9
[root@localhost ~]# oc413 adm upgrade channel
warning: Clearing channel "candidate-4.9"; cluster will no longer request available update recommendations.


token=`oc -n openshift-monitoring create token prometheus-k8s`
url=`oc get route prometheus-k8s -n openshift-monitoring --no-headers|awk '{print $2}'`
curl -s -k -H "Authorization: Bearer $token" https://$url/api/v1/label/reason/values|grep 'FeatureGates_RestrictedFeatureGates_TechPreviewNoUpgrade'

oc patch featuregates.config.openshift.io cluster --type=merge --patch '{"spec":{"featureSet":"DevPreviewNoUpgrade"}}'



token=`oc -n openshift-monitoring create token prometheus-k8s`
route=`oc get route prometheus-k8s -n openshift-monitoring -ojsonpath='{.status.ingress[].host}'`
echo $route
prometheus-k8s-openshift-monitoring.apps.jianl062101.qe.devcluster.openshift.com
curl -s -k -H "Authorization: Bearer $token" https://$route/api/v1/alerts | jq -r '.data.alerts[]| select(.labels.alertname == "CannotRetrieveUpdates")|.state'

curl -s -k -H "Authorization: Bearer $token" https://$route/api/v1/alerts | jq -r '.data.alerts[]| select(.labels.severity == "critical")'

curl -s -k -H "Authorization: Bearer $(oc411 -n openshift-monitoring create token prometheus-k8s)"  https://$(oc411 get route prometheus-k8s -n openshift-monitoring --no-headers|awk '{print $2}')/api/v1/alerts |  jq -r '.data.alerts[]| select(.labels.alertname == "ClusterOperatorDown")|.state'

# get alert 可以简化一下：
$ OC_ENABLE_CMD_INSPECT_ALERTS=true oc adm inspect-alerts --token $token | jq -r '.data.alerts[]'




# EUS Upgrade 只有偶数版本才有EUS
# Pause the worker pool
#. Pause the worker pool
oc patch --type=merge --patch='{"spec":{"paused":true}}' machineconfigpool/worker
oc get mcp worker -ojson| jq .spec.paused
true


# 删除channel
oc patch clusterversion version --type json -p '[{"op": "remove", "path": "/spec/channel"}]'



# Pause the worker pool
oc patch --type=merge --patch='{"spec":{"paused":true}}' machineconfigpool/worker
# Unpause
oc412 patch --type=merge --patch='{"spec":{"paused":false}}' machineconfigpool/worker
[root@localhost ~]# oc412 get mcp worker -ojson| jq .spec.paused
false
[root@localhost ~]# 


# Disable the default catalog source
oc412 patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'