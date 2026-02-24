package cmd

import (
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/spf13/cobra"

	awsclient "github.com/openshift/rosa-boundary/internal/aws"
	"github.com/openshift/rosa-boundary/internal/output"
)

var listTasksCmd = &cobra.Command{
	Use:   "list-tasks",
	Short: "List ECS tasks in the cluster",
	Long: `List running (or stopped) ECS tasks in the configured cluster,
including tag metadata such as cluster_id, investigation_id, and username.`,
	RunE: runListTasks,
}

var (
	listStatus       string
	listOutputFormat string
)

func init() {
	listTasksCmd.Flags().StringVar(&listStatus, "status", "RUNNING", "Task status filter: RUNNING, STOPPED, or all")
	listTasksCmd.Flags().StringVar(&listOutputFormat, "output", "text", "Output format: text or json")
	rootCmd.AddCommand(listTasksCmd)
}

func runListTasks(cmd *cobra.Command, args []string) error {
	cfg, err := getConfig(false, false)
	if err != nil {
		return err
	}

	awsCfg, err := config.LoadDefaultConfig(cmd.Context(), config.WithRegion(cfg.AWSRegion))
	if err != nil {
		return fmt.Errorf("cannot load AWS credentials: %w", err)
	}

	clusterName := cfg.ClusterName
	ecsClient := awsclient.NewECSClient(cfg.AWSRegion, clusterName, awsCfg.Credentials)

	desiredStatus := strings.ToUpper(listStatus)
	if desiredStatus == "ALL" {
		desiredStatus = ""
	}

	debugf("Listing tasks in cluster %s with status %q", clusterName, desiredStatus)

	tasks, err := ecsClient.ListRunningTasks(cmd.Context(), desiredStatus)
	if err != nil {
		return fmt.Errorf("cannot list tasks: %w", err)
	}

	if listOutputFormat == "json" {
		return output.JSON(tasks)
	}

	tbl := output.NewTable("TASK ID", "STATUS", "CLUSTER", "INVESTIGATION", "USERNAME", "STARTED")
	tbl.PrintHeader()

	for _, t := range tasks {
		startedAt := ""
		if t.StartedAt != nil {
			startedAt = t.StartedAt.Format("2006-01-02 15:04")
		}
		tbl.PrintRow(
			t.TaskID,
			t.Status,
			t.Tags["cluster_id"],
			t.Tags["investigation_id"],
			t.Tags["username"],
			startedAt,
		)
	}
	tbl.Flush()

	if len(tasks) == 0 {
		output.Status("No tasks found")
	}

	return nil
}
