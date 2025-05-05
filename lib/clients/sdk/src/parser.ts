import { Command, RecipeDefinition, Namespace, Parameter } from './types';

/**
 * Parse the output of 'just --list --unsorted --show-hidden'
 * @param output Output from the just list command
 * @returns Array of parsed commands
 */
export function parseJustfileCommands(output: string): Command[] {
  const commands: Command[] = [];
  
  // Split by lines and remove the header
  const lines = output.split('\n').filter(line => line.trim().length > 0);
  
  // Skip the header line if it exists
  const startIndex = lines[0].includes('Available recipes:') ? 1 : 0;
  
  for (let i = startIndex; i < lines.length; i++) {
    const line = lines[i].trim();
    
    // Parse the command name and description
    const match = line.match(/^([a-zA-Z0-9_-]+(?:\:[a-zA-Z0-9_-]+)?)(?:\s+(.*))?$/);
    
    if (match) {
      const [, fullName, description = ''] = match;
      
      // Check if the command has a namespace
      const [namespace, name] = fullName.includes(':') 
        ? fullName.split(':') 
        : [undefined, fullName];
      
      const command: Command = {
        name: fullName,
        shortName: name,
        namespace: namespace as Namespace,
        description: description.trim(),
        parameters: parseParameters(description),
      };
      
      commands.push(command);
    }
  }
  
  return commands;
}

/**
 * Parse parameters from a command description
 * @param description Command description
 * @returns Array of parsed parameters
 */
function parseParameters(description: string): Parameter[] {
  const parameters: Parameter[] = [];
  
  // Look for parameter patterns like [name], [name: type], [name=default]
  const paramRegex = /\[([a-zA-Z0-9_-]+)(?::([a-zA-Z0-9_-]+))?(?:=([^\]]+))?\]/g;
  let match;
  
  while ((match = paramRegex.exec(description)) !== null) {
    const [, name, type = 'string', defaultValue] = match;
    
    parameters.push({
      name,
      type: type || 'string',
      defaultValue,
      required: defaultValue === undefined,
    });
  }
  
  return parameters;
}