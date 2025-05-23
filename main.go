package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	"connectrpc.com/connect"
	pb "github.com/wippyai/module-registry-proto/gen/registry/module/v1"
	modulev1connect "github.com/wippyai/module-registry-proto/gen/registry/module/v1/modulev1connect"
)

func main() {
	if len(os.Args) != 6 {
		log.Fatalf("Usage: %s <module_id> <tag> <zip_file> <basic_auth_user> <basic_auth_password>\n\nNote: You need to provide the Basic Auth username and password for authentication", os.Args[0])
	}

	ctx := context.Background()

	moduleID := os.Args[1]
	tag := os.Args[2]
	zipFile := os.Args[3]
	basicAuthUser := os.Args[4]
	basicAuthPassword := os.Args[5]

	// Read the zip file
	zipData, err := os.ReadFile(zipFile)
	if err != nil {
		log.Fatalf("Failed to read zip file: %v", err)
	}

	// Create custom HTTP client with auth header
	httpClient := &http.Client{
		Transport: &authTransport{
			username: basicAuthUser,
			password: basicAuthPassword,
			base:     http.DefaultTransport,
		},
	}

	// Create client with custom HTTP client
	client := modulev1connect.NewUploadServiceClient(
		httpClient,
		"https://modules.wippy.ai",
	)

	// Create request
	req := connect.NewRequest(&pb.UploadArchiveRequest{
		ModuleId:       moduleID,
		ArchiveContent: zipData,
		Format:         pb.UploadArchiveRequest_ARCHIVE_FORMAT_ZIP,
	})

	commitID := ""

	// Send request
	resp, err := client.UploadArchive(context.Background(), req)
	switch {
	case err != nil && strings.Contains(err.Error(), "already_exists"):
		// extract commitID from already commited changes
		commitID, err = GetLatestModuleCommitID(ctx, moduleID, basicAuthUser, basicAuthPassword)
		if err != nil {
			log.Fatalf("Failed to get latest module commit ID: %v", err)
		}
	case err != nil:
		log.Fatalf("Failed to upload archive: %v", err)
	default:
		commitID = resp.Msg.GetCommit().GetId()
		fmt.Printf("Successfully uploaded archive. Extracted %d files.\n", resp.Msg.ExtractedFilesCount)
	}

	if commitID == "" {
		log.Fatalf("Failed to get commit ID from response")
	}

	labelClient := modulev1connect.NewLabelServiceClient(
		httpClient,
		"https://modules.wippy.ai",
	)

	respCreateLabel, err := labelClient.CreateLabel(ctx, connect.NewRequest(&pb.CreateLabelRequest{
		ModuleId: moduleID,
		CommitId: commitID,
		Name:     tag,
	}))

	labelID := ""
	switch {
	case err != nil && strings.Contains(err.Error(), "already_exists"):
		labelID, err = GetLatestModuleLabelID(ctx, moduleID, tag, basicAuthUser, basicAuthPassword)
		if err != nil {
			log.Printf("Failed to get latest module label ID: %v", err)
		}
	case err != nil:
		log.Fatalf("Failed to create label: %v", err)
	default:
		labelID = respCreateLabel.Msg.GetLabel().GetId()
		fmt.Printf("Successfully created label for module %s: %s\n", labelID, tag)
	}
}

func GetLatestModuleLabelID(ctx context.Context, moduleID string, tag string, basicAuthUser string, basicAuthPassword string) (string, error) {
	httpClient := &http.Client{
		Transport: &authTransport{
			username: basicAuthUser,
			password: basicAuthPassword,
			base:     http.DefaultTransport,
		},
	}

	client := modulev1connect.NewLabelServiceClient(
		httpClient,
		"https://modules.wippy.ai",
	)

	resp, err := client.ListModuleLabels(ctx, connect.NewRequest(&pb.ListModuleLabelsRequest{
		ModuleIds: []string{moduleID},
	}))

	if err != nil {
		return "", err
	}

	labels := resp.Msg.GetLabels()
	if len(labels) == 0 {
		return "", fmt.Errorf("no labels found for module %s", moduleID)
	}

	// Filter labels to find the one matching the tag
	for _, label := range labels {
		if label.GetName() == tag {
			fmt.Printf("Found label for module %s with tag %s: id=%s, commit_id=%s, created_by=%s, created_at=%s\n",
				moduleID,
				label.GetName(),
				label.GetId(),
				label.GetCommitId(),
				label.GetCreatedByUserId(),
				label.GetCreateTime().AsTime().Format(time.RFC3339))
			return label.GetName(), nil
		}
	}

	return "", fmt.Errorf("no label found for module %s with tag %s", moduleID, tag)
}

func GetLatestModuleCommitID(ctx context.Context, moduleID string, basicAuthUser string, basicAuthPassword string) (string, error) {
	httpClient := &http.Client{
		Transport: &authTransport{
			username: basicAuthUser,
			password: basicAuthPassword,
			base:     http.DefaultTransport,
		},
	}

	// Create client with custom HTTP client
	client := modulev1connect.NewCommitServiceClient(
		httpClient,
		"https://modules.wippy.ai",
	)

	resp, err := client.ListModuleCommits(ctx, connect.NewRequest(&pb.ListModuleCommitsRequest{
		ModuleIds: []string{moduleID},
	}))
	if err != nil {
		return "", err
	}

	commits := resp.Msg.GetCommits()
	if len(commits) == 0 {
		return "", fmt.Errorf("no commits found for module %s", moduleID)
	}

	// Sort commits by creation date in descending order
	sort.Slice(commits, func(i, j int) bool {
		return commits[i].GetCreateTime().AsTime().After(commits[j].GetCreateTime().AsTime())
	})

	fmt.Printf("Latest commit for module %s: %s\n", moduleID, commits[0].GetId())

	return commits[0].GetId(), nil
}

// authTransport adds the basic auth header to all requests
type authTransport struct {
	username string
	password string
	base     http.RoundTripper
}

func (t *authTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	auth := base64.StdEncoding.EncodeToString([]byte(t.username + ":" + t.password))
	req.Header.Set("Authorization", "Basic "+auth)
	return t.base.RoundTrip(req)
}
