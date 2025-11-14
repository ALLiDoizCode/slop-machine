/**
 * Process validation utilities for CLI commands
 * Validates process.json metadata before deployment and publishing
 */

import fs from 'fs/promises';
import path from 'path';
import chalk from 'chalk';
import { z } from 'zod';
import {
  ProcessMetadataSchema,
  validateProcessMetadata,
  safeValidateProcessMetadata,
  formatValidationError,
  type ProcessMetadata
} from '../schemas/process-schema';

/**
 * Load and validate process.json from a directory
 * @param processDir - Path to process directory
 * @returns Validated ProcessMetadata
 * @throws Error if file not found or validation fails
 */
export async function loadAndValidateProcessMetadata(processDir: string): Promise<ProcessMetadata> {
  const metadataPath = path.join(processDir, 'process.json');

  // Check file exists
  try {
    await fs.access(metadataPath);
  } catch (error) {
    throw new Error(
      `process.json not found in ${processDir}\n` +
      `  Expected: ${metadataPath}\n` +
      `  Create one with: permamind init`
    );
  }

  // Read and parse JSON
  let rawData: unknown;
  try {
    const content = await fs.readFile(metadataPath, 'utf-8');
    rawData = JSON.parse(content);
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error(
        `process.json contains invalid JSON:\n` +
        `  ${error.message}\n` +
        `  File: ${metadataPath}`
      );
    }
    throw error;
  }

  // Validate against schema
  const result = safeValidateProcessMetadata(rawData);

  if (!result.success) {
    const formattedError = formatValidationError(result.error);
    throw new Error(
      `${formattedError}\n\n` +
      `  File: ${metadataPath}\n` +
      `  Fix the errors above and try again.`
    );
  }

  return result.data;
}

/**
 * Validate process.lua file exists and has valid Lua syntax
 * @param processDir - Path to process directory
 * @returns Path to validated process.lua file
 * @throws Error if file not found or invalid syntax
 */
export async function validateProcessLuaFile(processDir: string): Promise<string> {
  const luaPath = path.join(processDir, 'src', 'process.lua');
  const fallbackPath = path.join(processDir, 'process.lua');

  // Try src/process.lua first, then fallback to process.lua
  let finalPath: string;
  try {
    await fs.access(luaPath);
    finalPath = luaPath;
  } catch {
    try {
      await fs.access(fallbackPath);
      finalPath = fallbackPath;
    } catch {
      throw new Error(
        `process.lua not found in ${processDir}\n` +
        `  Expected: ${luaPath} OR ${fallbackPath}\n` +
        `  Create one with: permamind init`
      );
    }
  }

  // Basic Lua syntax check (look for common errors)
  const content = await fs.readFile(finalPath, 'utf-8');

  // Check for required SDK import
  if (!content.includes('require') || !content.includes('permamind')) {
    console.warn(
      chalk.yellow('\n⚠️  Warning: process.lua does not appear to import Permamind SDK\n') +
      chalk.gray('  Expected: local permamind = require("permamind")\n')
    );
  }

  // Check for handler registration
  if (!content.includes('Handlers.add')) {
    console.warn(
      chalk.yellow('\n⚠️  Warning: process.lua does not appear to register any handlers\n') +
      chalk.gray('  Expected: Handlers.add(...)\n')
    );
  }

  return finalPath;
}

/**
 * Display validation errors in user-friendly format
 * @param error - Error from validation
 */
export function displayValidationError(error: Error): void {
  console.error(chalk.red('\n✗ Validation Failed\n'));

  if (error instanceof z.ZodError) {
    const formatted = formatValidationError(error);
    console.error(chalk.gray(formatted));
  } else {
    console.error(chalk.gray(error.message));
  }

  console.error(chalk.cyan('\n💡 Tip: Check the process.json schema documentation'));
  console.error(chalk.gray('  Run: permamind init --help\n'));
}

/**
 * Create example process.json with default values
 * @param name - Process name
 * @param options - Additional options
 * @returns ProcessMetadata object
 */
export function createExampleMetadata(
  name: string,
  options: {
    description?: string;
    defaultPrice?: number;
    capabilities?: string[];
  } = {}
): ProcessMetadata {
  return {
    name,
    version: '1.0.0',
    description: options.description || `Payment-gated ${name} service`,
    pricing: {
      DefaultAction: options.defaultPrice || 1000000
    },
    skills: [],
    capabilities: options.capabilities || [],
  };
}

/**
 * Save process metadata to process.json
 * @param processDir - Target directory
 * @param metadata - ProcessMetadata to save
 */
export async function saveProcessMetadata(
  processDir: string,
  metadata: ProcessMetadata
): Promise<void> {
  const metadataPath = path.join(processDir, 'process.json');

  // Validate before saving
  validateProcessMetadata(metadata);

  // Pretty-print JSON
  const content = JSON.stringify(metadata, null, 2);

  await fs.writeFile(metadataPath, content, 'utf-8');
}

/**
 * Update specific fields in process.json
 * @param processDir - Process directory
 * @param updates - Partial metadata updates
 */
export async function updateProcessMetadata(
  processDir: string,
  updates: Partial<ProcessMetadata>
): Promise<ProcessMetadata> {
  // Load existing metadata
  const existing = await loadAndValidateProcessMetadata(processDir);

  // Merge updates
  const updated = {
    ...existing,
    ...updates,
    updatedAt: Date.now()
  };

  // Validate merged result
  const validated = validateProcessMetadata(updated);

  // Save
  await saveProcessMetadata(processDir, validated);

  return validated;
}
