# Cloud Deployment

Guide to deploying this configuration on AWS EC2 and GCP GCE.

---

## Status

**📋 Planned** - Cloud deployment is designed but not yet fully implemented.

This document describes the planned cloud deployment strategy.

---

## Overview

This configuration will support cloud deployment with:
- AWS EC2 instances
- GCP GCE instances
- Cloud-init integration
- Automated provisioning
- Remote management

---

## Architecture

### Cloud Base Modules

**AWS EC2** (`nix/modules/cloud/ec2-base.nix` - placeholder):

```nix
{ config, pkgs, lib, ... }:
{
  # EC2-specific configuration
  boot.loader.grub.device = "/dev/xvda";

  services.cloud-init.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 ];

  # EC2 metadata service
  services.amazon-ssm-agent.enable = true;
}
```

**GCP GCE** (`nix/modules/cloud/gce-base.nix` - placeholder):

```nix
{ config, pkgs, lib, ... }:
{
  # GCE-specific configuration
  boot.loader.grub.device = "/dev/sda";

  services.cloud-init.enable = true;

  # GCP guest agent
  services.google-guest-agent.enable = true;
}
```

---

## AWS EC2 Deployment (Planned)

### Build AMI

```bash
# Build custom AMI with nixos-generators
nix build .#nixosConfigurations.ec2-instance.config.system.build.amazonImage

# Upload to AWS
aws ec2 import-image --disk-containers file://image.json
```

### Launch Instance

```bash
# Create instance with Terraform
terraform init
terraform apply

# Or with AWS CLI
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.medium \
  --key-name your-key \
  --user-data file://cloud-init.yaml
```

### Remote Deployment

```bash
# Deploy configuration to EC2
nixos-rebuild switch --flake .#ec2-instance \
  --target-host ec2-user@instance-ip \
  --build-host localhost
```

---

## GCP GCE Deployment (Planned)

### Build GCE Image

```bash
# Build GCE image
nix build .#nixosConfigurations.gce-instance.config.system.build.googleComputeImage

# Upload to GCP
gcloud compute images create nixos-image \
  --source-uri gs://bucket/image.tar.gz
```

### Launch Instance

```bash
# Create instance
gcloud compute instances create nixos-vm \
  --image nixos-image \
  --machine-type n1-standard-2 \
  --zone us-central1-a
```

### Remote Deployment

```bash
# Deploy to GCE
nixos-rebuild switch --flake .#gce-instance \
  --target-host user@instance-ip \
  --build-host localhost
```

---

## Cloud Configuration

### Example EC2 Config

```nix
# hosts/ec2-web.nix
{ config, pkgs, ... }:
{
  imports = [
    ../nix/modules/common.nix
    ../nix/modules/linux-base.nix
    ../nix/modules/cloud/ec2-base.nix
  ];

  # Web server
  services.nginx.enable = true;

  # Auto-updates
  system.autoUpgrade.enable = true;

  # Monitoring
  services.prometheus.exporters.node.enable = true;
}
```

### Cloud-Init Integration

```yaml
# cloud-init.yaml
#cloud-config
users:
  - name: admin
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-ed25519 AAAA...

write_files:
  - path: /etc/nixos/flake.nix
    content: |
      # Nix configuration

runcmd:
  - git clone https://github.com/user/Config.git /etc/nixos
  - nixos-rebuild switch --flake /etc/nixos#cloud-instance
```

---

## Terraform Integration (Planned)

### Using Terranix

```nix
# terranix/aws-ec2.nix
{ config, lib, ... }:
{
  resource.aws_instance.nixos = {
    ami = "ami-xxxxx";  # NixOS AMI
    instance_type = "t3.medium";

    user_data = ''
      #!/bin/bash
      git clone https://github.com/user/Config.git /etc/nixos
      nixos-rebuild switch --flake /etc/nixos#ec2-instance
    '';
  };
}
```

### Deploy with Terraform

```bash
# Generate Terraform JSON
terranix terranix/ > config.tf.json

# Deploy
terraform init
terraform apply
```

---

## Image Building (Planned)

### nixos-generators

```bash
# Install nixos-generators
nix-shell -p nixos-generators

# Build AWS AMI
nixos-generate -f amazon -c ./configuration.nix

# Build GCP image
nixos-generate -f gce -c ./configuration.nix

# Build Azure image
nixos-generate -f azure -c ./configuration.nix

# Build ISO
nixos-generate -f iso -c ./configuration.nix
```

### Custom Image Builder

```nix
# In flake.nix
outputs = { self, nixpkgs, nixos-generators, ... }: {
  images = {
    aws = nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "amazon";
      modules = [
        ./nix/modules/common.nix
        ./nix/modules/cloud/ec2-base.nix
      ];
    };

    gcp = nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "gce";
      modules = [
        ./nix/modules/common.nix
        ./nix/modules/cloud/gce-base.nix
      ];
    };
  };
};
```

---

## Auto-Scaling (Planned)

### AWS Auto Scaling Group

```nix
# terranix/asg.nix
resource.aws_launch_template.nixos = {
  image_id = "ami-xxxxx";
  instance_type = "t3.medium";

  user_data = base64encode(''
    #!/bin/bash
    nixos-rebuild switch --flake github:user/Config#ec2-web
  '');
};

resource.aws_autoscaling_group.nixos = {
  launch_template = {
    id = "\${aws_launch_template.nixos.id}";
  };
  min_size = 2;
  max_size = 10;
};
```

---

## Monitoring & Logging (Planned)

### CloudWatch Integration

```nix
# EC2 with CloudWatch
services.amazon-cloudwatch-agent = {
  enable = true;
  config = {
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/syslog";
              log_group_name = "/aws/ec2/nixos";
            }
          ];
        };
      };
    };
  };
};
```

### Prometheus Monitoring

```nix
# Prometheus exporters
services.prometheus.exporters = {
  node.enable = true;
  systemd.enable = true;
};

# Open firewall for Prometheus
networking.firewall.allowedTCPPorts = [ 9100 9558 ];
```

---

## Roadmap

### Phase 1: Image Building
- [ ] nixos-generators integration
- [ ] AWS AMI builds
- [ ] GCP image builds
- [ ] Automated image uploads

### Phase 2: Basic Deployment
- [ ] EC2 deployment tested
- [ ] GCE deployment tested
- [ ] Cloud-init integration
- [ ] Remote rebuild

### Phase 3: Advanced Features
- [ ] Terranix integration
- [ ] Auto-scaling groups
- [ ] Load balancer support
- [ ] Monitoring/logging

### Phase 4: Production Ready
- [ ] High availability
- [ ] Disaster recovery
- [ ] Cost optimization
- [ ] Security hardening

---

## Best Practices (When Implemented)

### Security

```nix
# Hardened configuration
security.sudo.wheelNeedsPassword = true;
services.openssh.settings.PasswordAuthentication = false;
services.openssh.settings.PermitRootLogin = "no";

# Automatic updates
system.autoUpgrade = {
  enable = true;
  allowReboot = true;
  dates = "04:00";
};
```

### Cost Optimization

```nix
# Use spot instances where appropriate
# Implement auto-scaling based on metrics
# Schedule non-prod instances
```

---

## Next Steps

- **[Darwin Deployment](./darwin.md)** - macOS deployment (current)
- **[NixOS Deployment](./nixos.md)** - Linux deployment (planned)
- **[Design Doc](../../architecture/design.md)** - Architecture details

---

## Related Documentation

- [Structure Guide](../../architecture/structure.md) - Module system
- [Design Philosophy](../../architecture/design.md) - Cloud strategy

---

## External References

- [nixos-generators](https://github.com/nix-community/nixos-generators) - Image builder
- [Terranix](https://terranix.org/) - Terraform in Nix
- [NixOS on AWS](https://nixos.wiki/wiki/NixOS_on_AWS) - Wiki guide
- [NixOS on GCP](https://nixos.wiki/wiki/Google_Cloud_Platform) - Wiki guide

---

**Status:** 📋 Planned - [Contribute on GitHub](#)
