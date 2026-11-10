package test

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testLambda(t *testing.T, variant string) {
	t.Parallel()

	ctx := context.Background()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
		Upgrade:      true,
	}

	defer terraform.DestroyContext(t, ctx, terraformOptions)

	// This is annoying, but necessary. Log Group isn't cleaned up correctly after destroy.
	logGroupName := fmt.Sprintf("/aws/lambda/example-tf-pbs-lambda-%s", variant)
	deleteLogGroup(t, logGroupName)

	terraform.InitContext(t, ctx, terraformOptions)

	if variant == "docker" {
		ecrTargetTerraformOptions := &terraform.Options{
			TerraformDir: terraformDir,
			LockTimeout:  "5m",
			Targets:      []string{"module.ecr"},
		}

		terraform.ApplyContext(t, ctx, ecrTargetTerraformOptions)

		ecrRepo := terraform.OutputContext(t, ctx, ecrTargetTerraformOptions, "ecr_repo_url")

		tag := fmt.Sprintf("%s:latest", ecrRepo)
		buildOptions := &docker.BuildOptions{
			Tags:          []string{tag},
			Architectures: []string{"linux/arm64"},
			OtherOptions: []string{
				"--provenance", "false",
			},
		}

		docker.BuildContext(t, ctx, "../examples/src-docker", buildOptions)

		// We can test the image locally before pushing it to ECR

		logger := logger.Terratest

		runOptions := &docker.RunOptions{
			Remove: true,
			Detach: true,
			Name:   variant,
			OtherOptions: []string{
				"-p", "8080:8080",
			},
		}

		docker.RunContext(t, ctx, tag, runOptions)
		defer docker.StopContext(t, ctx, []string{variant}, &docker.StopOptions{Time: 5, Logger: logger})

		body := retry.DoWithRetryContext(t, ctx, "Local lambda invocation via HTTP", 5, 5 * time.Second, func () (string, error) {
			payload := []byte(`{}`)
			req, err := http.NewRequest("POST", "http://127.0.0.1:8080/2015-03-31/functions/function/invocations", bytes.NewBuffer(payload))

			if err != nil {
				return "", err
			}

			req.Header.Set("Content-Type", "application/json")
			resp, err := http.DefaultClient.Do(req)
			if err != nil {
				return "", err
			}

			defer resp.Body.Close()
			if resp.StatusCode != 200 {
				return "", fmt.Errorf("Expected status code 200, got %d", resp.StatusCode)
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				return "", err
			}

			return string(body[:]), nil
		})

		assert.Equal(t, "\"Hello Ishmael!\"", string(body))

		docker.PushContext(t, ctx, logger, tag)
	}

	terraform.ApplyContext(t, ctx, terraformOptions)

	arn := terraform.OutputContext(t, ctx, terraformOptions, "arn")
	name := terraform.OutputContext(t, ctx, terraformOptions, "name")
	qualifiedARN := terraform.OutputContext(t, ctx, terraformOptions, "qualified_arn")

	region := getAWSRegion(t)
	accountID := getAWSAccountID(t)

	expectedName := fmt.Sprintf("example-tf-pbs-lambda-%s", variant)
	expectedARN := fmt.Sprintf("arn:aws:lambda:%s:%s:function:%s", region, accountID, expectedName)

	expectedResponse := "\"Hello Jane!\""
	if variant == "env" {
		expectedResponse = "\"Hello Sarah!\""
	}
	if variant == "ssm" {
		expectedResponse = "\"Hello John!\""
	}
	if variant == "app-config" {
		expectedResponse = "\"Hello Billy!\""
	}
	if variant == "docker" {
		expectedResponse = "\"Hello Ishmael!\""
	}

	assert.Equal(t, expectedARN, arn)
	assert.Equal(t, expectedName, name)
	assert.Contains(t, qualifiedARN, expectedARN)

	result, err := invokeLambda(t, name)
	if err != nil {
		assert.Equal(t, nil, err)
	}

	assert.Equal(t, expectedResponse, string(result.Payload))
}
