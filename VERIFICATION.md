# CTF Completion Verification

This document describes how the Learn to Cloud CTF verification token system works and how to implement verification in your application.

## Overview

When users complete all 18 challenges and run `verify export <github_username>`, they receive:
1. A visual certificate displayed in the terminal
2. A **signed verification token** they can copy-paste to verify their completion

## Security Design

The verification system uses **GitHub OAuth** as the primary security mechanism:

1. **User completes CTF** and runs `verify export <github_username>`
2. **Token is generated** containing their GitHub username
3. **User visits verification app** at https://learntocloud.guide/phase2 and signs in with GitHub
4. **App verifies**: `token.github_username === OAuth_user.login`

This means:
- Users must sign in with the **same GitHub account** they specified when exporting
- Even if someone forges a token, they can only claim it for their own GitHub account
- No value in forging tokens for other users (can't log in as them)

Additionally, tokens are signed with HMAC-SHA256 using a derived secret:
- `VERIFICATION_SECRET = SHA256(MASTER_SECRET:INSTANCE_ID)`
- This allows the app to verify the token structure is valid

## Token Format

The token is a base64-encoded JSON object containing:

```json
{
  "payload": {
    "github_username": "octocat",
    "date": "2026-01-13",
    "time": "02:30",
    "challenges": 18,
    "timestamp": 1736784000,
    "instance_id": "a1b2c3d4e5f6..."
  },
  "signature": "abc123..."
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `github_username` | string | User's GitHub username (verified via OAuth) |
| `date` | string | Completion date (YYYY-MM-DD) |
| `time` | string | Total time to complete (HH:MM) |
| `challenges` | number | Number of challenges completed (always 18) |
| `timestamp` | number | Unix timestamp when token was generated |
| `instance_id` | string | Unique identifier for this VM instance (32 hex chars) |
| `signature` | string | HMAC-SHA256 signature of the payload |

## Verification App Implementation

### Master Secret

```
L2C_CTF_MASTER_2024
```

> ⚠️ **IMPORTANT**: This master secret must be stored securely in your verification app (environment variable, secrets manager, etc.). Never expose it to the client/frontend.

### Verification Algorithm

1. **User signs in** with GitHub OAuth → get `oauth_user.login`
2. **Decode** the token from base64
3. **Parse** the JSON to extract `payload` and `signature`
4. **Check GitHub username**: `payload.github_username === oauth_user.login` ⚠️ **Critical step!**
5. **Extract** the `instance_id` from the payload
6. **Derive** the verification secret: `SHA256(MASTER_SECRET + ":" + instance_id)`
7. **Stringify** the payload (exactly as received)
8. **Compute** HMAC-SHA256 of the payload using the derived secret
9. **Compare** computed signature with the provided signature
10. **Validate** the payload fields (challenges === 18, reasonable timestamp, etc.)

### Example Implementations

#### Python

```python
import base64
import json
import hmac
import hashlib
from datetime import datetime

MASTER_SECRET = "L2C_CTF_MASTER_2024"

def derive_secret(instance_id: str) -> str:
    """Derive the verification secret from master secret and instance ID."""
    data = f"{MASTER_SECRET}:{instance_id}"
    return hashlib.sha256(data.encode()).hexdigest()

def verify_token(token: str, oauth_github_username: str) -> dict:
    """
    Verify a CTF completion token.
    
    Args:
        token: The base64-encoded token from the user
        oauth_github_username: The GitHub username from OAuth sign-in
    
    Returns:
        dict with 'valid' (bool) and 'data' (payload) or 'error' (message)
    """
    try:
        # Decode base64
        decoded = base64.b64decode(token).decode('utf-8')
        token_data = json.loads(decoded)
        
        payload = token_data.get('payload')
        signature = token_data.get('signature')
        
        if not payload or not signature:
            return {"valid": False, "error": "Invalid token structure"}
        
        # CRITICAL: Verify GitHub username matches OAuth user
        token_username = payload.get('github_username', '').lower()
        if token_username != oauth_github_username.lower():
            return {"valid": False, "error": "GitHub username mismatch"}
        
        # Get instance ID and derive the secret
        instance_id = payload.get('instance_id')
        if not instance_id:
            return {"valid": False, "error": "Missing instance ID"}
        
        verification_secret = derive_secret(instance_id)
        
        # Recreate the payload string exactly as it was signed
        payload_str = json.dumps(payload, separators=(',', ':'))
        
        # Compute expected signature
        expected_sig = hmac.new(
            verification_secret.encode(),
            payload_str.encode(),
            hashlib.sha256
        ).hexdigest()
        
        # Constant-time comparison to prevent timing attacks
        if not hmac.compare_digest(signature, expected_sig):
            return {"valid": False, "error": "Invalid signature"}
        
        # Validate payload
        if payload.get('challenges') != 18:
            return {"valid": False, "error": "Incomplete challenges"}
        
        # Check timestamp is reasonable (not in future, not too old)
        timestamp = payload.get('timestamp', 0)
        now = datetime.now().timestamp()
        if timestamp > now + 3600:  # Allow 1 hour clock skew
            return {"valid": False, "error": "Invalid timestamp"}
        
        return {
            "valid": True,
            "data": {
                "github_username": payload.get('github_username'),
                "date": payload.get('date'),
                "completion_time": payload.get('time'),
                "challenges": payload.get('challenges')
            }
        }
        
    except Exception as e:
        return {"valid": False, "error": f"Token parsing failed: {str(e)}"}


# Example usage (in your Flask/FastAPI route after OAuth)
if __name__ == "__main__":
    # In real app, oauth_username comes from GitHub OAuth callback
    oauth_username = input("Your GitHub username: ").strip()
    test_token = input("Paste token: ").strip()
    result = verify_token(test_token, oauth_username)
    print(json.dumps(result, indent=2))
```

#### JavaScript/Node.js

```javascript
const crypto = require('crypto');

const MASTER_SECRET = 'L2C_CTF_MASTER_2024';

function deriveSecret(instanceId) {
  const data = `${MASTER_SECRET}:${instanceId}`;
  return crypto.createHash('sha256').update(data).digest('hex');
}

function verifyToken(token, oauthGithubUsername) {
  try {
    // Decode base64
    const decoded = Buffer.from(token, 'base64').toString('utf-8');
    const tokenData = JSON.parse(decoded);
    
    const { payload, signature } = tokenData;
    
    if (!payload || !signature) {
      return { valid: false, error: 'Invalid token structure' };
    }
    
    // CRITICAL: Verify GitHub username matches OAuth user
    const tokenUsername = (payload.github_username || '').toLowerCase();
    if (tokenUsername !== oauthGithubUsername.toLowerCase()) {
      return { valid: false, error: 'GitHub username mismatch' };
    }
    
    // Get instance ID and derive the secret
    const instanceId = payload.instance_id;
    if (!instanceId) {
      return { valid: false, error: 'Missing instance ID' };
    }
    
    const verificationSecret = deriveSecret(instanceId);
    
    // Recreate the payload string exactly as it was signed
    const payloadStr = JSON.stringify(payload);
    
    // Compute expected signature
    const expectedSig = crypto
      .createHmac('sha256', verificationSecret)
      .update(payloadStr)
      .digest('hex');
    
    // Constant-time comparison
    if (!crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSig)
    )) {
      return { valid: false, error: 'Invalid signature' };
    }
    
    // Validate payload
    if (payload.challenges !== 18) {
      return { valid: false, error: 'Incomplete challenges' };
    }
    
    return {
      valid: true,
      data: {
        githubUsername: payload.github_username,
        date: payload.date,
        completionTime: payload.time,
        challenges: payload.challenges
      }
    };
    
  } catch (e) {
    return { valid: false, error: `Token parsing failed: ${e.message}` };
  }
}

module.exports = { verifyToken };
```

#### Go

```go
package main

import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/base64"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "strings"
)

const masterSecret = "L2C_CTF_MASTER_2024"

type Payload struct {
    GithubUsername string `json:"github_username"`
    Date           string `json:"date"`
    Time           string `json:"time"`
    Challenges     int    `json:"challenges"`
    Timestamp      int64  `json:"timestamp"`
    InstanceID     string `json:"instance_id"`
}

type TokenData struct {
    Payload   Payload `json:"payload"`
    Signature string  `json:"signature"`
}

type VerificationResult struct {
    Valid bool                   `json:"valid"`
    Data  map[string]interface{} `json:"data,omitempty"`
    Error string                 `json:"error,omitempty"`
}

func deriveSecret(instanceID string) string {
    data := fmt.Sprintf("%s:%s", masterSecret, instanceID)
    hash := sha256.Sum256([]byte(data))
    return hex.EncodeToString(hash[:])
}

func verifyToken(token string, oauthGithubUsername string) VerificationResult {
    // Decode base64
    decoded, err := base64.StdEncoding.DecodeString(token)
    if err != nil {
        return VerificationResult{Valid: false, Error: "Base64 decode failed"}
    }
    
    var tokenData TokenData
    if err := json.Unmarshal(decoded, &tokenData); err != nil {
        return VerificationResult{Valid: false, Error: "JSON parse failed"}
    }
    
    // CRITICAL: Verify GitHub username matches OAuth user
    if strings.ToLower(tokenData.Payload.GithubUsername) != strings.ToLower(oauthGithubUsername) {
        return VerificationResult{Valid: false, Error: "GitHub username mismatch"}
    }
    
    // Derive secret from instance ID
    if tokenData.Payload.InstanceID == "" {
        return VerificationResult{Valid: false, Error: "Missing instance ID"}
    }
    verificationSecret := deriveSecret(tokenData.Payload.InstanceID)
    
    // Recreate payload string
    payloadBytes, _ := json.Marshal(tokenData.Payload)
    
    // Compute expected signature
    h := hmac.New(sha256.New, []byte(verificationSecret))
    h.Write(payloadBytes)
    expectedSig := hex.EncodeToString(h.Sum(nil))
    
    // Compare signatures
    if !hmac.Equal([]byte(tokenData.Signature), []byte(expectedSig)) {
        return VerificationResult{Valid: false, Error: "Invalid signature"}
    }
    
    // Validate challenges
    if tokenData.Payload.Challenges != 18 {
        return VerificationResult{Valid: false, Error: "Incomplete challenges"}
    }
    
    return VerificationResult{
        Valid: true,
        Data: map[string]interface{}{
            "githubUsername":  tokenData.Payload.GithubUsername,
            "date":            tokenData.Payload.Date,
            "completionTime":  tokenData.Payload.Time,
            "challenges":      tokenData.Payload.Challenges,
        },
    }
}
```

## Security Considerations

1. **GitHub OAuth is the Primary Security**: The key security mechanism is that users must sign in with the same GitHub account specified in their token. Even if someone forges a token, they can only claim it for their own GitHub account.

2. **Master Secret Storage**: The master secret (`L2C_CTF_MASTER_2024`) should be stored securely in your verification app (environment variable or secrets manager), but note that the real security comes from GitHub OAuth verification.

3. **Case-Insensitive Username Matching**: GitHub usernames are case-insensitive, so always compare with `.toLowerCase()` / `.lower()`.

4. **Timing Attacks**: Always use constant-time comparison functions when comparing signatures.

5. **Token Expiration**: Consider adding expiration validation if tokens should only be valid for a certain period.

6. **Rate Limiting**: Implement rate limiting on your verification endpoint.

7. **HTTPS Only**: Always serve the verification API over HTTPS.

## Token Lifecycle

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   VM Setup      │     │   User          │     │  Verification   │
│                 │     │                 │     │      App        │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │ Generate INSTANCE_ID  │                       │
         │ Derive SECRET from    │                       │
         │ MASTER + INSTANCE_ID  │                       │
         │                       │                       │
         │                       │ verify export "user"  │
         │                       │<──────────────────────│
         │                       │                       │
         │ Sign with SECRET      │                       │
         │ Include github_user   │                       │
         │ in token              │                       │
         │──────────────────────>│                       │
         │                       │                       │
         │                       │ Sign in with GitHub   │
         │                       │──────────────────────>│
         │                       │                       │
         │                       │ Paste token           │
         │                       │──────────────────────>│
         │                       │                       │
         │                       │   token.github_user   │
         │                       │   == oauth.login?     │
         │                       │   ✅ Verified!        │
         │                       │<──────────────────────│
         │                       │                       │
```

## Updating the Master Secret

If the master secret is compromised:

1. Generate a new master secret
2. Update `ctf_setup.sh` with the new master secret
3. Update the verification app with the new master secret
4. **Note**: All previously issued tokens will become invalid

## Questions?

Open an issue in the [linux-ctfs repository](https://github.com/learntocloud/linux-ctfs).
