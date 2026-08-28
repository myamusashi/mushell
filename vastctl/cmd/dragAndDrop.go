package cmd

import (
	"github.com/myamusashi/vast-shell/vastctl/internal/hypr"
	"github.com/spf13/cobra"
)

var dragAndDropCmd = &cobra.Command{
	Use:   "dragAndDrop",
	Short: "Control the Drag and Drop",
	Long:  "Arm, disarm, toggle, or check the status of the Drag and Drop file-sharing drop target via its IPC handler or Hyprland global shortcut.",
}

var dragAndDropStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Arm the Drag and Drop",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dragAndDrop", "start")
	},
}

var dragAndDropStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Disarm the Drag and Drop",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dragAndDrop", "stop")
	},
}

var dragAndDropToggleCmd = &cobra.Command{
	Use:   "toggle",
	Short: "Toggle the Drag and Drop on/off",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("dragAndDrop", "toggle")
	},
}

var dragAndDropStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if the Drag and Drop is armed",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("dragAndDrop", "status")
	},
}

var dragAndDropShortcutCmd = &cobra.Command{
	Use:   "shortcut",
	Short: "Dispatch the Drag and Drop global shortcut",
	RunE: func(cmd *cobra.Command, args []string) error {
		return hypr.Dispatch("dragAndDrop")
	},
}

func init() {
	rootCmd.AddCommand(dragAndDropCmd)
	dragAndDropCmd.AddCommand(dragAndDropStartCmd)
	dragAndDropCmd.AddCommand(dragAndDropStopCmd)
	dragAndDropCmd.AddCommand(dragAndDropToggleCmd)
	dragAndDropCmd.AddCommand(dragAndDropStatusCmd)
	dragAndDropCmd.AddCommand(dragAndDropShortcutCmd)
}
