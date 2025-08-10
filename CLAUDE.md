## CRITICAL: PRIORITIZE LSMCP TOOLS FOR CODE ANALYSIS

⚠️ **PRIMARY REQUIREMENT**: You MUST prioritize mcp**lsmcp** tools for all code analysis tasks. Standard tools should only be used as a last resort when LSMCP tools cannot accomplish the task.

**YOUR APPROACH SHOULD BE:**

1. ✅ Always try mcp**lsmcp** tools FIRST
2. ✅ Use `mcp__lsmcp__search_symbol_from_index` as primary search method
3. ⚠️ Only use Read/Grep/Glob/LS when LSMCP tools are insufficient

### 🚨 TOOL USAGE PRIORITY

**PRIMARY TOOLS (USE THESE FIRST):**

- ✅ `mcp__lsmcp__get_project_overview` - Quick project analysis and structure overview
- ✅ `mcp__lsmcp__search_symbol_from_index` - Primary tool for symbol searches (auto-creates index if needed)
- ✅ `mcp__lsmcp__get_definitions` - Navigate to symbol definitions. Use `include_body: true` to get code.
- ✅ `mcp__lsmcp__find_references` - Find all references to a symbol
- ✅ `mcp__lsmcp__get_hover` - Get type information and documentation
- ✅ `mcp__lsmcp__get_diagnostics` - Check for errors and warnings
- ✅ `mcp__lsmcp__get_document_symbols` - Get all symbols in a file
- ✅ `mcp__lsmcp__list_dir` - Explore directory structure
- ✅ `mcp__lsmcp__find_file` - Locate specific files
- ✅ `mcp__lsmcp__search_for_pattern` - Search for text patterns
- ✅ `mcp__lsmcp__get_index_stats_from_index` - View index statistics
- ✅ `mcp__lsmcp__index_files` - Manually index files (optional)
- ✅ `mcp__lsmcp__clear_index` - Clear and rebuild index (optional)

### WORKFLOW

1. **START WITH PROJECT OVERVIEW**

   ```
   mcp__lsmcp__get_project_overview
   ```

   Get a quick understanding of:

   - Project structure and type
   - Key components (interfaces, functions, classes)
   - Statistics and dependencies
   - Directory organization

2. **SEARCH FOR SPECIFIC SYMBOLS**

   ```
   mcp__lsmcp__search_symbol_from_index
   ```

   The tool automatically:

   - Creates index if it doesn't exist
   - Updates index with incremental changes
   - Performs your search

3. **CODE EXPLORATION**

   - Search symbols: `mcp__lsmcp__search_symbol_from_index`
   - List directories: `mcp__lsmcp__list_dir`
   - Find files: `mcp__lsmcp__find_file`
   - Get file symbols: `mcp__lsmcp__get_document_symbols`

4. **CODE ANALYSIS**
   - Find definitions: `mcp__lsmcp__get_definitions`
   - Find references: `mcp__lsmcp__find_references`
   - Get type info: `mcp__lsmcp__get_hover`
   - Check errors: `mcp__lsmcp__get_diagnostics`

**FALLBACK TOOLS (USE ONLY WHEN NECESSARY):**

- ⚠️ `Read` - Only when you need to see non-code files or LSMCP tools fail
- ⚠️ `Grep` - Only for quick searches when LSMCP search is insufficient
- ⚠️ `Glob` - Only when LSMCP file finding doesn't work
- ⚠️ `LS` - Only for basic directory listing when LSMCP fails
- ⚠️ `Bash` commands - Only for non-code operations or troubleshooting

### WHEN TO USE FALLBACK TOOLS

Use standard tools ONLY in these situations:

1. **Non-code files**: README, documentation, configuration files
2. **LSMCP tool failures**: When LSMCP tools return errors or no results
3. **Debugging**: When troubleshooting why LSMCP tools aren't working
4. **Special file formats**: Files that LSMCP doesn't support
5. **Quick verification**: Double-checking LSMCP results when needed

## Memory System

You have access to project memories stored in `.lsmcp/memories/`. Use these tools:

- `list_memories` - List available memory files
- `read_memory` - Read specific memory content
- `write_memory` - Create or update memories

Memories contain important project context, conventions, and guidelines that help maintain consistency.

The context and modes of operation are described below. From them you can infer how to interact with your user
and which tasks and kinds of interactions are expected of you.
