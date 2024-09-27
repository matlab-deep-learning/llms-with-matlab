
# addResponseMessage

Add response message to message history


`updatedMessages = addResponseMessage(messages,completeOutput)`

# Description

`updatedMessages = addResponseMessage(messages,completeOutput)` adds the generated output of a large language model to the `messageHistory` object `messages`.

# Examples
## Add Response Message to Message History

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Chat Completion API.

```matlab
model = openAIChat("You are a helpful assistant.");
```

Initialize the message history.

```matlab
messages = messageHistory;
```

Add a user message to the message history.

```matlab
messages = addUserMessage(messages,"Why is a raven like a writing desk?");

Generate a response.

```matlab
[generatedText,completeOutput,httpResponse] = generate(model,messages);
```

Add the response to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
messages.Messages{end}
```

```matlabTextOutput
ans = struct with fields:
       role: "assistant"
    content: "The question "Why is a raven like a writing desk?" is famously posed by the Mad Hatter in Lewis Carroll's "Alice's Adventures in Wonderland." Initially, it is presented as a riddle without a clear answer, contributing to the absurdity and nonsensical nature of the story. However, over time, various interpretations and answers have been suggested, such as:↵↵1. **Both can produce notes**: Ravens can "caw" or make sounds like a note, and writing desks are used for writing notes or letters.↵2. **Both are associated with writing**: Ravense have historically been linked to writers (like Edgar Allan Poe's famous poem "The Raven"), and desks are where writing is done.↵3. **The riddle is inherently nonsensical**: The whole point may be that some riddles don't have answers, fitting into the whimsical and illogical world of Wonderland.↵↵Carroll himself later suggested that the riddle was meant to be without an answer, thus adding to its charm and mystique in the context of his work."

```
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

The model has not generated any text. Instead, it has detected a function call, `completeOutput.tool_calls`.


Add the response to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
```

Extract the tool call ID and the name of the called function.

```matlab
toolCallID = string(completeOutput.tool_calls.id)
```

```matlabTextOutput
toolCallID = "call_VLRxaOUTDEyzCY4c8rDnq0jM"
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
generatedText = "The sine of thirty degrees is 0.5."
```
# Input Arguments
### `messages` — Message history

`messageHistory` object


Message history, specified as a [`messageHistory`](messageHistory.md) object.

### completeOutput — Complete output

structure array


Complete output generated from a large language model using the [`generate`](generate.md) function, specified as a structure array. 


The type and name of the fields in the structure depend on the API, the model, whether you use function calls, and whether you stream the output.

# Output Argument
### `updatedMessages` — Updated message history

`messageHistory` object


Updated message history, specified as a [`messageHistory`](messageHistory.md) object. 


The updated message history includes a new structure array with these fields:

-  role —`"assistant"` 
-  content — Set by the `content` input argument 

If the generated response includes a function call, then the updated message history also includes this field:

-  tool\_calls — `completeOutput.tool_calls` structure array 
# See Also

[`generate`](generate.md) | [`messageHistory`](messageHistory.md) | [`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md) | [`azureChat`](azureChat.md) | [`addUserMessage`](addUserMessage.md) | [`addUserMessageWithImage`](addUserMessageWithImage.md) | [`addToolMessage`](addToolMessage.md) | [`addSystemMessage`](addSystemMessage.md)

-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md) 

*Copyright 2024 The MathWorks, Inc.*

