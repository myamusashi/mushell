package cmd

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/myamusashi/vast-shell/vastctl/internal/pretty"
	"github.com/spf13/cobra"
)

func ipcCallPrint(target, method string, args ...string) error {
	output, err := ipc.Call(target, method, args...)
	if err != nil {
		return err
	}
	if !rawJSON {
		if tree, treeErr := pretty.Tree(output); treeErr == nil {
			output = tree
		}
	}
	fmt.Println(output)
	return nil
}

func ipcCallVoid(target, method string, args ...string) error {
	_, err := ipc.Call(target, method, args...)
	return err
}

type percentArg struct {
	value    int
	relative bool
}

func parsePercent(s string) (percentArg, error) {
	invalid := fmt.Errorf("invalid percent: %s", s)
	body := strings.TrimSuffix(s, "%")
	if body == "" {
		return percentArg{}, invalid
	}
	sign := 0
	switch body[0] {
	case '+':
		sign = 1
		body = body[1:]
	case '-':
		sign = -1
		body = body[1:]
	}
	if body == "" {
		return percentArg{}, invalid
	}
	v, err := strconv.Atoi(body)
	if err != nil || v < 0 || v > 100 {
		return percentArg{}, fmt.Errorf("invalid percent: %s (must be 0-100)", s)
	}
	if sign == 0 {
		return percentArg{value: v}, nil
	}
	return percentArg{value: sign * v, relative: true}, nil
}

// percentSetCmd configures a command whose first positional argument is
// a percent, so leading '-' values are not parsed as flags.
func percentSetCmd(use, short, long string, run func(cmd *cobra.Command, pct percentArg) error) *cobra.Command {
	return &cobra.Command{
		Use:                use,
		Short:              short,
		Long:               long,
		DisableFlagParsing: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			args, handled, err := rawPositional(cmd, args)
			if err != nil || handled {
				return err
			}
			pct, err := parsePercent(args[0])
			if err != nil {
				return err
			}
			return run(cmd, pct)
		},
	}
}

// rawPositional strips help and global flags from the raw args of a
// DisableFlagParsing command and validates the positional count.
func rawPositional(cmd *cobra.Command, args []string) ([]string, bool, error) {
	positional := make([]string, 0, 1)
	for _, arg := range args {
		switch arg {
		case "-h", "--help":
			_ = cmd.Help()
			return nil, true, nil
		case "--json", "--":
		default:
			positional = append(positional, arg)
		}
	}
	if len(positional) != 1 {
		return nil, false, fmt.Errorf("accepts 1 arg, received %d", len(positional))
	}
	return positional, false, nil
}

func actionOrDefault(args []string, defaultAction string) string {
	if len(args) > 0 {
		return args[0]
	}
	return defaultAction
}
