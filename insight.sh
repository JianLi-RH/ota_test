# disable insights
oc extract secret/pull-secret -n openshift-config --to=.
# In a text editor, edit the .dockerconfigjson file that was downloaded.
# Remove the cloud.openshift.com JSON entry, for example:
"cloud.openshift.com":{"auth":"<hash>","email":"<email_address>"}
# Save the file.

# update the global pull secret
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=.dockerconfigjson
