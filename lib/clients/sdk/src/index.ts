/**
 * Main entry point for the dotfiles SDK
 * Provides programmatic access to justfile commands and AI functionality
 */
import { DotfilesSDK } from './sdk';
import * as types from './types';

export { DotfilesSDK, types };
export default DotfilesSDK;