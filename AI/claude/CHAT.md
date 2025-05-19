# Flopilot Chat and PDF Architecture

This document outlines the architecture and flow of Flopilot's chat functionality and PDF handling.

## Class Diagram

```mermaid
classDiagram
    class FloPilotRoot {
        -useState() input
        +render()
    }
    
    class PromptBox {
        -message: string
        -setMessage: function
        +handleAttachClick()
        +render()
    }
    
    class PromptController {
        +handleSend(message, stemUid, pdfUids)
    }
    
    class PdfProcessController {
        -useState() processedFiles
        +processPdf(files)
        +handlePdfChange(e)
        +handleRemovePdf()
        +isPdfProcessingMap
    }
    
    class Chat {
        +render()
    }
    
    class ChatController {
        -messages: array
        -input: string
        +handleInputChange(e)
        +handleSubmit(e)
        +append(message)
    }
    
    class ChatInput {
        -input: string
        -handleInputChange: function
        -handleSubmit: function
        +render()
    }
    
    class Message {
        -content: string
        -messageId: string
        +render()
    }
    
    class UserMessage {
        -id: string
        -content: string
        +render()
    }
    
    class AttachedFile {
        -file: File
        -isFileProcessing: boolean
        -onRemove: function
        +render()
    }
    
    class DataSourcesLabel {
        -hasAttachments: boolean
        +render()
    }
    
    class PdfStatus {
        -status: "processing" | "ready" | "error"
        -message?: string
    }
    
    class PdfProcess {
        -stemUid: string
        -pdfUids: string[]
    }
    
    class PdfExtracts {
        -result: object
        -extracts: array
    }
    
    FloPilotRoot --> PromptBox: contains
    FloPilotRoot --> SavedPromptsSection: contains
    PromptBox --> PromptController: uses
    PromptBox --> PdfProcessController: uses
    PromptBox --> AttachedFile: renders
    PromptBox --> DataSourcesLabel: renders
    Chat --> ChatController: uses
    Chat --> Message: renders
    Chat --> UserMessage: renders
    Chat --> ChatInput: contains
    PdfProcessController --> PdfStatus: uses
    PdfProcessController --> PdfProcess: uses
    ChatController --> Message: manages
```

## Sequence Diagram: Chat Flow

```mermaid
sequenceDiagram
    participant User
    participant PromptBox
    participant PdfProcessController
    participant Router
    participant ChatComponent
    participant ChatController
    participant Backend
    
    User->>PromptBox: Enters message
    User->>PromptBox: Clicks send
    PromptBox->>PromptController: handleSend(message, stemUid, pdfUids)
    PromptController->>Router: navigate to chat route with params
    Router->>ChatComponent: Render Chat component
    ChatComponent->>ChatController: Initialize with stemUid, pdfUids
    
    Note over ChatController: useEffect checks for initialMessage
    ChatController->>ChatController: append user message to messages
    ChatController->>Backend: POST request to /chat
    Backend-->>ChatController: Stream response
    ChatController->>ChatComponent: Update messages state
    ChatComponent->>Message: Render assistant message
    Message-->>User: Display message
    
    User->>ChatInput: Type response
    User->>ChatInput: Submit message
    ChatInput->>ChatController: handleSubmit(message)
    ChatController->>ChatController: append user message
    ChatController->>Backend: POST request to /chat
    Backend-->>ChatController: Stream response
    ChatController->>ChatComponent: Update messages state
    ChatComponent->>Message: Render assistant message
    Message-->>User: Display message
```

## Sequence Diagram: PDF Upload and Processing Flow

```mermaid
sequenceDiagram
    participant User
    participant PromptBox
    participant PdfProcessController
    participant Backend
    participant Router
    
    User->>PromptBox: Click Attach button
    PromptBox->>User: Show file picker dialog
    User->>PromptBox: Select PDF file(s)
    PromptBox->>PdfProcessController: handlePdfChange(files)
    PdfProcessController->>PdfProcessController: Create FormData
    PdfProcessController->>Backend: POST /pdfs/process-pdfs
    Backend-->>PdfProcessController: Return stemUid and pdfUids
    PdfProcessController->>PdfProcessController: setProcessedFiles(result)
    
    loop For each PDF
        PdfProcessController->>Backend: GET /pdfs/pdf-status/{stemUid}/{pdfUid}
        Backend-->>PdfProcessController: Return status (processing/ready/error)
        
        alt If status is "processing"
            PdfProcessController->>PdfProcessController: Set refetch interval (5s)
            PdfProcessController->>PdfProcessController: Update isPdfProcessingMap
            PdfProcessController->>PromptBox: Re-render with processing status
        else If status is "ready"
            PdfProcessController->>PdfProcessController: Update isPdfProcessingMap
            PdfProcessController->>PromptBox: Re-render with ready status
        else If status is "error"
            PdfProcessController->>PdfProcessController: Throw error
            PdfProcessController->>PromptBox: Display error message
        end
    end
    
    User->>PromptBox: Enter message and click send
    PromptBox->>Router: Navigate to chat with stemUid and pdfUids
```

## Key Technical Details

### PDF Processing Flow
- PDF files are uploaded via FormData to `/pdfs/process-pdfs` endpoint
- Backend assigns a unique stemUid and pdfUids for each uploaded file
- Frontend polls the PDF status endpoint to check processing progress
- Processing states are tracked in isPdfProcessingMap for UI feedback

### Chat Flow with PDFs
- When navigating to the chat route, stemUid and pdfUids are passed as URL parameters
- ChatController initializes with these parameters and includes them in API calls
- The backend uses the PDFs as context for the chat conversation
- User messages and AI responses use the same chat component structure

### Data Architecture
- Each chat session has a unique stemUid identifier
- PDF documents have unique pdfUids linked to the session stemUid
- Messages are streamed from the backend using AI SDK's useChat hook
- PDF processing status is polled at 5-second intervals until complete

### Technologies Used
- **TanStack Router** for routing
- **React Query** for server state management and API calls
- **AI SDK** for chat functionality
- **Zod** for schema validation

### Architectural Patterns
- **Model-View-Controller (MVC)** pattern
- Clear separation between UI components (view), business logic (controllers), and data models
- Reactive UI updates based on state changes
- Polling pattern for long-running processes
