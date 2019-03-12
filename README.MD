# Cloud Environment and DevOps Pipeline Setup

This document outlines the necessary steps to setup the Azure infrastructure for a DevOps sandbox and test application. All source code is represented in this repository. 

Under *cloud-ops/azure/devops-sandbox-cluster* you will find everything necessary for building out the following infrastructure in Azure:

* A two node linux cluster of the size Standard_DS1_v2 that is the DevOps cluster of this project (see the next section for general information regarding standard cluster sizes that can be used with these creation scripts). Node count can also be changed easily.

Under *cloud-ops/kubernetes/devops-sandbox-cluster* you will find everything necessary for building out the following inside of that kubernetes cluster within Azure:

* A publicly accessible but secured harbor instance that houses docker images and helm charts for this devops sandbox. That instance is accessible at https://sandboxregistry.freebytech.com.
* A publicly accessible but secured jenkins instance that builds the application found in this sandbox repository. That instance is accessible at https://sandboxbuilds.freebytech.com.

This kubernetes cluster also tests and is the release environment for the test application contained in *src* and whose helm chart is located under *deploy*, it is accessible at https://sandboxapp.freebytech.com. The application in this repository was originally based off of the React / .NET Core Okta test application found at:

https://github.com/oktadeveloper/okta-dotnetcore-react-example


# Azure VM Pricing

VMs are not the only cost related to AKS in Azure, dynamic disks and container insights logging also represent important pricing factors, but here is a breakdown of pricing per VM for standard kubernetes cluster sizes.

The following prices and sizes are based off of quotes from March of 2019, more information and different cluster types can be viewed here:

https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/

| Size              | vCPU | Mem | Temp Storage (SSD) | Max Disks* | Monthly Cost East US  | 1 year reserved | 3 year reserved |
|-------------------|------|-----|--------------------|------------|-----------------------|-----------------|-----------------|
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
| Standard_DS5_v2	| 16   | 56  | 112                | 64         | ~$854.10/month | ~$361.9997/month (~58%) | ~$234.6658/month (~73%) |
| Standard_D16s_v3  | 16   | 64  | 128                | 32         | ~$560.64/month | ~$334.3327/month (~40%) |  ~$215.1967/month (~62%) |
| Standard_D32s_v3  | 32   | 128 | 256                | 32         | ~$1,121.28/month | ~$668.6654/month (~40%) | ~$430.3861/month (~62%) |
| Standard_D64s_v3  | 64   | 256 | 512                | 32         | ~$2,242.56/month | ~$1,337.3308/month (~40%) | ~$860.7795/month (~62%) |

*The number disks allowed per node is the maximum amount of storage containers that a cluster can support per node.

## Step 1, Azure Cloud Infrastructure 

The cloud infrastructure can be setup by running the following command:

```powershell
cd cloud-aps/azure/devops-sandbox-cluster
01-Setup-ClusterEnvironment.ps1
```

## LICENSE

Apache 2.0, see [LICENSE](LICENSE)