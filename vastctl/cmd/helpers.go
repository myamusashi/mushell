package cmd

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/myamusashi/vast-shell/vastctl/internal/pretty"
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

func actionOrDefault(args []string, defaultAction string) string {
	if len(args) > 0 {
		return args[0]
	}
	return defaultAction
}
