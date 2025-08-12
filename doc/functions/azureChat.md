
# azureChat

Connect to Azure® OpenAI® Services Chat Completion API from MATLAB®

# Creation
## Syntax

`model = azureChat`


`model = azureChat(systemPrompt)`


`model = azureChat(___,Name=Value)`

## Description

Connect to the Azure OpenAI Services Chat Completion API to generate text using large language models developed by OpenAI using [Azure OpenAI Services](https://azure.microsoft.com/en-gb/products/ai-services/openai-service).


To connect to the Azure OpenAI API, you need a valid API key and Azure endpoint. You also need to choose the OpenAI model deployment by specifying the deployment ID. You can specify the API key, endpoint, and deployment ID either by using name\-value arguments or by specifying the corresponding environment variables. For more information, see [Azure OpenAI Services API](../Azure.md).


`model = azureChat` creates an `azureChat` object.


`model = azureChat(systemPrompt)` creates an `azureChat` object with the specified system prompt.


`model = azureChat(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Input Arguments
### `systemPrompt` — System prompt

character vector | string scalar


Specify the system prompt and set the `SystemPrompt` property. The system prompt is a natural\-language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc. 


**Example**: `"You are a helpful assistant who provides answers to user queries in iambic pentameter."`

## Name\-Value Arguments
### `APIKey` — Azure OpenAI API key

character vector | string scalar


Azure OpenAI API key to access OpenAI models using Azure. 


To keep sensitive information out of code, instead of using the `APIKey` name\-value argument, you can also set the environment variable AZURE\_OPENAI\_API\_KEY. 


For more information on connecting to the Azure OpenAI API, see [Azure OpenAI Services API](../Azure.md).


For more information on keeping sensitive information out of code, see [Keep Sensitive Information Out of Code](https://www.mathworks.com/help/matlab/import_export/keep-sensitive-information-out-of-code.html).



### `Tools` — Functions to call during output generation

`openAIFunction` object | array of `openAIFunction` objects


Information about tools available for function calling, specified as [`openAIFunction`](openAIFunction.md) objects.


For an example of OpenAI function calling using the OpenAI Chat Completion API, see [Analyze Scientific Papers Using ChatGPT Function Calls](http://../examples/AnalyzeScientificPapersUsingFunctionCalls.md).

### `StreamFun` — Custom streaming function

function handle


Specify a custom streaming function to process the generated output as it is being generated, rather than having to wait for the end of the generation. For example, you can use this function to print the output as it is generated.


**Example:** `@(token) fprint("%s",token)`

# Properties Settable at Construction

Optionally specify these properties at construction using name\-value arguments. Specify `PropertyName1=PropertyValue1,...,PropertyNameN=PropertyValueN`, where `PropertyName` is the property name and `PropertyValue` is the corresponding value.

### `Endpoint` — Azure endpoint

character vector | string scalar


After construction, this property is read\-only.


Network address used to communicate with Azure. 


Instead of using the `Endpoint` name\-value argument, you can also set the environment variable AZURE\_OPENAI\_ENDPOINT. For more information, see [Azure OpenAI Services API](../Azure.md).


For more information on how to obtain an Azure endpoint, see [https://learn.microsoft.com/en\-us/azure/ai\-services/openai/chatgpt\-quickstart?tabs=command\-line%2Cpython\-new&pivots=rest\-api\#set\-up](https://learn.microsoft.com/en-us/azure/ai-services/openai/chatgpt-quickstart?tabs=command-line%2Cpython-new&pivots=rest-api#set-up).

### `DeploymentID` — Deployment ID

character vector | string scalar


After construction, this property is read\-only.


The deployment ID, also known as deployment name, specifies the Azure OpenAI deployment to use for generation. 


Instead of using the `DeploymentID` name\-value argument, you can also set the environment variable AZURE\_OPENAI\_DEPLOYMENT. For more information, see [Azure OpenAI Services API](../Azure.md).

**Example**: `"my-gpt-35-turbo-deployment"`

### `APIVersion` — API Version

`"2024-10-21"` (default) | `"2024-06-01"` | `"2024-02-01"` | `"2025-02-01-preview"` | `"2025-01-01-preview"` | ...


After construction, this property is read\-only.


Specify the Azure OpenAI API version. For more information, see [https://learn.microsoft.com/en\-us/azure/ai\-services/openai/api\-version\-deprecation](https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-deprecation).

### `Temperature` — Temperature

`1` (default) | numeric scalar between `0` and `2`


Temperature value for controlling the randomness of the output. Higher temperature increases the randomness of the output.

### `TopP` — Top probability mass

`1` (default) | numeric scalar between `0` and `1`


Top probability mass for controlling the diversity of the generated output. Higher top probability mass corresponds to higher diversity.

### `StopSequences` — Stop sequences

`[]` (default) | string array with between `0` and `4` elements


Sequences that stop generation of tokens.


**Example:** `["The end.","And that is all she wrote."]`

### `PresencePenalty` — Presence penalty

`0` (default) | numeric scalar between `-2` and `2`


Penalty value for using a token that has already been used at least once in the generated output. Higher values reduce the repetition of tokens. Negative values increase the repetition of tokens.


The presence penalty is independent of the number of incidents of a token, so long as it has been used at least once. To increase the penalty for every additional time a token is generated, use the `FrequencyPenalty` name\-value argument.

### `FrequencyPenalty` — Frequency penalty

`0` (default) | numeric scalar between `-2` and `2`


Penalty value for repeatedly using the same token in the generated output. Higher values reduce the repetition of tokens. Negative values increase the repetition of tokens.


The frequency penalty increases with every instance of a token in the generated output. To use a constant penalty for a repeated token, independent of the number of instances that token is generated, use the `PresencePenalty` name\-value argument.

### `TimeOut` — Connection timeout in seconds

`10` (default) | nonnegative numeric scalar


After construction, this property is read\-only.


If the server does not respond within the timeout, then the `generate` function throws an error during text generation.

### `ResponseFormat` — Response format

`"text"` (default) | `"json"` | string scalar | structure array


After construction, this property is read\-only.


Format of the `generatedOutput` output argument of the `generate` function. You can request unformatted output, JSON mode, or structured output.


#### Unformatted Output


If you set the response format to `"text"`, then the generated output is an unformatted string. 


#### JSON Mode


If you set the response format to `"json"`, then the generated output is a formatted string containing JSON encoded data.


To configure the format of the generated JSON file, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.


The JSON response format is not supported for these models:

-  `"gpt-4"` 
-  `"gpt-4-0613"` 
-  `"o1-mini"` 

#### Structured Output


To ensure that the model follows the required format, use structured output. To do this, set `ReponseFormat` to:

-  A string scalar containing a valid JSON Schema.
-  A structure array containing an example that adheres to the required format, for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0 0])`

Structured output is only supported for models `"gpt-4o-mini"`, `"gpt-4o-mini-2024-07-18"`, `"gpt-4o-2024-08-06"` and later.

# Other Properties
### `SystemPrompt` — System prompt

character vector | string scalar


This property is read\-only.


The system prompt is a natural\-language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc. 


Set the `SystemPrompt` property during construction using the `systemPrompt` input argument.


**Example**: `"You are a helpful assistant who provides answers to user queries in iambic pentameter."`

### `FunctionNames` — Names of OpenAI functions to call during output generation

string array


This property is read\-only.


Names of the custom functions specified in the `Tools` name\-value argument.

# Object Functions

[`generate`](generate.md) — Generate output from large language models

# Examples
## Create Azure Chat and Generate Text

First, specify the Azure OpenAI API key, endpoint, and deployment as environment variables and save them to a file called `".env"`, as described in [Azure OpenAI Services API](../Azure.md). Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the Azure OpenAI Chat Completion API.

```matlab
model = azureChat("You are a helpful assistant awaiting further instructions.");
```

Generate text using the `generate` function.

```matlab
generate(model,"Why is a raven like a writing desk?",MaxNumTokens=50)
```

```matlabTextOutput
ans = "The question "Why is a raven like a writing desk?" is a famous nonsensical riddle from Lewis Carroll's book "Alice's Adventures in Wonderland." When Carroll originally wrote the riddle in 1865, it was meant to be puzz"
```
# See Also

[`generate`](generate.md) | [`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md)


*Copyright 2024 The MathWorks, Inc.*

