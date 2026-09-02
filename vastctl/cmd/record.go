package cmd

import (
	"github.com/spf13/cobra"
)

var recordCmd = &cobra.Command{
	Use:     "captureScreenVideo",
	Aliases: []string{"record"},
	Short:   "Control screen recording",
	Long:    "Start, stop, or check the status of screen recording via vast-shell (captureScreenVideo).",
}

var recordStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start recording the active screen",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("captureScreenVideo", "start")
	},
}

var recordStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the active recording",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("captureScreenVideo", "stop")
	},
}

var recordToggleCmd = &cobra.Command{
	Use:   "toggle",
	Short: "Toggle recording on/off",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("captureScreenVideo", "toggle")
	},
}

var recordStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if recording is active",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("captureScreenVideo", "status")
	},
}

func init() {
	rootCmd.AddCommand(recordCmd)
	recordCmd.AddCommand(recordStartCmd)
	recordCmd.AddCommand(recordStopCmd)
	recordCmd.AddCommand(recordToggleCmd)
	recordCmd.AddCommand(recordStatusCmd)
}
