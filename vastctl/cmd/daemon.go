package cmd

import (
	"fmt"
	"io"
	"os/exec"
	"strings"
	"syscall"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var daemonVerbose bool
var daemonForeground bool

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Manage the vast-shell background process",
	Long:  "Start, stop, restart, or check the status of the vast-shell quickshell daemon.",
}

var daemonStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Launch vast-shell in the background",
	RunE: func(cmd *cobra.Command, args []string) error {
		if ipc.ShellRunning() {
			cmd.Println("vast-shell is already running")
			return nil
		}
		return startDaemon(cmd)
	},
}

var daemonStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		pids := shellPIDs()
		if len(pids) == 0 {
			cmd.Println("vast-shell is not running")
			return nil
		}
		killAll(pids)
		cmd.Printf("vast-shell stopped (%d process%s)\n", len(pids), plural(len(pids)))
		return nil
	},
}

var daemonRestartCmd = &cobra.Command{
	Use:   "restart",
	Short: "Restart the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		if pids := shellPIDs(); len(pids) > 0 {
			killAll(pids)
		}
		return startDaemon(cmd)
	},
}

var daemonStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if vast-shell is running",
	RunE: func(cmd *cobra.Command, args []string) error {
		pids := shellPIDs()
		if len(pids) == 0 {
			cmd.Println("vast-shell is not running")
			return nil
		}
		cmd.Printf("vast-shell is running (pid%s %s)\n", plural(len(pids)), strings.Join(pids, ", "))
		return nil
	},
}

func startDaemon(cmd *cobra.Command) error {
	bin, args := ipc.ShellBinArgs()
	proc := exec.Command(bin, args...)
	if daemonForeground {
		proc.Stdout = cmd.OutOrStdout()
		proc.Stderr = cmd.ErrOrStderr()
		// Forward signals so systemd can manage the process.
		proc.SysProcAttr = &syscall.SysProcAttr{Setpgid: false}
		if err := proc.Run(); err != nil {
			return err
		}
		return nil
	}
	// Background starts have no terminal; forward output to /tmp so
	// logs survive after the launching shell exits.
	logFile := ipc.LogFile()
	if logFile != nil {
		defer func() { _ = logFile.Close() }()
		_, _ = fmt.Fprintf(logFile, "\n--- %s ---\n", time.Now().Format(time.RFC3339))
		proc.Stdout = logFile
		proc.Stderr = logFile
	}
	if daemonVerbose {
		proc.Stdout = cmd.OutOrStdout()
		proc.Stderr = cmd.ErrOrStderr()
		if logFile != nil {
			proc.Stdout = io.MultiWriter(proc.Stdout, logFile)
			proc.Stderr = io.MultiWriter(proc.Stderr, logFile)
		}
	}
	if err := proc.Start(); err != nil {
		return err
	}
	cmd.Printf("vast-shell started (pid %d)\n", proc.Process.Pid)
	if logFile != nil {
		cmd.Printf("logs: %s\n", ipc.LogFilePath)
	}
	return nil
}

func shellPIDs() []string {
	out, err := exec.Command("pgrep", "-f", "quickshell").Output()
	if err != nil || len(out) == 0 {
		return nil
	}
	return strings.Fields(string(out))
}

func killAll(pids []string) {
	for _, pid := range pids {
		_ = exec.Command("kill", pid).Run()
	}
}

func plural(n int) string {
	if n > 1 {
		return "es"
	}
	return ""
}

func init() {
	daemonCmd.PersistentFlags().BoolVarP(&daemonVerbose, "verbose", "v", false, "Show quickshell output")
	daemonCmd.PersistentFlags().BoolVarP(&daemonForeground, "foreground", "f", false, "Run in foreground (blocking, for systemd)")
	rootCmd.AddCommand(daemonCmd)
	daemonCmd.AddCommand(daemonStartCmd)
	daemonCmd.AddCommand(daemonStopCmd)
	daemonCmd.AddCommand(daemonRestartCmd)
	daemonCmd.AddCommand(daemonStatusCmd)
}
