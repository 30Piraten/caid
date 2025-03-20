# Week 1: 
## Terraform / CDK setup for cost awareness

- Deploy a basic EC2 + S3 + Lambda setup with terraform/cdk
- monitor cost impact using AWS cost explorer

### STEPS
Define overall structure
1. Define the use case: 
    - Low cost resource definition
    - Long term or short term? 
        - if long term, what resources are required? 
            * fallback to On-Deman from spot
            * right size instances
            * auto terminate idle instances
        - if short term, what resources are required?
            * spot instances?
2. Impact: (how else to measure beside aws cost explorer?)
3. Features:
    *EC2*
    - use spot instances for ec2
    - right size intances based on cpu
    - auto-terminate idle instances
    *S3*
    - apply intelligent tiering & lifecycle policy (auto move data to glacier)
    - enforce compression (gzip, zstd) to reduce storage costs
    - auto-enable S3 object locking & versioning (data integrity + cost optimization)
    - **impact:** this is for large scale (what about basic for S3?)
    *Lambda*
    - auto-adjusts memory allocation
    - uses provisioned concurrency only during peak hours
    - includes a finops tag policy for cost tracking 
    
