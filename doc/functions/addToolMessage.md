
# addToolMessage

Add tool message to message history


`updatedMessages = addToolMessage(messages,toolCallID,name,content)`

# Description

Add tool messages to the message history to pass the return of a function call to a large language model. For more information on function calling, see [`openAIFunction`](openAIFunction.md).


`updatedMessages = addToolMessage(messages,toolCallID,name,content)` adds a tool message to the `messageHistory` object `messages` and specifies the tool call ID, the name of the speaker, and the content of the message.

# Examples
## Compute Sine Using OpenAI Function Call

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Create an `openAIFunction` object that represents the [`sind`](https://www.mathworks.com/help/matlab/ref/sind.html) function. The `sind` function has a single input argument, `x`, representing the input angle in degrees.

```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees");
```

Connect to the OpenAI Chat Completion API. Pass the `openAIFunction` object `f` as an input argument.

```matlab
model = openAIChat("You are a helpful assistant.",Tools=f);
```

Initialize the message history. Add a user message to the message history.

```matlab
messages = messageHistory;
messages = addUserMessage(messages,"What is the sine of thirty?");
```

Generate a response based on the message history.

```matlab
[~,completeOutput] = generate(model,messages)
```

```matlabTextOutput
completeOutput = struct with fields:
          role: 'assistant'
       content: []
    tool_calls: [1x1 struct]
       refusal: []

```

The model has not generated any text. Instead, it has created a function call, `completeOutput.tool_calls`.


Add the response to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
```

Extract the tool call ID and the name of the called function.

```matlab
toolCallID = string(completeOutput.tool_calls.id)
```

```matlabTextOutput
toolCallID = "call_fnCZwyltX0jJmVweBTAgC4qI"
```

```matlab
functionCalled = string(completeOutput.tool_calls.function.name)
```

```matlabTextOutput
functionCalled = "sind"
```

Make sure that the model is calling the correct function. Even with only a single function, large language models can hallucinate function calls to fictitious functions.


Extract the input argument values from the complete output using the [`jsondecode`](https://www.mathworks.com/help/matlab/ref/jsondecode.html) function. Compute the sine of the generated argument value and add the result to the message history using the `addToolMessage` function.

```matlab
if functionCalled == "sind"
    args = jsondecode(completeOutput.tool_calls.function.arguments);
    result = sind(args.x)
    messages = addToolMessage(messages,toolCallID,functionCalled,"x="+result);
end
```

```matlabTextOutput
result = 0.5000
```

Finally, generate a natural language response.

```matlab
generatedText = generate(model,messages)
```

```matlabTextOutput
generatedText = "The sine of 30 degrees is 0.5."
```
# Input Arguments
### `messages` — Message history

`messageHistory` object


Message history, specified as a [`messageHistory`](messageHistory.md) object.

### `toolCallID` — Tool call ID

string scalar | character vector


Tool call ID, specified as a string scalar or character vector.


If an LLM creates a function call during generation, then the tool call ID is part of the complete output of the [`generate`](generate.md) function.

### `name` — Tool name

string scalar | character vector


Name of the tool, specified as a string scalar or character vector. The name must be nonempty and must only contain letters, numbers, underscores (\_), and dashes (\-).

### `content` — Message content

string scalar | character vector


Message content, specified as a string scalar or character vector. The content must be nonempty.

# Output Argument
### `updatedMessages` — Updated message history

`messageHistory` object


Updated message history, specified as a [`messageHistory`](messageHistory.md) object. The updated message history includes a new structure array with these fields:

-  tool\_call\_id — Set by the `toolCallID` input argument 
-  role —`"tool"` 
-  name — Set by the `name` input argument 
-  content — Set by the `content` input argument 
# See Also

[`messageHistory`](messageHistory.md) | [`openAIFunction`](openAIFunction.md) | [`generate`](generate.md) | [`addResponseMessage`](addResponseMessage.md)

-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md)
-  [Analyze Text Data Using Parallel Function Calls with Ollama](../../examples/AnalyzeTextDataUsingParallelFunctionCallwithOllama.md) 

*Copyright 2024 The MathWorks, Inc.*

