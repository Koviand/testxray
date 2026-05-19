package main

import "testing"

func TestSanitizeRemovesEmptyFallbackDest(t *testing.T) {
	in := `{"clients":[],"decryption":"none","fallbacks":[{"dest":"3333"},{"dest":""},{"path":"/x","dest":"@vless-ws"}]}`
	out, err := sanitizeVLESSSettings(in, "vless")
	if err != nil {
		t.Fatal(err)
	}
	if contains(out, `"dest":""`) {
		t.Fatalf("empty dest not removed: %s", out)
	}
	if !contains(out, `"dest":"3333"`) {
		t.Fatalf("valid dest removed: %s", out)
	}
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || len(sub) == 0 || indexOf(s, sub) >= 0)
}

func indexOf(s, sub string) int {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return i
		}
	}
	return -1
}
