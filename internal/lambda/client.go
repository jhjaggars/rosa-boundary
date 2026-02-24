package lambda

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// InvestigationRequest is the payload sent to the create-investigation Lambda.
type InvestigationRequest struct {
	ClusterID       string `json:"cluster_id"`
	InvestigationID string `json:"investigation_id"`
	OCVersion       string `json:"oc_version"`
	TaskTimeout     int    `json:"task_timeout"`
}

// InvestigationResponse is the JSON response from a successful Lambda invocation.
type InvestigationResponse struct {
	Message         string `json:"message"`
	RoleARN         string `json:"role_arn"`
	TaskARN         string `json:"task_arn"`
	AccessPointID   string `json:"access_point_id"`
	InvestigationID string `json:"investigation_id"`
	ClusterID       string `json:"cluster_id"`
	Owner           string `json:"owner"`
	OCVersion       string `json:"oc_version"`
	TaskTimeout     int    `json:"task_timeout"`
}

// errorResponse is returned by the Lambda on error.
type errorResponse struct {
	Error string `json:"error"`
}

// Client is an HTTP client for the create-investigation Lambda function URL.
type Client struct {
	lambdaURL string
	http      *http.Client
}

// New returns a new Lambda Client.
func New(lambdaURL string) *Client {
	return &Client{
		lambdaURL: strings.TrimRight(lambdaURL, "/"),
		http: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// CreateInvestigation calls the Lambda to create an investigation task.
func (c *Client) CreateInvestigation(idToken string, req InvestigationRequest) (*InvestigationResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("cannot marshal request: %w", err)
	}

	httpReq, err := http.NewRequest(http.MethodPost, c.lambdaURL, bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("cannot create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+idToken)

	resp, err := c.http.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("lambda request failed: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	rawBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("cannot read Lambda response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		// Try to parse error message
		var errResp errorResponse
		if jsonErr := json.Unmarshal(rawBody, &errResp); jsonErr == nil && errResp.Error != "" {
			return nil, fmt.Errorf("lambda returned %d: %s", resp.StatusCode, errResp.Error)
		}
		return nil, fmt.Errorf("lambda returned HTTP %d: %s", resp.StatusCode, string(rawBody))
	}

	var result InvestigationResponse
	if err := json.Unmarshal(rawBody, &result); err != nil {
		return nil, fmt.Errorf("cannot decode Lambda response: %w", err)
	}

	if result.TaskARN == "" {
		return nil, fmt.Errorf("lambda response missing task_arn")
	}

	return &result, nil
}
