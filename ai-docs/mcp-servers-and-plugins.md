# MCP Servers

All MCP (Model Context Protocol) servers configured for this project.

---

## Configured Servers (`.mcp.json`)

### 1. task-master-ai
- **Command**: `npx -y --package=task-master-ai task-master-ai`
- **Type**: stdio
- **Env**: `ANTHROPIC_API_KEY`, `PERPLEXITY_API_KEY`
- **Purpose**: AI-powered task management. Parses PRDs into tasks, manages task dependencies, and provides intelligent task sequencing.
- **Available Tools**:
  - `get_tasks` - List all tasks
  - `next_task` - Get the next task to work on
  - `get_task` - Get details of a specific task
  - `set_task_status` - Update task status
  - `update_subtask` - Update a subtask
  - `parse_prd` - Parse a PRD into tasks
  - `expand_task` - Expand a task into subtasks

### 2. Serena
- **Command**: `uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context claude-code --project . --enable-web-dashboard False`
- **Type**: stdio
- **Purpose**: Semantic code analysis and editing agent. Provides symbol-level code understanding, navigation, and editing capabilities across the entire codebase.
- **Available Tools**:
  - `read_file` / `create_text_file` - File operations
  - `list_dir` / `find_file` - Directory/file navigation
  - `replace_content` - Regex-based file editing
  - `search_for_pattern` - Pattern search across codebase
  - `get_symbols_overview` - Overview of symbols in a file
  - `find_symbol` - Find symbols by name path
  - `find_referencing_symbols` - Find all references to a symbol
  - `replace_symbol_body` - Replace a symbol's definition
  - `insert_after_symbol` / `insert_before_symbol` - Insert code relative to symbols
  - `rename_symbol` - Rename symbols across codebase
  - `write_memory` / `read_memory` / `list_memories` / `delete_memory` / `edit_memory` - Persistent memory
  - `execute_shell_command` - Run shell commands
  - `activate_project` / `switch_modes` / `get_current_config` - Project management
  - `check_onboarding_performed` / `onboarding` - Setup
  - `think_about_collected_information` / `think_about_task_adherence` / `think_about_whether_you_are_done` - Reasoning tools
  - `prepare_for_new_conversation` / `initial_instructions` - Session management

### 3. GitHub
- **Command**: `npx -y @modelcontextprotocol/server-github`
- **Type**: stdio
- **Env**: `GITHUB_PERSONAL_ACCESS_TOKEN`
- **Purpose**: Full GitHub integration for repository management, issues, PRs, and code search.
- **Available Tools**:
  - `create_or_update_file` / `get_file_contents` / `push_files` - File operations
  - `search_repositories` / `create_repository` / `fork_repository` - Repo management
  - `create_issue` / `list_issues` / `update_issue` / `get_issue` / `add_issue_comment` / `search_issues` - Issue management
  - `create_pull_request` / `list_pull_requests` / `get_pull_request` / `merge_pull_request` - PR management
  - `create_pull_request_review` / `get_pull_request_files` / `get_pull_request_status` - PR review
  - `update_pull_request_branch` / `get_pull_request_comments` / `get_pull_request_reviews` - PR details
  - `create_branch` / `list_commits` - Branch/commit operations
  - `search_code` / `search_users` - Search

### 4. Octocode
- **Command**: `npx octocode-mcp@latest`
- **Type**: stdio
- **Env**: `GITHUB_TOKEN`
- **Purpose**: Expert code forensics and discovery agent. Provides deep code search across GitHub repositories and local codebases with LSP integration for semantic understanding.
- **Available Tools**:
  - `githubSearchCode` / `githubGetFileContent` / `githubViewRepoStructure` - GitHub code exploration
  - `githubSearchRepositories` / `githubSearchPullRequests` - GitHub search
  - `packageSearch` - Search for packages/libraries
  - `localSearchCode` / `localViewStructure` / `localFindFiles` / `localGetFileContent` - Local codebase exploration
  - `lspGotoDefinition` / `lspFindReferences` / `lspCallHierarchy` - LSP semantic analysis

### 5. Playwright
- **Command**: `npx -y @playwright/mcp@latest`
- **Type**: stdio
- **Purpose**: Browser automation and testing. Enables interaction with web pages for E2E testing, screenshot capture, and UI verification.

### 6. ESLint
- **Command**: `npx -y @eslint/mcp`
- **Type**: stdio
- **Purpose**: JavaScript/TypeScript linting server. Provides code quality analysis and auto-fix capabilities.

### 7. Chrome DevTools
- **Command**: `npx -y chrome-devtools-mcp@latest`
- **Type**: stdio
- **Purpose**: Chrome DevTools integration for debugging, performance profiling, network inspection, and DOM manipulation.

---

## iOS Development Servers (LockCraft-specific)

These servers are specifically chosen for the LockCraft iOS project — covering Xcode builds, Apple documentation, simulator testing, and Swift code analysis.

### 8. XcodeBuildMCP
- **Command**: `npx -y xcodebuildmcp@latest mcp`
- **Type**: stdio
- **Purpose**: AI-powered Xcode automation. Build, test, and manage iOS/macOS projects directly from AI agents. Enables building for simulators and devices, running tests, capturing logs, and debugging — all without leaving the agent workflow.
- **Requirements**: macOS 14.5+, Xcode 16.x+, Node.js 18.x+
- **LockCraft Use Cases**:
  - Build all 4 targets (Main App, Widget Extension, Intent Extension, Tests)
  - Run unit and snapshot tests for the rendering engine
  - Build and deploy to iOS Simulator for visual verification
  - Capture build diagnostics and resolve compilation errors
- **Reference**: [XcodeBuildMCP on GitHub](https://github.com/cameroncooke/XcodeBuildMCP)

### 9. Apple Docs
- **Command**: `npx -y @kimsungwhee/apple-docs-mcp@latest`
- **Type**: stdio
- **Purpose**: Search Apple Developer Documentation, WWDC videos, framework APIs, and sample code. Provides AI-native access to SwiftUI, UIKit, EventKit, WidgetKit, AppIntents, BGTaskScheduler, Core Graphics, and all Apple frameworks.
- **Available Tools**:
  - `search_apple_docs` - Search Apple Developer Documentation
  - `get_apple_doc_content` - Retrieve detailed documentation with analysis
  - `list_technologies` - Browse Apple's technology catalog
  - `search_framework_symbols` - Find classes, structs, protocols in frameworks
  - `get_related_apis` - Discover inheritance and conformance relationships
  - `resolve_references_batch` - Extract and resolve API references
  - `get_platform_compatibility` - Analyze version support and deprecation info
  - `find_similar_apis` - Get Apple's official API recommendations
  - `get_documentation_updates` - Track WWDC announcements and release notes
  - `get_technology_overviews` - Access comprehensive technology guides
  - `get_sample_code` - Browse Apple's sample code library
  - `search_wwdc_videos` - Query 1,260+ WWDC sessions (2014-2025)
  - `get_wwdc_video_details` - Retrieve full transcripts and resources
  - `list_wwdc_topics` / `list_wwdc_years` - Explore WWDC content organization
- **LockCraft Use Cases**:
  - Look up EventKit APIs for calendar integration (Phase 2)
  - Reference Core Graphics drawing APIs for the rendering engine (Phase 3)
  - Check WidgetKit timeline provider patterns (Phase 7)
  - Verify AppIntents/Shortcuts API usage (Phase 6)
  - Search WWDC sessions on BGTaskScheduler best practices (Phase 5)
- **Reference**: [apple-docs-mcp on GitHub](https://github.com/kimsungwhee/apple-docs-mcp)

### 10. Mobile MCP
- **Command**: `npx -y @mobilenext/mobile-mcp@latest`
- **Type**: stdio
- **Purpose**: iOS Simulator automation. Launch apps, capture screenshots, interact with UI elements, and automate testing on iOS simulators and real devices.
- **Available Tools**:
  - Device management — list devices, get/set orientation, screen dimensions
  - App operations — launch, terminate, install, uninstall applications
  - Screen interaction — capture screenshots, identify UI elements, tap, swipe, long press
  - Input & navigation — type text, press device buttons, open URLs
- **LockCraft Use Cases**:
  - Visual verification of generated wallpapers on different device resolutions
  - Test onboarding flow (7 screens) on simulator
  - Capture screenshots of all 6 templates for App Store submission (Phase 10)
  - Verify lock screen widget rendering across widget families
  - Test image picker and calendar permission flows
- **Reference**: [Mobile MCP on GitHub](https://github.com/mobile-next/mobile-mcp)

### 11. SwiftLens
- **Command**: `uvx swiftlens`
- **Type**: stdio
- **Purpose**: Deep, semantic-level analysis of Swift codebases via SourceKit-LSP integration. Provides compiler-grade accuracy for understanding types, protocols, dependencies, and symbol relationships.
- **Available Tools**:
  - `swift_analyze_file` - Extract structure and symbols from a file
  - `swift_summarize_file` - Get symbol counts and overview
  - `swift_validate_file` - Validate syntax with swiftc
  - `swift_get_file_imports` - Extract import statements
  - `swift_build_index` - Build index store for cross-file analysis
  - `swift_find_symbol_references` - Locate all uses of a symbol across the project
  - `swift_get_symbol_definition` - Navigate to symbol definitions
  - `swift_get_hover_info` - Get type info and documentation
  - `swift_replace_symbol_body` - Refactor function/type bodies
- **LockCraft Use Cases**:
  - Navigate the WallpaperRenderer protocol and all conforming types
  - Find all references to DesignSettings across targets
  - Validate Swift syntax before building
  - Refactor shared models used across App Group targets
  - Analyze type relationships in the template rendering engine
- **Reference**: [SwiftLens on GitHub](https://github.com/swiftlens/swiftlens)

---

## Plugin-Provided MCP Servers

These MCP servers are provided by installed Claude Code plugins:

### 12. Context7 (via `context7` plugin)
- **Purpose**: Retrieves up-to-date documentation and code examples for any library.
- **Available Tools**:
  - `resolve-library-id` - Resolve a library name to its Context7 ID
  - `query-docs` - Query documentation for a specific library
