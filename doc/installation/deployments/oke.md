# Deploying GitLab on OKE

## Assumptions

1. Builtin Container Registry
1. Builtin Runner
1. Domain name and ability to update DNS records
1. OKE Cluster has access to the internet
1. Access to OCI and necissary resources to provision OKE Environment
1. Setting the GitLab Runner to privlidged mode

## Install

1. Setup OKE Cluster with necessary resources
1. Configure Local Shell to access OKE Cluster<br>
   - NOTE: Cloud Shell had an old version of Helm installed that was below the minimum version that GitLab documentation says to use.
   - Follow this Quickstart Guide:
   - [https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm](https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
   - Ensure to upload your public API key
      - Default location:  
          `/Users/<username>/.oci/oci_api_key_public.pem` <br><br>

1. Return to OKE and navigate to the cluster page.
   - Click on **Access Cluster** at the top of the page
   - Select **Local Access** and follow the steps using your local CLI
   - Ensure correct versions are installed and update using brew (on Mac) if necessary.<br><br>

1. Ensure the requirements are meet by checking here:
   - [https://docs.gitlab.com/charts/quickstart/index.html#requirements](../../quickstart/index.md#requirements)
   - Note: Requirements will change overtime as the Helm chart is updated.<br><br>

1. From your local CLI - Type the following commands:
   - Add the GitLab Helm Repo:

       `helm repo add gitlab https://charts.gitlab.io/`

   - Install GitLab using:

        ```shell
            helm install gitlab gitlab/gitlab \
            --timeout 600s \
            --set global.hosts.domain=%DOMAIN_NAME% \
            --set global.hosts.gitlab.name=%GITLAB_HOSTNAME%.%DOMAIN_NAME% \
            --set certmanager-issuer.email=%EMAIL_ADDRESS% \
            --set gitlab-runner.runners.privileged=true
        ```

1. You can validate the pods are being initialized by typing:

      `kubectl get pods`

1. Get the external IP addresses:

      `kubectl get ingress -lrelease=gitlab`

1. Update your DNS records to point to the IP address displayed from the above command.
    - The runner pod requires the DNS to be configured so this pod will enter a CrashLoopBackOff until DNS is configured. You will not be able to proceed without this piece running.
    - Navigating to the GitLab webpage will result in a: `“default backend - 404” error.`<br><br>

1. After the DNS zone record has been created, use the following command to get the base64 root password, which you need to connect in the dashboard
    
      `kubectl get secret &lt;name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo`
    - Copy the output to enter into the GitLab configuration screen later. <br><br>

1. Ensure all pods are running before proceeding by running:
      
      `kubectl get pods`

1. Login to GitLab
    - Within a Web Browser navigate to the DNS address of the GitLab Instance (configured above)
    - Enter the follow credentials:
        - Username= `root`
        - Password= Password that was copied from above command. (base64 string)<br><br>

1. You will be forced to update the root password.
    - Please record this for future reference.

## Configure

We will now do a basic configuration of GitLab to include setting up some users, importing a sample project, configure an Operations K8s integration, enabling AutoDevOps and starting your pipeline.

1. Create new admin users - Login to GitLab using the root account.
    - Admin Area (wrench at the top) -> **Users** <br><br>

1. Import Express project and configure AutoDevops
    - From Welcome Page -> **Create Project -> Import Project -> Repo by URL**
        - Project to Import (Example): [https://gitlab.com/gitlab-org/express-example.git](https://gitlab.com/gitlab-org/express-example.git)
        - Paste the URL and follow fill out the remaining items and click create.
    - Enable AutoDevOps on your project
        - In the project Navigate to **Settings -> CI/CD -> Auto DevOps** and enable **Default to Auto DevOps pipeline** <br><br>

1. Setup project level Kubernetes with existing GitLab. You will need several pieces configuration details. Obtain the necessary information:
    - Get the API URL by running this command:

        `kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}'`

        - Record the API URL for later. <br><br>
    - Obtain the CA Certificate, Run:

        `kubectl get secrets`

        - One of the secrets listed should be named similar to default-token-xxxxx. Copy that token name and use it in the following command. 
          - Example: `default-token-l5x6k` <br><br>

    - Token: GitLab authenticates against Kubernetes by using service tokens, which are scoped to a particular namespace. The token used should belong to a service account with cluster-admin privileges. Follow these steps to create this service account:
        - Create a file called `gitlab-admin-service-account.yaml` on your local machine with the following contents:

            ```yaml
                apiVersion: v1
                kind: ServiceAccount
                metadata:
                  name: gitlab-admin
                  namespace: kube-system
                ---
                apiVersion: rbac.authorization.k8s.io/v1beta1
                kind: ClusterRoleBinding
                metadata:
                  name: gitlab-admin
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: ClusterRole
                  name: cluster-admin
                subjects:
                - kind: ServiceAccount
                  name: gitlab-admin
                  namespace: kube-system
            ```

    - Run the following command to apply the service account and cluster role binding to your cluster:
        `kubectl apply -f gitlab-admin-service-account.yaml`

        - You should receive the following output:

            ```shell
                serviceaccount "gitlab-admin" created
                clusterrolebinding "gitlab-admin" created
            ```

    - Retrieve the token for the `gitlab-admin` service account:

        `kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')`
        - Record this for later<br><br>

1. Add the Kubernetes Cluster in GitLab.
    - From your project navigate to **Operations -> Kubernetes -> Connect existing cluster**
    - From here enter in the recorded information
        - Kubernetes cluster name
            - Create a name
        - API URL
            - Previously recorded
        - CA Certificate
            - Previously recorded
        - Service Token
            - Previously recorded
    - Click **Add Kubernetes cluster** when finished<br><br>
1. Install Applications within the GitLab connected Kubernetes cluster
    - From your project navigate to **Operations -> Kubernetes ->Click on the newly created cluster -> Applications**
    - Install the following components:
        - Ingress - Disable WAF
            - Endpoint should be the IP address
        - Cert-Manager
        - Prometheus<br><br>
1. Upload GitLab License Key
    - Navigate to the license page: `https://*YOUR-GITLAB-FQDN*/admin/license`
    - Note you will need GitLab Ultimate to have the security scans working.<br><br>
1. Run your CI pipeline
    - Navigate to your project -> **CI/CD**
    - Click on **Run Pipeline**
    - You should have successfully completed a pipeline<br><br>
1. Success!
