package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rawJSON bool

var rootCmd = &cobra.Command{
	Use:   "vastctl",
	Short: "CLI control surface for vast-shell",
	Long:  "vastctl is a scriptable CLI companion for the vast-shell Hyprland desktop shell.",
	CompletionOptions: cobra.CompletionOptions{
		DisableDefaultCmd: true,
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().BoolVar(&rawJSON, "json", false, "Output raw JSON instead of tree format")
}
