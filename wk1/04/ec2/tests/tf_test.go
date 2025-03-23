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
		TerraformDir: "../config/instance.tf",
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	instanceId := terraform.Output(t, terraformOptions, "ec2_instance_id")
	assert.Equal(t, "ec2_instance_id", instanceId)
}
