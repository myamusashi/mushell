package ipc

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// LogFilePath is where background shell output is forwarded.
const LogFilePath = "/tmp/vast-shell.log"

// LogFile opens the background log file for appending, creating it if
// needed. Returns nil if the file cannot be opened.
func LogFile() *os.File {
	f, err := os.OpenFile(LogFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil
	}
	return f
}

var ensureOnce sync.Once

func ensureShellDaemon() {
	ensureOnce.Do(func() {
		if ShellRunning() {
			return
		}
		bin, args := ShellBinArgs()
		cmd := exec.Command(bin, args...)
		if logFile := LogFile(); logFile != nil {
			defer func() { _ = logFile.Close() }()
			_, _ = fmt.Fprintf(logFile, "\n--- %s ---\n", time.Now().Format(time.RFC3339))
			cmd.Stdout = logFile
			cmd.Stderr = logFile
		}
		_ = cmd.Start()
		time.Sleep(500 * time.Millisecond)
	})
}

// ShellRunning reports whether a quickshell process is currently active.
func ShellRunning() bool {
	out, err := exec.Command("pgrep", "-f", "quickshell").Output()
	return err == nil && len(out) > 0
}

// ShellBinArgs returns the binary and arguments to launch the shell.
// An explicit VAST_SHELL_DIRECTORY takes precedence over the installed
// "shell" wrapper so IPC targets the instance launched from that exact
// config path (quickshell routes IPC per config path).
func ShellBinArgs() (string, []string) {
	if dir := shellDirectory(); dir != "" {
		return "quickshell", []string{"-p", dir + "/Qml"}
	}
	if _, err := exec.LookPath("shell"); err == nil {
		return "shell", nil
	}
	return "quickshell", nil
}

// shellDirectory returns the VAST_SHELL_DIRECTORY value with any session
// variables expanded and made absolute, or "" if unset.
func shellDirectory() string {
	dir := ExpandEnv(os.Getenv("VAST_SHELL_DIRECTORY"))
	if dir == "" {
		return ""
	}
	abs, err := filepath.Abs(dir)
	if err != nil {
		return dir
	}
	return abs
}

// ExpandEnv expands session variable references in s. The supported forms
// are $VAR, ${VAR}, and $env.VAR — all read from the process environment.
// Unknown variables expand to an empty string.
func ExpandEnv(s string) string {
	if !strings.ContainsRune(s, '$') {
		return s
	}
	isIdent := func(c byte) bool {
		return c == '_' || c >= '0' && c <= '9' || c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
	}
	var b strings.Builder
	for i := 0; i < len(s); {
		if s[i] != '$' {
			b.WriteByte(s[i])
			i++
			continue
		}
		if strings.HasPrefix(s[i:], "$env.") {
			start := i + len("$env.")
			j := start
			for j < len(s) && isIdent(s[j]) {
				j++
			}
			b.WriteString(os.Getenv(s[start:j]))
			i = j
			continue
		}
		if i+1 < len(s) && s[i+1] == '{' {
			end := strings.IndexByte(s[i+2:], '}')
			if end < 0 {
				b.WriteString(s[i:])
				break
			}
			b.WriteString(os.Getenv(s[i+2 : i+2+end]))
			i += 2 + end + 1
			continue
		}
		start := i + 1
		if start < len(s) && isIdent(s[start]) {
			j := start
			for j < len(s) && isIdent(s[j]) {
				j++
			}
			b.WriteString(os.Getenv(s[start:j]))
			i = j
			continue
		}
		b.WriteByte('$')
		i++
	}
	return b.String()
}

func shellIPCArgs() (string, []string) {
	bin, args := ShellBinArgs()
	return bin, append(args, "ipc", "call")
}

// Call invokes `shell ipc call <target> <method> [args...]` and returns
// the stdout output trimmed. Call only works for IPC targets that print
// results to stdout; void functions return empty string.
func Call(target string, method string, args ...string) (string, error) {
	ensureShellDaemon()

	bin, callArgs := shellIPCArgs()
	callArgs = append(callArgs, target, method)
	callArgs = append(callArgs, args...)

	cmd := exec.Command(bin, callArgs...)
	output, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			stderr := strings.TrimSpace(string(exitErr.Stderr))
			if stderr != "" {
				return "", fmt.Errorf("%s ipc call %s %s: %s", bin, target, method, stderr)
			}
		}
		return "", fmt.Errorf("%s ipc call %s %s: %w", bin, target, method, err)
	}
	return strings.TrimSpace(string(output)), nil
}
