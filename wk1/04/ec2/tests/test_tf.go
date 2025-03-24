package tests

/*
Defining test cases for infrastructure config on Terraform with Terratest.
*/

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEC2Instance(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../config",
		Upgrade:      true,
	})

	defer terraform.Destroy(t, terraformOptions)

	// terraform.InitAndApplyE(t, terraformOptions)
	terraform.InitE(t, terraformOptions)
	terraform.ApplyAndIdempotentE(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	assert.NotEmpty(t, instanceID, "Expects an EC2 instance ID")

	instancePublicIP := terraform.Output(t, terraformOptions, "instance_public_ip")
	assert.NotEmpty(t, instancePublicIP, "Expects an EC2 instance IP")
}
