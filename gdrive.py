import os
import sys
import json
import base64
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.http import MediaFileUpload

import io


def get_credentials(service_account_json_or_b64):
    """Load credentials from a file path or a base64-encoded JSON string."""
    # If it's a file, load from file
    if os.path.isfile(service_account_json_or_b64):
        return service_account.Credentials.from_service_account_file(service_account_json_or_b64)
    # If it looks like base64, decode and load as JSON
    try:
        decoded = base64.b64decode(service_account_json_or_b64).decode()
        info = json.loads(decoded)
        return service_account.Credentials.from_service_account_info(info)
    except Exception:
        # If not base64, try to load as raw JSON string
        try:
            info = json.loads(service_account_json_or_b64)
            return service_account.Credentials.from_service_account_info(info)
        except Exception:
            raise ValueError(
                "Provided service_account_json_or_b64 is not a valid file path, base64 string, or raw JSON.")


def upload_file(service, file_path, folder_id):
    """Upload a single file to Google Drive folder."""
    file_metadata = {
        'name': os.path.basename(file_path),
        'parents': [folder_id]
    }
    media = MediaFileUpload(file_path, resumable=True)
    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, name'
    ).execute()
    print(
        f"Uploaded {file_path} as '{file.get('name')}' (ID: {file.get('id')})")


def upload_folder(service_account_json_or_b64, input_dir, folder_id):
    """Upload all files from a local folder to a Google Drive folder."""
    creds = get_credentials(service_account_json_or_b64)
    service = build('drive', 'v3', credentials=creds)

    # Verify folder
    metadata = service.files().get(
        fileId=folder_id, fields="id, name, mimeType").execute()
    if metadata['mimeType'] != 'application/vnd.google-apps.folder':
        raise ValueError(
            f"Drive item '{metadata['name']}' ({folder_id}) is not a folder.")

    for filename in os.listdir(input_dir):
        file_path = os.path.join(input_dir, filename)  # full path
        if os.path.isfile(file_path):
            print(f"Uploading {filename}...")
            upload_file(service, filename, folder_id)


def download_file(service, file_id, output_path):
    """Download a single file from Google Drive."""
    request = service.files().get_media(fileId=file_id)
    fh = io.FileIO(output_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        status, done = downloader.next_chunk()
        print(f"Downloading {output_path}: {int(status.progress() * 100)}%")


def download_folder(service_account_json_or_b64, output_dir, folder_id):
    """Download all files from a Google Drive folder."""
    creds = get_credentials(service_account_json_or_b64)
    service = build('drive', 'v3', credentials=creds)

    # Verify folder
    metadata = service.files().get(
        fileId=folder_id, fields="id, name, mimeType").execute()
    if metadata['mimeType'] != 'application/vnd.google-apps.folder':
        raise ValueError(
            f"Drive item '{metadata['name']}' ({folder_id}) is not a folder.")

    os.makedirs(output_dir, exist_ok=True)

    # List all files in folder
    page_token = None
    while True:
        response = service.files().list(
            q=f"'{folder_id}' in parents and mimeType != 'application/vnd.google-apps.folder'",
            spaces='drive',
            fields='nextPageToken, files(id, name)',
            pageToken=page_token
        ).execute()

        for file in response.get('files', []):
            file_path = os.path.join(output_dir, file['name'])
            download_file(service, file['id'], file_path)

        page_token = response.get('nextPageToken', None)
        if page_token is None:
            break


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python gdrive.py <download|upload> <service_account_json_b64_or_filepath> <local_dir> <folder_id>")
        sys.exit(1)

    mode = sys.argv[1].lower()
    service_account_json_or_b64 = sys.argv[2]
    local_dir = sys.argv[3]
    folder_id = sys.argv[4]

    if mode == "download":
        download_folder(service_account_json_or_b64, local_dir, folder_id)
    elif mode == "upload":
        upload_folder(service_account_json_or_b64, local_dir, folder_id)
    else:
        print("First argument must be 'download' or 'upload'.")
        sys.exit(1)
