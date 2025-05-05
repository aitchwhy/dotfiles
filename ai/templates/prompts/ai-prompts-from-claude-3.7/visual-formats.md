# Visual Format Specifications

This document provides detailed specifications for visual elements in AI responses, ensuring consistent, high-quality visual outputs across different AI tools.

## Architecture Diagrams

### System Architecture Diagrams

#### Content Requirements
- **Components**: All significant system components clearly labeled
- **Interfaces**: Connections between components with interface type
- **Data Flow**: Directional indicators showing information flow
- **External Boundaries**: Clear system boundaries and external integrations
- **Layers**: Logical grouping of components by function/layer
- **Dependencies**: Clear indication of component dependencies

#### Notation Guidelines
```
[External System] ←→ [API Gateway] → [Service A] → [Database]
                                    ↓
                                [Service B] → [Cache]
                                    ↓
                               [Event Bus] → [Service C]
```

#### Example Specification
```markdown
Please create a system architecture diagram showing:
- Frontend components (UI, state management)
- Backend services (authentication, core logic, data access)
- Data storage systems (databases, caches)
- External integrations (third-party APIs, partner systems)
- Communication patterns (sync/async, events, direct calls)

Use distinct symbols for different component types and indicate data flow directions.
```

### Sequence Diagrams

#### Content Requirements
- **Actors**: All participants in the interaction
- **Time Flow**: Clear temporal sequence (typically top to bottom)
- **Messages**: Labeled arrows showing requests/responses
- **Activation**: Indication of when components are active
- **Conditional Paths**: Decision points and alternative flows
- **Failure Scenarios**: Error handling paths where relevant

#### Notation Guidelines
```
Actor     Service A     Service B     Database
  |           |             |            |
  |--Request->|             |            |
  |           |--Query----->|            |
  |           |             |--DB Call-->|
  |           |             |<--Result---|
  |           |<--Response--|            |
  |<--Reply---|             |            |
```

#### Example Specification
```markdown
Create a sequence diagram for user authentication flow showing:
- Initial request from client
- Authentication service validation
- Token generation
- Response to client
- Subsequent authenticated request
- Token validation
- Resource access

Include error paths for:
- Invalid credentials
- Expired tokens
- Insufficient permissions
```

## Data Visualization

### Comparison Tables

#### Content Requirements
- **Header Row**: Clear column headers with units if applicable
- **First Column**: Items being compared
- **Data Cells**: Consistent formatting of values
- **Scoring**: Numeric ratings (1-10) with visual indicators
- **Weighting**: Weight values for weighted calculations
- **Totals**: Weighted scores and rankings
- **Highlight**: Visual emphasis on optimal values

#### Format Example
```
| Option | Performance (w=0.3) | Security (w=0.4) | Maintainability (w=0.3) | Weighted Score | Rank |
|--------|---------------------|------------------|-------------------------|----------------|------|
| Opt A  | 9 ⭐⭐⭐ (2.7)        | 7 ⭐⭐ (2.8)       | 8 ⭐⭐⭐ (2.4)            | 7.9            | 1    |
| Opt B  | 7 ⭐⭐ (2.1)          | 8 ⭐⭐⭐ (3.2)      | 6 ⭐⭐ (1.8)              | 7.1            | 2    |
| Opt C  | 8 ⭐⭐⭐ (2.4)         | 6 ⭐⭐ (2.4)       | 7 ⭐⭐ (2.1)              | 6.9            | 3    |
```

#### Example Specification
```markdown
Create a comparison table for the options with these characteristics:
- Include all 5 options in rows
- Evaluate each on the 6 criteria specified
- Use a 1-10 scale for each criterion
- Apply the weights as indicated in parentheses
- Calculate weighted scores
- Rank options from highest to lowest score
- Add visual indicators (⭐) for scores:
  - 1-3: No stars
  - 4-6: ⭐
  - 7-8: ⭐⭐
  - 9-10: ⭐⭐⭐
- Highlight the best score in each column
```

### Decision Trees

#### Content Requirements
- **Decision Nodes**: Questions or decision points
- **Option Branches**: Paths representing choices
- **Leaf Nodes**: Outcomes or terminal states
- **Branch Labels**: Conditions for taking each path
- **Probabilities/Values**: Associated with paths or nodes (if applicable)
- **Critical Path**: Highlighted recommended path

#### Notation Guidelines
```
                         [Initial Decision]
                           /           \
                     [Yes]/             \[No]
                         /               \
            [Secondary Decision]     [Alternative Decision]
               /         \               /        \
          [Opt A]      [Opt B]      [Opt C]     [Opt D]
```

#### Example Specification
```markdown
Create a decision tree for the described scenario with:
- Root node representing the initial decision
- Branches for each option with conditions
- Secondary decision points where relevant
- Terminal nodes showing outcomes
- Annotations with key considerations at each step
- Highlight the recommended path based on specified criteria
```

### Process Flows

#### Content Requirements
- **Start/End**: Clear beginning and end points
- **Actions**: Process steps with descriptive labels
- **Decisions**: Conditional branching points
- **Flows**: Directional arrows connecting elements
- **Loops**: Clearly marked iteration points
- **Swimlanes**: Responsibility boundaries (if applicable)
- **Artifacts**: Inputs and outputs of steps

#### Notation Guidelines
```
(Start) → [Process Step] → <Decision?> → [Success Step] → (End)
                               |
                               ↓
                          [Failure Step] → [Recovery] ↩
```

#### Example Specification
```markdown
Create a process flow diagram showing:
- Initial request handling
- Validation steps with error paths
- Main processing sequence
- Decision points with criteria
- Success and failure paths
- Retry loops where applicable
- Final states and outputs

Use distinct symbols for:
- Start/end points (parentheses)
- Process steps [rectangles]
- Decision points <diamonds>
- Directional arrows connecting elements
```

## Code Visualization

### Code Structure Diagrams

#### Content Requirements
- **Modules**: Major code components
- **Classes/Functions**: Key implementation elements
- **Relationships**: Inheritance, composition, dependencies
- **Interfaces**: Public APIs and contracts
- **Access Patterns**: Usage and interaction flows
- **Data Structures**: Key data representations

#### Notation Guidelines
```
[Module A] ← implements ← [Interface X]
    ↑                         ↑
 inherits                  inherits
    |                         |
[Module B] → depends on → [Module C]
```

#### Example Specification
```markdown
Create a code structure diagram showing:
- Major components/modules
- Key classes with inheritance relationships
- Critical interfaces and implementations
- Dependencies between components
- Data flow between modules
- Extension points

Use UML-inspired notation with:
- Boxes for classes/modules
- Arrows for relationships
- Labels indicating relationship types
```

### Algorithm Flowcharts

#### Content Requirements
- **Initialization**: Starting state and setup
- **Steps**: Processing stages with operations
- **Branching**: Conditional logic
- **Loops**: Iteration constructs
- **Termination**: Exit conditions
- **Complexity**: Annotated time/space complexity
- **Examples**: Sample data state at key points

#### Notation Guidelines
```
(Initialize) → [Step 1] → [Step 2] → <Condition?> → [Step 3A] → (End)
                                         |
                                         ↓
                                     [Step 3B] → [Loop back to Step 2] ↩
```

#### Example Specification
```markdown
Create an algorithm flowchart showing:
- Initialization with input parameters
- Main processing steps in sequence
- Conditional branches with criteria
- Loop structures with entry/exit conditions
- Terminal states and return values
- Annotations with complexity analysis
- Example state progression with sample input

Use consistent notation:
- Rounded rectangles for start/end
- Rectangles for process steps
- Diamonds for decisions
- Arrows for flow direction
```

## Tabular Data

### Feature Comparison Matrices

#### Content Requirements
- **Features**: Comprehensive feature list in rows
- **Options**: Items being compared in columns
- **Support**: Clear indicators of feature support
- **Limitations**: Notes on partial implementations
- **Standouts**: Highlighting of exceptional capabilities
- **Categories**: Logical grouping of related features
- **Importance**: Indicators of feature significance

#### Format Example
```
| Feature Category | Feature | Option A | Option B | Option C |
|------------------|---------|----------|----------|----------|
| Performance      | Feature 1 | ✅ | ⚠️ Limited | ❌ |
|                  | Feature 2 | ✅ | ✅ | ⚠️ Planned |
| Security         | Feature 3 | ✅ Best | ✅ | ✅ |
|                  | Feature 4 | ❌ | ✅ | ✅ |
| Usability        | Feature 5 | ⚠️ Basic | ✅ | ✅ Best |
```

#### Example Specification
```markdown
Create a feature comparison matrix with:
- Features organized by category (rows)
- All options being evaluated (columns)
- Support indicators:
  - ✅ = Fully supported
  - ⚠️ = Partial/limited support (with note)
  - ❌ = Not supported
- "Best" notation for standout implementations
- "Planned" notation for upcoming features
- Bold text for critical features
```

### Decision Matrices

#### Content Requirements
- **Options**: Alternatives in rows
- **Criteria**: Evaluation factors in columns
- **Weights**: Importance weighting for criteria
- **Scores**: Raw scores (typically 1-10)
- **Weighted Scores**: Calculated weighted values
- **Totals**: Sum of weighted scores
- **Ranking**: Clear indication of final ranking

#### Format Example
```
| Option | Criterion 1 (w=0.2) | Criterion 2 (w=0.5) | Criterion 3 (w=0.3) | Total Score | Rank |
|--------|---------------------|---------------------|---------------------|-------------|------|
| Opt A  | 7 (1.4)             | 8 (4.0)             | 9 (2.7)             | 8.1         | 1    |
| Opt B  | 9 (1.8)             | 6 (3.0)             | 8 (2.4)             | 7.2         | 2    |
| Opt C  | 8 (1.6)             | 5 (2.5)             | 7 (2.1)             | 6.2         | 3    |
```

#### Example Specification
```markdown
Create a weighted decision matrix with:
- All options listed as rows
- Evaluation criteria as columns with weights
- Scores on a 1-10 scale for each option/criterion
- Calculation showing raw score and weighted contribution
- Total weighted score for each option
- Ranking based on total score
- Conditional formatting:
  - Bold the highest score in each column
  - Highlight the top-ranked option
```

## Chart Types

### Technical Chart Specifications

Specifications for common chart types in technical contexts:

#### Time Series
```markdown
Create a time series chart showing:
- X-axis: Time periods (specify increments)
- Y-axis: Metric values (specify units and scale)
- Multiple series for comparing trends
- Clear legend identifying each series
- Notable events or thresholds marked
- Trend lines where appropriate

Use text-based visualization with appropriate symbols and labels.
```

#### Comparison Bar Charts
```markdown
Create a bar chart comparing:
- X-axis: Categories/items being compared
- Y-axis: Value metric (specify units and scale)
- Grouped bars for multi-dimension comparison
- Labels showing exact values
- Sorted in descending order by primary metric
- Color coding to distinguish categories

Use text-based visualization with proportional bar lengths.
```

#### Technical Scatter Plots
```markdown
Create a scatter plot showing:
- X-axis: First variable (specify units and range)
- Y-axis: Second variable (specify units and range)
- Points representing individual data items
- Size variation for third dimension (if applicable)
- Color coding for categories
- Trend line showing correlation
- Labeled quadrants or regions of interest

Use text-based visualization with appropriate symbols and positioning.
```

## Documentation Diagrams

### API Interface Diagrams

#### Content Requirements
- **Endpoints**: All API endpoints grouped logically
- **Methods**: HTTP methods or function calls
- **Parameters**: Required and optional inputs
- **Responses**: Return types and structures
- **Authentication**: Security requirements
- **Dependencies**: Related services or components
- **Examples**: Sample calls and responses

#### Format Example
```
API: UserService
┌─────────────────────────────────────────────────────────┐
│ GET /users/{id}                                         │
├─────────────────────────────────────────────────────────┤
│ Parameters:                                             │
│   - id: string (required) - User identifier             │
├─────────────────────────────────────────────────────────┤
│ Responses:                                              │
│   - 200: User object                                    │
│   - 404: Not found error                                │
│   - 401: Authentication error                           │
├─────────────────────────────────────────────────────────┤
│ Authentication: Bearer token                            │
└─────────────────────────────────────────────────────────┘
```

#### Example Specification
```markdown
Create an API interface diagram documenting:
- All endpoints grouped by resource
- HTTP methods for each endpoint
- Path and query parameters with types
- Request body schema for POST/PUT methods
- Response codes and data structures
- Authentication requirements
- Rate limiting information
- Example request/response pairs

Use consistent box notation with clear sections for each component.
```

### Entity Relationship Diagrams

#### Content Requirements
- **Entities**: All major data entities
- **Attributes**: Key fields for each entity
- **Relationships**: Connections between entities
- **Cardinality**: Relationship multiplicity (1:1, 1:N, M:N)
- **Primary Keys**: Clearly marked identifiers
- **Foreign Keys**: Relationship implementation
- **Constraints**: Business rules and validations

#### Notation Guidelines
```
[User]                      [Order]
id (PK)    1 ------- * ┌─→ id (PK)
username               │   user_id (FK)
email                  │   total_amount
created_at             │   created_at
                       │
                       │   [OrderItem]
                       └── id (PK)
                           order_id (FK)
                           product_id (FK)
                           quantity
                           price
```

#### Example Specification
```markdown
Create an entity relationship diagram showing:
- All entities in the data model
- Primary key fields marked (PK)
- Foreign key relationships marked (FK)
- Essential attributes for each entity
- Relationship lines with cardinality:
  - One-to-one: 1 ──── 1
  - One-to-many: 1 ──── *
  - Many-to-many: * ──── *
- Optional relationships shown with dashed lines
```
