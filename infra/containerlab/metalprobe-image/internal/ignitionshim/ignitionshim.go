// Package ignitionshim fetches the per-server Ignition document boot-operator
// serves (via the kernel-cmdline-supplied ignition.config.url) and extracts
// the raw metalprobe CLI flags string embedded in it, without needing a full
// Ignition-spec runtime. Mirrors the pattern used by
// metal-maintenance-operator/sanitizer/config/ignitionshim.go.
package ignitionshim

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/vincent-petithory/dataurl"
)

// ConfigPath is the storage.files path metal-operator's containerlab-local
// ignition template writes the metalprobe flags string to.
const ConfigPath = "/metalprobe/config"

type ignitionDoc struct {
	Storage struct {
		Files []struct {
			Path     string `json:"path"`
			Contents struct {
				Source string `json:"source"`
			} `json:"contents"`
		} `json:"files"`
	} `json:"storage"`
}

// FetchFlags fetches the Ignition document at ignitionURL and returns the raw
// metalprobe CLI flags string (e.g. "--registry-url=... --server-uuid=...")
// found in the storage.files entry at ConfigPath.
func FetchFlags(ctx context.Context, ignitionURL string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, ignitionURL, nil)
	if err != nil {
		return "", fmt.Errorf("creating request: %w", err)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("executing request: %w", err)
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode != http.StatusOK {
		data, _ := io.ReadAll(res.Body)
		return "", fmt.Errorf("unexpected status code: %d: %s", res.StatusCode, string(data))
	}

	data, err := io.ReadAll(res.Body)
	if err != nil {
		return "", fmt.Errorf("reading response body: %w", err)
	}

	return decodeFlags(data)
}

func decodeFlags(ignitionData []byte) (string, error) {
	doc := &ignitionDoc{}
	if err := json.Unmarshal(ignitionData, doc); err != nil {
		return "", fmt.Errorf("unmarshalling json: %w", err)
	}

	for _, file := range doc.Storage.Files {
		if file.Path != ConfigPath {
			continue
		}

		decoded, err := dataurl.DecodeString(file.Contents.Source)
		if err != nil {
			return "", fmt.Errorf("decoding data url: %w", err)
		}

		return string(decoded.Data), nil
	}

	return "", fmt.Errorf("no file found at %s in ignition document", ConfigPath)
}
