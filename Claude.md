# Claude Development Guidelines

## Frontend Development

When building or working with the frontend of this project, **ALWAYS** use the following MCP servers:

### shadcn-ui MCP Server
- Use `mcp__shadcn-ui__*` tools for all UI component work
- **IMPORTANT**: Always use `get_component_demo` BEFORE `get_component` to understand how to use the component properly
- Available tools:
  - `mcp__shadcn-ui__list_components` - Get all available shadcn/ui v4 components
  - `mcp__shadcn-ui__get_component_demo` - Get demo code for component usage (USE THIS FIRST)
  - `mcp__shadcn-ui__get_component` - Get source code for specific components (use after demo)
  - `mcp__shadcn-ui__get_component_metadata` - Get component metadata
  - `mcp__shadcn-ui__list_blocks` - Get all available shadcn/ui v4 blocks
  - `mcp__shadcn-ui__get_block` - Get source code for blocks (e.g., dashboard-01, login-02)

#### Workflow for shadcn components:
1. First, call `get_component_demo` to see usage examples
2. Then, call `get_component` to get the source code
3. This ensures you understand the proper API and usage patterns

### Playwright MCP Server
- Use `mcp__playwright__*` tools for all browser automation and testing
- Available tools include:
  - `mcp__playwright__browser_navigate` - Navigate to URLs
  - `mcp__playwright__browser_snapshot` - Capture accessibility snapshots
  - `mcp__playwright__browser_click` - Perform clicks
  - `mcp__playwright__browser_type` - Type text
  - `mcp__playwright__browser_evaluate` - Evaluate JavaScript
  - `mcp__playwright__browser_take_screenshot` - Take screenshots
  - And many more browser interaction tools

## Best Practices

1. **Always check available shadcn components** before creating custom UI components
2. **Use Playwright for browser testing** instead of manual testing approaches
3. **Leverage shadcn blocks** for common UI patterns (dashboards, login forms, etc.)
4. **Prefer MCP tools** over manual implementation when available
