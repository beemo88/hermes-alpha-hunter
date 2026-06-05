# Injection Pattern Detection

Deep methodology for finding injection vulnerabilities through source code analysis.

## Universal Principle: Source-Transform-Sink

Every injection follows the same pattern:
1. Source — where user input enters (request params, body, headers, file uploads)
2. Transform — what happens between entry and use (validation, encoding, sanitization)
3. Sink — where input is used dangerously (query, template render, URL fetch)

A vulnerability exists when user input reaches a dangerous sink WITHOUT adequate sanitization.

## SQL Injection

### Finding SQL Sinks
- Python: .execute(), .raw(), cursor. methods
- Node: .query(), .rawQuery(), Sequelize.literal()
- Java: .createNativeQuery(), Statement.execute()
- Go: db.Query() with fmt.Sprintf
- ORM escape hatches: Django .extra(), .raw(), Rails .find_by_sql()

### Vulnerable Pattern Indicators
- f-strings or .format() containing SELECT/INSERT/UPDATE/DELETE/WHERE
- Template literals with ${} containing request data
- String concatenation (+) building query strings with variables
- sprintf/String.format building queries with user parameters

### Safe Pattern (Not Vulnerable)
- Parameterized queries using ? or $1 placeholders with separate value arrays
- ORM query builders using method chaining (.where().eq() style)
- Prepared statements with bound parameters

### Second-Order SQLi
Data stored from user input, then retrieved and used in a different query unsafely.

## NoSQL Injection

### Finding NoSQL Sinks
MongoDB: .find(), .findOne(), .findOneAndUpdate(), .aggregate(), .updateOne(), .deleteOne()

### Vulnerable Pattern Indicators
- Request body passed directly as query filter without type checking
- Query operators ($ne, $gt, $lt, $regex, $where, $or) constructable from user input
- String type not enforced on inputs used in equality comparisons

### $where Operator
Search for $where usage — it evaluates JavaScript server-side. User input in $where = code execution.

## Command Injection

### Finding Command Sinks
- Python: subprocess module, os.system, os.popen
- Node: child_process module (exec, execSync, spawn)
- Java: Runtime.getRuntime().exec, ProcessBuilder
- Go: os/exec package
- PHP: exec, system, passthru, shell_exec, popen
- Ruby: system, exec, backticks, %x{}

### Vulnerable Pattern Indicators
- User input concatenated into command string
- Shell=True (Python) or shell form with user data
- String interpolation in command strings containing request data

### Safe Pattern
- Array/list form of command execution
- No shell interpretation (shell=False or execFile)
- Strict input validation (allowlist of characters/values)

## Server-Side Template Injection (SSTI)

### Finding Template Sinks
- Python/Jinja2: render_template_string(), Template(), from_string()
- PHP/Twig: createTemplate(), renderString()
- Java/Freemarker: Template constructor, process()
- Node/Nunjucks: renderString()
- Node/EJS: ejs.render() with user-controlled template
- Node/Pug: pug.render() with user-controlled template

### Key Distinction
VULNERABLE: the template string itself contains user input
SAFE: a fixed template string receives user input as a named variable

## SSRF (Server-Side Request Forgery)

### Finding SSRF Sinks
- Python: requests library, urllib, urlopen
- Node: fetch(), axios, http.get, http.request
- Java: HttpClient, URL.openConnection, RestTemplate, WebClient
- Go: http.Get, http.NewRequest

### High-Risk Features
- Webhook URL configuration by users
- Avatar/image URL fetching
- URL preview / link unfurling
- Import-from-URL features
- PDF generation from user-supplied URL
- RSS/feed fetching with user-supplied URL

### Verification Checklist
- Can user control the scheme? (file://, gopher://)
- Can user reach internal IPs? (127.x, 10.x, 172.16-31.x, 192.168.x)
- Can user reach cloud metadata? (169.254.169.254)
- Does the app follow redirects?
- Is DNS rebinding possible?

## XXE (XML External Entities)

### Finding XXE Sinks
- Python: xml.etree, lxml (etree.parse, etree.fromstring)
- Java: DocumentBuilder, SAXParser, XMLReader
- Node: xml2js, libxmljs, DOMParser
- PHP: simplexml_load, DOMDocument
- .NET: XmlDocument, XmlReader

### Vulnerable Pattern Indicators
- XML parser with default settings (many allow external entities by default)
- No explicit disabling of external entity processing
- User-uploaded XML files parsed without protection

### XXE via File Upload
XML-based formats: SVG, DOCX, XLSX, PPTX, XML, XSD, SOAP requests

## Deserialization

### Finding Deserialization Sinks
- Python: pickle.loads, pickle.load, yaml.load (without SafeLoader), marshal.loads
- Java: ObjectInputStream.readObject, XMLDecoder, XStream.fromXML
- PHP: unserialize()
- Ruby: Marshal.load, YAML.load (without safe_mode)
- Node: node-serialize, js-yaml.load (without safe schema)

### Impact
Insecure deserialization of user-controlled data typically leads to remote code execution. Almost always Critical severity.

## Prototype Pollution (JavaScript/Node.js)

### Finding Pollution Sinks
- Recursive merge/extend functions without prototype key filtering
- lodash vulnerable functions (merge, defaultsDeep in older versions)
- Custom deep-clone/deep-merge utilities

### Impact Chain
Pollution alone is medium. Combined with gadgets (obj.isAdmin, obj.role), can escalate to auth bypass or RCE.

## Priority Ranking for Bug Bounties
1. SQL Injection — Classic, well-understood, high payouts
2. SSRF — Hot category, cloud metadata = critical
3. Command Injection — Code execution = critical
4. Deserialization — Code execution = critical
5. SSTI — Often leads to code execution
6. NoSQL Injection — Auth bypass, data access
7. XXE — File read, internal SSRF
8. Prototype Pollution — Impact varies

For each finding, document the complete source-transform-sink chain with file paths and line numbers.
