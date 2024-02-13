[[English](README.md)] [[한국어](README.ko.md)]

# ECS Blueprint
This is ECS Blueprint example helps you compose complete ECS clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With this ECS Blueprint example, you describe the configuration for the desired state of your ECS environment, such as the control plane, worker nodes, as an Infrastructure as Code (IaC) template/blueprint. Once a blueprint is configured, you can use it to stamp out consistent environments across multiple AWS accounts and Regions using your automation workflow tool, such as Jenkins, CodePipeline. Also, you can use ECS Blueprint to easily bootstrap an ECS cluster and ECS tasks. ECS Blueprint also helps you implement relevant security controls needed to operate workloads from multiple teams in the same cluster.

## Setup
### Download
Download this example on your workspace
```
git clone https://github.com/Young-ook/terraform-aws-ecs
cd terraform-aws-ecs/examples/blueprint
```

Then you are in **blueprint** directory under your current workspace. There is an exmaple that shows how to use terraform configurations to create and manage an ECS cluster on your AWS account. Please make sure that you have installed the terraform in your workspace before moving to the next step.

Run terraform:
```
terraform init
terraform apply
```
Also you can use the *-var-file* option for customized paramters when you run the terraform plan/apply command.
```
terraform plan -var-file fixture.tc1.tfvars
terraform apply -var-file fixture.tc1.tfvars
```

## Clean up
To destroy all infrastrcuture, run terraform:
```
terraform destroy
```

If you don't want to see a confirmation question, you can use quite option for terraform destroy command
```
terraform destroy --auto-approve
```

**[DON'T FORGET]** You have to use the *-var-file* option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```
