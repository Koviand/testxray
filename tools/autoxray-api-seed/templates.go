package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func LoadInboundTemplate(path string, vars map[string]string) (Inbound, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return Inbound{}, err
	}
	raw := string(b)
	for k, v := range vars {
		raw = strings.ReplaceAll(raw, "{{"+k+"}}", v)
	}
	var ib Inbound
	if err := json.Unmarshal([]byte(raw), &ib); err != nil {
		return Inbound{}, fmt.Errorf("%s: %w", path, err)
	}
	return ib, nil
}

func SeedOrder() []string {
	return []string{
		"vsWSinternal",
		"vsXHTTPrty",
		"vsXHTTPtls",
		"vsGRPCtls",
		"vsRAWrtyVISION",
		"vsRAWtlsVISION",
		"socks5",
	}
}

func templatePath(dir, tag string) string {
	return filepath.Join(dir, tag+".json")
}
