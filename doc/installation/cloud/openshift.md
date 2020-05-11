# Installing GitLab on OpenShift Enterprise & OKD

## GitLab Runner Installation via OpenShift Operator (Alpha)
NOTE: **Note:** The GitLab OpenShift Operator is currently in 
alpha. This should not be used in production just yet. If you
need assistance, you can reach out in `#openshift` on slack.

GitLab provides a supported Operator for OpenShift. Currently this is used only to install the GitLab Runner. In the future this will be used to install, maintain, and secure GitLab on OpenShift. For now, the GitLab Runner is supported in beta. You can install the GitLab Runner via the instructions below.

#### Install The GitLab OpenShift Operator

1. Login to your cluster as a cluster-admin. Go to the operatorhub section on the left side of the navigation panel. In the search area, enter `GitLab` and locate the install button. Click this button.

2. You will now be presented with a `Create Operator Subscription` page. On this page, pick the beta channel, approval strategy, and a specific namespace to deploy the runner in.

#### Deploying A GitLab Runner

1. Open a Terminal and Login to your OpenShift Cluster and select the proper namespace.
```
$ oc login -u ${YOUR_LOGIN} -p ${YOUR_PASSWORD} ${OPENSHIFT_API_URL}
$ oc project ${YOUR_NAMESPACE}
```

2. Now, We need to get your GitLab Runner token. We can do this by either getting the global GitLab Runner token to make a global runner, or we can assign it per project/group. [For assistance with getting a CI Token, Click Here.](https://docs.gitlab.com/ee/ci/runners/)

3. Once we have the token, we need to make a secret in the namespace with our CI Token inside of it. You can do that with the following command:
```
oc create secret generic ${MY_SECRET_NAME} --from-literal runner_registration_token=${MY_CI_TOKEN}
```

4. Now we need to make our CRD and apply it. Open your terminal and make a file.
```
$ vi gitlab-runner.yml
```

Now put the following in that file, Fill out the details for yourself.
```
apiVersion: gitlab.com/v1beta1
kind: Runner
metadata:
  name: ${MY_OBJECT_NAME}
spec:
  gitlab:
    url: ${MY_GITLAB_URL -or- https://gitlab.com}
  token: ${MY_SECRET_NAME}
  tags: openshift, test
```

Now Apply those changes.
```
$ oc apply -f gitlab-runner.yml
```

*If you were successful in this,* in the next 3-5 minutes you should see the runner pods spin up and register with your Project/Group/GitLab Instance. You should not be able to run workloads in OpenShift.


NOTE: **Note:** If you need more advanced configuration such
as modifying the config.toml values. You will find a configmap
inside your namespace with the config.toml value there. Edit
this configmap entry for advanced configurations.

## GitLab Installation on OpenShift & OKD

Currently GitLab does not target or provide support for OpenShift Installations. We have extensive and verbose documentation around Kubernetes and Omnibus. However, due to OpenShift's increased security restrictions we do not currently target or support it.

Work is being done to rectify this, This work can be tracked [in this epic](https://gitlab.com/groups/gitlab-org/-/epics/2068).

As soon as we finish the engineering work to provide support for OpenShift we'll revise this document with new installation procedures.
