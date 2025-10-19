# 🛡️ AKS Security Guide

## Current Security Status: ✅ SIGNIFICANTLY IMPROVED

Your AKS cluster now has **enhanced security configurations** with proper access controls and network restrictions. This document outlines the current security posture and provides guidance for further hardening.

## ✅ Current Security Implementations

### 1. **API Server Access Control**
- ✅ Kubernetes API server access restricted to authorized IPs
- ✅ Current authorized IP ranges configured (see terraform.tfvars)
- ✅ Unauthorized access attempts are blocked at the network level

### 2. **Network Security**
- ✅ Azure CNI with network policies enabled
- ✅ Azure Policy integration enabled
- ✅ Custom Network Security Group rules implemented
- ✅ HTTPS traffic restricted to authorized IPs only
- ✅ Internal AKS communication properly configured
- ✅ Azure Load Balancer health probes allowed

### 3. **Key Management**
- ✅ Azure Key Vault deployed for secret management
- ✅ Key Vault access restricted to authorized IPs
- ✅ Proper access policies configured for AKS cluster identity

### 4. **Monitoring & Compliance**
- ✅ Log Analytics workspace enabled
- ✅ Container Insights monitoring active
- ✅ 30-day log retention configured

## 🚨 Remaining Security Considerations

### 1. **Public Load Balancer**
- ⚠️ Standard Load Balancer with public IP allows inbound traffic
- ⚠️ Services of type `LoadBalancer` will get public IPs by default
- **Recommendation**: Use internal load balancers or ingress controllers with proper TLS termination

### 2. **Cluster Access Model**
- ⚠️ Currently using public cluster with IP restrictions
- **Recommendation**: Consider private cluster for production workloads

## 🛡️ Security Hardening Options

### Option 1: Current Configuration (Enhanced Public Cluster) ✅ IMPLEMENTED

**Best for**: Development/testing environments that need external access

**Current Status**: ✅ **ACTIVE**
- API server access restricted to your current IP
- Network Security Group rules properly configured
- Key Vault access controls in place

**To update authorized IPs**:
```bash
# Find your current public IP
curl https://ipv4.icanhazip.com

# Update terraform.tfvars with new IPs
api_server_authorized_ip_ranges = [
  "YOUR_CURRENT_IP/32",     # Replace with your actual IP
  "203.0.113.0/32",         # Example: Additional IP
  "198.51.100.0/24",        # Example: Office network range
]

# Apply changes
cd tf
terraform plan
terraform apply
```

### Option 2: Maximum Security (Private Cluster)

**Best for**: Production environments

1. **Enable Private Cluster**:
   ```hcl
   # In terraform.tfvars
   enable_private_cluster = true
   api_server_authorized_ip_ranges = []  # Not needed for private clusters
   ```

2. **Set up VPN or ExpressRoute** for access to the private cluster

## 🔧 Current Configuration Details

### ⚠️ Security Notice
**Important**: This repository does not contain actual IP addresses for security reasons. You must configure your own IP addresses in `terraform.tfvars` before deploying. The file `terraform.tfvars` is excluded from version control to prevent accidental exposure of sensitive information.

### Implemented Security Features

Your cluster now includes the following security configurations:

**Network Security Group Rules**:
- `AllowHTTPSFromAuthorizedIPs` (Priority 1000): Allows HTTPS (443) from your IP
- `AllowAKSInternal` (Priority 1200): Allows internal AKS communication
- `AllowAzureLoadBalancer` (Priority 1300): Allows Azure Load Balancer health probes
- `DenyAllInbound` (Priority 4000): Denies all other inbound traffic

**API Server Access Profile**:
- Authorized IP ranges: Configured (check terraform.tfvars for current values)
- Virtual network integration: Disabled (public cluster)

**Key Vault Configuration**:
- Network ACLs: Default action is Deny
- Allowed IP ranges: Configured to match API server authorized IPs
- Soft delete enabled with 7-day retention

### Updating Your Configuration

**To add more authorized IPs**:
```bash
# Get your current IP first
YOUR_IP=$(curl -s https://ipv4.icanhazip.com)
echo "Your current IP: $YOUR_IP"

# Edit terraform.tfvars
api_server_authorized_ip_ranges = [
  "YOUR_CURRENT_IP/32",    # Replace with your actual IP
  "203.0.113.0/32",        # Example: Additional IP
  "198.51.100.0/24",       # Example: Office network range
]

# Apply changes
cd tf
terraform plan
terraform apply
```

**To verify current settings**:
```bash
# Check API server access restrictions
az aks show --resource-group demo-aks-rg --name demo-aks --query "apiServerAccessProfile"

# Check Network Security Group rules
az network nsg show --resource-group demo-aks-rg --name demo-aks-additional-nsg --query "securityRules[].{Name:name,Priority:priority,Access:access,Direction:direction}"

# Test cluster access (should work from your IP)
kubectl cluster-info
```

## 🔍 Additional Security Measures

### 1. **Enable Azure Defender for Kubernetes**
```bash
# Enable in Azure Security Center
az security pricing create --name KubernetesService --tier Standard
```

### 2. **Implement Pod Security Standards**
```yaml
# Create pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 3. **Network Policies Example**
```yaml
# Create network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### 4. **Use Azure Key Vault for Secrets**
```bash
# Install the CSI driver
kubectl apply -f https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/deployment/provider-azure-installer.yaml
```

## 🚦 Security Checklist

### ✅ Completed Actions (High Priority)
- [x] Restrict API server access with `api_server_authorized_ip_ranges`
- [x] Configure SSH access restrictions with `allowed_ssh_ip_ranges` (empty for security)
- [x] Enable additional Network Security Group rules
- [x] Set up Azure Key Vault for secret management
- [x] Enable Log Analytics and Container Insights monitoring

### 🔄 Next Actions (Medium Priority)
- [ ] Consider enabling private cluster for production workloads
- [ ] Implement Pod Security Standards
- [ ] Set up network policies for workload isolation
- [ ] Enable Azure Defender for Kubernetes
- [ ] Configure audit logging and alerting
- [ ] Implement internal load balancers for services
- [ ] Set up proper TLS certificates for ingress

### 📋 Long-term Actions (Lower Priority)
- [ ] Implement GitOps for secure deployments
- [ ] Set up image scanning in CI/CD pipeline
- [ ] Implement service mesh (Istio/Linkerd) for advanced security
- [ ] Regular security assessments and penetration testing
- [ ] Implement Azure Policy for governance
- [ ] Set up Azure Sentinel for security monitoring

## 🔗 Useful Commands

### Check Current Security Status
```bash
# View cluster configuration and API server access profile
az aks show --resource-group demo-aks-rg --name demo-aks --query "apiServerAccessProfile"

# Check Network Security Group rules
az network nsg show --resource-group demo-aks-rg --name demo-aks-additional-nsg --query "securityRules[].{Name:name,Priority:priority,Access:access,Direction:direction,SourceAddressPrefixes:sourceAddressPrefixes}"

# View Key Vault network access rules
az keyvault show --name demo-aks-kv-fgs99gv2 --resource-group demo-aks-rg --query "properties.networkAcls"

# Check cluster node resource group
az aks show --resource-group demo-aks-rg --name demo-aks --query "nodeResourceGroup"

# View current public IPs in the node resource group
az network public-ip list --resource-group MC_demo-aks-rg_demo-aks_westus --query "[].{Name:name,IP:ipAddress,AllocationMethod:publicIPAllocationMethod}"
```

### Test Security Configuration
```bash
# This should work from authorized IPs (your current IP)
kubectl cluster-info
kubectl get nodes

# Test Key Vault access (should work from your IP)
az keyvault secret list --vault-name demo-aks-kv-fgs99gv2

# Check if you can access from unauthorized IP
# (Test from different network/VPN - should fail)
```

### Monitor Security Events
```bash
# Check AKS logs in Log Analytics
az monitor log-analytics query \
  --workspace demo-workspace \
  --analytics-query "ContainerLog | where TimeGenerated > ago(1h) | limit 10"

# View cluster events
kubectl get events --sort-by='.lastTimestamp'
```

## 📚 Additional Resources

- [AKS Security Best Practices](https://docs.microsoft.com/en-us/azure/aks/security-baseline)
- [Azure Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Azure Key Vault Provider for Secrets Store CSI Driver](https://azure.github.io/secrets-store-csi-driver-provider-azure/)

## ⚠️ Important Security Notes

### Current Configuration Warnings
1. **IP Address Changes**: Your authorized IP ranges may change if you're using dynamic IPs. Update the configuration when your IP changes.
2. **Network Restrictions**: If you lose access, you can update the configuration from Azure Portal or Azure CLI from an authorized location.
3. **Key Vault Access**: The Key Vault is also restricted to the same IP ranges as the API server. Ensure you can access it when needed.

### Best Practices
1. **Regular IP Updates**: Monitor and update your authorized IP ranges as your network changes
2. **Multiple Access Points**: Consider adding office/VPN IP ranges for redundant access
3. **Emergency Access**: Keep Azure Portal access available for emergency configuration changes
4. **Monitor Logs**: Regularly check logs for unauthorized access attempts
5. **Backup Strategy**: Ensure you have alternative access methods before making changes

### Production Considerations
1. **Private Cluster**: For production workloads, consider migrating to a private cluster
2. **VPN/ExpressRoute**: Implement dedicated network connectivity for production access
3. **Service Mesh**: Consider implementing Istio or Linkerd for advanced traffic management
4. **Image Security**: Implement container image scanning and signing
5. **Compliance**: Ensure configuration meets your organization's compliance requirements

## 🔄 Maintenance Tasks

### Weekly
- [ ] Review and update authorized IP ranges if needed
- [ ] Check security logs for any anomalies
- [ ] Verify Key Vault access and secret rotation

### Monthly
- [ ] Review Network Security Group rules
- [ ] Update Kubernetes version if available
- [ ] Review and update Pod Security Standards
- [ ] Audit user access and permissions

### Quarterly
- [ ] Conduct security assessment
- [ ] Review and update security policies
- [ ] Test disaster recovery procedures
- [ ] Update security documentation
