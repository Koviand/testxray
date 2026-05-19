package main

import (
	"fmt"
	"strings"
)

// Authenticate logs in (session cookie) and optionally validates/creates API token.
// Inbound API works with session cookies; Bearer is optional.
func (c *Client) Authenticate(credsPath string, creds *Credentials) error {
	if err := c.Login(); err != nil {
		return fmt.Errorf("login: %w", err)
	}
	if err := c.EnsureCSRF(); err != nil {
		return fmt.Errorf("csrf: %w", err)
	}

	if creds.APIToken != "" {
		c.SetToken(creds.APIToken)
		if _, err := c.ListInbounds(); err != nil && strings.Contains(strings.ToLower(err.Error()), "unauthorized") {
			c.SetToken("")
		}
	}

	if c.token == "" {
		if _, err := c.ListInbounds(); err != nil {
			return fmt.Errorf("session auth failed (check PANEL_URL/webBasePath): %w", err)
		}
		// Best-effort API token for credentials.env (not required for seed).
		if err := c.EnsureAPIToken(); err == nil && c.Token() != "" {
			_ = SaveAPIToken(credsPath, c.Token())
		}
		return nil
	}

	if _, err := c.ListInbounds(); err != nil {
		return fmt.Errorf("api token auth failed: %w", err)
	}
	return nil
}
