//go:build tools

// Package cmds blank-imports every external command built into the
// metalprobe u-root initramfs by hack/build.sh, purely to pin their modules
// (and transitive dependencies, e.g. gosh's line-editing/shell deps) in
// go.mod/go.sum so u-root's package resolution can find them at build time.
// Mirrors metal-maintenance-operator/sanitizer/cmds/init.go.
package cmds

import (
	_ "github.com/ironcore-dev/metal-operator/cmd/metalprobe"
	_ "github.com/u-root/u-root/cmds/core/gosh"
	_ "github.com/u-root/u-root/cmds/core/init"
	_ "github.com/u-root/u-root/cmds/core/insmod"
)
n