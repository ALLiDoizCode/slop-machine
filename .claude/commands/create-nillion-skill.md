# /create-nillion-skill

When this command is used, execute the following task:

# Create Nillion Skill

This command helps create a comprehensive Nillion skill for Claude Code that enables developers to build privacy-preserving applications using the Nillion decentralized network.

## Purpose

Generate a well-structured Nillion skill that:

- Provides clear documentation on Nillion concepts and APIs
- Includes practical code examples and patterns
- Guides developers through common use cases
- Enables building privacy-preserving applications
- Integrates seamlessly with Claude Code workflows

## Skill Component Selection

CRITICAL: First, help the user identify which Nillion components and capabilities should be included in the skill.

### 1. Core Nillion Components

Present these numbered options to the user:

1. **Nillion Client & Configuration**
   - Setting up Nillion client connections
   - Network configuration (testnet/mainnet)
   - Authentication and credentials management
   - Environment setup best practices

2. **Nada Programs (Privacy-Preserving Computation)**
   - Writing Nada programs for secure computation
   - Data types and operations
   - Testing and debugging Nada programs
   - Deployment and execution patterns

3. **Data Storage & Retrieval**
   - Storing secret values on the network
   - Retrieving and managing stored data
   - Permissions and access control
   - Data lifecycle management

4. **Compute Operations**
   - Running computations on secret data
   - Handling computation results
   - Error handling and retry logic
   - Performance optimization

5. **Permissions & Access Control**
   - Setting up user permissions
   - Managing compute permissions
   - Sharing and collaboration patterns
   - Security best practices

6. **Integration Patterns**
   - Web3 integration (wallets, smart contracts)
   - Backend service integration
   - Frontend application patterns
   - API design for privacy-preserving apps

7. **Testing & Development**
   - Local development setup
   - Testing strategies for Nada programs
   - Integration testing approaches
   - Debugging techniques

8. **Deployment & Production**
   - Production deployment checklist
   - Monitoring and observability
   - Error handling and recovery
   - Performance tuning

9. **Custom Focus**
   - User-defined Nillion use cases
   - Specialized privacy requirements
   - Advanced integration scenarios

### 2. Context Gathering

**If Existing Nillion Code provided:**

- Identify current Nillion usage patterns
- Note libraries and dependencies in use
- Extract working examples and patterns
- Highlight gaps or missing capabilities

**If Use Case Description provided:**

- Understand privacy requirements
- Identify data types and operations needed
- Determine integration points
- Note performance and scale requirements

**If Nillion Documentation Available:**

- Extract official API references
- Document recommended patterns
- Identify version-specific considerations
- Note common pitfalls and solutions

**If Starting Fresh:**

- Determine skill scope and focus areas
- Identify primary use cases to support
- Establish skill organization structure
- Define key examples to include

## Process

### 3. Nillion Skill Structure

CRITICAL: Collaboratively develop a comprehensive Nillion skill with these components.

#### A. Skill Objectives

CRITICAL: Collaborate with the user to define clear, specific objectives for the skill.

- Primary use cases the skill will support
- Developer experience goals
- Integration requirements
- Success criteria for the skill

#### B. Core Concepts Documentation

CRITICAL: Collaborate with the user to identify key Nillion concepts to document.

**Essential Concepts:**

- Fundamental Nillion architecture concepts
- Key terminology and definitions
- Core workflow patterns
- Security and privacy principles

**Advanced Concepts:**

- Optimization techniques
- Advanced integration patterns
- Performance considerations
- Best practices and conventions

#### C. Code Examples & Patterns

**Basic Examples:**

- Client setup and configuration
- Simple Nada program examples
- Basic storage and retrieval
- Common operation patterns

**Advanced Examples:**

- Complex multi-party computations
- Integration with external systems
- Error handling patterns
- Production-ready implementations

#### D. Skill File Requirements

**SKILL.md Structure:**

- Overview and purpose
- Quick start guide
- API reference and usage
- Common patterns and examples
- Troubleshooting guide

**Supporting Files:**

- Example Nada programs
- TypeScript/JavaScript snippets
- Configuration templates
- Test examples

### 4. Skill File Generation

**Nillion SKILL.md Template:**

```markdown
# Nillion

[Brief description of Nillion and the skill's purpose]

## Overview

[What this skill enables developers to do with Nillion]

## Core Concepts

### Nillion Network

[Explanation of the decentralized network]

### Nada Programs

[Introduction to privacy-preserving computation programs]

### Secret Storage

[How data is stored securely on the network]

### Compute Operations

[How to run computations on secret data]

## Quick Start

### Installation

\`\`\`bash
[Installation commands]
\`\`\`

### Basic Setup

\`\`\`typescript
[Basic client configuration example]
\`\`\`

### Your First Nada Program

\`\`\`python
[Simple Nada program example]
\`\`\`

## Common Patterns

### Pattern 1: [Name]

[Description and code example]

### Pattern 2: [Name]

[Description and code example]

## API Reference

### Client Methods

[Key client methods with parameters and return types]

### Nada Language Features

[Core Nada language constructs]

## Examples

### Example 1: [Use Case]

[Complete working example]

### Example 2: [Use Case]

[Complete working example]

## Best Practices

- [Best practice 1]
- [Best practice 2]
- [Security considerations]

## Troubleshooting

### Common Issues

[Issue and solution pairs]

## Resources

- [Official documentation links]
- [Additional resources]
```

### 5. Review and Refinement

1. **Present Complete Skill Structure**
   - Show the full SKILL.md outline
   - Explain key sections and organization
   - Highlight any assumptions or placeholders

2. **Gather Feedback**
   - Are the objectives and scope clear?
   - Do the examples cover key use cases?
   - Is the organization intuitive?
   - Are any critical components missing?

3. **Refine as Needed**
   - Incorporate user feedback
   - Add or remove sections
   - Adjust example complexity
   - Clarify ambiguities

### 6. Implementation Guidance

**Creation Steps:**

1. **Create Skill Directory**: `.claude/skills/nillion/`
2. **Generate SKILL.md**: Using the template and gathered requirements
3. **Add Code Examples**: Create supporting code files if needed
4. **Test the Skill**: Verify it works in Claude Code workflows
5. **Document Usage**: Add examples of how to invoke the skill

**Quality Checks:**

- All code examples are working and tested
- Documentation is clear and comprehensive
- Common use cases are covered
- Edge cases and errors are addressed
- Links to official resources are included

## Important Notes

- The quality of the skill directly impacts developer productivity with Nillion
- Include working, tested code examples - not pseudocode
- Focus on practical patterns developers will actually use
- Keep documentation concise but comprehensive
- Document edge cases and common errors
- Reference official Nillion documentation where appropriate
- Update skill as Nillion SDK evolves

## Usage Examples

**Create basic Nillion skill:**
```
/create-nillion-skill
```

**Create Nillion skill with specific focus:**
```
/create-nillion-skill focused on Nada program development
```

**Create comprehensive Nillion skill:**
```
/create-nillion-skill with full API coverage and advanced examples
```

**Create skill for specific use case:**
```
/create-nillion-skill for building privacy-preserving healthcare applications
```
