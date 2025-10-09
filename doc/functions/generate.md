
# generate

Generate output from large language models

# Syntax

`[generatedText,completeOutput,httpResponse] = generate(model,userPrompt)`


`[generatedText,completeOutput,httpResponse] = generate(model,messageHistory)`


`___ = generate(___,Name=Value)`

# Description

`[generatedText,completeOutput,httpResponse] = generate(model,userPrompt)` generates output from a large language model given a single user prompt.


`___ = generate(model,messageHistory)` instead uses the entire chat history to generate output. This can include example inputs and outputs for few\-shot prompting. The message history can also include images that models with vision capabilities, such as GPT\-4o, can use to generate text.


`___ = generate(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Examples
## Generate Text Using OpenAI API

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the OpenAI API. Generate text based on a user prompt.

```matlab
model = openAIChat;
[generatedText,completeOutput,httpResponse]=generate(model,"Why is a raven like a writing desk?",MaxNumTokens=50)
```

```matlabTextOutput
generatedText = "The phrase "Why is a raven like a writing desk?" is famously posed by the Mad Hatter in Lewis Carroll's "Alice's Adventures in Wonderland." Initially, it is presented as a nonsensical riddle without a definitive answer, highlighting the"
completeOutput = struct with fields:
       role: 'assistant'
    content: 'The phrase "Why is a raven like a writing desk?" is famously posed by the Mad Hatter in Lewis Carroll's "Alice's Adventures in Wonderland." Initially, it is presented as a nonsensical riddle without a definitive answer, highlighting the'
    refusal: []

httpResponse = 
  ResponseMessage with properties:

    StatusLine: 'HTTP/1.1 200 OK'
    StatusCode: OK
        Header: [1x24 matlab.net.http.HeaderField]
          Body: [1x1 matlab.net.http.MessageBody]
     Completed: 0

```
# Input Arguments
### `model` — Chat Completion API

[`openAIChat`](openAIChat.md) object | [`ollamaChat`](ollamaChat.md) object | [`azureChat`](azureChat.md) object


Specify the chat completion API to use to generate text.

### `userPrompt` — User prompt

character vector | string scalar


Natural language prompt instructing the model what to do.


**Example:** `"Please list three MATLAB functions beginning with m."`

### `messageHistory` — Chat history

`messageHistory` object


Chat history, specified as a [`messageHistory`](messageHistory.md) object. 

## Name\-Value Arguments

The supported name\-value arguments depend on the chat completion API.

| **Name\-Value Argument**   | **`openAIChat`**   | **`azureChat`**   | **`ollamaChat`**    |
| :-- | :-- | :-- | :-- |
| `MaxNumTokens`   | Supported   | Supported   | Supported    |
| `Seed`   | Supported   | Supported   | Supported    |
| `Temperature`   | Supported   | Supported   | Supported    |
| `TopP`   | Supported   | Supported   | Supported    |
| `StopSequences`   | Supported   | Supported   | Supported    |
| `TimeOut`   | Supported   | Supported   | Supported    |
| `StreamFun`   | Supported   | Supported   | Supported    |
| `ResponseFormat`   | Supported   | Supported   | Supported    |
| `ModelName`   | Supported   |  | Supported  |
| `PresencePenalty`   | Supported   | Supported   |   |
| `FrequencyPenalty`   | Supported   | Supported   |   |
| `NumCompletions`   | Supported   | Supported   |   |
| `Tools` | Supported | Supported | Supported |
| `ToolChoice`   | Supported   | Supported   |   |
| `MinP`   |  |  | Supported    |
| `TopK`   |  |  | Supported    |
| `TailFreeSamplingZ`   |  |  | Supported    |

### `MaxNumTokens` — Maximum number of tokens to generate

`inf` (default) | positive integer


Specify the maximum number of tokens to generate.

### `Seed` — Random seed

`[]` (default) | integer


Specify a random seed to ensure deterministic outputs.

### `Temperature` — Temperature

`model.Temperature` (default) | numeric scalar between `0` and `2`


Temperature value for controlling the randomness of the output. Higher temperature increases the randomness of the output.

### `TopP` — Top probability mass

`model.TopP` (default) | numeric scalar between `0` and `1`


Top probability mass for controlling the diversity of the generated output. Higher top probability mass corresponds to higher diversity.

### `StopSequences` — Stop sequences

`model.StopSequences` (default) | string array with between `0` and `4` elements


Sequences that stop generation of tokens.


**Example:** `["The end.","And that is all she wrote."]`

### `TimeOut` — Connection timeout in seconds

`model.TimeOut` (default) | nonnegative numeric scalar


If the server does not respond within the timeout, then the function throws an error.

### `StreamFun` — Custom streaming function

`model.StreamFun` (default) | function handle


Specify a custom streaming function to process the generated output as it is being generated, rather than having to wait for the end of the generation. For example, you can use this function to print the output as it is generated.


For an example, see [Process Generated Text in Real Time by Using ChatGPT™ in Streaming Mode](../../examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md).


**Example:** `@(token) fprintf("%s",token)`

### `ResponseFormat` — Response format

`model.ResponseFormat` (default) | `"text"` | `"json"` | string scalar | structure array


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

### `ModelName` — Model name

`model.ModelName` (default) | `"gpt-4o-mini"` | `"gpt-4"` | `"gpt-3.5-turbo"` | `"dall-e-2"` | ...


Name of the OpenAI or Ollama model to use for text generation.

To use an Ollama model, first install it following the instructions at [https://ollama.com/library](https://ollama.com/library).


This option is only supported for [`openAIChat`](openAIChat.md) and [`ollamaChat`](ollamaChat.md) objects.

### `PresencePenalty` — Presence penalty

`model.PresencePenalty` (default) | numeric scalar between `-2` and `2`


Penalty value for using a token that has already been used at least once in the generated output. Higher values reduce the repetition of tokens. Negative values increase the repetition of tokens.


The presence penalty is independent of the number of incidents of a token, so long as it has been used at least once. To increase the penalty for every additional time a token is generated, use the `FrequencyPenalty` name\-value argument.


This option is only supported for these chat completion APIs:

-  [`openAIChat`](openAIChat.md) objects 
-  [`azureChat`](azureChat.md) objects 

### `FrequencyPenalty` — Frequency penalty

`model.FrequencyPenalty` (default) | numeric scalar between `-2` and `2`


Penalty value for repeatedly using the same token in the generated output. Higher values reduce the repetition of tokens. Negative values increase the repetition of tokens.


The frequency penalty increases with every instance of a token in the generated output. To use a constant penalty for a repeated token, independent of the number of instances that token is generated, use the `PresencePenalty` name\-value argument.


This option is only supported for these chat completion APIs:

-  [`openAIChat`](openAIChat.md) objects 
-  [`azureChat`](azureChat.md) objects 
### `NumCompletions` — Number of generated outputs

`model.NumCompletions` (default) | positive integer


Specify the number of outputs to generate.


This option is only supported for these chat completion APIs:

-  [`openAIChat`](openAIChat.md) objects 
-  [`azureChat`](azureChat.md) objects 

### `Tools` — Functions to call during output generation

`model.Tools` (default) | `openAIFunction` object | array of `openAIFunction` objects

Information about tools available for function calling, specified as [`openAIFunction`](openAIFunction.md) objects.

### `ToolChoice` — Tool choice

`"auto"` (default) | `"none"` | `"required"` | string scalar

Tools that a model is allowed to call during output generation, specified as `"auto"`, `"none"`, `"required"`, or as a tool name. For more information on OpenAI function calling, see [`openAIFunction`](openAIFunction.md).


If the tool choice is set to `"auto"`, then any tools available to the model can be called during output generation. To find out which tools are available to the model, see the `FunctionNames` property of the `model` input argument.


If the tool choice is set to `"none"`, then no tools are called during output generation.

If the tool choice is set to `"required"`, then one or more tools are called during output generation. 

You can also require that the model uses a specific tool by setting `ToolChoice` to the name of that tool. The name must refer to a tool that is available to the model. To give a model access to specific tools, either specify the `Tools` name-value argument during construction of the `model` object, or specify the `Tools` name-value argument of the `generate` function. 

This option is only supported for these chat completion APIs:

-  [`openAIChat`](openAIChat.md) objects 
-  [`azureChat`](azureChat.md) objects

### `MinP` — Minimum probability ratio

`model.MinP` (default) | numeric scalar between `0` and `1`


Tune the frequency of improbable tokens in generated output using min\-p sampling. Higher minimum probability ratio corresponds to lower diversity.


This option is only supported for [`ollamaChat`](ollamaChat.md) objects.

### `TopK` — Top\-k sampling

`model.TopK` (default) | positive numeric scalar


Sample only from the `TopK` most likely next tokens for each token during generation. Higher top\-k sampling corresponds to higher diversity.


This option is only supported for [`ollamaChat`](ollamaChat.md) objects.

### `TailFreeSamplingZ` — Tail free sampling

`model.TailFreeSamplingZ` (default) | numeric scalar


Tune the frequency of improbable tokens in generated output. Higher tail free sampling corresponds to lower diversity. If `TailFreeSamplingZ` is set to `1`, then the model does not use this sampling technique.


This option is only supported for [`ollamaChat`](ollamaChat.md) objects.

# Output Argument
### `generatedText` — Generated text

string scalar


Text that the model generates, returned as a string.

### `completeOutput` — Complete output

structure array


Complete output that the model generates, returned as a structure array. 


The type and name of the fields in the structure depend on the API, the model, whether you use function calls, and whether you stream the output.

### `httpResponse` — HTTP response message

`matlab.net.http.ResponseMessage` object


Response message returned by the server, specified as a [`matlab.net.http.ResponseMessage`](https://www.mathworks.com/help/matlab/ref/matlab.net.http.responsemessage-class.html) object.

# See Also

[`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md) | [`azureChat`](azureChat.md) | [`messageHistory`](messageHistory.md)

-  [Create Simple Chat Bot](../../examples/CreateSimpleChatBot.md) 
-  [Create Simple Ollama Chat Bot](../../examples/CreateSimpleOllamaChatBot.md) 
-  [Analyze Scientific Papers Using Function Calls](../../examples/AnalyzeScientificPapersUsingFunctionCalls.md) 
-  [Retrieval Augmented Generation Using Ollama and MATLAB](../../examples/RetrievalAugmentedGenerationusingOllamaAndMATLAB.md) 

*Copyright 2024 The MathWorks, Inc.*

