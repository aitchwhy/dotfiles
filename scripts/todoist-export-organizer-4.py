import tkinter as tk
from tkinter import ttk, scrolledtext
import json
import requests
import re
from typing import List, Dict
from datetime import datetime
import threading
from pathlib import Path
import keyring
import os

class TodoistExporter:
    def __init__(self, todoist_token: str):
        self.todoist_token = todoist_token
        self.todoist_api = "https://api.todoist.com/rest/v2"
        self.headers = {"Authorization": f"Bearer {self.todoist_token}"}

    def get_all_tasks(self) -> List[Dict]:
        """Fetch all tasks from Todoist"""
        response = requests.get(f"{self.todoist_api}/tasks", headers=self.headers)
        response.raise_for_status()
        return response.json()

    def get_or_create_project(self, project_name: str) -> str:
        """Get or create a project by name"""
        # Get all projects
        projects = requests.get(f"{self.todoist_api}/projects", headers=self.headers).json()
        
        # Look for existing project
        for project in projects:
            if project['name'] == project_name:
                return project['id']
        
        # Create new project if not found
        response = requests.post(
            f"{self.todoist_api}/projects",
            headers=self.headers,
            json={"name": project_name}
        )
        response.raise_for_status()
        return response.json()['id']

    def get_or_create_label(self, label_name: str) -> str:
        """Get or create a label by name"""
        # Get all labels
        labels = requests.get(f"{self.todoist_api}/labels", headers=self.headers).json()
        
        # Look for existing label
        for label in labels:
            if label['name'] == label_name:
                return label['id']
        
        # Create new label if not found
        response = requests.post(
            f"{self.todoist_api}/labels",
            headers=self.headers,
            json={"name": label_name}
        )
        response.raise_for_status()
        return response.json()['id']

    def is_valid_url(self, url: str) -> bool:
        """
        Validate URL format and scheme
        - Must start with http:// or https://
        - Must not contain whitespace
        - Must not contain invalid URL characters
        """
        url = url.strip()
        if not url:
            return False
        
        # Check for valid scheme
        if not url.startswith(('http://', 'https://')):
            return False
            
        # Basic URL validation using urlparse
        try:
            from urllib.parse import urlparse
            result = urlparse(url)
            return all([result.scheme, result.netloc])
        except Exception:
            return False

    def clean_title(self, title: str) -> str:
        """
        Clean and validate the title
        - Remove leading/trailing whitespace
        - Remove newlines
        - Ensure non-empty
        """
        if not title:
            return ""
        
        # Remove newlines and excessive whitespace
        title = ' '.join(title.split())
        return title.strip()

    def filter_url_tasks(self, tasks: List[Dict]) -> List[Dict]:
        """
        Filter tasks that contain valid Markdown-style links [title](url)
        Returns only tasks with properly formatted links and valid URLs
        """
        # Match [...](...)
        markdown_link_pattern = re.compile(
            r'\[([^\]]+)\]\(((?:http[s]?://)[^)\s]+)\)'
        )
        
        valid_tasks = []
        for task in tasks:
            content = task.get('content', '')
            match = markdown_link_pattern.search(content)
            
            if match:
                title = self.clean_title(match.group(1))
                url = match.group(2)
                
                # Only include if both title and URL are valid
                if title and self.is_valid_url(url):
                    valid_tasks.append(task)
        
        return valid_tasks

    def extract_url_and_title(self, content: str) -> tuple[str, str] | None:
        """
        Extract and validate URL and title from Markdown-style link
        Returns (url, title) tuple if valid, None otherwise
        """
        # Match [...](...)
        markdown_link_pattern = re.compile(
            r'\[([^\]]+)\]\(((?:http[s]?://)[^)\s]+)\)'
        )
        
        match = markdown_link_pattern.search(content)
        if not match:
            return None
            
        title = self.clean_title(match.group(1))
        url = match.group(2)
        
        if not title or not self.is_valid_url(url):
            return None
            
        return url, title

    def export_tasks(self, tasks: List[Dict], filepath: str):
        """Export tasks to JSON file"""
        export_data = []
        for task in tasks:
            result = self.extract_url_and_title(task['content'])
            if result:
                url, title = result
                export_data.append({
                    'title': title,
                    'url': url,
                    'todoist_id': task['id'],
                    'created': task.get('created', ''),
                    'labels': task.get('labels', []),
                    'project_id': task.get('project_id', '')
                })
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, indent=2, ensure_ascii=False)

    def update_task(self, task_id: str, project_id: str, label_id: str) -> bool:
        """Update task with new project and label"""
        try:
            # Get current task
            task = requests.get(f"{self.todoist_api}/tasks/{task_id}", headers=self.headers).json()
            
            # Prepare labels (add new label while preserving existing ones)
            labels = task.get('labels', [])
            if label_id not in labels:
                labels.append(label_id)
            
            # Update task
            response = requests.post(
                f"{self.todoist_api}/tasks/{task_id}",
                headers=self.headers,
                json={
                    "project_id": project_id,
                    "labels": labels
                }
            )
            response.raise_for_status()
            return True
        except requests.exceptions.RequestException:
            return False

class TodoistExporterGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Todoist URL Tasks Exporter")
        self.root.geometry("600x700")
        
        # Create main frame with padding
        main_frame = ttk.Frame(root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Token Input Section
        self.create_token_section(main_frame)
        
        # Status and Progress Section
        self.create_status_section(main_frame)
        
        # Buttons Section
        self.create_button_section(main_frame)
        
        # Load saved token if it exists
        self.load_saved_token()
        
        # Configure grid weights
        root.columnconfigure(0, weight=1)
        root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)

    def create_token_section(self, parent):
        # Todoist Token
        ttk.Label(parent, text="Todoist API Token:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.todoist_token = ttk.Entry(parent, width=50, show="•")
        self.todoist_token.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=5)
        
        # Show/Hide Todoist Token
        self.todoist_show_var = tk.BooleanVar()
        ttk.Checkbutton(parent, text="Show", variable=self.todoist_show_var, 
                       command=lambda: self.toggle_token_visibility(self.todoist_token, self.todoist_show_var)
        ).grid(row=0, column=2, padx=5)

    def create_status_section(self, parent):
        # Status Log
        ttk.Label(parent, text="Status Log:").grid(row=2, column=0, sticky=tk.W, pady=5)
        self.status_log = scrolledtext.ScrolledText(parent, height=20, width=60)
        self.status_log.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=5)
        
        # Progress Bar
        self.progress = ttk.Progressbar(parent, length=300, mode='determinate')
        self.progress.grid(row=4, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=5)

    def create_button_section(self, parent):
        button_frame = ttk.Frame(parent)
        button_frame.grid(row=5, column=0, columnspan=3, pady=10)
        
        # Save Token Button
        ttk.Button(button_frame, text="Save Token", 
                  command=self.save_token).grid(row=0, column=0, padx=5)
        
        # Start Export Button
        ttk.Button(button_frame, text="Start Export & Organize", 
                  command=self.start_process).grid(row=0, column=1, padx=5)
        
        # Clear Log Button
        ttk.Button(button_frame, text="Clear Log", 
                  command=self.clear_log).grid(row=0, column=2, padx=5)

    def toggle_token_visibility(self, entry_widget, show_var):
        entry_widget.config(show="" if show_var.get() else "•")

    def load_saved_token(self):
        try:
            todoist_token = keyring.get_password("todoist_exporter", "todoist_token")
            if todoist_token:
                self.todoist_token.insert(0, todoist_token)
                self.log_message("Loaded saved token")
        except Exception as e:
            self.log_message(f"Error loading saved token: {str(e)}")

    def save_token(self):
        try:
            keyring.set_password("todoist_exporter", "todoist_token", self.todoist_token.get())
            self.log_message("Token saved successfully")
        except Exception as e:
            self.log_message(f"Error saving token: {str(e)}")

    def log_message(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.status_log.insert(tk.END, f"[{timestamp}] {message}\n")
        self.status_log.see(tk.END)

    def clear_log(self):
        self.status_log.delete(1.0, tk.END)
        self.progress['value'] = 0

    def start_process(self):
        # Disable buttons during process
        for widget in self.root.winfo_children():
            if isinstance(widget, ttk.Button):
                widget.configure(state='disabled')
        
        # Start process in a separate thread
        process_thread = threading.Thread(target=self.perform_process)
        process_thread.daemon = True
        process_thread.start()

    def perform_process(self):
        try:
            exporter = TodoistExporter(self.todoist_token.get())
            
            # Validate token before proceeding
            try:
                self.log_message("Validating Todoist token...")
                requests.get(
                    "https://api.todoist.com/rest/v2/projects", 
                    headers={"Authorization": f"Bearer {self.todoist_token.get()}"}
                ).raise_for_status()
            except requests.exceptions.RequestException:
                self.log_message("❌ Invalid Todoist token. Please check your token and try again.")
                return
            
            self.log_message("Fetching tasks from Todoist...")
            tasks = exporter.get_all_tasks()
            
            url_tasks = exporter.filter_url_tasks(tasks)
            self.log_message(f"Found {len(url_tasks)} tasks with valid Markdown links")
            
            if not url_tasks:
                self.log_message("❌ No valid Markdown-formatted links found. Tasks should use format: [Title](https://example.com)")
                return
                
            # Log sample of matched tasks for verification
            if len(url_tasks) > 0:
                self.log_message("\nExample matches:")
                for task in url_tasks[:3]:  # Show up to 3 examples
                    url, title = exporter.extract_url_and_title(task['content'])
                    self.log_message(f"✓ '{title}' -> {url}")
            
            # Export tasks to Downloads folder
            downloads_path = str(Path.home() / "Downloads")
            export_filename = f"todoist_url_tasks_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            export_filepath = os.path.join(downloads_path, export_filename)
            
            self.log_message("Exporting tasks to JSON...")
            exporter.export_tasks(url_tasks, export_filepath)
            self.log_message(f"Exported tasks to: {export_filepath}")
            
            # Get or create project and label
            self.log_message("Setting up project and label...")
            project_id = exporter.get_or_create_project("clippings-export")
            label_id = exporter.get_or_create_label("clippings")
            
            # Update tasks
            self.log_message("Updating tasks in Todoist...")
            self.progress['maximum'] = len(url_tasks)
            self.progress['value'] = 0
            
            success_count = 0
            for i, task in enumerate(url_tasks):
                if exporter.update_task(task['id'], project_id, label_id):
                    success_count += 1
                self.progress['value'] = i + 1
                self.log_message(f"Processed task {i+1}/{len(url_tasks)}")
            
            self.log_message(f"\nCompleted! Successfully updated {success_count}/{len(url_tasks)} tasks")
            
        except Exception as e:
            self.log_message(f"Error during process: {str(e)}")
        
        finally:
            # Re-enable buttons
            for widget in self.root.winfo_children():
                if isinstance(widget, ttk.Button):
                    widget.configure(state='normal')

def main():
    root = tk.Tk()
    app = TodoistExporterGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
