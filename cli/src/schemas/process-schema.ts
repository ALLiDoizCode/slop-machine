/**
 * JSON Schema validation for process.json metadata
 * Uses Zod for runtime validation and TypeScript type inference
 */

import { z } from 'zod';

/**
 * AO/Arweave address validation (43 characters, base64url format)
 */
const Address43Schema = z.string()
  .length(43, 'Address must be exactly 43 characters')
  .regex(/^[a-zA-Z0-9_-]+$/, 'Address must contain only alphanumeric, underscore, and dash characters');

/**
 * Arweave transaction ID validation (43 characters)
 */
const TxIdSchema = z.string()
  .length(43, 'Transaction ID must be exactly 43 characters')
  .regex(/^[a-zA-Z0-9_-]+$/, 'TX ID must contain only alphanumeric, underscore, and dash characters');

/**
 * Semantic version validation (e.g., "1.0.0", "2.1.3-beta")
 */
const SemanticVersionSchema = z.string()
  .regex(/^\d+\.\d+\.\d+(-[a-zA-Z0-9-]+)?$/, 'Version must follow semantic versioning (e.g., "1.0.0")');

/**
 * AO token amount validation (positive integer)
 */
const AoTokenAmountSchema = z.number()
  .int('Token amount must be an integer')
  .positive('Token amount must be positive');

/**
 * Pricing configuration: map of action names to AO token amounts
 */
const PricingSchema = z.record(
  z.string().min(1, 'Action name cannot be empty'),
  AoTokenAmountSchema
).refine(
  (pricing) => Object.keys(pricing).length > 0,
  { message: 'At least one action must be defined in pricing' }
);

/**
 * Process metadata schema (process.json)
 */
export const ProcessMetadataSchema = z.object({
  name: z.string()
    .min(1, 'Process name is required')
    .max(100, 'Process name must be less than 100 characters'),

  version: SemanticVersionSchema,

  description: z.string()
    .min(10, 'Description must be at least 10 characters')
    .max(1000, 'Description must be less than 1000 characters'),

  pricing: PricingSchema,

  skills: z.array(TxIdSchema)
    .optional()
    .default([])
    .refine(
      (skills) => skills.length <= 10,
      { message: 'Maximum 10 skills supported per process (token limit)' }
    ),

  capabilities: z.array(z.string())
    .optional()
    .default([])
    .refine(
      (caps) => caps.every(c => c.length >= 2 && c.length <= 50),
      { message: 'Each capability must be 2-50 characters' }
    ),

  creator: Address43Schema.optional(),

  processId: Address43Schema.optional(),

  createdAt: z.number().optional(),

  updatedAt: z.number().optional(),

  // Additional metadata
  metadata: z.record(z.any()).optional()
});

/**
 * Inferred TypeScript type from schema
 */
export type ProcessMetadata = z.infer<typeof ProcessMetadataSchema>;

/**
 * Validate process.json metadata
 * @param data - Raw JSON data to validate
 * @returns Validated and typed ProcessMetadata
 * @throws ZodError with detailed validation errors
 */
export function validateProcessMetadata(data: unknown): ProcessMetadata {
  return ProcessMetadataSchema.parse(data);
}

/**
 * Safe validation that returns result object instead of throwing
 * @param data - Raw JSON data to validate
 * @returns { success: true, data } or { success: false, error }
 */
export function safeValidateProcessMetadata(data: unknown) {
  return ProcessMetadataSchema.safeParse(data);
}

/**
 * Format Zod validation errors for user-friendly CLI output
 * @param error - ZodError from validation
 * @returns Formatted error message with field details
 */
export function formatValidationError(error: z.ZodError): string {
  const errors = error.errors.map(err => {
    const path = err.path.join('.');
    return `  • ${path}: ${err.message}`;
  }).join('\n');

  return `process.json validation failed:\n${errors}`;
}

/**
 * Example valid process.json
 */
export const EXAMPLE_PROCESS_METADATA: ProcessMetadata = {
  name: 'Code Security Reviewer',
  version: '1.0.0',
  description: 'AI-powered security analysis for code using React security skills',
  pricing: {
    ReviewCode: 1000000,
    QuickScan: 500000
  },
  skills: [
    'react_security_txid_43_chars_example_here'
  ],
  capabilities: ['code-review', 'security', 'react'],
  creator: 'creator_ao_wallet_address_43_chars_here'
};
