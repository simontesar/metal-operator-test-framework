//go:build linux

package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"golang.org/x/sys/unix"
)

// https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
const (
	evKey    = 0x01 // EV_KEY
	keyPower = 116  // KEY_POWER
)

// watchACPIPowerButton waits for the power button to be pressed and shuts
// down the machine when it is.
func watchACPIPowerButton() {
	dev, err := findPowerButtonEvdev(10 * time.Second)
	if err != nil {
		slog.Error("acpi: power button input device not found, graceful power-off will hang", "error", err)
		return
	}

	f, err := os.Open(dev)
	if err != nil {
		slog.Error("acpi: opening power button device", "device", dev, "error", err)
		return
	}
	defer func() { _ = f.Close() }()

	slog.Info("acpi: watching for power button events", "device", dev)

	buf := make([]byte, 24)
	for {
		if _, err := io.ReadFull(f, buf); err != nil {
			slog.Error("acpi: reading power button device", "error", err)
			return
		}

		typ := binary.LittleEndian.Uint16(buf[16:18])
		code := binary.LittleEndian.Uint16(buf[18:20])
		value := binary.LittleEndian.Uint32(buf[20:24])
		if typ != evKey || code != keyPower || value != 1 {
			continue
		}

		slog.Info("acpi: power button pressed, powering off")
		if err := unix.Reboot(unix.LINUX_REBOOT_CMD_POWER_OFF); err != nil {
			slog.Error("acpi: reboot syscall failed", "error", err)
		}
	}
}

// findPowerButtonEvdev retries until the power button device appears
func findPowerButtonEvdev(timeout time.Duration) (string, error) {
	deadline := time.Now().Add(timeout)
	for {
		matches, _ := filepath.Glob("/sys/class/input/event*/device/name")
		for _, m := range matches {
			data, err := os.ReadFile(m)
			if err != nil {
				continue
			}
			if strings.TrimSpace(string(data)) == "Power Button" {
				eventName := filepath.Base(filepath.Dir(filepath.Dir(m)))
				return filepath.Join("/dev/input", eventName), nil
			}
		}

		if time.Now().After(deadline) {
			return "", fmt.Errorf("no \"Power Button\" input device found within %v", timeout)
		}
		time.Sleep(500 * time.Millisecond)
	}
}
