import os
import sys
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io


def get_credentials(service_account_json):
    """Load credentials from a file path or a raw JSON string."""
    if os.path.isfile(service_account_json):
        return service_account.Credentials.from_service_account_file(service_account_json)
    else:
        info = json.loads(service_account_json)
        return service_account.Credentials.from_service_account_info(info)


def download_file(service, file_id, output_path):
    """Download a single file from Google Drive."""
    request = service.files().get_media(fileId=file_id)
    fh = io.FileIO(output_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        status, done = downloader.next_chunk()
        print(f"Downloading {output_path}: {int(status.progress() * 100)}%")


def main(service_account_json, output_dir, folder_id):
    """Download all files from a Google Drive folder."""
    creds = get_credentials(service_account_json)
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
    if len(sys.argv) != 4:
        print("Usage: python gdrive_download.py <service_account_json_or_path> <output_dir> <folder_id>")
        sys.exit(1)

    service_account_json = sys.argv[1]
    output_dir = sys.argv[2]
    folder_id = sys.argv[3]

    main(service_account_json, output_dir, folder_id)
