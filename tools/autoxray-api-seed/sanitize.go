package main

import (
	"encoding/json"
	"fmt"
)

func sanitizeVLESSSettings(settingsJSON, protocol string) (string, error) {
	if protocol != "vless" && protocol != "trojan" {
		return settingsJSON, nil
	}
	var obj map[string]any
	if err := json.Unmarshal([]byte(settingsJSON), &obj); err != nil {
		return settingsJSON, err
	}
	fb, ok := obj["fallbacks"].([]any)
	if !ok {
		return settingsJSON, nil
	}
	clean := make([]any, 0, len(fb))
	for _, item := range fb {
		m, ok := item.(map[string]any)
		if !ok {
			clean = append(clean, item)
			continue
		}
		dest, _ := m["dest"].(string)
		if dest == "" {
			continue
		}
		clean = append(clean, item)
	}
	if len(clean) == 0 {
		delete(obj, "fallbacks")
	} else {
		obj["fallbacks"] = clean
	}
	out, err := json.Marshal(obj)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func sanitizeInbound(ib *Inbound) error {
	if ib.Settings == "" {
		return nil
	}
	s, err := sanitizeVLESSSettings(ib.Settings, ib.Protocol)
	if err != nil {
		return fmt.Errorf("sanitize %s: %w", ib.Tag, err)
	}
	ib.Settings = s
	return nil
}
