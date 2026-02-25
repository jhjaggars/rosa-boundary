package cmd

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	"github.com/openshift/rosa-boundary/internal/config"
)

var configureCmd = &cobra.Command{
	Use:   "configure",
	Short: "Interactively configure rosa-boundary",
	Long: `Prompt for required configuration values and write them to
~/.config/rosa-boundary/config.yaml (respects XDG_CONFIG_HOME).

Current values are shown in brackets. Press Enter to keep them.`,
	Args: cobra.NoArgs,
	RunE: runConfigure,
}

func init() {
	rootCmd.AddCommand(configureCmd)
}

func runConfigure(cmd *cobra.Command, args []string) error {
	// Load existing config so we can show current values as defaults
	cfg, _ := config.Get()
	if cfg == nil {
		cfg = &config.Config{}
	}

	scanner := bufio.NewScanner(os.Stdin)

	prompt := func(label, current, def string) string {
		display := current
		if display == "" {
			display = def
		}
		if display != "" {
			fmt.Fprintf(os.Stderr, "%s [%s]: ", label, display)
		} else {
			fmt.Fprintf(os.Stderr, "%s: ", label)
		}
		if !scanner.Scan() {
			return display
		}
		input := strings.TrimSpace(scanner.Text())
		if input == "" {
			return display
		}
		return input
	}

	keycloakURL := prompt("Keycloak URL (required)", cfg.KeycloakURL, "")
	keycloakRealm := prompt("Keycloak realm", cfg.KeycloakRealm, "sre-ops")
	oidcClientID := prompt("OIDC client ID", cfg.OIDCClientID, "aws-sre-access")
	lambdaFunctionName := prompt("Lambda function name (required)", cfg.LambdaFunctionName, "")
	invokerRoleARN := prompt("Invoker role ARN (required)", cfg.InvokerRoleARN, "")
	sreRoleARN := prompt("SRE role ARN", cfg.SRERoleARN, "")
	awsRegion := prompt("AWS region", cfg.AWSRegion, "us-east-2")
	clusterName := prompt("Cluster name", cfg.ClusterName, "rosa-boundary-dev")

	configDir, err := config.ConfigDir()
	if err != nil {
		return err
	}
	configPath := filepath.Join(configDir, "config.yaml")

	entries := [][2]string{
		{"keycloak_url", keycloakURL},
		{"keycloak_realm", keycloakRealm},
		{"oidc_client_id", oidcClientID},
		{"lambda_function_name", lambdaFunctionName},
		{"invoker_role_arn", invokerRoleARN},
		{"sre_role_arn", sreRoleARN},
		{"aws_region", awsRegion},
		{"cluster_name", clusterName},
	}

	if err := config.WriteConfigFile(configPath, entries); err != nil {
		return err
	}

	fmt.Fprintf(os.Stderr, "\nConfiguration saved to %s\n", configPath)
	return nil
}
