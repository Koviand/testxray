package main

import (
	"encoding/json"
	"os"
)

type Metadata struct {
	Version     int      `json:"version"`
	ManagedBy   string   `json:"managed_by"`
	Domain      string   `json:"domain"`
	UUID        string   `json:"uuid"`
	PrivateKey  string   `json:"private_key"`
	PublicKey   string   `json:"public_key"`
	ShortID     string   `json:"short_id"`
	PathXHTTP   string   `json:"path_xhttp"`
	PathSubpage string   `json:"path_subpage"`
	SocksUser   string   `json:"socks_user"`
	SocksPass   string   `json:"socks_pass"`
	InboundTags []string `json:"inbound_tags"`
}

func LoadMetadata(path string) (*Metadata, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var m Metadata
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	if len(m.InboundTags) == 0 {
		m.InboundTags = []string{
			"vsWSinternal", "vsXHTTPrty", "vsXHTTPtls", "vsGRPCtls",
			"vsRAWrtyVISION", "vsRAWtlsVISION", "socks5",
		}
	}
	return &m, nil
}

func (m *Metadata) TemplateVars(tag string) map[string]string {
	return map[string]string{
		"UUID":         m.UUID,
		"EMAIL":        "autoxray-" + tag + "@local",
		"SUB_ID":       "ax" + tag,
		"DOMAIN":       m.Domain,
		"PRIVATE_KEY":  m.PrivateKey,
		"PUBLIC_KEY":   m.PublicKey,
		"SHORT_ID":     m.ShortID,
		"PATH_XHTTP":   m.PathXHTTP,
		"PATH_SUBPAGE": m.PathSubpage,
		"SOCKS_USER":   m.SocksUser,
		"SOCKS_PASS":   m.SocksPass,
	}
}
