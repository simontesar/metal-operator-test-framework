//go:build linux

// Command metalprobe-launcher runs as PID 1 in the metalprobe u-root
// initramfs. It configures networking via DHCP, fetches the per-server
// metalprobe flags via the boot-operator-served Ignition document, then runs
// metalprobe as a child process.
//
// metalprobe itself is not run as PID 1: its main() calls os.Exit(1) on a
// failed initial registration, which would panic the kernel if it were PID 1.
// The launcher stays PID 1 and always parks (blocks forever) afterwards,
// regardless of how metalprobe exited.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/insomniacslk/dhcp/dhcpv4"
	"github.com/insomniacslk/dhcp/dhcpv6"
	"github.com/u-root/u-root/pkg/cmdline"
	"github.com/u-root/u-root/pkg/dhclient"

	"github.com/simontesar/metal-operator-test-framework/infra/containerlab/metalprobe-image/internal/ignitionshim"
)

func dhConfigure(ctx context.Context) error {
	ifs, err := dhclient.Interfaces("^e.*")
	if err != nil || len(ifs) == 0 {
		allIfaces, _ := dhclient.Interfaces(".*")
		allIfaceNames := make([]string, 0, len(allIfaces))
		for _, iface := range allIfaces {
			allIfaceNames = append(allIfaceNames, fmt.Sprintf("%#+v", iface.Attrs()))
		}
		if err == nil {
			err = fmt.Errorf("no interfaces matched")
		}
		return fmt.Errorf("getting interfaces: %w (available interfaces %v)", err, allIfaceNames)
	}

	ifNames := make([]string, len(ifs))
	for i, iface := range ifs {
		ifNames[i] = iface.Attrs().Name
	}
	slog.Info("dhcp: sending requests", "interfaces", ifNames)

	var (
		errs       []error
		done       = make(chan struct{})
		closeOnce  sync.Once
		notifyDone = func() {
			closeOnce.Do(func() { close(done) })
		}
	)
	go func() {
		defer notifyDone()

		for res := range dhclient.SendRequests(ctx, ifs, true, true, dhclient.Config{
			Timeout: 15 * time.Second,
			Retries: 5,
			V4ServerAddr: &net.UDPAddr{
				IP:   net.IPv4bcast,
				Port: dhcpv4.ServerPort,
			},
			V6ServerAddr: &net.UDPAddr{
				IP:   net.ParseIP("ff02::1:2"),
				Port: dhcpv6.DefaultServerPort,
			},
		}, 30*time.Second) {
			if res.Err != nil {
				errs = append(errs, res.Err)
				continue
			}

			if err := res.Lease.Configure(); err != nil {
				errs = append(errs, err)
				continue
			}

			notifyDone()
		}
	}()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-done:
		return errors.Join(errs...)
	}
}

func main() {
	ctx := context.Background()

	ignitionURL, _ := cmdline.Flag("ignition.config.url")
	if ignitionURL == "" {
		park(fmt.Errorf("no ignition.config.url on kernel cmdline"))
	}

	dhcpCtx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	err := dhConfigure(dhcpCtx)
	cancel()
	if err != nil {
		park(fmt.Errorf("dhcp configure: %w", err))
	}
	slog.Info("dhcp: configured")

	rawFlags, err := ignitionshim.FetchFlags(ctx, ignitionURL)
	if err != nil {
		park(fmt.Errorf("fetch metalprobe config: %w", err))
	}

	args := strings.Fields(rawFlags)
	slog.Info("starting metalprobe", "args", args)

	cmd := exec.Command("metalprobe", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		park(fmt.Errorf("metalprobe exited: %w", err))
	}

	park(nil)
}

// park blocks forever, since PID 1 must never return. It logs why it's
// parking (error path vs. clean metalprobe exit) so the console/serial log
// shows the actual failure instead of just an unexplained hang.
func park(err error) {
	if err != nil {
		slog.Error("metalprobe-launcher parking after error", "error", err)
	} else {
		slog.Info("metalprobe-launcher parking after clean metalprobe exit")
	}
	select {}
}
