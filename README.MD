# Cloud Environment and DevOps Pipeline Setup

This repository demonstrates the necessary steps to setup the Azure infrastructure for a DevOps sandbox and test application with SQL Server and an external OAuth 2.0 / OpenID Connect STS. All source code is represented in this repository minus secret definitions defined in environment variables and loaded dynamically into Kuberetes for already exsiting external resources. This is one aspect of a twelve-factor application as originally outlined by the developers at Heroku. More information about twelve-factor applications can be found here at https://12factor.net/.

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/02-Project-Architecture.PNG "Project Architecture Diagram")

Under *cloud-ops/azure/devops-sandbox-cluster* you will find everything necessary for building out the following infrastructure in Azure:

* A 3 node linux cluster of the size Standard_B2s that is the DevOps cluster of this project. See the next section for general information regarding standard cluster sizes that can be used with these creation scripts, node count can also be changed easily.

Under *cloud-ops/kubernetes/devops-sandbox-cluster* you will find everything necessary for building out the following inside of that kubernetes cluster within Azure:

* A publicly accessible but secured harbor instance that houses docker images and helm charts for this devops sandbox. That instance is accessible at https://sandboxregistry.freebytech.com.
* A publicly accessible but secured jenkins instance that builds the application found in this sandbox repository. That instance is accessible at https://sandboxbuilds.freebytech.com.

This kubernetes cluster also tests and is the release environment for the test application contained in *src* and whose helm chart is located under *deploy*, it is accessible at https://sandboxapp.freebytech.com. The application under *src* in this repository was originally based off of the React / .NET Core Okta test application found at:

https://github.com/oktadeveloper/okta-dotnetcore-react-example

That application's source is governed by the Apache 2.0 license, see its repository for more inforrmation.

# Azure VM Pricing

VMs are not the only cost related to AKS in Azure, SQL Server instances, dynamically provisioned volumes for kubernetes services, and Application and Container Insights logging also represent important pricing factors, but here is a breakdown of pricing per VM for standard kubernetes cluster sizes as that represents one of the largest factors.

The following prices and sizes are based off of quotes from March of 2019 from the East US region, more information and different VM types can be viewed on Microsoft's website at https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/.

| Size              | vCPU | Mem | Temp Storage (SSD) | Max Disks* | Monthly Cost | 1 year reserved | 3 year reserved |
|-------------------|------|-----|--------------------|------------|--------------|-----------------|-----------------|
| Standard_B2s      | 2    | 4   | 8                  | 4          | ~$30.368/month | ~$17.7536/month (~42%) | ~$11.4464/month (~62%) |
| Standard_DS1_v2	| 1	   | 3.5 | 7                  | 4          | ~$53.29/month | ~$22.4986/month (~58%) | ~$14.7533/month (~72%) |
| Standard_B2ms     | 2    | 8   | 16                 | 4          | ~$60.736/month | ~$35.5802/month (~41%) | ~$22.8636/month (~62%) |
| Standard_D2s_v3   | 2    | 8   | 16                 | 4          | ~$70.08/month  | ~$41.7487/month (~40%) | ~$26.8859/month (~62%) |
| Standard_DS2_v2	| 2    | 7   | 14                 | 8          | ~$106.58/month | ~$45.0848/month (~58%) | ~$29.4993/month (~72%) |
| Standard_B4ms	    | 4    | 16  | 32                 | 8          | ~$121.18/month | ~$71.0801/month (~41%) | ~$45.7199/month (~62%) |
| Standard_D4s_v3   | 4    | 16  | 32                 | 8          | ~$140.16/month | ~$83.585/month (~40%)  | ~$53.8083/month (~62%) |
| Standard_DS3_v2	| 4    | 14  | 28                 | 16         | ~$213.89/month | ~$90.1696/month (~58%) | ~$58.9986/month (~72%) |
| Standard_B8ms	    | 8    | 32  | 64                 | 16         | ~$243.09/month | ~$142.1675/month (~42%) | ~$91.469/month (~62%) |
| Standard_D8s_v3   | 8    | 32  | 64                 | 16         | ~$280.32/month | ~$167.17/month (~40%)  | ~$107.5801/month (~62%) |
| Standard_DS4_v2	| 8	   | 28  | 56                 | 32         | ~$427.05/month | ~$181.0035/month (~58%) | ~$117.3329/month (~73%) |
| Standard_D16s_v3  | 16   | 64  | 128                | 32         | ~$560.64/month | ~$334.3327/month (~40%) |  ~$215.1967/month (~62%) |
| Standard_DS5_v2	| 16   | 56  | 112                | 64         | ~$854.10/month | ~$361.9997/month (~58%) | ~$234.6658/month (~73%) |
| Standard_D32s_v3  | 32   | 128 | 256                | 32         | ~$1,121.28/month | ~$668.6654/month (~40%) | ~$430.3861/month (~62%) |
| Standard_D64s_v3  | 64   | 256 | 512                | 32         | ~$2,242.56/month | ~$1,337.3308/month (~40%) | ~$860.7795/month (~62%) |

*The number disks allowed per node is the maximum amount of dynamic or persistent volumes that a cluster can support per node.

# Workstation Setup

The latest Azure PowerShell module is required for compatibility with the powershell modules defined in this repository, that requires PowerShell 5 and the .NET framework 4.7.2 to be installed on the development workstation. For more information you can view the microsoft documentation at https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.5.0.

You will know you don't have it installed if your recieve this error:

```powershell
The specified module 'Az.Accounts' was not loaded because no valid module file was found in any module directory.
At ...\cloud-ops\azure\common\ps-modules\New-ServicePrinciple.psm1:4 char:1
+ Import-Module Az.Accounts
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
```

If other prerequisites are installed this command should work to install it:

```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser
```

Terraform is also required, here is an excerpt of its installation procedure from https://github.com/freebyTech/Bootstrapping/blob/develop/WorkstationSetup/Win10-Pro/ContainerWorkstationSetup.ps1:

```powershell
$env:TERRAFORM_VERSION = '0.11.11'
$env:TERRAFORM_FULL_NAME = "terraform_${env:TERRAFORM_VERSION}_windows_amd64"

# Install HashiCorp Terraform Support
$terraformUrl = "https://releases.hashicorp.com/terraform/${env:TERRAFORM_VERSION}/${env:TERRAFORM_FULL_NAME}.zip"
Write-Host "Downloading and installing terraform from $terraformUrl"
Invoke-WebRequest $terraformUrl -OutFile /build/terraform.zip -UseBasicParsing;
Expand-Archive /build/terraform.zip -DestinationPath /build/terraform-tmp;
Move-Item /build/terraform-tmp ${env:ProgramFiles}/terraform;
Remove-Item -Force /build/terraform.zip;
[Environment]::SetEnvironmentVariable('path', $($Env:PATH + ';' + $Env:ProgramFiles + '\terraform'), 'Machine')
```

# Setup Azure Cloud Infrastructure 

1) The cloud infrastructure of kubernetes and SQL Server can be setup by running the following command:

```powershell
cd cloud-ops/azure/devops-sandbox-cluster
. ./01-Setup-ClusterAndSqlServerEnvironment.ps1
```

2) You will be required to log in to your Azure account to gain access to create the proper resources for the cluster:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/01-AzureLogin.PNG "Azure Login")

3) After execution is complete, the *.secrets* directory and the *terraform* directory will now exist in *devops-sandbox-cluster*, the script will also show you how to connect to the cluster and run kubectl:

```bash
You will need to run the following to attach to the new cluster in bash:

cd .../cloud-ops/azure/devops-sandbox-cluster
. init-kube-connection.sh

...

kubectl proxy

And go to:
http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default
```

# Setup Kubernetes Cluster Environment

1) The kubernetes environment can be setup by running the following command starting at the base of this repository:

```powershell
cd cloud-ops/kubernetes/devops-sandbox-cluster
. ./02-setup-kubernetes-environment.sh
```

2) Then, the nginx-ingress, acme protocol cert-manager, local harbor service instances, and the local jenkins instance can all be setup by running the following command:

```powershell
. ./03-install-devops-pipeline-apps.sh
```

3) Once these commands are run you can use `kubectl proxy` to verify the status of your build environment inside the cluster, you will need to wait a few minutes to allow the containers to all come up as harbor is actually several processes that need to provision their own dynamic volumes:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/02b-VerifyBuildEnvironmentStatus.PNG "Kubernetes Status")

4) cert-manager also needs to interact with Let's Encrypt to setup the proper certificates for your websites in an automated way. This means at least two things:

    * You will need to verify in Azure what your cluster's load balancing IP address is.
    * Any domains that you want to be serviced by your cluster you will have to point to the IP address of your kubernetes load balancer. We did this for our example domains:

        * https://sandboxregistry.freebytech.com
        * https://sandboxbuilds.freebytech.com
        * https://sandboxapp.freebytech.com

6) Once that is setup you can access your harbor and jenkins instances (and soon your sandbox application). You may receive a certificate error the first time you try to access a site as the Let's Encrypt certificate creation may not have finished yet. But once that is finished you will have valid certs automatically created for you like these:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/09-LetsEncryptCert.PNG "freebyTech Cert from Let's Encrypt Authority")

5) Harbor needs a couple of manual things setup as the harbor helm chart does not support automated setup of initial users (beyond the base admin user) and projects. Here are screen shots depicting our playground harbor setup:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/03-SetupHarborPublisher.PNG "Setup Jenkins Publishing Agent User")

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/04-SetupPublicProject.PNG "Setup Public Project for freebyJenkinsAgent")

6) Once harbor is setup, you can start to create builds and publish the resulting docker images and helm charts to your sandbox harbor registry if you build out your Jekinsfiles using the commands found in our Open Source freebyJenkinsLibrary Global Pipeline Library. That library can be found here: 

https://github.com/freebyTech/freebyJenkinsLibrary

7) If you wish to use the commands available in this libary, you will need to setup a link to the library in your Jenkins configuration like so (or you can fork a copy and link to yours if you are more confortable with that):

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/10-GroovyPipelineLibrarySetup.PNG "Global Pipeline Library Settings")

8) To fully utilize that library the first build you *absolutely need* to setup is the freebyTech freebyAgent docker image. Without that image you will not be able to run the special commands necessary for cluster publish operations supported by our Open Source freebyJenkinsLibrary Groovy build operations for builds and publication. Here are screen shots depicting that setup and the results of the first build:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/05-CreateTheAgentBuild.PNG "Build Screen 1")

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/06-AgentBuildSettings.PNG "Build Screen 2")

9) Once the build is setup the server will automatically build the image and publish it to the playground registry:

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/07-AgentBuildItself.PNG "Successful Build")

![alt text](https://github.com/freebyTech/AKS-Cluster-With-Harbor-And-Jenkins/blob/develop/documentation/08-PublishToHarbor.PNG "Successful Publish")
