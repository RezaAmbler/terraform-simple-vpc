# terraform-simple-vpc
AWS Simple VPC - 3 Tiers Arch with RDS

Build AMI images with packer first.

`$ pwd
.../terraform-simple-vpc/packer`

`packer$ packer build webapp.json`


amazon-ebs output will be in this color.
==> amazon-ebs: Prevalidating AMI Name: packer-webapp 1543105670
    amazon-ebs: Found Image ID: ami-076e276d85f524150
==> amazon-ebs: Creating temporary keypair: packer_5bf9ec88-4a17-8a43-4db3-9bd3e5908eaa
...
==> amazon-ebs: Copying AMI (ami-0543b66abbbb14a3c) to other regions...
    amazon-ebs: Copying to: us-east-1
    amazon-ebs: Waiting for all copies to complete...
...
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-east-1: ami-0111979781e55ac30
us-west-2: ami-0543b66abbbb14a3c


Take the output of the bastion and webapp AMI IDs and place the IDs into their respective regions for the variables "amiweb" and "amibastion"

Task List
- [x] Finish my changes
- [ ] Item One
- [ ] Item Two

:shipit:
