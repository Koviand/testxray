package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

type Credentials struct {
	BaseURL   string
	Username  string
	Password  string
	APIToken  string
	WebBase   string
}

func LoadCredentials(path string) (*Credentials, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	c := &Credentials{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		k := strings.TrimSpace(parts[0])
		v := strings.Trim(strings.TrimSpace(parts[1]), `"'`)
		switch k {
		case "PANEL_URL":
			c.BaseURL = strings.TrimRight(v, "/")
		case "PANEL_USER":
			c.Username = v
		case "PANEL_PASS":
			c.Password = v
		case "API_TOKEN":
			c.APIToken = v
		case "WEB_BASE_PATH":
			c.WebBase = v
		}
	}
	if c.BaseURL == "" {
		return nil, fmt.Errorf("PANEL_URL missing in %s", path)
	}
	if c.Username == "" || c.Password == "" {
		return nil, fmt.Errorf("PANEL_USER/PANEL_PASS missing in %s", path)
	}
	return c, sc.Err()
}

func SaveAPIToken(path, token string) error {
	data, err := os.ReadFile(path)
	if err != nil && !os.IsNotExist(err) {
		return err
	}
	lines := strings.Split(string(data), "\n")
	out := make([]string, 0, len(lines)+1)
	found := false
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "API_TOKEN=") {
			out = append(out, "API_TOKEN="+token)
			found = true
		} else if line != "" || len(out) > 0 {
			out = append(out, line)
		}
	}
	if !found {
		out = append(out, "API_TOKEN="+token)
	}
	return os.WriteFile(path, []byte(strings.Join(out, "\n")+"\n"), 0o600)
}
