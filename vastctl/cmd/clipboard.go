package cmd

import (
	"github.com/spf13/cobra"
)

var clipboardCmd = &cobra.Command{
	Use:   "clipboard",
	Short: "Manage the clipboard history",
	Long:  "List, copy, pin, remove, or clear entries in the vast-shell clipboard history.",
}

var clipboardListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all clipboard history entries",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("clipboardHistory", "list")
	},
}

var clipboardStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show clipboard manager status",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("clipboardHistory", "status")
	},
}

var clipboardRemoveCmd = &cobra.Command{
	Use:   "remove <entry-id>",
	Short: "Remove a history entry",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("clipboardHistory", "remove", args[0])
	},
}

var clipboardClearCmd = &cobra.Command{
	Use:   "clear",
	Short: "Clear the entire clipboard history",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("clipboardHistory", "clear")
	},
}

var clipboardSearchCmd = &cobra.Command{
	Use:   "search <query>",
	Short: "Search clipboard history",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("clipboardHistory", "search", args[0])
	},
}

func init() {
	rootCmd.AddCommand(clipboardCmd)
	clipboardCmd.AddCommand(clipboardListCmd)
	clipboardCmd.AddCommand(clipboardStatusCmd)
	clipboardCmd.AddCommand(clipboardRemoveCmd)
	clipboardCmd.AddCommand(clipboardClearCmd)
	clipboardCmd.AddCommand(clipboardSearchCmd)
}
