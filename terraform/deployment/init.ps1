terraform init -backend=false
try {
    terraform init -backend-config="token=$env:TERRAFORM_TOKEN"
}
catch {

}
EXIT 0