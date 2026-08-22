package cmd

import (
	"strconv"

	"github.com/spf13/cobra"
)

var volumeCmd = &cobra.Command{
	Use:   "volume",
	Short: "Control system and per-app volume",
	Long:  "Get/set system volume, mute, and manage per-application audio streams via PipeWire.",
}

var volumeSystemCmd = &cobra.Command{
	Use:   "system",
	Short: "Manage system volume",
}

var volumeSystemGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get system volume and mute state",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("volume", "systemGet")
	},
}

var volumeSystemSetCmd = &cobra.Command{
	Use:   "set [+|-]<percent>[%]",
	Short: "Set system volume (0-100), or adjust it relatively",
	Long:  "Set system volume to an absolute value (e.g. 50%), or adjust it relatively with +10% / -10%. Prefix negative values with -- (e.g. -- -5%).",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		pct, err := parsePercent(args[0])
		if err != nil {
			return err
		}
		if pct.relative {
			return ipcCallVoid("volume", "systemChange", strconv.Itoa(pct.value))
		}
		return ipcCallVoid("volume", "systemSet", strconv.Itoa(pct.value))
	},
}

var volumeSystemMuteCmd = &cobra.Command{
	Use:   "mute",
	Short: "Mute system audio",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "systemMute")
	},
}

var volumeSystemUnmuteCmd = &cobra.Command{
	Use:   "unmute",
	Short: "Unmute system audio",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "systemUnmute")
	},
}

var volumeSystemToggleCmd = &cobra.Command{
	Use:   "toggle-mute",
	Short: "Toggle system mute",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "systemToggleMute")
	},
}

var volumeAppCmd = &cobra.Command{
	Use:   "app",
	Short: "Manage per-app audio volume",
}

var volumeAppListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all audio streams with their volumes",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("volume", "appList")
	},
}

var volumeAppSetCmd = &cobra.Command{
	Use:   "set <node-id> [+|-]<percent>[%]",
	Short: "Set volume for an app by PipeWire node ID, or adjust it relatively",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		pct, err := parsePercent(args[1])
		if err != nil {
			return err
		}
		if pct.relative {
			return ipcCallVoid("volume", "appChange", args[0], strconv.Itoa(pct.value))
		}
		return ipcCallVoid("volume", "appSet", args[0], strconv.Itoa(pct.value))
	},
}

var volumeAppMuteCmd = &cobra.Command{
	Use:   "mute <node-id>",
	Short: "Mute an app by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "appMute", args[0])
	},
}

var volumeAppUnmuteCmd = &cobra.Command{
	Use:   "unmute <node-id>",
	Short: "Unmute an app by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "appUnmute", args[0])
	},
}

var volumeAppToggleCmd = &cobra.Command{
	Use:   "toggle-mute <node-id>",
	Short: "Toggle app mute by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("volume", "appToggleMute", args[0])
	},
}

func init() {
	rootCmd.AddCommand(volumeCmd)

	volumeCmd.AddCommand(volumeSystemCmd)
	volumeSystemCmd.AddCommand(volumeSystemGetCmd)
	volumeSystemCmd.AddCommand(volumeSystemSetCmd)
	volumeSystemCmd.AddCommand(volumeSystemMuteCmd)
	volumeSystemCmd.AddCommand(volumeSystemUnmuteCmd)
	volumeSystemCmd.AddCommand(volumeSystemToggleCmd)

	volumeCmd.AddCommand(volumeAppCmd)
	volumeAppCmd.AddCommand(volumeAppListCmd)
	volumeAppCmd.AddCommand(volumeAppSetCmd)
	volumeAppCmd.AddCommand(volumeAppMuteCmd)
	volumeAppCmd.AddCommand(volumeAppUnmuteCmd)
	volumeAppCmd.AddCommand(volumeAppToggleCmd)
}
