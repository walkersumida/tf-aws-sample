# install

```
brew install tfenv
tfenv install 0.11.7
brew install ansible
brew install terraform-inventory
```

# Create S3 bucket for tfstate file
Create `tf-sample-files` bucket.

# Create access key

# Add aws credentials
```
mkdir ~/.aws
touch ~/.aws/config
```

```
[profile tf-sample]
aws_access_key_id = hogehoeg
aws_secret_access_key = hogehoge
```

# init command

```
cd terraform
terraform init \
     -backend-config "bucket=tf-sample-files" \
     -backend-config "key=terraform/terraform.tfstate.aws" \
     -backend-config "region=ap-northeast-1" \
     -backend-config "profile=tf-sample"
```

# Copy files

```
cp terraform/variables.tf.sample terraform/variables.tf
cp ansible/wp/group_vars_all.sample ansible/wp/group_vars/all
cp ansible/ansible.cfg.sample ansible/ansible.cfg
```

# create key pair

```
cd ~/.ssh
ssh-keygen -t rsa -f tf-sample
```

# Apply

```
cd terraform
terraform apply
```

# Exec Ansible

```shell
cd terraform
terraform state pull > .terraform/local.tfstate

cd ansible/wp
TF_STATE=../../terraform/.terraform/local.tfstate ansible-playbook --inventory-file=/usr/local/bin/terraform-inventory playbook.yml

cd terraform
terraform destroy
```
