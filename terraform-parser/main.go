package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclwrite"
)

var (
	path = "/Users/jackstockley/repo/cloud-platform-environments/namespaces/live.cloud-platform.service.justice.gov.uk/offender-management-staging/resources/ecr-allocation-manager.tf"
	// hclFile *hcl.File
)

type Config struct {
	KubernetesSecret KubernetesSecret `hcl:"kubernetes_secret"`
}

type KubernetesSecret struct {
	Name      string `hcl:"metadata,name"`
	Namespace string `hcl:"metadata,namespace"`
}

func convertFile() ([]*hclwrite.Block, error) {
	var blocks []*hclwrite.Block
	fmt.Println(path)
	if filepath.Ext(path) == ".tf" {
		data, err := os.ReadFile(path)

		if err != nil {
			return nil, fmt.Errorf("error reading file %s", err)
		}

		f, diags := hclwrite.ParseConfig(data, path, hcl.Pos{
			Line:   1,
			Column: 1,
		})

		if diags.HasErrors() {
			return nil, fmt.Errorf("error getting TF resource: %s", diags)
		}
		// Grab slice of blocks in HCL file.
		blocks = f.Body().Blocks()

		fmt.Println(blocks)
	}
	return blocks, nil
}

// func decodeFile() {
// 	var config Config
// 	data, _ := os.ReadFile(path)
// 	err := hclsimple.Decode(path, data, nil, nil)
// 	if err != nil {
// 		log.Fatalf("Failed to load configuration: %s", err)
// 	}
// 	log.Printf("Configuration is %#v", config)
// }

// func decodeFile(block *hcl.Block) hcl.Diagnostics {
// 	var raw Config
// 	diags := gohcl.DecodeBody(block.Body, nil, &raw)
// 	if diags.HasErrors() {
// 		return diags
// 	}
// 	return diags
// }

func main() {
	// blocks, err := convertFile()
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// decodeFile()
	convertFile()

}
