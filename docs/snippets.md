# Snippet Expansions Best Practices & Example Library

This README outlines **best practices** for text snippet expansions—particularly useful if you use a tool like **TextExpander**, **Espanso**, **Alfred**, or **Raycast**. It also includes a **curated snippet library** with **dynamic fill-in** examples, organized by use case:

- **General Use**
- **Professional Email**
- **Backend Programming**
- **Data Analysis**
- **Project Management**
- **Obsidian Note-Taking** (Apple Silicon macOS)

Feel free to adapt these snippets or abbreviations to your favorite snippet manager.

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
8. [Recommended Keyboard Shortcuts](#recommended-keyboard-shortcuts)
9. [Final Tips & References](#final-tips--references)

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
   - Commonly `;` (semicolon) or `,` or `\\`.  
   - Example: `;addr` → expands to your full address.

2. **Be Short but Descriptive**  
   - `;tyvm` (thank you very much), `;me` (your name), etc.

3. **Prefix by Category**  
   - `;e-...` for emails, `;c-...` for code, `;p-...` for phone numbers, etc.

4. **Avoid Overlaps**  
   - If you have `;ty` for “Thank you,” don’t create `;tya` for “Thank you again”—they might partially conflict.

---

## Keyboard Shortcuts & Expansion Behavior

1. **Set a “Pop-up” Search Shortcut**  
   - E.g., `⌥ + Space` to open a snippet search. Type partial snippet names, select to insert.

2. **Toggle or Pause Snippets**  
   - A quick way to disable expansions if you need to type something literal without expansion.

3. **Use Delimiters**  
   - Decide whether expansions trigger immediately after typing the abbreviation or only once you press space, tab, or punctuation.

---

## Organizing Snippets into Categories

1. **General Use**: Quick phrases, addresses, phone numbers, sign-offs, etc.  
2. **Professional Email**: Intros, sign-offs, disclaimers, boilerplate replies.  
3. **Backend Programming**: Code templates, server commands, logs, cURL calls.  
4. **Data Analysis**: Python or R code snippets for dataframes, visualizations, etc.  
5. **Project Management**: Meeting notes, to-do templates, issue & PR templates.  
6. **Obsidian Note-Taking**: Daily or weekly journaling, knowledge-base templates.

---

## Dynamic Fill-In Fields

Many snippet managers (e.g., TextExpander) support **fill-in fields** (placeholders) to prompt you for user input.  
- Example: `"Hello, %filltext:name=FirstName%, thanks for your interest in %filltext:name=ProductName%."`

When triggered, you’ll see a pop-up with fields for **FirstName** and **ProductName**.

---

## Suggested Snippets

Below is a curated set of snippet examples by category. **Adapt them** to your needs and snippet manager’s syntax.

### General Use

| Abbrev   | Expansion (Example)                                                                              | Notes                                                                                   |
|----------|---------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `;addr`  | **Multiline** address: <br/>`123 Example St\nCity, State 12345`                                   | Home / office address.                                                                  |
| `;cell`  | `+1 (202) 123-4567`                                                                               | Your cell phone number.                                                                 |
| `;e`     | `yourname@example.com`                                                                            | Short email snippet.                                                                    |
| `;date`  | Dynamically inserts today’s date (e.g., `April 15, 2025`)                                         | Use snippet manager date placeholders.                                                  |
| `;time`  | Dynamically inserts current time (e.g., `10:24 AM`)                                              | Another date/time placeholder usage.                                                    |
| `;ty`    | “Thank you,”                                                                                     | Quick sign-off phrase.                                                                  |
| `;tyvm`  | “Thank you very much!”                                                                            | Another quick sign-off.                                                                 |
| `;cheers`| “Cheers,”                                                                                        | Informal sign-off.                                                                      |
| `;sig`   | “**Name**<br/>**Title**<br/>**Company**<br/>**Phone**<br/>**Email**”                              | Your standard signature with bold or normal text.                                       |
| `;intro` | “Thanks %filltext:name=FirstName% for the intro! Moving you to BCC to spare your inbox.”         | Example fill-in.                                                                        |

### Professional Email

| Abbrev       | Expansion                                                                                                               | Notes                                                                                          |
|--------------|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| `;p-ack`     | “Thanks for your email. I will review and get back to you shortly.”                                                     | A short acknowledgement.                                                                       |
| `;p-follow`  | “Just following up on the previous conversation from %filldate%—do you have any updates?”                               | References a date fill-in.                                                                     |
| `;p-meet`    | Email scheduling snippet: “Would you be available for a quick 30-min call on %filltext:name=Date% at %filltext:Time%?”  | Two fill-in fields for date/time.                                                              |
| `;p-legal`   | A disclaimer or NDA snippet.                                                                                            | Long text with disclaimers or legal text.                                                      |
| `;p-closing` | “If there’s anything else you need, please let me know. Thanks!”                                                        | Standard closing line.                                                                         |

### Backend Programmer

| Abbrev      | Expansion                                                                                           | Notes                                                                                               |
|-------------|------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `;dev-api`  | ```js<br/>fetch('https://api.example.com/v1/%filltext:name=endpoint%', {<br/>  method: 'GET'<br/>})``` | Quick fill-in for an API call.                                                                       |
| `;docker`   | `docker run -it --rm --name %filltext:name=ContainerName% %filltext:name=ImageName%:latest`         | Docker run command with fill-ins.                                                                    |
| `;logs`     | `docker logs -f %filltext:name=ContainerName%`                                                      | Tail logs snippet.                                                                                   |
| `;dev-curl` | `curl -X GET "https://api.example.com/v1/%filltext:name=endpoint%?token=YOUR_TOKEN" -H "Accept: application/json"` | cURL snippet with dynamic endpoint.                                               |
| `;env`      | ```dotenv<br/>DB_HOST=localhost<br/>DB_USER=admin<br/>DB_PASS=password```                           | Common `.env` template.                                                                              |

### Data Analyst

| Abbrev       | Expansion                                                                                                                       | Notes                                                                    |
|--------------|----------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `;da-import` | ```py<br/>import pandas as pd<br/>df = pd.read_csv('%filltext:name=FilePath%')<br/>df.head()```                                | Basic CSV import snippet in Python.                                      |
| `;da-stats`  | ```py<br/>df.describe()```                                                                                                      | Quick data summary.                                                      |
| `;da-plot`   | ```py<br/>import matplotlib.pyplot as plt<br/>df['%filltext:name=Column%'].hist(bins=20)<br/>plt.show()```                      | Basic histogram snippet.                                                |
| `;da-info`   | ```py<br/>df.info()```                                                                                                          | Show DF schema info.                                                     |
| `;da-sql`    | ```sql<br/>SELECT *<br/>FROM %filltext:name=TableName%<br/>WHERE %filltext:name=Condition%;```                                   | A common SQL snippet for quick queries.                                  |

### Project Management

| Abbrev     | Expansion                                                                                                                                                                    | Notes                                                                                   |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `;pm-task` | “**Task**: %filltext:name=TaskTitle%<br/>**Due**: %filltext:name=DueDate%<br/>**Owner**: %filltext:name=OwnerName%<br/>**Notes**: <br/> - [ ]”                               | Basic fill-in for creating tasks.                                                      |
| `;pm-mtg`  | ```md<br/># Meeting: %filltext:name=Title% (%filldate%)<br/><br/>## Agenda<br/>- <br/><br/>## Notes<br/>- <br/><br/>## Action Items<br/>- [ ] <br/>```                       | Meeting notes template with fill-in.                                                   |
| `;pm-wrap` | “**Wrap-up**: Thanks everyone for attending. Summary of next steps: %filltext:name=NextSteps%. Let’s reconvene on %filltext:name=NextMeetingDate%.”                         | Email wrap-up snippet.                                                                 |
| `;pm-risk` | “**Risk**: %filltext:name=RiskDescription%<br/>**Severity**: %fillpopup:name=Severity:High|Medium|Low%<br/>**Mitigation**: <br/> - [ ]”                                        | For risk tracking.                                                                     |
| `;pm-ghpr` | ```md<br/>Fixes #%filltext:name=IssueNumber%<br/><br/>## Proposed Changes<br/>- <br/>- <br/>- <br/><br/>## Screenshots (if any)<br/><br/>## Additional Context<br/>```       | GitHub PR template with fill-in.                                                       |

### Obsidian Note-Taking

*(macOS Apple Silicon–friendly, but works anywhere Obsidian is installed.)*

| Abbrev       | Expansion                                                                                                                                               | Notes                                                                            |
|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| `;obs-daily` | ```md<br/># Daily Note (%filldate%)<br/><br/>## Goals<br/>- [ ] <br/><br/>## Events<br/>- <br/><br/>## Notes<br/>- <br/><br/>## Reflection<br/>- <br/>``` | Basic daily note template in Obsidian Markdown.                                  |
| `;obs-week`  | ```md<br/># Weekly Plan (%filldate%)<br/><br/>## Objectives<br/>- <br/><br/>## Key Projects<br/>- <br/><br/>## Schedule<br/>- <br/><br/>## Review<br/>``` | Weekly overview note.                                                            |
| `;obs-link`  | `[[%filltext:name=LinkTitle%|%filltext:name=Alias%]]`                                                                                                  | Create an Obsidian wiki link with fill-in for link text and alias display.       |
| `;obs-code`  | \`\`\`%fillpopup:name=Language:js|python|bash<br/>%filltext:name=Code%<br/>\`\`\`                                                                       | Code block snippet with language selection popup.                                |
| `;obs-task`  | `- [ ] %filltext:name=Task%`                                                                                                                           | Quick check-list item.                                                           |

---

## Recommended Keyboard Shortcuts

1. **Snippet Search**: `⌥ + Space` (Option + Space)  
2. **Disable Snippets**: `⌃⌥⌘ + X` (Control + Option + Command + X) for 30 seconds  
3. **Cycle Fill-in Fields**: `Tab` to jump forward, `Shift + Tab` to jump backward  
4. **Expand Abbreviations Immediately**: Typically triggered when you type a space or punctuation after your abbreviation (configurable per manager).

---

## Final Tips & References

- **Start Small**: Add snippets as you notice repetitive text.  
- **Use Fill-Ins Wisely**: Great for partially changing content.  
- **Security**: Avoid storing extremely sensitive data (e.g., root passwords) in plain text expansions. Some snippet managers don’t fully encrypt your data.  
- **Sync**: If you use multiple devices, leverage your manager’s sync or iCloud/Dropbox.  
- **Keep Learning**:
  - [TextExpander Docs](https://textexpander.com/help)
  - [Espanso](https://espanso.org/)
  - [Alfred Snippets](https://www.alfredapp.com/help/features/snippets/)
  - [Raycast Snippets](https://www.raycast.com/)

That’s it! Customize these examples and use them consistently. Your future self (and your wrists) will thank you. 