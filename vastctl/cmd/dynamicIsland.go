package cmd

import (
	"github.com/myamusashi/vast-shell/vastctl/internal/hypr"
	"github.com/spf13/cobra"
)

var dynamicIslandCmd = &cobra.Command{
	Use:   "dynamicIsland",
	Short: "Control the Dynamic Island",
	Long:  "Arm, disarm, toggle, or check the status of the Dynamic Island file-sharing drop target via its IPC handler or Hyprland global shortcut.",
}

var dynamicIslandStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Arm the Dynamic Island",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dynamicIsland", "start")
	},
}

var dynamicIslandStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Disarm the Dynamic Island",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dynamicIsland", "stop")
	},
}

var dynamicIslandToggleCmd = &cobra.Command{
	Use:   "toggle",
	Short: "Toggle the Dynamic Island on/off",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dynamicIsland", "toggle")
	},
}

var dynamicIslandStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if the Dynamic Island is armed",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("dynamicIsland", "status")
	},
}

var dynamicIslandShortcutCmd = &cobra.Command{
	Use:   "shortcut",
	Short: "Dispatch the Dynamic Island global shortcut",
	RunE: func(cmd *cobra.Command, args []string) error {
		return hypr.Dispatch("dynamicIsland")
	},
}

func init() {
	rootCmd.AddCommand(dynamicIslandCmd)
	dynamicIslandCmd.AddCommand(dynamicIslandStartCmd)
	dynamicIslandCmd.AddCommand(dynamicIslandStopCmd)
	dynamicIslandCmd.AddCommand(dynamicIslandToggleCmd)
	dynamicIslandCmd.AddCommand(dynamicIslandStatusCmd)
	dynamicIslandCmd.AddCommand(dynamicIslandShortcutCmd)
}
