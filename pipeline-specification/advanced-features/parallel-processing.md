TODO - write this up.

- Allowing elements to be executed in parallel adds considerable complexity:
  - Flow Data must be capable of enforcing thread-safe writes to data structures 
    while also maintaining performance when it is not needed (which seems to be 
    majority of installations) 
  - Additional options available during configuration.
  - More features to document and test.
- Many elements have dependencies on each other's output so cannot be executed 
  in parallel anyway.
- The end-to-end processing time is still limited by the slowest element. If 
  this takes a significant proportion of the total processing time then the 
  performance benefit will be marginal.
- If users want to improve performance through concurrent processing, they can 
  do so more effectively by creating flow data instances on separate threads and 
  calling process. This is exactly what web servers are doing.
  
