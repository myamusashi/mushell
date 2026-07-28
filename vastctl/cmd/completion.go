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
		sb.WriteString("# Completions for vastctl — auto-generated, do not edit.\n")
		sb.WriteString("module vastctl {\n")
		walkNushell(cmd.Root(), &sb)
		sb.WriteString("}\n\n")
		sb.WriteString("use vastctl *\n")
		_, err := io.WriteString(cmd.OutOrStdout(), sb.String())
		return err
	},
}

// nushellType maps cobra/pflag type names to Nushell types.
func nushellType(cobraType string) string {
	switch cobraType {
	case "bool":
		return ""
	case "int", "int8", "int16", "int32", "int64",
		"uint", "uint8", "uint16", "uint32", "uint64":
		return "int"
	case "float32", "float64":
		return "number"
	default:
		return "string"
	}
}

// parsePositionalArgs extracts positional argument tokens from a cobra Use
// string.  Required args look like <name>, optional like [name].
func parsePositionalArgs(use string) []struct {
	Name     string
	Optional bool
} {
	fields := strings.Fields(use)
	if len(fields) <= 1 {
		return nil
	}
	var out []struct {
		Name     string
		Optional bool
	}
	for _, f := range fields[1:] {
		if strings.HasPrefix(f, "<") && strings.HasSuffix(f, ">") {
			out = append(out, struct {
				Name     string
				Optional bool
			}{strings.Trim(f, "<>"), false})
		} else if strings.HasPrefix(f, "[") && strings.HasSuffix(f, "]") {
			out = append(out, struct {
				Name     string
				Optional bool
			}{strings.Trim(f, "[]"), true})
		}
	}
	return out
}

func walkNushell(cmd *cobra.Command, sb *strings.Builder) {
	// Comment with command description.
	if cmd.Short != "" {
		sb.WriteString("\n  # ")
		sb.WriteString(cmd.Short)
		sb.WriteByte('\n')
	}

	sb.WriteString("  export extern \"")
	sb.WriteString(cmd.CommandPath())
	sb.WriteString("\" [\n")

	// Positional arguments parsed from the Use string.
	for _, arg := range parsePositionalArgs(cmd.Use) {
		sb.WriteString("    ")
		sb.WriteString(arg.Name)
		if arg.Optional {
			sb.WriteString("?: string")
		} else {
			sb.WriteString(": string")
		}
		sb.WriteByte('\n')
	}

	// Collect flag names we've already written to avoid duplicates between
	// local and persistent flag sets.
	seen := make(map[string]bool)

	cmd.Flags().VisitAll(func(f *pflag.Flag) {
		if writeNushellFlag(sb, f) {
			seen[f.Name] = true
		}
	})
	cmd.PersistentFlags().VisitAll(func(f *pflag.Flag) {
		if seen[f.Name] {
			return
		}
		writeNushellFlag(sb, f)
	})

	// Always include --help.
	sb.WriteString("    --help(-h) # Display the help message for this command\n")

	sb.WriteString("  ]\n")

	for _, sub := range cmd.Commands() {
		if sub.Hidden || sub.Name() == "completion" || sub.Name() == "help" {
			continue
		}
		walkNushell(sub, sb)
	}
}

// writeNushellFlag writes a single flag line and returns true if it wrote
// anything.
func writeNushellFlag(sb *strings.Builder, f *pflag.Flag) bool {
	if f.Hidden || f.Name == "help" {
		return false
	}

	sb.WriteString("    ")

	long := "--" + f.Name
	if f.Shorthand != "" && f.Shorthand != f.Name {
		fmt.Fprintf(sb, "%s(-%s)", long, f.Shorthand)
	} else {
		sb.WriteString(long)
	}

	if nuType := nushellType(f.Value.Type()); nuType != "" {
		sb.WriteString(": ")
		sb.WriteString(nuType)
	}

	if f.Usage != "" {
		sb.WriteString(" # ")
		sb.WriteString(f.Usage)
	}

	sb.WriteByte('\n')
	return true
}

func init() {
	rootCmd.AddCommand(completionCmd)
	completionCmd.AddCommand(completionBashCmd)
	completionCmd.AddCommand(completionFishCmd)
	completionCmd.AddCommand(completionZshCmd)
	completionCmd.AddCommand(completionNushellCmd)
}
