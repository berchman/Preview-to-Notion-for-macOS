Preview to Notion for macOS
Version 1.0
Author Bert Mahoney

----
Overview

This tool allows you to send an image from macOS directly into a Notion database.
It prompts for a custom page title, creates a new page in your database, sets a Type property to Image, uploads the file, and appends it as an Image block.

----
Requirements

macOS Ventura or newer recommended
Homebrew installed
jq installed
A Notion Internal Integration

----
To install jq if needed, run:

brew install jq

----
All Install Commands

mkdir -p "$HOME/.config/preview-to-notion"

cat > "$HOME/.config/preview-to-notion/.env" <<'EOF'
NOTION_TOKEN="ntn_PASTE_YOUR_TOKEN_HERE"
NOTES_DB_ID="PASTE_YOUR_DATABASE_ID_HERE"
NOTES_DATA_SOURCE_ID="PASTE_YOUR_DATA_SOURCE_ID_HERE"
EOF

mkdir -p "$HOME/.local/bin"

cp "./scripts/send_to_notion_image.sh" "$HOME/.local/bin/send_to_notion_image.sh"

chmod +x "$HOME/.local/bin/send_to_notion_image.sh"

"$HOME/.local/bin/send_to_notion_image.sh" "/path/to/your/test-image.jpg"

----
Step 1 Create a Notion Internal Integration
	1.	Open Notion.
	2.	Go to Settings then Connections then Develop or manage integrations.
	3.	Click New integration.
	4.	Choose Type Internal.
	5.	Copy the generated token. It will start with ntn_.
	6.	Open your target Notion database.
	7.	Click Share.
	8.	Invite your integration.
	9.	Grant Edit access.

If you skip this step you will receive either 401 unauthorized or 404 object_not_found errors.

Step 2 Get Required IDs

Step 2.1 Get Your Database ID
	1.	Open your database in Notion.
	2.	Click the three dot menu in the top right.
	3.	Click Copy link.

Example link:

https://www.notion.so/164ffa30cf0b81b1929ae59d8b6afabb?v=…

Database ID example:

164ffa30cf0b81b1675ae59d8b6afabb

Step 2.2 Get Your Data Source ID

This is required for Notion API version 2025-09-03 and later.

Method A Recommended
	1.	Open your database.
	2.	Click the three dot menu.
	3.	Select Manage data sources.
	4.	Copy the Data Source ID.

Method B Using Terminal

Replace YOUR_DATABASE_ID and YOUR_TOKEN below.

DB_ID=“YOUR_DATABASE_ID”

curl -sS “https://api.notion.com/v1/databases/$DB_ID”
-H “Authorization: Bearer YOUR_TOKEN”
-H “Notion-Version: 2025-09-03”
| jq -r ‘.data_sources[0].id’

Step 3 Configure Your Local Environment

Create a configuration directory:

mkdir -p “$HOME/.config/preview-to-notion”

Create your environment file:

nano “$HOME/.config/preview-to-notion/.env”

Add the following lines and replace with your actual values:

NOTION_TOKEN=“ntn_YOUR_TOKEN”
NOTES_DB_ID=“YOUR_DATABASE_ID”
NOTES_DATA_SOURCE_ID=“YOUR_DATA_SOURCE_ID”

Save and exit.

Step 4 Install the Script

Create a local bin directory if it does not exist:

mkdir -p “$HOME/.local/bin”

Copy the script:

cp scripts/send_to_notion_image.sh “$HOME/.local/bin/send_to_notion_image.sh”

Make it executable:

    chmod +x “$HOME/.local/bin/send_to_notion_image.sh”

Step 5 Configure the macOS Shortcut
	1.	Open the Shortcuts app.
	2.	Create a new shortcut named Send Image to Notion.
	3.	Add an action Run Shell Script.
	4.	Set the script to:

/Users/YOUR_USERNAME/.local/bin/send_to_notion_image.sh “$@”
	5.	Set input to be passed as arguments.
	6.	Enable Use as Quick Action.
	7.	Enable Show in Share Sheet.
	8.	Set it to receive Images.

Usage

Open an image in Preview.
Click Share.
Select Send Image to Notion.
Enter a page title when prompted.
The page will be created and the image uploaded automatically.

Troubleshooting

401 unauthorized means your token is invalid or incorrectly copied.
404 object_not_found means the database is not shared with your integration or the ID is incorrect.
If the script cannot find jq, install it with brew install jq.

Security Notes

Do not commit your Notion token to GitHub.
Keep your .env file private.

License

MIT License

Copyright (c) 2026 Bert Mahoney

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
