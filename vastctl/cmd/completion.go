package cmd

import (
	"fmt"
	"io"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

var completionCmd = &cobra.Command{
	Use:   "completion",
	Short: "Generate the autocompletion script for the specified shell",
}

var completionBashCmd = &cobra.Command{
	Use:   "bash",
	Short: "Generate the autocompletion script for bash",
	RunE: func(cmd *cobra.Command, args []string) error {
		return cmd.Root().GenBashCompletionV2(cmd.OutOrStdout(), true)
	},
}

var completionFishCmd = &cobra.Command{
	Use:   "fish",
	Short: "Generate the autocompletion script for fish",
	RunE: func(cmd *cobra.Command, args []string) error {
		return cmd.Root().GenFishCompletion(cmd.OutOrStdout(), true)
	},
}

var completionZshCmd = &cobra.Command{
	Use:   "zsh",
	Short: "Generate the autocompletion script for zsh",
	RunE: func(cmd *cobra.Command, args []string) error {
		return cmd.Root().GenZshCompletion(cmd.OutOrStdout())
	},
}

var completionNushellCmd = &cobra.Command{
	Use:   "nushell",
	Short: "Generate the autocompletion script for nushell",
	RunE: func(cmd *cobra.Command, args []string) error {
		var sb strings.Builder
		walkNushell(cmd.Root(), &sb, 0)
		_, err := io.WriteString(cmd.OutOrStdout(), sb.String())
		return err
	},
}

func walkNushell(cmd *cobra.Command, sb *strings.Builder, depth int) {
	if depth == 0 {
		sb.WriteString("export extern \"")
	} else {
		sb.WriteString("\nexport extern \"")
	}
	sb.WriteString(cmd.CommandPath())
	sb.WriteString("\" [\n")

	cmd.Flags().VisitAll(func(f *pflag.Flag) {
		writeNushellFlag(sb, f)
	})
	cmd.PersistentFlags().VisitAll(func(f *pflag.Flag) {
		if cmd.Flags().Lookup(f.Name) != nil {
			return
		}
		writeNushellFlag(sb, f)
	})

	sb.WriteString("]\n")

	for _, sub := range cmd.Commands() {
		if sub.Hidden || sub.Name() == "completion" || sub.Name() == "help" {
			continue
		}
		walkNushell(sub, sb, depth+1)
	}
}

func writeNushellFlag(sb *strings.Builder, f *pflag.Flag) {
	if f.Hidden {
		return
	}
	name := "--" + f.Name
	if f.Shorthand != "" && f.Shorthand != f.Name {
		fmt.Fprintf(sb, "    (-%s|%s)", f.Shorthand, name)
	} else {
		sb.WriteString("    ")
		sb.WriteString(name)
	}

	if f.Value.Type() != "bool" {
		sb.WriteString(": string")
	}

	if f.Usage != "" {
		sb.WriteString(" // ")
		sb.WriteString(f.Usage)
	}

	sb.WriteByte('\n')
}

func init() {
	rootCmd.AddCommand(completionCmd)
	completionCmd.AddCommand(completionBashCmd)
	completionCmd.AddCommand(completionFishCmd)
	completionCmd.AddCommand(completionZshCmd)
	completionCmd.AddCommand(completionNushellCmd)
}
