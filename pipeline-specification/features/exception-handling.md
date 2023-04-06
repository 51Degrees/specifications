- Elements should throw exceptions/errors freely, unless they specifically want
  to handle them internally.
- The pipeline should catch exceptions/errors throw by elements and either:
    - (DEFAULT) Add them to the errors collection and store. Once all elements
      are processed, throw an exception/error with all the stored errors
      included as sub-errors. - This is often preferred during development in
      order to surface errors.
    - Add them to the errors collection and log. - This is often preferred in
      production in order to prevent the process from crashing.
- Errors/exceptions may occur outside the 'Process' method. In general, the
  guidance is to catch and log these rather than throwing them to the caller.
  Examples of common places for such errors are:
    - Standalone/background services (For example automatic data updates)
    - Web integration logic



