//go:build tools

// Package cmds blank-imports every external command built into the initramfs by
// hack/build.sh to pin their modules in so u-root's package resolution can find
// them at build time
package cmds

import (
	_ "github.com/ironcore-dev/metal-operator/cmd/metalprobe"
	_ "github.com/u-root/u-root/cmds/core/init"
)
