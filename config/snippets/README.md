# Snippet Expansions Best Practices & Example Library

This README outlines **best practices** for text snippet expansions—particularly useful if you use a tool like **TextExpander**, **Espanso**, **Alfred**, **Raycast**, **Hammerspoon**, **Superhuman**, or similar. It also includes a **curated snippet library** from both our previously suggested examples and the **attached image** (see [New Private Snippets from Attached Image](#new-private-snippets-from-attached-image)). Finally, it explains **how to track these snippets in a GitHub repo** so you can keep them synchronized across multiple devices and apps on macOS (e.g., neovim, VSCode, zsh shell on “Ghostty IDE,” Raycast, Hammerspoon, or Superhuman).

---

## Table of Contents

1. [Introduction](#introduction)
2. [Why Use Snippet Expansions](#why-use-snippet-expansions)
3. [Abbreviation Conventions](#abbreviation-conventions)
4. [Keyboard Shortcuts & Expansion Behavior](#keyboard-shortcuts--expansion-behavior)
5. [Organizing Snippets into Categories](#organizing-snippets-into-categories)
6. [Dynamic Fill-In Fields](#dynamic-fill-in-fields)
7. [Suggested Snippets](#suggested-snippets)
   - [General Use](#general-use)
   - [Professional Email](#professional-email)
   - [Backend Programmer](#backend-programmer)
   - [Data Analyst](#data-analyst)
   - [Project Management](#project-management)
   - [Obsidian Note-Taking](#obsidian-note-taking)
   - [New Private Snippets from Attached Image](#new-private-snippets-from-attached-image)
8. [Tracking Snippets in a GitHub Repo](#tracking-snippets-in-a-github-repo)
   - [1. Creating a Dedicated Repo](#1-creating-a-dedicated-repo)
   - [2. Local Setup on Each Device](#2-local-setup-on-each-device)
   - [3. Adding/Editing Snippets in Source Control](#3-addingediting-snippets-in-source-control)
   - [4. Optional Cloud Sync Integration](#4-optional-cloud-sync-integration)
   - [5. Making Apps Read from the Repo](#5-making-apps-read-from-the-repo)
9. [Recommended Keyboard Shortcuts](#recommended-keyboard-shortcuts)
10. [Final Tips & References](#final-tips--references)

---

## Introduction

Snippets are short text triggers that **automatically expand** into longer text (or dynamic templates). By standardizing snippet usage, you reduce repetitive typing, maintain consistency, and boost productivity in day-to-day tasks—whether emailing, coding, writing meeting notes, or analyzing data.

---

## Why Use Snippet Expansions

- **Save Time**: Avoid retyping boilerplate or repetitive text.
- **Ensure Consistency**: Keep consistent language and formatting across messages, docs, or code.
- **Reduce Typos**: Long or repeated phrases (like URLs or addresses) can be error-prone to type out.
- **Speed Up Workflows**: Dynamic fields let you fill in only the changing parts.

---

## Abbreviation Conventions

1. **Use a Distinct Trigger Prefix**

   - Commonly `;`, `,`, or `\\`.
   - Example: `;addr` → expands to your full address.

2. **Be Short but Descriptive**

   - `;tyvm` (thank you very much), `;me` (your name), etc.

3. **Prefix by Category**

   - `;e-...` for emails, `;c-...` for code, `;p-...` for phone numbers, etc.

4. **Avoid Overlaps**
   - If you have `;ty` for “Thank you,” don’t also create `;tya` for “Thank you again” if it might overlap or conflict.

---

## Keyboard Shortcuts & Expansion Behavior

1. **Snippet Search Shortcut**

   - E.g., `⌥ + Space` to open a snippet search. Type partial snippet names, select to insert.

2. **Toggle or Pause Snippets**

   - A quick way to disable expansions if you need to type something literally (like code that resembles your snippet abbreviation).

3. **Use Delimiters**
   - Decide whether expansions trigger **immediately** or only once you press space, tab, or punctuation.

---

## Organizing Snippets into Categories

1. **General Use**: Quick phrases, addresses, phone numbers, sign-offs, etc.
2. **Professional Email**: Intros, sign-offs, disclaimers, boilerplate replies.
3. **Backend Programming**: Code templates, server commands, logs, cURL calls.
4. **Data Analysis**: Python or R code snippets for dataframes, visualizations, etc.
5. **Project Management**: Meeting notes, to-do templates, issue & PR templates.
6. **Obsidian Note-Taking**: Daily or weekly journaling, knowledge-base templates.

Keeping them grouped helps you stay organized and quickly locate or update relevant snippets.

---

## Dynamic Fill-In Fields

Many snippet managers (e.g., TextExpander, Raycast, Espanso) support **fill-in fields** that prompt you for user input.

- Example: `"Hello, %filltext:name=FirstName%, thanks for your interest in %filltext:name=ProductName%."`

When triggered, you’ll see a pop-up with fields for **FirstName** and **ProductName**.

---

## Suggested Snippets

Below is a **curated set** of snippet examples. Adapt them to your snippet manager’s syntax.

### General Use

| Abbrev   | Expansion (Example)                                                                      | Notes                                      |
| -------- | ---------------------------------------------------------------------------------------- | ------------------------------------------ |
| `;addr`  | **Multiline** address: <br/>`123 Example St\nCity, State 12345`                          | Home / office address.                     |
| `;cell`  | `+1 (202) 123-4567`                                                                      | Your phone number.                         |
| `;e`     | `yourname@example.com`                                                                   | Short email snippet.                       |
| `;date`  | Dynamically inserts today’s date (e.g., `April 15, 2025`)                                | Manager date placeholders.                 |
| `;time`  | Dynamically inserts current time (e.g., `10:24 AM`)                                      | Another date/time placeholder usage.       |
| `;ty`    | “Thank you,”                                                                             | Quick sign-off phrase.                     |
| `;tyvm`  | “Thank you very much!”                                                                   | Another quick sign-off.                    |
| `;sig`   | “**Name**<br/>**Title**<br/>**Company**<br/>**Phone**<br/>**Email**”                     | Your standard signature with minimal HTML. |
| `;intro` | “Thanks %filltext:name=FirstName% for the intro! Moving you to BCC to spare your inbox.” | Example fill-in.                           |

### Professional Email

| Abbrev       | Expansion                                                                                         | Notes                                     |
| ------------ | ------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `;p-ack`     | “Thanks for your email. I will review and get back to you shortly.”                               | A short acknowledgement.                  |
| `;p-follow`  | “Just following up on the conversation from %filltext:name=Date%—any updates?”                    | References a date fill-in.                |
| `;p-meet`    | “Would you be available for a quick 30-min call on %filltext:name=Date% at %filltext:name=Time%?” | Two fill-in fields for date/time.         |
| `;p-legal`   | A disclaimer or NDA snippet.                                                                      | Long text with disclaimers or legal text. |
| `;p-closing` | “If there’s anything else you need, please let me know. Thanks!”                                  | Standard closing line.                    |

### Backend Programmer

| Abbrev      | Expansion                                                                                                          | Notes                               |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ----------------------------------- |
| `;dev-api`  | `js<br/>fetch('https://api.example.com/v1/%filltext:name=endpoint%', {<br/>  method: 'GET'<br/>})`                 | Quick fill-in for an API call.      |
| `;docker`   | `docker run -it --rm --name %filltext:name=ContainerName% %filltext:name=ImageName%:latest`                        | Docker run command with fill-ins.   |
| `;logs`     | `docker logs -f %filltext:name=ContainerName%`                                                                     | Tail logs snippet.                  |
| `;dev-curl` | `curl -X GET "https://api.example.com/v1/%filltext:name=endpoint%?token=YOUR_TOKEN" -H "Accept: application/json"` | cURL snippet with dynamic endpoint. |
| `;env`      | `dotenv<br/>DB_HOST=localhost<br/>DB_USER=admin<br/>DB_PASS=password`                                              | Common `.env` file template.        |

### Data Analyst

| Abbrev       | Expansion                                                                                              | Notes                                   |
| ------------ | ------------------------------------------------------------------------------------------------------ | --------------------------------------- |
| `;da-import` | `py<br/>import pandas as pd<br/>df = pd.read_csv('%filltext:name=FilePath%')<br/>df.head()`            | Basic CSV import snippet in Python.     |
| `;da-stats`  | `py<br/>df.describe()`                                                                                 | Quick data summary.                     |
| `;da-plot`   | `py<br/>import matplotlib.pyplot as plt<br/>df['%filltext:name=Column%'].hist(bins=20)<br/>plt.show()` | Basic histogram snippet.                |
| `;da-info`   | `py<br/>df.info()`                                                                                     | Show DataFrame schema info.             |
| `;da-sql`    | `sql<br/>SELECT *<br/>FROM %filltext:name=TableName%<br/>WHERE %filltext:name=Condition%;`             | A common SQL snippet for quick queries. |

### Project Management

| Abbrev     | Expansion                                                                                                                                                        | Notes                                |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------- | ------------------ |
| `;pm-task` | “**Task**: %filltext:name=TaskTitle%<br/>**Due**: %filltext:name=DueDate%<br/>**Owner**: %filltext:name=OwnerName%<br/>**Notes**: <br/> - [ ]”                   | Basic fill-in for creating tasks.    |
| `;pm-mtg`  | `md<br/># Meeting: %filltext:name=Title% (%filldate%)<br/><br/>## Agenda<br/>- <br/><br/>## Notes<br/>- <br/><br/>## Action Items<br/>- [ ] <br/>`               | Meeting notes template with fill-in. |
| `;pm-wrap` | “**Wrap-up**: Thanks everyone for attending. Next steps: %filltext:name=NextSteps%. Let’s reconvene on %filltext:name=NextMeetingDate%.”                         | Email wrap-up snippet.               |
| `;pm-risk` | “**Risk**: %filltext:name=RiskDescription%<br/>**Severity**: %fillpopup:name=Severity:High                                                                       | Medium                               | Low%<br/>**Mitigation**: <br/> - [ ]” | For risk tracking. |
| `;pm-ghpr` | `md<br/>Fixes #%filltext:name=IssueNumber%<br/><br/>## Proposed Changes<br/>- <br/>- <br/>- <br/><br/>## Screenshots<br/>- <br/><br/>## Additional Context<br/>` | GitHub PR template with fill-in.     |

### Obsidian Note-Taking

| Abbrev       | Expansion                                                                                                                                             | Notes                                           |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------- |
| `;obs-daily` | `md<br/># Daily Note (%filldate%)<br/><br/>## Goals<br/>- [ ] <br/><br/>## Events<br/>- <br/><br/>## Notes<br/>- <br/><br/>## Reflection<br/>- <br/>` | Basic daily note template in Obsidian Markdown. |
| `;obs-week`  | `md<br/># Weekly Plan (%filldate%)<br/><br/>## Objectives<br/>- <br/><br/>## Key Projects<br/>- <br/><br/>## Schedule<br/>- <br/><br/>## Review<br/>` | Weekly overview note.                           |
| `;obs-link`  | `[[%filltext:name=LinkTitle%                                                                                                                          | %filltext:name=Alias%]]`                        | Create an Obsidian wiki link with fill-in for link text and alias display. |
| `;obs-code`  | \`\`\`%fillpopup:name=Language:js                                                                                                                     | python                                          | bash<br/>%filltext:name=Code%<br/>\`\`\`                                   | Code block snippet with language selection popup. |
| `;obs-task`  | `- [ ] %filltext:name=Task%`                                                                                                                          | Quick check-list item.                          |

---

### New Private Snippets from Attached Image

Below are **snippets** seen in the attached screenshot, commonly used in **Superhuman** or other email apps:

1. **first chat 30 min scheduling (Calendly)**

Hi {first_name}, Excited to learn more about {company_name} and how I can contribute!
Here’s my Calendly link to schedule a quick 30-min chat:
<https://calendly.com/hank-lee/30min>
If none of the times work, just let me know and we’ll find something else.

2. **Schedule Calendly**

Here’s my 30-minute Calendly link for scheduling:
<https://calendly.com/hank-lee/30min>
If none of the available times work, let me know.

3. **Schedule**

Thanks {first_name}! Adding Matti on CC who will find us time to connect.

4. **Handle Rejection Email**

Hey {sender}, Sorry to hear things didn’t work out with {company_name},
but I appreciate you keeping me updated through the process.

5. **Team Progress Update**

Hey all, TL;DR: We are {on track / exceeding / off track} for {key result / milestone}.
📋 Goals {Goal}/{Milestones} {relevant links}…

6. **Meeting notes + next steps**

Hey {first_name}, Quick recap, but looking forward to our next call on {MM/DD}:
Next Steps: {Name: Actionable next step}…

7. **TODO Hank experience description**

Superhuman is the fastest email experience in the world. Our customers get through their inbox twice
as fast as before, resulting in “Inbox Zero” like never before…

8. **Zoom link**

Here is my zoom link - <https://us06web.zoom.us/j/5347018535>

9. **TODO Decline recruiter**

Hi {first_name}, Thanks for the note! I’m not interested right now, but perhaps later.

10. **Call follow-up**

```
Following up on our chat.
Hi {first_name}, Just following up on our recent chat—curious if any thoughts or ideas have come up?
```

11. **Intro Hi**

```
Hi {first_name}! 👋 I’m {your_name}, nice to meet you! I’m a {your_role} at {your_company}.
```

Feel free to adapt these for your snippet manager with placeholders (`%filltext:name=company_name%`, etc.) as needed.

---

## Tracking Snippets in a GitHub Repo

To **version-control** your snippet expansions and use them on multiple devices, we suggest the following approach:

### 1. Creating a Dedicated Repo

1. Make a **new private repo** on GitHub, e.g., `github.com/<username>/snippets`.
2. Initialize it with a `README.md` (like this file) plus a folder structure such as:

snippets/
general.json
email.json
code.json
…
README.md

3. You can keep your snippet expansions in **JSON**, **YAML**, or **markdown**—whatever your snippet manager can parse easily.

### 2. Local Setup on Each Device

1. **Clone** the repo on each machine:

```bash
git clone git@github.com:<username>/snippets.git ~/snippets

 2. (Optional) Symlink your snippet manager config folder to the relevant JSON or YAML files.
 • For example, with Raycast:

ln -s ~/snippets/raycast-snippets.json \
      ~/.config/raycast/snippets.json


 • Or if you use a dotfiles approach, you might store them in ~/.dotfiles/snippets/.

3. Adding/Editing Snippets in Source Control
 1. Create or edit snippet files in the ~/snippets directory.
 2. Commit and push changes to GitHub:

git add .
git commit -m "Add new snippet for handle rejection email"
git push


 3. On other devices, pull updates:

cd ~/snippets
git pull



4. Optional Cloud Sync Integration

If you want automatic file syncing:
 1. Place your snippets/ folder inside a cloud storage directory (e.g. iCloud Drive or Dropbox).
 2. Initialize Git there as well:

cd ~/Dropbox/snippets
git init
git remote add origin git@github.com:<username>/snippets.git


 3. Commits/pulls remain the same, but now you also get continuous cloud sync.

Pro: Automated updates across machines.
Con: Potential merge conflicts if editing from multiple devices simultaneously.

5. Making Apps Read from the Repo
 • Raycast: If using JSON for Raycast snippets, point Raycast’s snippet extension to the file in your repo.
 • Hammerspoon: Create a Lua script in ~/.hammerspoon/init.lua that loads snippet data from your cloned folder.
 • neovim / VSCode: For code snippets, you can place them in ~/snippets/ultisnips or ~/snippets/vscode and symlink to the official snippet folder.
 • zsh (Ghostty IDE): Source a .sh file in your .zshrc:

source ~/snippets/zsh_aliases.sh


 • Superhuman: Currently requires manual snippet creation in the Superhuman app, but you can keep your “source-of-truth” text in your Git repo for consistent reference. Periodically copy/paste updated text into Superhuman’s snippet UI.

Recommended Keyboard Shortcuts
 1. Snippet Search: ⌥ + Space (Option + Space)
 2. Disable Snippets: ⌃⌥⌘ + X (Control + Option + Command + X) for 30 seconds (if your snippet manager supports it)
 3. Cycle Fill-in Fields: Tab to jump forward, Shift + Tab to jump backward
 4. Expand Abbreviations Immediately: Typically triggered when you type a space or punctuation after your abbreviation (configurable per snippet tool).

Final Tips & References
 • Start Small: Add snippets as you notice repetitive text.
 • Use Fill-Ins Wisely: Great for partially changing content.
 • Security: Avoid storing extremely sensitive data (e.g., root passwords) in plain text expansions.
 • Sync: If you use multiple devices, choose your syncing approach (Git only or Git + iCloud/Dropbox).
 • Keep Learning:
 • TextExpander Docs
 • Espanso
 • Alfred Snippets
 • Raycast Snippets
 • Superhuman Snippets Guide

That’s it! Customize these examples, store them in a version-controlled Git repository, and use a sync method (if desired) to ensure your snippet library is always up-to-date across all your devices. Happy expanding!


```
