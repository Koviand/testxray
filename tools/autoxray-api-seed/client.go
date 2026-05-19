package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strings"
	"time"
)

const csrfHeader = "X-CSRF-Token"

type apiMsg struct {
	Success bool            `json:"success"`
	Msg     string          `json:"msg"`
	Obj     json.RawMessage `json:"obj"`
}

type Client struct {
	base    string
	user    string
	pass    string
	token   string
	csrf    string
	http    *http.Client
}

func NewClient(creds *Credentials) (*Client, error) {
	jar, _ := cookiejar.New(nil)
	c := &Client{
		base: strings.TrimRight(creds.BaseURL, "/"),
		user: creds.Username,
		pass: creds.Password,
		token: creds.APIToken,
		http: &http.Client{
			Timeout: 120 * time.Second,
			Jar:     jar,
		},
	}
	return c, nil
}

func (c *Client) Token() string { return c.token }

func (c *Client) SetToken(t string) { c.token = t }

func (c *Client) Login() error {
	form := url.Values{}
	form.Set("username", c.user)
	form.Set("password", c.pass)
	loginURL := strings.TrimRight(c.base, "/") + "/login"
	req, err := http.NewRequest(http.MethodPost, loginURL, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	var msg apiMsg
	if err := json.Unmarshal(body, &msg); err != nil {
		return fmt.Errorf("login parse: %w (%s)", err, string(body))
	}
	if !msg.Success {
		return fmt.Errorf("login failed: %s", msg.Msg)
	}
	return nil
}

func (c *Client) EnsureCSRF() error {
	if c.csrf != "" {
		return nil
	}
	req, err := http.NewRequest(http.MethodGet, strings.TrimRight(c.base, "/")+"/panel/csrf-token", nil)
	if err != nil {
		return err
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	var msg apiMsg
	if err := json.Unmarshal(body, &msg); err != nil {
		return err
	}
	if !msg.Success {
		return fmt.Errorf("csrf: %s", msg.Msg)
	}
	var token string
	if err := json.Unmarshal(msg.Obj, &token); err != nil {
		return err
	}
	c.csrf = token
	return nil
}

func (c *Client) EnsureAPIToken() error {
	if c.token != "" {
		return nil
	}
	name := "testxray-seed"
	body := map[string]string{"name": name}
	b, _ := json.Marshal(body)
	req, err := http.NewRequest(http.MethodPost, c.base+"/panel/apiTokens/create", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	c.setSessionHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var msg apiMsg
	if err := json.Unmarshal(raw, &msg); err != nil {
		return err
	}
	if msg.Success {
		var view struct {
			Token string `json:"token"`
		}
		if err := json.Unmarshal(msg.Obj, &view); err != nil {
			return err
		}
		if view.Token == "" {
			return fmt.Errorf("empty api token")
		}
		c.token = view.Token
		return nil
	}
	// Token name already exists — session auth is enough; ignore.
	if strings.Contains(strings.ToLower(msg.Msg), "already") {
		return nil
	}
	return fmt.Errorf("create token: %s", msg.Msg)
}

func (c *Client) setSessionHeaders(req *http.Request) {
	if c.csrf != "" {
		req.Header.Set(csrfHeader, c.csrf)
	}
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
}

func (c *Client) setAPIHeaders(req *http.Request) {
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
}

func (c *Client) UpdateXrayTemplate(tplPath string) error {
	raw, err := readFileTrim(tplPath)
	if err != nil {
		return err
	}
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	_ = w.WriteField("xraySetting", raw)
	_ = w.WriteField("outboundTestUrl", "https://www.google.com/generate_204")
	w.Close()

	req, err := http.NewRequest(http.MethodPost, strings.TrimRight(c.base, "/")+"/panel/xray/update", &buf)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", w.FormDataContentType())
	c.setSessionHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return checkMsg(resp)
}

func (c *Client) ListInbounds() ([]Inbound, error) {
	req, err := http.NewRequest(http.MethodGet, strings.TrimRight(c.base, "/")+"/panel/api/inbounds/list", nil)
	if err != nil {
		return nil, err
	}
	c.setAPIHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusUnauthorized {
		return nil, fmt.Errorf("unauthorized")
	}
	var list []Inbound
	if err := json.Unmarshal(body, &list); err == nil {
		return list, nil
	}
	var msg apiMsg
	if err := json.Unmarshal(body, &msg); err != nil {
		return nil, fmt.Errorf("list parse: %w", err)
	}
	if !msg.Success {
		return nil, fmt.Errorf("list: %s", msg.Msg)
	}
	if err := json.Unmarshal(msg.Obj, &list); err != nil {
		return nil, err
	}
	return list, nil
}

func (c *Client) DeleteInbound(id int) error {
	req, err := http.NewRequest(http.MethodPost, fmt.Sprintf("%s/panel/api/inbounds/del/%d", strings.TrimRight(c.base, "/"), id), nil)
	if err != nil {
		return err
	}
	c.setAPIHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return checkMsg(resp)
}

func (c *Client) RestartXray() error {
	req, err := http.NewRequest(http.MethodPost, strings.TrimRight(c.base, "/")+"/panel/api/server/restartXrayService", nil)
	if err != nil {
		return err
	}
	c.setAPIHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return checkMsg(resp)
}

func (c *Client) VerifyManagedTags(tags []string) error {
	list, err := c.ListInbounds()
	if err != nil {
		return err
	}
	found := map[string]bool{}
	for _, ib := range list {
		found[ib.Tag] = true
	}
	for _, t := range tags {
		if !found[t] {
			return fmt.Errorf("missing inbound tag %q", t)
		}
	}
	return nil
}

func checkMsg(resp *http.Response) error {
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return fmt.Errorf("http %d: %s", resp.StatusCode, string(body))
	}
	var msg apiMsg
	if err := json.Unmarshal(body, &msg); err != nil {
		return nil
	}
	if !msg.Success {
		if msg.Msg != "" {
			return fmt.Errorf("%s", msg.Msg)
		}
		return fmt.Errorf("request failed (success=false)")
	}
	return nil
}

func readFileTrim(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}
