# PRUEBA DEVCO SALOMON ESLAIT
En este repositorio se incluya la prueba solicitada para el proceso de selección en el cargo de SRE.

Se utiliza GitHub Actions como herramienta de CI/CD donde se crea un workflow para el plan y otro para el apply en terraform usando una estrategia de ramas para llevar los cambios a la rama main, tambien se usa el action de Chekov para hacer el análisis de código estático de Terraform.

Se utilizan los modulos de Terraform de VPC y EKS para crear los recursos necesarios para desplegar el cluster de Kubernetes en AWS.

## Requirements


| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.6.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |


## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 18.29.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.14.3 |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
