#!/usr/bin/env python3
"""
CTF Token Verification Script

This script mimics what the verification app at https://learntocloud.guide/phase2
would do to verify a CTF completion token.
"""

import base64
import json
import hmac
import hashlib
from datetime import datetime

# Master secret (same as in ctf_setup.sh)
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
        # Step 1: Decode base64
        print(f"[1] Decoding base64 token...")
        decoded = base64.b64decode(token).decode('utf-8')
        token_data = json.loads(decoded)
        print(f"    ✓ Decoded successfully")
        
        payload = token_data.get('payload')
        signature = token_data.get('signature')
        
        if not payload or not signature:
            return {"valid": False, "error": "Invalid token structure"}
        
        print(f"\n[2] Parsed payload:")
        print(f"    - github_username: {payload.get('github_username')}")
        print(f"    - date: {payload.get('date')}")
        print(f"    - time: {payload.get('time')}")
        print(f"    - challenges: {payload.get('challenges')}")
        print(f"    - instance_id: {payload.get('instance_id')}")
        
        # Step 2: CRITICAL - Verify GitHub username matches OAuth user
        print(f"\n[3] Verifying GitHub username...")
        token_username = (payload.get('github_username') or '').lower()
        oauth_username_lower = oauth_github_username.lower()
        
        if token_username != oauth_username_lower:
            print(f"    ✗ MISMATCH: Token has '{token_username}', OAuth user is '{oauth_username_lower}'")
            return {"valid": False, "error": f"GitHub username mismatch. Token is for '{token_username}', but you signed in as '{oauth_github_username}'"}
        print(f"    ✓ Username match: {token_username}")
        
        # Step 3: Get instance ID and derive the secret
        print(f"\n[4] Deriving verification secret...")
        instance_id = payload.get('instance_id')
        if not instance_id:
            return {"valid": False, "error": "Missing instance ID"}
        
        verification_secret = derive_secret(instance_id)
        print(f"    ✓ Secret derived from MASTER_SECRET + instance_id")
        
        # Step 4: Recreate the payload string and compute signature
        print(f"\n[5] Verifying signature...")
        payload_str = json.dumps(payload, separators=(',', ':'))
        
        expected_sig = hmac.new(
            verification_secret.encode(),
            payload_str.encode(),
            hashlib.sha256
        ).hexdigest()
        
        # Step 5: Constant-time comparison
        if not hmac.compare_digest(signature, expected_sig):
            print(f"    ✗ Signature mismatch!")
            print(f"    Expected: {expected_sig}")
            print(f"    Got:      {signature}")
            return {"valid": False, "error": "Invalid signature"}
        print(f"    ✓ Signature valid!")
        
        # Step 6: Validate payload fields
        print(f"\n[6] Validating payload...")
        if payload.get('challenges') != 18:
            return {"valid": False, "error": f"Incomplete challenges: {payload.get('challenges')}/18"}
        print(f"    ✓ All 18 challenges completed")
        
        # Step 7: Check timestamp is reasonable
        timestamp = payload.get('timestamp', 0)
        now = datetime.now().timestamp()
        if timestamp > now + 3600:  # Allow 1 hour clock skew
            return {"valid": False, "error": "Invalid timestamp (in the future)"}
        print(f"    ✓ Timestamp valid")
        
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


def main():
    print("=" * 60)
    print("    Learn to Cloud - CTF Token Verification")
    print("=" * 60)
    print()
    
    # In the real app, this comes from GitHub OAuth
    oauth_username = input("Enter GitHub username (simulating OAuth login): ").strip()
    print()
    
    # Token from the user
    token = input("Paste your verification token: ").strip()
    print()
    
    print("-" * 60)
    print("                    VERIFICATION PROCESS")
    print("-" * 60)
    print()
    
    result = verify_token(token, oauth_username)
    
    print()
    print("=" * 60)
    print("                         RESULT")
    print("=" * 60)
    print()
    
    if result["valid"]:
        print("✅ VERIFICATION SUCCESSFUL!")
        print()
        print(f"   GitHub User:      {result['data']['github_username']}")
        print(f"   Completion Date:  {result['data']['date']}")
        print(f"   Completion Time:  {result['data']['completion_time']}")
        print(f"   Challenges:       {result['data']['challenges']}/18")
        print()
        print("   🎉 Congratulations on completing the Linux CTF!")
    else:
        print("❌ VERIFICATION FAILED!")
        print()
        print(f"   Error: {result['error']}")
    
    print()
    print("=" * 60)


if __name__ == "__main__":
    main()
