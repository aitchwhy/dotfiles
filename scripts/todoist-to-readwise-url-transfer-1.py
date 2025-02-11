import requests
import json
from typing import List, Dict
import re
from urllib.parse import urlparse


class TodoistToReadwise:
    def __init__(self, todoist_token: str, readwise_token: str):
        self.todoist_token = todoist_token
        self.readwise_token = readwise_token
        self.todoist_api = "https://api.todoist.com/rest/v2"
        self.readwise_api = "https://readwise.io/api/v2"

    def get_all_tasks(self) -> List[Dict]:
        """Fetch all tasks from Todoist"""
        headers = {"Authorization": f"Bearer {self.todoist_token}"}
        response = requests.get(f"{self.todoist_api}/tasks", headers=headers)
        response.raise_for_status()
        return response.json()

    def filter_url_tasks(self, tasks: List[Dict]) -> List[Dict]:
        """Filter tasks that contain URLs"""
        url_pattern = re.compile(
            r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"
        )
        return [task for task in tasks if url_pattern.search(task["content"])]

    def extract_url(self, content: str) -> str:
        """Extract URL from task content"""
        url_pattern = re.compile(
            r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"
        )
        match = url_pattern.search(content)
        return match.group(0) if match else None

    def send_to_readwise(self, url_tasks: List[Dict]) -> List[Dict]:
        """Send URLs to Readwise"""
        headers = {
            "Authorization": f"Token {self.readwise_token}",
            "Content-Type": "application/json",
        }

        results = []
        for task in url_tasks:
            url = self.extract_url(task["content"])
            if url:
                data = {"url": url, "title": task["content"], "source": "todoist"}
                response = requests.post(
                    f"{self.readwise_api}/highlights/", headers=headers, json=data
                )
                results.append(
                    {
                        "task_id": task["id"],
                        "url": url,
                        "success": response.status_code == 200,
                    }
                )

        return results


def main():
    # Replace with your tokens
    # todoist_token = "YOUR_TODOIST_TOKEN"
    # readwise_token = "YOUR_READWISE_TOKEN"
    todoist_token = "dbc3b89c72dc12b7daf0d4fa1bb9e287b543160f"
    readwise_token = "YOUR_READWISE_TOKEN"

    processor = TodoistToReadwise(todoist_token, readwise_token)

    # Get all tasks
    print("Fetching tasks from Todoist...")
    tasks = processor.get_all_tasks()

    # Filter URL tasks
    url_tasks = processor.filter_url_tasks(tasks)
    print(f"Found {len(url_tasks)} tasks with URLs")

    return 1

    # Send to Readwise
    print("Sending to Readwise...")
    results = processor.send_to_readwise(url_tasks)

    # Print results
    successful = [r for r in results if r["success"]]
    print(f"\nSuccessfully sent {len(successful)} URLs to Readwise")

    if len(successful) != len(results):
        print("\nFailed transfers:")
        for result in results:
            if not result["success"]:
                print(f"- Task {result['task_id']}: {result['url']}")


if __name__ == "__main__":
    main()
