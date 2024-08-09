
# openAIChat—

Connect to OpenAI® Chat Completion API from MATLAB®

# Creation
## Syntax

`chat = openAIChat`


`chat = openAIChat(systemPrompt)`


`chat = openAIChat(___,ApiKey=key)`


`chat = openAIChat(___,Name=Value)`

## Description

Connect to the OpenAI Chat Completion API to generate text using large language models developed by OpenAI.


To connect to the OpenAI API, you need a valid API key. For information on how to obtain an API key, see [https://platform.openai.com/docs/quickstart](https://platform.openai.com/docs/quickstart).


`chat = openAIChat` creates an `openAIChat` object. Connecting to the OpenAI API requires a valid API key. Either set the environment variable `OPENAI_API_KEY` or specify the `APIKey` name\-value argument.


`chat = openAIChat(systemPrompt)` creates an `openAIChat` object with the specified system prompt.


`chat = openAIChat(___,APIKey=key)` uses the specified API key. 


`chat = openAIChat(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Input Arguments
### `systemPrompt` — System prompt

character vector | string scalar


Specify the system prompt and set the `SystemPrompt` property. The system prompt is a natural\-language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc. 


**Example**: "You are a helpful assistant who provides answers to user queries in iambic pentameter."

## Name\-Value Arguments
### `APIKey` — OpenAI API key

character vector | string scalar


OpenAI API key to access OpenAI APIs such as ChatGPT. 


Instead of using the `APIKey` name\-value argument, you can also set the environment variable OPEN\_API\_KEY. For more information, see [OpenAI API](http://../OpenAI.md).

### `Tools` — OpenAI functions to use during output generation

`openAIFunction` object | array of `openAIFunction` objects


Custom functions used by the model to collect or generate additional data.


For an example, see [Analyze Scientific Papers Using ChatGPT Function Calls](http://../examples/AnalyzeScientificPapersUsingFunctionCalls.md).

# Properties Settable at Construction

Optionally specify these properties at construction using name\-value arguments. Specify `PropertyName1=PropertyValue1,...,PropertyNameN=PropertyValueN`, where `PropertyName` is the property name and `PropertyValue` is the corresponding value.

### `ModelName` — Model name

`"gpt-4o-mini"` (default) | `"gpt-4"` | `"gpt-3.5-turbo"` | `"dall-e-2"` | ...


Name of the OpenAI model to use for text or image generation.


For a list of currently supported models, see [OpenAI API](../OpenAI.md).

### `Temperature` — Temperature

`1` (default) | numeric scalar between `0` and `2`


Temperature value for controlling the randomness of the output. Higher temperature increases the randomness of the output. Setting the temperature to `0` results in fully deterministic output.

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


If the OpenAI server does not respond within the timeout, then the function throws an error.

### `StreamFun` — Custom streaming function

function handle


Specify a custom streaming function to process the generated output token by token as it is being generated, rather than having to wait for the end of the generation. For example, you can use this function to print the output as it is generated.


For an example, see [Process Generated Text in Real Time by Using ChatGPT™ in Streaming Mode](../../examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md).


**Example:** `@(token) fprint("%s",token)`

### `ResponseFormat` — Response format

`"text"` (default) | `"json"`


After construction, this property is read\-only.


Format of generated output.


If you set the response format to `"text"`, then the generated output is a string.


If you set the response format to `"json"`, then the generated output is a string containing JSON encoded data. 


To configure the format of the generated JSON file, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.


For an example, see [Analyze Sentiment in Text Using ChatGPT in JSON Mode](../../examples/AnalyzeSentimentinTextUsingChatGPTinJSONMode.md).


The JSON response format is not supported for these models:

-  `ModelName="gpt-4"` 
-  `ModelName="gpt-4-0613"` 
# Other Properties
### `SystemPrompt` — System prompt

character vector | string scalar


This property is read\-only.


The system prompt is a natural\-language description that provides the framework in which a large language model generates its responses. The system prompt can include instructions about tone, communications style, language, etc. 


**Example**: "You are a helpful assistant who provides answers to user queries in iambic pentameter."

### `FunctionNames` — Names of OpenAI functions to use during output generation

string array


This property is read\-only.


Names of the custom functions specified in the `Tools` name\-value argument.

# Object Functions

[`generate`](generate.md) — Generate output from large language models

# Examples
## Create OpenAI Chat
```matlab
loadenv(".env")
modelName = "gpt-4o-mini";
chat = openAIChat("You are a helpful assistant awaiting further instructions.",ModelName=modelName)
```

```matlabTextOutput
chat = 
  openAIChat with properties:

           ModelName: "gpt-4o-mini"
         Temperature: 1
                TopP: 1
       StopSequences: [0x0 string]
             TimeOut: 10
        SystemPrompt: {[1x1 struct]}
      ResponseFormat: "text"
     PresencePenalty: 0
    FrequencyPenalty: 0
       FunctionNames: []

```
## Generate and Stream Text
```matlab
loadenv(".env")
sf = @(x) fprintf("%s",x);
chat = openAIChat(StreamFun=sf);
generate(chat,"Why is a raven like a writing desk?",MaxNumTokens=50)
```

```matlabTextOutput
The phrase "Why is a raven like a writing desk?" comes from Lewis Carroll's "Alice's Adventures in Wonderland." Initially posed by the Mad Hatter during the tea party scene, the question is often interpreted as nonsense, in line with the book
ans = "The phrase "Why is a raven like a writing desk?" comes from Lewis Carroll's "Alice's Adventures in Wonderland." Initially posed by the Mad Hatter during the tea party scene, the question is often interpreted as nonsense, in line with the book"
```
# See Also
-  [Create Simple Chat Bot](../../examples/CreateSimpleChatBot.md) 
-  [Process Generated Text in Real Time Using ChatGPT in Streaming Mode](../../examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md) 
-  [Analyze Scientific Papers Using Function Calls](../../examples/AnalyzeScientificPapersUsingFunctionCalls.md) 
-  [Analyze Sentiment in Text Using ChatGPT in JSON Mode](../../examples/AnalyzeSentimentinTextUsingChatGPTinJSONMode.md) 

*Copyright 2024 The MathWorks, Inc.*

