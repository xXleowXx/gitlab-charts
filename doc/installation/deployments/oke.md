# Deploy GitLab on OKE

This is a quickstart guide that will help you deploy GitLab in
[Oracle Kubernetes Engine (OKE)](https://www.oracle.com/cloud-native/container-engine-kubernetes/)
hosted on Oracle Cloud Infrastructure (OCI).

## Assumptions

The following are assumed:

- A builtin Container Registry will be used.
- A builtin Runner will be used.
- You have a domain name to be used with GitLab and you are able to update DNS records.
- The OKE cluster has access to the internet.
- You have access to OCI and any necessary resources to provision the OKE environment.
- The GitLab Runner will be set to [privileged mode](https://docs.gitlab.com/runner/executors/docker.html#the-privileged-mode).

## Set up and configure the OKE cluster

1. Set up the OKE cluster.
1. Follow Oracle's [quickstart guide](https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
   to configure your local shell to access the OKE cluster.
1. Ensure to [upload your public API key](https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#three).
   The default location should be at `~/.oci/oci_api_key_public.pem`.
1. Return to OKE and navigate to the cluster page.
   1. Click on **Access Cluster** at the top of the page.
   1. Select **Local Access** and follow the steps using your local CLI.
   1. Ensure the correct versions are installed and update them if necessary.

## Install GitLab

1. Ensure the [requirements](../../quickstart/index.md#requirements) are met.
1. From your local CLI add the GitLab Helm repo:

   ```shell
   helm repo add gitlab https://charts.gitlab.io/
   ```

1. Install GitLab:

   ```shell
   helm install gitlab gitlab/gitlab \
   --timeout 600s \
   --set global.hosts.domain=%DOMAIN_NAME% \
   --set global.hosts.gitlab.name=%GITLAB_HOSTNAME%.%DOMAIN_NAME% \
   --set certmanager-issuer.email=%EMAIL_ADDRESS% \
   --set gitlab-runner.runners.privileged=true
   ```

1. You can validate the pods are being initialized:

   ```shell
   kubectl get pods
   ```

1. Get the external IP addresses:

   ```shell
   kubectl get ingress -lrelease=gitlab
   ```

1. Update your DNS records to point to the IP address displayed from the above command.
   The runner pod requires the DNS to be configured so this pod will enter a
   `CrashLoopBackOff` until DNS is configured. You will not be able to proceed
   without this piece running. Navigating to the GitLab webpage will result in a:
   `default backend - 404 error.`

1. After the DNS zone record has been created, get the base64 root password,
   which you need to connect in the dashboard:

   ```shell
   kubectl get secret &lt;name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo`
   ```

   Copy the output to enter into the GitLab configuration screen later.

1. Ensure all pods are running before proceeding:

   ```shell
   kubectl get pods
   ```

1. Log in to GitLab by navigating to the DNS address of the GitLab instance.
   As username use `root` and as password the one you copied above. At the first
   login you will be forced to update the root password.

## Configure GitLab

We will now do a basic configuration of GitLab to include
importing a sample project, configure an Operations Kubernetes integration,
enabling Auto DevOps, and starting your pipeline:

1. Import an example project and configure Auto DevOps:
   1. From the welcome page, select **Create Project > Import Project > Repo by URL**.
      For the project to import use the Express example: `https://gitlab.com/gitlab-org/express-example.git`.
      Paste the URL, follow fill out the remaining items, and click create.
   1. Enable Auto DevOps on your project, by navigating to **Settings > CI/CD > Auto DevOps**,
      and enable **Default to Auto DevOps pipeline**.
1. Next, set up the project level Kubernetes integration. You will need several
   pieces of configuration details. Obtain the necessary information:
   1. Get the API URL:

      ```shell
      kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}'
      ```

   1. CA Certificate:
      1. List the Secrets:

      ```shell
      kubectl get secrets
      ```

      One of the secrets listed should be named similar to `default-token-xxxxx`.
      Copy that token name and use it in the following command.

      1. Obtain the CA Certificate:

      ```shell
      kubectl get secret <secret name> -o jsonpath="{['data']['ca\.crt']}" | base64 --decode
      ```

      If the command returns the entire certificate chain, you must copy the Root CA certificate and any intermediate certificates at the bottom of the chain.

   1. GitLab authenticates against Kubernetes by using service tokens, which are
      scoped to a particular namespace. The token used should belong to a service
      account with cluster-admin privileges. To create this service account:

      1. Create a file called `gitlab-admin-service-account.yaml` on your local
         machine with the following contents:

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

      1. Apply the service account and cluster role binding to your cluster:

         ```shell
         kubectl apply -f gitlab-admin-service-account.yaml
         ```

         You should receive the following output:

         ```plaintext
         serviceaccount "gitlab-admin" created
         clusterrolebinding "gitlab-admin" created
         ```

      1. Retrieve the token for the `gitlab-admin` service account:

         ```shell
         kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')
         ```

1. Add the Kubernetes Cluster in GitLab:
   1. From your project navigate to **Operations -> Kubernetes -> Connect existing cluster**
   1. From here enter in the recorded information
      1. Create a Kubernetes cluster name
      1. Add the API URL from the previous steps.
      1. Add the CA Certificate from the previous steps.
      1. Add the service token from the previous steps.
   1. Click **Add Kubernetes cluster**.
1. Install applications within the GitLab-connected Kubernetes cluster:
   1. From your project navigate to **Operations > Kubernetes**, click on the
      newly-created cluster and navigate to **Applications**.
   1. Install the following components:
       - Ingress (disable WAF): the endpoint should be the IP address of the cluster.
       - Cert-Manager
       - Prometheus
1. Upload a license key to your GitLab instance by navigating to the license page
   (`https://<YOUR-GITLAB-FQDN>/admin/license`).
   You will need GitLab Ultimate to have the security scans working.
1. Run your CI pipeline by navigating to your project's **CI/CD** and click on
   **Run Pipeline**. After a few minutes your Auto DevOps pipeline should have
   successfully completed.
