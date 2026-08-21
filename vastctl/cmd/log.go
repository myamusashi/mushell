package cmd

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"syscall"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var logLines int
var logNoFollow bool

const logTailScanLimit = 64 << 10

var logCmd = &cobra.Command{
	Use:   "log",
	Short: "Watch vast-shell daemon logs",
	Long:  "Show recent vast-shell output from " + ipc.LogFilePath + " and stream new lines as they arrive.",
	RunE: func(cmd *cobra.Command, args []string) error {
		return runLog(cmd)
	},
}

func runLog(cmd *cobra.Command) error {
	file, err := os.Open(ipc.LogFilePath)
	if os.IsNotExist(err) {
		if logNoFollow {
			cmd.Printf("no log file at %s\n", ipc.LogFilePath)
			return nil
		}
		cmd.Printf("waiting for %s ...\n", ipc.LogFilePath)
		file = waitForLogFile()
	} else if err != nil {
		return err
	}

	offset, err := printRecentLines(cmd, file, logLines)
	if err != nil {
		_ = file.Close()
		return err
	}
	if logNoFollow {
		_ = file.Close()
		return nil
	}
	// followLog takes ownership of file and any replacements it opens.
	return followLog(cmd, file, offset)
}

func waitForLogFile() *os.File {
	for {
		time.Sleep(200 * time.Millisecond)
		if file, err := os.Open(ipc.LogFilePath); err == nil {
			return file
		}
	}
}

// printRecentLines prints up to n lines from the end of the log and
// returns the offset to resume streaming from.
func printRecentLines(cmd *cobra.Command, file *os.File, n int) (int64, error) {
	info, err := file.Stat()
	if err != nil {
		return 0, err
	}
	size := info.Size()
	start := size - logTailScanLimit
	partialFirstLine := start > 0
	if start < 0 {
		start = 0
	}
	if n < 0 {
		n = 0
	}
	buf := make([]byte, size-start)
	if _, err := file.ReadAt(buf, start); err != nil && !errors.Is(err, io.EOF) {
		return 0, err
	}
	content := strings.TrimSuffix(string(buf), "\n")
	if content != "" {
		lines := strings.Split(content, "\n")
		if partialFirstLine {
			lines = lines[1:]
		}
		if len(lines) > n {
			lines = lines[len(lines)-n:]
		}
		for _, line := range lines {
			if _, err := fmt.Fprintln(cmd.OutOrStdout(), line); err != nil {
				return 0, err
			}
		}
	}
	if _, err := file.Seek(size, io.SeekStart); err != nil {
		return 0, err
	}
	return size, nil
}

func followLog(cmd *cobra.Command, file *os.File, offset int64) (err error) {
	defer func() {
		if cerr := file.Close(); err == nil {
			err = cerr
		}
	}()
	out := cmd.OutOrStdout()
	buf := make([]byte, 4096)
	info, err := file.Stat()
	if err != nil {
		return err
	}
	inode := inodeOf(info)
	for {
		n, readErr := file.Read(buf)
		if n > 0 {
			offset += int64(n)
			if _, err := out.Write(buf[:n]); err != nil {
				return err
			}
		}
		switch {
		case readErr == nil:
			continue
		case errors.Is(readErr, io.EOF):
		default:
			return readErr
		}
		info, statErr := os.Stat(ipc.LogFilePath)
		switch {
		case statErr == nil && inodeOf(info) != inode:
			// The log was replaced (rotation); follow the new file.
			fresh, openErr := os.Open(ipc.LogFilePath)
			if openErr != nil {
				break
			}
			_ = file.Close()
			file = fresh
			inode = inodeOf(info)
			offset = 0
		case statErr == nil && info.Size() < offset:
			// Same file was truncated in place.
			if _, err := file.Seek(0, io.SeekStart); err != nil {
				return err
			}
			offset = 0
		}
		time.Sleep(200 * time.Millisecond)
	}
}

func inodeOf(info os.FileInfo) uint64 {
	return info.Sys().(*syscall.Stat_t).Ino
}

func init() {
	logCmd.Flags().IntVarP(&logLines, "lines", "n", 20, "Number of recent lines to show before following")
	logCmd.Flags().BoolVar(&logNoFollow, "no-follow", false, "Print recent lines and exit")
	rootCmd.AddCommand(logCmd)
}
