# AMI Cleanup

If you would like to manually save your images from being tagged / deprecated, add a 
tag to them with only a Key of 'safe' (no value)

## Getting Started

s3 backend
```
git clone
cd tf-module-ec2_ami_cleanup
make s3 backend tf
terraform init

```


