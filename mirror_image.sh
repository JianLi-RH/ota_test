# https://docs.openshift.com/container-platform/4.15/installing/disconnected_install/installing-mirroring-installation-images.html


# get pull secret (config.json) from https://console.redhat.com/openshift/install/pull-secret

# Download image to local folder
oc adm release mirror --from=quay.io/openshift-release-dev/ocp-release:4.16.0-ec.5-x86_64 --to-dir=/home/cloud-user/jianl/data --to=file://test -a config.json

# oc image mirror quay.io/prega/redhat-operator-index:4.16.0-ec.6 quay.io/rhn_support_jianl/operators -a config.json
# oc image mirror registry.redhat.io/redhat/redhat-operator-index:v4.15 quay.io/rhn_support_jianl/operators -a config.json
oc image mirror registry.redhat.io/redhat/redhat-operator-index:v4.15 --dir=/home/cloud-user/jianl/operators file://quay.io/rhn_support_jianl/operators -a config.json




# Upload image to registry
oc image mirror --from-dir=/home/cloud-user/jianl/data 'file://test:4.16.0-ec.5-x86_64*' quay.io/rhn_support_jianl/release -a config.json
oc image mirror --from-dir=/home/cloud-user/jianl/operators quay.io/rhn_support_jianl/operators -a config.json
oc image mirror -f file://quay.io/rhn_support_jianl/operators quay.io/rhn_support_jianl/operators -a config.json


# Directly push the release images to the local registry by using following command:
oc adm release mirror -a config.json \
    --from=quay.io/openshift-release-dev/ocp-release:4.16.0-ec.5-x86_64 \
    --to=quay.io/rhn_support_jianl/release \
    --to-release-image=quay.io/rhn_support_jianl/release:4.16.0-ec.5-x86_64

oc413 adm release mirror -a config.json --from=quay.io/openshift-release-dev/ocp-release:4.13.7-x86_64 --to-dir=/tmp/OCP-30833/data --to=file://test
oc413 adm release mirror -a config.json --to-dir=/mnt/mirror-to-disk quay.io/openshift-release-dev/ocp-release:4.13.7-x86_64
oc413 adm release mirror --dry-run --from=quay.io/openshift-release-dev/ocp-release:4.13.7-x86_64 --to-dir=/tmp/OCP-30833/data --to=file://test -a config.json




#===========================================

sha256:0933c7550ec72358281dcda82da8a0aaf2f84afa1505df7ff128b674d7234be4 file://test:4.16.0-ec.5-x86_64-network-tools
sha256:04760fa270aa4303569d0fb26d4de2376ba67108612cf951ee6a89d5acfbaaa7 file://test:4.16.0-ec.5-x86_64-ironic-agent
info: Mirroring completed in 1m59.92s (147.2MB/s)

Success
Update image:  test:4.16.0-ec.5-x86_64
Mirror prefix: file://test

To upload local images to a registry, run:

    oc image mirror --from-dir=/home/cloud-user/jianl/data 'file://test:4.16.0-ec.5-x86_64*' REGISTRY/REPOSITORY

Configmap signature file /home/cloud-user/jianl/data/config/signature-sha256-f5c9cf5a461434e7.json created
[cloud-user@preserve-yangyang-02 jianl]$ 



oc mirror --config=operator.yaml docker://quay.io/rhn_support_jianl/operators