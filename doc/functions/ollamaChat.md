
# ollamaChat

Connect to Ollama™ Server from MATLAB®

# Creation
## Syntax

`model = ollamaChat(modelName)`


`model = ollamaChat(modelName,systemPrompt)`


`model = ollamaChat(___,Name=Value)`

## Description

Connect to an Ollama server to generate text using local large language models. 


To generate text using an `ollamaChat` object, you first need to install and start an Ollama server. You also need to install the specific model you want to use. For more information on how to install the server and models, see [https://ollama.com/library](https://ollama.com/library).


`model = ollamaChat(modelName)` creates an `ollamaChat` object.


`model = ollamaChat(modelName,systemPrompt)` creates an `ollamaChat` object with the specified system prompt.


`model = ollamaChat(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Input Arguments
###  `modelName` — Model name

character vector | string scalar


Specify the name of the model and set the `Model` property. To use an Ollama model, first install it following the instructions at [https://ollama.com/library](https://ollama.com/library).


**Example:** `"mistral"`

### `systemPrompt` — System prompt

character vector | string scalar


Specify the system prompt and set the `SystemPrompt` property. The system prompt is a natural language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc. 


**Example**: `"You are a helpful assistant who provides answers to user queries in iambic pentameter."`

## Name\-Value Arguments
### `StreamFun` — Custom streaming function

function handle


Specify a custom streaming function to process the generated output as it is generated, rather than having to wait for the end of the generation. For example, you can use this function to print the output as it is generated.


**Example:** `@(token) fprint("%s",token)`

# Properties Settable at Construction

Optionally specify these properties at construction using name\-value arguments. Specify `PropertyName1=PropertyValue1,...,PropertyNameN=PropertyValueN`, where `PropertyName` is the property name and `PropertyValue` is the corresponding value.

### `Endpoint` — Ollama endpoint

`"127.0.0.1:11434"` (default) | string scalar


After construction, this property is read\-only.


Network address used to communicate with Ollama server. 


To connect to a remote Ollama server, include the server name and port number. Ollama starts on port `11434` by default.


**Example:** `"myOllamaServer:11434"`

### `Temperature` — Temperature

`1` (default) | numeric scalar between `0` and `2`


Temperature value for controlling the randomness of the output. Higher temperature increases the randomness of the output.

### `TopP` — Top probability mass

`1` (default) | numeric scalar between `0` and `1`


Top probability mass for controlling the diversity of the generated output. Higher top probability mass corresponds to higher diversity.

### `TopK` — Top\-k sampling

`Inf` (default) | positive numeric scalar


Sample only from the `TopK` most likely next tokens for each token during generation. Higher values of `TopK` correspond to higher diversity.

### `TailFreeSamplingZ` — Tail free sampling

`1` (default) | numeric scalar


Tune the frequency of improbable tokens in generated output. Higher values of `TailFreeSamplingZ` correspond to lower diversity. If `TailFreeSamplingZ` is set to `1`, then the model does not use this sampling technique.

### `MinP` — Minimum probability ratio

`0` (default) | numeric scalar between `0` and `1`


Tune the frequency of improbable tokens in generated output using min\-p sampling. Higher minimum probability ratio corresponds to lower diversity.

### `StopSequences` — Stop sequences

`[]` (default) | string array with between `0` and `4` elements


Sequences that stop generation of tokens.


**Example:** `["The end.","And that is all she wrote."]`

### `TimeOut` — Connection timeout in seconds

`120` (default) | nonnegative numeric scalar


After construction, this property is read\-only.


If the server does not respond within the timeout, then the function throws an error.

### `ResponseFormat` — Response format

`"text"` (default) | `"json"` | string scalar | structure array


After construction, this property is read\-only.


Format of the `generatedOutput` output argument of the `generate` function. You can request unformatted output, JSON mode, or structured output.


#### Unformatted Output


If you set the response format to `"text"`, then the generated output is an unformatted string. 


#### JSON Mode


If you set the response format to `"json"`, then the generated output is a formatted string containing JSON encoded data.


To configure the format of the generated JSON file, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.

#### Structured Output


This option is only supported for Ollama version 0.5.0 and later.


To ensure that the model follows the required format, use structured output. To do this, set `ReponseFormat` to:

-  A string scalar containing a valid JSON Schema.
-  A structure array containing an example that adheres to the required format, for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0 0])`

# Other Properties
### `SystemPrompt` — System prompt

character vector | string scalar


This property is read\-only.


The system prompt is a natural\-language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc.


Set the `SystemPrompt` property during construction using the `systemPrompt` input argument.


**Example**: `"You are a helpful assistant who provides answers to user queries in iambic pentameter."`

### `Model` — Model name

character vector | string scalar


This property is read\-only.


Name of the model. 


Set the `Model` property using the `modelName` input argument. To use an Ollama model, first install it following the instructions at [https://ollama.com/library](https://ollama.com/library).


**Example:** `"mistral"`

# Object Functions

[`generate`](generate.md) — Generate output from large language models

# Class Functions

`models` — List models available on local Ollama server

# Examples
## Create Ollama Chat and Generate Text

Connect to the Ollama API.

```matlab
model = ollamaChat("mistral");
```

Generate text using the [`generate`](generate.md) function.

```matlab
generate(model,"Why is a raven like a writing desk?",MaxNumTokens=50)
```

```matlabTextOutput
ans = " This question is attributed to the poem "The Raven" by Edgar Allan Poe. The exact meaning of this line is intentionally ambiguous and open to interpretation, as it serves as a central theme in the story. In the poem"
```
# See Also

[`generate`](generate.md) | [`openAIChat`](openAIChat.md) | [`azureChat`](azureChat.md)

-  [Create Simple Ollama Chat Bot](../../examples/CreateSimpleOllamaChatBot.md) 
-  [Retrieval Augmented Generation Using Ollama and MATLAB](../../examples/RetrievalAugmentedGenerationusingOllamaAndMATLAB.md) 
-  [Process Generated Text in Real Time by Using Ollama in Streaming Mode](../../examples/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.md) 

*Copyright 2024 The MathWorks, Inc.*

