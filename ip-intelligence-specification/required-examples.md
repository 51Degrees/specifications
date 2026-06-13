# Required Examples

This section describes the user-runnable examples that MUST be implemented to demonstrate usage of the IP Intelligence API to customers.

## Implementation Notes

IP Intelligence examples follow the same general principles as [device detection examples](../device-detection-specification/required-examples.md) but with specific differences for IP-based processing:

### Evidence Keys

IP Intelligence uses **IP address evidence** with these accepted evidence keys (as defined in data files):

**Primary evidence keys:**
- `query.client-ip` - Standard client IP from query parameters (most common)
- `server.client-ip` - Client IP from server variables  
- `query.client-ip-51d` - 51Degrees-specific client IP (may have priority)
- `server.client-ip-51d` - 51Degrees-specific server client IP
- `query.true-client-ip-51d` - 51Degrees-specific true client IP (highest priority)
- `server.true-client-ip-51d` - 51Degrees-specific server true client IP

**Evidence formats:**
- IPv4: `"203.0.113.1"`
- IPv6: `"2001:db8::1"`

### Properties Available

IP Intelligence provides network and location properties as defined in the [51Degrees Property Dictionary](https://51degrees.com/developers/property-dictionary?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=ip-intelligence-specification-required-examples.md&utm_term=properties-available):

**Network Properties:**
- `IpRangeStart`/`IpRangeEnd` - Start/end of the IP range
- `RegisteredCountry` - Country code of the registered range
- `RegisteredName` - Name of the IP range (usually the owner)
- `RegisteredOwner` - Registered owner of the range

**Location Properties:**
- `Country` - Country name
- `CountryCode` - 2-character ISO 3166-1 code
- `CountryCode3` - 3-character ISO 3166-1 alpha-3 code
- `Town` - Town name
- `State` - State name  
- `Region` - Geographic region name
- `Latitude`/`Longitude` - Geographic coordinates (randomized for privacy)
- `TimeZoneOffset` - UTC offset in minutes
- `AccuracyRadius` - Accuracy radius for location data

Additional properties may include: `Address`, `County`, `Suburb`, `ZipCode`

### Available Implementations

Examples MUST be implemented for these available language implementations:

- **C/C++** - On-premise via ip-intelligence-cxx
- **.NET (C#)** - On-premise and Cloud via ip-intelligence-dotnet  
- **Go** - On-premise via ip-intelligence-go

**Note**: Node.js, Python, Java, and PHP implementations do not currently exist for IP Intelligence.

### Data Files

IP Intelligence uses `.ipi` data files:
- **Lite data file**: `51Degrees-LiteV41.ipi` (free, available from GitHub)
- **Enterprise data file**: Contact 51Degrees sales team for access (Distributor not yet available for IP Intelligence)

### Test Data

Examples use IP address evidence files:
- **evidence.yml** - YAML formatted file containing test IP addresses
- Format example:
  ```yaml
  - server.client-ip: "203.0.113.1"
  - query.client-ip: "198.51.100.42"
  - server.client-ip: "2001:db8::1"
  ```

### Weighted Values

Unlike Device Detection, IP Intelligence properties return **weighted values** due to the probabilistic nature of IP geolocation data. Examples MUST demonstrate accessing both the value and its associated weighting:

```csharp
var country = ipData.RegisteredCountry;
if (country.HasValue) {
    foreach (var value in country.Value) {
        Console.WriteLine($"Country: {value.Value} (Weight: {value.Weighting()})");
    }
}
```

### Performance Profiles

IP Intelligence supports the same performance profiles as Device Detection:
- `InMemoryConfig` - Loads entire data file into memory
- `HighPerformanceConfig` - Optimized for speed
- `LowMemoryConfig` - Optimized for minimal memory usage  
- `BalancedConfig` - Balance between performance and memory

## Concrete Examples

The following examples MUST be implemented for IP Intelligence:

### Getting Started Console (On-Premise)

Basic console application demonstrating:
- IP Intelligence engine initialization with data file
- Processing IP addresses through evidence
- Accessing network and location properties with weighted values
- Proper resource cleanup

**Key points to illustrate:**
- Pipeline creation with builder pattern
- Evidence creation with IP address using correct evidence keys
- Property access with weighted values
- Resource disposal patterns

### Getting Started Console (Cloud)

**Note**: Only available for .NET implementation currently.

Demonstrates:
- Cloud IP Intelligence engine configuration
- Resource key usage  
- Cloud service property access
- Error handling for cloud connectivity

### Getting Started Web

Web application demonstrating:
- Automatic IP detection from HTTP requests  
- Web integration with IP Intelligence pipeline
- Display of IP properties in web interface
- Request IP extraction from headers (X-Forwarded-For, etc.)

**Framework considerations:**
- .NET: ASP.NET Core examples
- Go: Standard HTTP server examples
- C/C++: Consider CGI or embedded server examples

### Metadata Console

Demonstrates accessing IP Intelligence metadata:
- Available properties and their descriptions
- Supported evidence keys via `getKeys()` function
- Data file information (publish date, tier, etc.)
- Component metadata (Network, Location components)

### Offline Processing Console

Batch processing example showing:
- Processing multiple IP addresses from YAML evidence file
- Performance configuration options (InMemory, HighPerformance, etc.)
- Output formatting for analysis
- Comparison between different performance profiles

### Performance Console  

Performance benchmarking tool demonstrating:
- Clock-time measurement for IP processing
- Thread concurrency testing
- Memory usage optimization
- Performance comparison between configurations

**Metrics to display:**
- Detections per second
- Average processing time per IP
- Memory usage patterns
- Concurrent processing capabilities

### Data Update Console

Shows data file update capabilities:
- Automatic daily updates (when Distributor becomes available)
- File system watcher for local file changes
- Programmatic update triggering
- Update on startup configuration

**Note**: Currently limited as Distributor is not yet available for IP Intelligence enterprise data files.

## Language-Specific Considerations

### C/C++
- Examples MUST demonstrate proper memory management with `ResourceManagerFree()`
- Show both C API (`IpiInitManagerFromFile`) and C++ API (`EngineIpi`) usage
- Include configuration struct initialization (`IpiInMemoryConfig`, etc.)
- Demonstrate SWIG wrapper usage for language bindings

### .NET (C#)
- Use `IpiPipelineBuilder` for fluent configuration
- Demonstrate dependency injection patterns for web apps
- Show both on-premise and cloud examples
- Include async/await patterns where appropriate
- Show proper disposal patterns with `using` statements

### Go
- Use builder pattern for pipeline configuration
- Demonstrate proper cgo integration
- Show error handling patterns
- Include context usage for cancellation
- Demonstrate goroutine safety

## Missing Features vs Device Detection

The following Device Detection features do NOT apply to IP Intelligence:

- **Find Profiles** - Not applicable for IP ranges
- **TAC/Native Key Lookup** - Device-specific functionality
- **User-Agent Client Hints** - Not relevant for IP processing
- **Client-side Evidence Collection** - Limited applicability for IP data
- **Match Metrics** - Different confidence model (uses weighted values instead)

## ShareUsage Considerations

IP Intelligence examples SHOULD disable usage sharing for console examples but enable it for web examples, following the same pattern as Device Detection. Include comments explaining that production deployments should enable usage sharing to improve service quality.