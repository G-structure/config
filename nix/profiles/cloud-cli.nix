# Cloud CLI tools profile
# AWS, GCP, Kubernetes, Terraform, etc.
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    # AWS tools
    awscli2

    # Infrastructure as Code
    terraform

    # Kubernetes tools
    kubectl

    # Container tools
    skopeo
    dive
  ];
}
