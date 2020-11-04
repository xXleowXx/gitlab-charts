# Gitlab on Oracle Kubernetes Engine (OKE) - Quick Install and Config Guide

## Assumptions:
1. Builtin Container Registry
2. Builtin Runner
3. Domain name and ability to update DNS records
4. OKE Cluster has access to the internet
5. Access to OCI and necissary resources to provision OKE Environment.

## Install
1. Setup OKE Cluster with necessary resources

2. Configure Local Shell to access OKE Cluster

NOTE: **Note:** Cloud Shell had an old version of HELM installed that was below the minimum version that Gitlab documentation says to use.
  
  - Follow this Quickstart Guide: \
  [https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm](https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
  - Ensure to upload your public API key
    - Default location:
    ```/Users/%username%/.oci/oci_api_key_public.pem```

3. Return to OKE and navigate to the cluster page.
  - Click on Access Cluster at the top of the page
  - Select Local Access and follow the steps using your local CLI
  - Ensure correct versions are installed and update using brew (on Mac) if necessary.

4. Ensure the requirements are meet by checking [here](https://docs.gitlab.com/charts/quickstart/index.html#requirements):

NOTE: **Note:** Requirements will change overtime as the Helm chart is updated.

5. From your local CLI - Type the following commands:
  - Add the Gitlab Helm Repo: \
  ```helm repo add gitlab https://charts.gitlab.io/```
  - Install Gitlab using:
      ```shell
      helm install gitlab gitlab/gitlab \
      --timeout 600s \
      --set global.hosts.domain=%DOMAIN_NAME% \
      --set global.hosts.https=true \
      --set global.hosts.gitlab.name=%GITLAB_HOSTNAME%.%DOMAIN_NAME% \
      --set certmanager-issuer.email=%EMAIL_ADDRESS% \
      --set gitlab-runner.runners.privileged=true
      ```
      
  - Additional Helm install paramaters can be found [here]()

6. You can validate the pods are being initialized by typing: \
  ```kubectl get pods```

7. Get the external IP addresses: \
```kubectl get ingress -lrelease=gitlab```

8. Update your DNS records to point to the IP address displayed from the above command.
  - The runner pod requires the DNS to be configured so this pod will enter a CrashLoopBackOff until DNS is configured. You will not be able to proceed without this piece running.
  - Navigating to the webpage will result in a: 
  ```"default backend" - 404 error."```

9. After the DNS zone record has been created, use the following command to get the base64 root password, which you need to connect in the dashboard
  - Run:
  ```kubectl get secret \&lt;name\&gt;-gitlab-initial-root-password -ojsonpath=&#39;{.data.password}&#39; | base64 --decode ; echo```
  - Copy the output to enter into the Gitlab configuration screen later.

10. Ensure all pods are running before proceeding by running:
  - Run:
  ```kubectl get pods```
11. Login to Gitlab
  - Within a Web Browser navigate to the DNS address of the Gitlab Instance (configured above)
  - Enter the follow credentials:
    - Username:
    ```root```
    - Password: It was copied from above command. (base64 string)
12. You will be forced to update the root password.
  - Please record this for future reference.

## Configure
We will now do a basic configuration of Gitlab to include setting up some users, importing a sample project, configure an Operations K8s integration, enabling AutoDevOps and starting your pipeline.

1. Create new admin users - Login to Gitlab using the root account.
  1. Admin Area (wrench at the top) -> Users
2. Import Express project and configure AutoDevops
  1. From Welcome Page -> Create Project -> Import Project -> Repo by URL
    1. Project to Import (Example): [here](https://gitlab.com/gitlab-org/express-example.git)
    2. Paste the URL and follow fill out the remaining items and click create.
  2. Enable AutoDevOps on your project
    1. In the project Navigate to Settings -> CI/CD -> Auto DevOps and enable Default to Auto DevOps pipeline
3. Setup project level Kubernetes with existing Gitlab. You will need several pieces configuration details. Obtain the necessary information:
  1. Get the API URL by running this command:
    1. kubectl cluster-info | grep &#39;Kubernetes master&#39; | awk &#39;/http/ {print $NF}&#39;
    2. Record the API URL for later.
  2. Obtain the CA Certificate, Run:
    1. kubectl get secrets.
      1. One of the secrets listed should be named similar to default-token-xxxxx. Copy that token name and use it in the following command.
        1. Example: default-token-l5x6k
  3. Token: GitLab authenticates against Kubernetes by using service tokens, which are scoped to a particular namespace. The token used should belong to a service account with cluster-admin privileges. Follow these steps to create this service account:
    1. Create a file called gitlab-admin-service-account.yaml on your local machine with the following contents:
    2.

| apiVersion: v1 kind: ServiceAccount metadata: name: gitlab-admin namespace: kube-system --- apiVersion: rbac.authorization.k8s.io/v1beta1 kind: ClusterRoleBinding metadata: name: gitlab-admin roleRef: apiGroup: rbac.authorization.k8s.io kind: ClusterRole name: cluster-admin subjects: - kind: ServiceAccount name: gitlab-admin namespace: kube-system |
| --- |

  1. Run the following command to apply the service account and cluster role binding to your cluster:
    1. kubectl apply -f gitlab-admin-service-account.yaml
    2. You should receive the following output:

serviceaccount &quot;gitlab-admin&quot; created

clusterrolebinding &quot;gitlab-admin&quot; created

  1. Retrieve the token for the gitlab-admin service account:
    1. kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk &#39;{print $1}&#39;)
    2. Record this for later
1. Add the Kubernetes Cluster in Gitlab.
  1. From your project navigate to Operations -> Kubernetes -> Connect existing cluster
  2. From here enter in the recorded information
    1. Kubernetes cluster name
      1. Create a name
    2. API URL
      1. Previously recorded
    3. CA Certificate
      1. Previously recorded
    4. Service Token
      1. Previously recorded
  3. Click Add Kubernetes cluster when finished
2. Install Applications within the Gitlab connected Kubernetes cluster
  1. From your project navigate to Operations -> Kubernetes -> Click on the newly created cluster -> Applications
  2. Install the following components:
    1. Ingress - Disable WAF
      1. Endpoint should be the IP address
    2. Cert-Manager
    3. Prometheus
3. Upload Gitlab License Key
  1. [https://gitlabtest.onsg.us/admin/license](https://gitlabtest.onsg.us/admin/license)
  2. Note you will need Gitlab Ultimate to have the security scans working.
4. Run your CI pipeline
  1. Navigate to your project -> CI/CD
  2. Click on Run Pipeline
  3. You should have successfully completed a pipeline
5. Success!
