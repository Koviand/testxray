package main

import (
	"fmt"
	"os"
	"time"
)

func RunSeed(client *Client, meta *Metadata, templatesDir, xrayTpl string, force bool) error {
	if force {
		list, err := client.ListInbounds()
		if err != nil {
			return err
		}
		tagSet := map[string]struct{}{}
		for _, t := range meta.InboundTags {
			tagSet[t] = struct{}{}
		}
		for _, ib := range list {
			if _, ok := tagSet[ib.Tag]; ok {
				if err := client.DeleteInbound(ib.Id); err != nil {
					return fmt.Errorf("delete %s: %w", ib.Tag, err)
				}
				time.Sleep(300 * time.Millisecond)
			}
		}
	}

	if err := client.UpdateXrayTemplate(xrayTpl); err != nil {
		return fmt.Errorf("xray template: %w", err)
	}
	time.Sleep(500 * time.Millisecond)

	for _, tag := range SeedOrder() {
		path := templatePath(templatesDir, tag)
		ib, err := LoadInboundTemplate(path, meta.TemplateVars(tag))
		if err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, "upsert inbound %s (port %d)...\n", tag, ib.Port)
		if err := client.UpsertInbound(ib); err != nil {
			return fmt.Errorf("upsert %s: %w", tag, err)
		}
	}

	if err := client.RestartXray(); err != nil {
		return fmt.Errorf("restart xray: %w", err)
	}
	time.Sleep(2 * time.Second)
	return client.VerifyManagedTags(meta.InboundTags)
}
