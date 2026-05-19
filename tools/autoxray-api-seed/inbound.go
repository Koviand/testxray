package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Inbound struct {
	Id             int    `json:"id"`
	Remark         string `json:"remark"`
	Enable         bool   `json:"enable"`
	Listen         string `json:"listen"`
	Port           int    `json:"port"`
	Protocol       string `json:"protocol"`
	Tag            string `json:"tag"`
	Settings       string `json:"settings"`
	StreamSettings string `json:"streamSettings"`
	Sniffing       string `json:"sniffing"`
}

func (c *Client) UpsertInbound(ib Inbound) error {
	if err := sanitizeInbound(&ib); err != nil {
		return err
	}
	list, err := c.ListInbounds()
	if err != nil {
		return err
	}
	var existing *Inbound
	for i := range list {
		if list[i].Tag == ib.Tag {
			existing = &list[i]
			break
		}
	}
	if existing == nil {
		return c.postInbound("panel/api/inbounds/add", ib)
	}
	ib.Id = existing.Id
	return c.postInbound(fmt.Sprintf("panel/api/inbounds/update/%d", existing.Id), ib)
}

func (c *Client) postInbound(path string, ib Inbound) error {
	b, err := json.Marshal(ib)
	if err != nil {
		return err
	}
	req, err := http.NewRequest(http.MethodPost, c.base+"/"+path, bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	c.setAPIHeaders(req)
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return fmt.Errorf("%s http %d: %s", path, resp.StatusCode, string(body))
	}
	var msg apiMsg
	if err := json.Unmarshal(body, &msg); err == nil && !msg.Success && msg.Msg != "" {
		return fmt.Errorf("%s: %s", path, msg.Msg)
	}
	time.Sleep(400 * time.Millisecond)
	return nil
}
