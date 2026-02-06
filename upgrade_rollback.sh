
# upgrade
oc adm upgrade --allow-explicit-upgrade --force --to-image=registry.ci.openshift.org/ocp/release@sha256:2df4604a396bd75a529919097bdf3e91773d1c67e5808da60384f972b0611a1e

# rollback
oc adm upgrade --allow-explicit-upgrade --allow-upgrade-with-warnings --force --to-image=registry.ci.openshift.org/ocp/release@sha256:6206a450efa714632c92017f83cfc91b23dec15f0b2fb663ba80d2ee5176ff9a