# Environment variables

These are the environment variables that packages, examples, tests and CI read in every language. Each name starts `_51DEGREES_` and holds one thing. No name is filled from another. A name that only one repository reads is documented in that repository, not here.

Names that GitHub, an operating system or another tool defines, such as `GITHUB_TOKEN`, `CHROMEWEBDRIVER`, `GECKOWEBDRIVER` or `EDGEWEBDRIVER`, aren't ours. They're used as that tool requires.

## Keys

| Name | What it holds |
| --- | --- |
| `_51DEGREES_RESOURCE_KEY` | The resource key a cloud example uses. A customer sets it. An example's own test sets it to each key it checks. |
| `_51DEGREES_RESOURCE_KEY_FREE` | A resource key for the free properties. |
| `_51DEGREES_RESOURCE_KEY_BASIC` | A resource key on the Basic tier. |
| `_51DEGREES_RESOURCE_KEY_PAID` | A resource key with a selection of paid properties. |
| `_51DEGREES_RESOURCE_KEY_BESPOKE` | A resource key with every property, for tests that need them all. |
| `_51DEGREES_RESOURCE_KEY_51DID` | A resource key for the 51Did service. |
| `_51DEGREES_LICENSE_KEY` | A 51Degrees license key. Each test sets the license it needs. |
| `_51DEGREES_LICENSE_KEY_BESPOKE` | A license key for tests that ask the cloud service for named properties with a license key. |
| `_51DEGREES_LICENSE_KEY_51DID` | The license key that goes with `_51DEGREES_RESOURCE_KEY_51DID`. |

## Settings

| Name | What it holds |
| --- | --- |
| `_51DEGREES_CLOUD_ENDPOINT` | The address of the cloud service to use. When it isn't set, the public service is used. |
| `_51DEGREES_DD_PATH` | The path of a Device Detection data file. |
| `_51DEGREES_IPI_PATH` | The path of an IP Intelligence data file. |
| `_51DEGREES_DD_PRODUCT` | The product the Device Detection update example asks the Distributor for, such as `V4TAC`. The example names a product only when this is set. When it isn't set, the example sends no product. |
| `_51DEGREES_IPI_PRODUCT` | The product the IP Intelligence update example asks the Distributor for, such as `IPIV4Enterprise`. The example names a product only when this is set. When it isn't set, the example sends no product. |
| `_51DEGREES_EVIDENCE_YAML` | The path of a YAML evidence file. When it isn't set, `20000 Evidence Records.yml` is used. |
| `_51DEGREES_EXAMPLE_HTTP_PORTS` | The port, or ports, a web example listens on. |
| `_51DEGREES_EXAMPLE_URL` | The address of a running example for the browser tests to open. |
| `_51DEGREES_EXAMPLE_LANG` | The language of the example at `_51DEGREES_EXAMPLE_URL`. |
