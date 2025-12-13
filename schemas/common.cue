package schemas

#Person: {
    id: string & =~"^[a-z][a-z0-9_]*$"
    name: string
    email?: string
}

#DateRange: {
    start: string & =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
    end: string & =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
}

#Manifest: {
    version: string & =~"^[0-9]+\\.[0-9]+$"
    domain: "health" | "finance"
    timestamp: string
    contentHash: string & =~"^sha256:[a-f0-9]{64}$"
    inputs: [string]: string
    outputs: [...#OutputFile]
}

#OutputFile: {
    file: string
    hash: string & =~"^sha256:[a-f0-9]{64}$"
}
