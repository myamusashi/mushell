package cmd

import (
	"github.com/spf13/cobra"
)

var mprisCmd = &cobra.Command{
	Use:   "mpris",
	Short: "Control MPRIS media players",
	Long:  "Play, pause, skip tracks, and list active media players via Quickshell.Services.Mpris.",
}

var mprisPlayPauseCmd = &cobra.Command{
	Use:   "play-pause",
	Short: "Toggle play/pause on the active player",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("mpris", "playPause")
	},
}

var mprisNextCmd = &cobra.Command{
	Use:   "next",
	Short: "Skip to the next track",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("mpris", "next")
	},
}

var mprisPreviousCmd = &cobra.Command{
	Use:   "previous",
	Short: "Skip to the previous track",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("mpris", "previous")
	},
}

var mprisStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the active player",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("mpris", "stop")
	},
}

var mprisListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all active media players",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("mpris", "list")
	},
}

func init() {
	rootCmd.AddCommand(mprisCmd)
	mprisCmd.AddCommand(mprisPlayPauseCmd)
	mprisCmd.AddCommand(mprisNextCmd)
	mprisCmd.AddCommand(mprisPreviousCmd)
	mprisCmd.AddCommand(mprisStopCmd)
	mprisCmd.AddCommand(mprisListCmd)
}
