terraform init -backend=false 
terraform init -backend-config="token=${env:TERRAFORM_TOKEN}"