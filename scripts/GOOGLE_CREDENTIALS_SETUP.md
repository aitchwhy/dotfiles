# Google Service Account Credentials Setup

## Steps to Create Service Account:

1. **Go to Google Cloud Console**
   - Visit https://console.cloud.google.com/
   - Create a new project or select existing one

2. **Enable Google Drive API**
   - Go to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"

3. **Create Service Account**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "Service Account"
   - Fill in:
     - Service account name: `google-docs-downloader`
     - Service account ID: (auto-generated)
   - Click "Create and Continue"
   - Skip optional permissions
   - Click "Done"

4. **Create JSON Key**
   - Click on the service account you just created
   - Go to "Keys" tab
   - Click "Add Key" > "Create new key"
   - Choose "JSON" format
   - Save the downloaded file

5. **Place the Credentials File**
   ```bash
   # Create config directory
   mkdir -p ~/.config/gcloud
   
   # Move the downloaded JSON file
   mv ~/Downloads/your-project-*.json ~/.config/gcloud/google-docs-service-account.json
   
   # Set restrictive permissions
   chmod 600 ~/.config/gcloud/google-docs-service-account.json
   ```

## What the JSON File Contains:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "service-account@your-project.iam.gserviceaccount.com",
  "client_id": "1234567890",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

## Important Notes:
- **NEVER commit this file to git** (already in .gitignore)
- Keep this file secure - it provides API access to your Google account
- The service account only needs read-only access to Drive
- You may need to share specific documents with the service account email if they're private