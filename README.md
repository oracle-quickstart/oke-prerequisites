# This doesn't work yet.  Sorry.

# oke-howto
These are instructions on how to setup an Oracle Kubernetes Engine (OKE) cluster along with a Terraform module to automate part of that process.

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/cloud-partners/oci-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/cloud-partners/oke-howto.git
    cd oke-howto/terraform
    ls

![](./images/01%20-%20git%20clone.png)

We now need to initialize the directory with the module in it.  This makes the module aware of the OCI provider.  You can do this by running:

    terraform init

This gives the following output:

![](./images/02%20-%20terraform%20init.png)

## Deploy
Now for the main attraction.  Let's make sure the plan looks good:

    terraform plan

That gives:

![](./images/03%20-%20terraform%20plan.png)

If that's good, we can go ahead and apply the deploy:

    terraform apply

You'll need to enter `yes` when prompted.  The apply should take about five minutes to run.  Once complete, you'll see something like this:

![](./images/04%20-%20terraform%20apply.png)

## Viewing the Cluster in the Console
We can check out our new cluster in the console by navigating [here](https://console.us-phoenix-1.oraclecloud.com/a/compute/instances).  These are the IaaS machines running the OKE cluster.

![](./images/05%20-%20console.png)

## Setup the Terminal
To interact with our cluster, we need to configure `kubectl` on our local machine.  To do that, first install the latest version with the commands:

    version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${version}/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    mkdir -p $HOME/.kube
    cp $KUBE_CONFIG_FILE_PATH ~/.kube/config

We're also probably going to want `helm`.  We can do that by running the commands:

    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh
    helm init
    helm init --upgrade
    helm repo update

We can make sure this all worked by running this command to check out the pods in our cluster:

    kubectl get pods

That should give something like:

![](./images/06%20-%20get%20pods.png)

## Destroy the Deployment
When you no longer need the DSE cluster, you can run this to delete the deployment:

    terraform destroy

You'll need to enter `yes` when prompted.  Once complete, you'll see something like this:

![](./images/13%20-%20terraform%20destroy.png)
