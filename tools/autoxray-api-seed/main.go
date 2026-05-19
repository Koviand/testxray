package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	var (
		credsPath  = flag.String("credentials", "/etc/testxray/credentials.env", "panel credentials file")
		statePath  = flag.String("state", "/etc/autoXRAY/panel-metadata.json", "autoXRAY metadata json")
		templates  = flag.String("templates", "", "inbound templates directory")
		xrayTpl    = flag.String("xray-template", "", "xray routing template json")
		force      = flag.Bool("force", false, "delete managed inbounds before seed")
		verifyOnly = flag.Bool("verify-only", false, "verify tags only")
		installDir = flag.String("install-dir", "/usr/local/testxray", "testxray install root")
	)
	flag.Parse()

	if *templates == "" {
		*templates = *installDir + "/config/inbounds"
	}
	if *xrayTpl == "" {
		*xrayTpl = *installDir + "/config/templates/xray-template.json"
	}

	creds, err := LoadCredentials(*credsPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "credentials: %v\n", err)
		os.Exit(1)
	}

	meta, err := LoadMetadata(*statePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "metadata: %v\n", err)
		os.Exit(1)
	}

	client, err := NewClient(creds)
	if err != nil {
		fmt.Fprintf(os.Stderr, "client: %v\n", err)
		os.Exit(1)
	}

	if err := client.Login(); err != nil {
		fmt.Fprintf(os.Stderr, "login: %v\n", err)
		os.Exit(1)
	}

	if err := client.EnsureCSRF(); err != nil {
		fmt.Fprintf(os.Stderr, "csrf: %v\n", err)
		os.Exit(1)
	}

	if creds.APIToken != "" {
		client.SetToken(creds.APIToken)
	} else if err := client.EnsureAPIToken(); err != nil {
		fmt.Fprintf(os.Stderr, "api token: %v\n", err)
		os.Exit(1)
	} else if err := SaveAPIToken(*credsPath, client.Token()); err != nil {
		fmt.Fprintf(os.Stderr, "save token: %v\n", err)
		os.Exit(1)
	}

	if *verifyOnly {
		if err := client.VerifyManagedTags(meta.InboundTags); err != nil {
			fmt.Fprintf(os.Stderr, "verify: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("verify: ok")
		return
	}

	if err := RunSeed(client, meta, *templates, *xrayTpl, *force); err != nil {
		fmt.Fprintf(os.Stderr, "seed: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("seed: ok")
}
