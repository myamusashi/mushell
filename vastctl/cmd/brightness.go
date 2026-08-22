package cmd

import (
	"strconv"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var brightnessCmd = &cobra.Command{
	Use:   "brightness",
	Short: "Control monitor brightness",
	Long:  "Get and set per-display brightness via vast-shell's BrightnessManager.",
}

var brightnessGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get current brightness for all displays",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("brightness", "get")
	},
}

var brightnessSetCmd = &cobra.Command{
	Use:   "set [+|-]<percent>[%]",
	Short: "Set brightness for all displays, or adjust it relatively",
	Long:  "Set brightness for all displays to an absolute value (e.g. 50%), or adjust all displays relatively with +10% / -10%. Prefix negative values with -- (e.g. -- -5%).",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		pct, err := parsePercent(args[0])
		if err != nil {
			return err
		}
		if pct.relative {
			_, err = ipc.Call("brightness", "change", strconv.Itoa(pct.value))
			return err
		}
		_, err = ipc.Call("brightness", "set", strconv.Itoa(pct.value))
		return err
	},
}

func init() {
	rootCmd.AddCommand(brightnessCmd)
	brightnessCmd.AddCommand(brightnessGetCmd)
	brightnessCmd.AddCommand(brightnessSetCmd)
}
