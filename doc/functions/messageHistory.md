
# messageHistory

Manage and store messages in a conversation

# Creation
## Syntax

`messages = messageHistory`

## Description

`messages = messageHistory` creates an empty `messageHistory` object.

# Properties
### `Messages` — Messages

`{}` (default) | cell array of `struct`


This property is read\-only.


Messages in the message history. Each element of the cell array is a structure array corresponding to one message. You can add and remove messages using the object functions. The content of the structure array depends on the type of message.

# Object Functions

[`addSystemMessage`](addSystemMessage.md) — Add system message to message history


[`addUserMessage`](addUserMessage.md) — Add user message to message history


[`addUserMessageWithImages`](addUserMessageWithImages.md) — Add user message with images to message history


[`addToolMessage`](addToolMessage.md) — Add tool message to message history


[`addResponseMessage`](addResponseMessage.md) — Add response message to message history


[`removeMessage`](removeMessage.md) — Remove message from message history

# Examples
## Add Messages to Message History
```matlab
messages = messageHistory
```

```matlabTextOutput
messages = 
  messageHistory with properties:

    Messages: {}

```

```matlab
messages = addSystemMessage(messages,"example_user","Hello, how are you?");
messages = addUserMessage(messages,"I am well, thank you for asking.");
messages.Messages{1}
```

```matlabTextOutput
ans = struct with fields:
       role: "system"
       name: "example_user"
    content: "Hello, how are you?"

```

```matlab
messages.Messages{2}
```

```matlabTextOutput
ans = struct with fields:
       role: "user"
    content: "I am well, thank you for asking."

```
## Generate Text from Example Conversation

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Chat Completion API. Use a system prompt to instruct the model.

```matlab
model = openAIChat("You are a helpful assistants who judges whether two English words rhyme. You answer either yes or no.");
```

Initialize the message history.

```matlab
messages = messageHistory;
```

Add example messages to the message history. When you pass this to the model, this example conversation further instructs the model on the output you want it to generate.

```matlab
messages = addSystemMessage(messages,"example_user","House and mouse?");
messages = addSystemMessage(messages,"example_assistant","Yes");
messages = addSystemMessage(messages,"example_user","Thought and brought?");
messages = addSystemMessage(messages,"example_assistant","Yes");
messages = addSystemMessage(messages,"example_user","Tough and though?");
messages = addSystemMessage(messages,"example_assistant","No");
```

Add a user message to the message history. When you pass this to the model, the system messages act as an extension of the system prompt. The user message acts as the prompt.

```matlab
messages = addUserMessage(messages,"Love and move?");
```

Generate a response from the message history.

```matlab
generate(model,messages)
```

```matlabTextOutput
ans = "No"
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
toolCallID = "call_HW11K1FFmOPun9ouXScMcanR"
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
# See Also

[`generate`](generate.md) | [`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md) | [`azureChat`](azureChat.md) | [`addSystemMessage`](addSystemMessage.md) | [`addUserMessage`](addUserMessage.md) | [`addUserMessageWithImage`](addUserMessageWithImage.md) | [`addToolMessage`](addToolMessage.md) | [`addResponseMessage`](addResponseMessage.md)

-  [Create Simple Chatbot](../../examples/CreateSimpleChatBot.md) 
-  [Create Simple Ollama Chatbot](../../examples/CreateSimpleOllamaChatBot.md) 
-  [Describe Images Using ChatGPT](../../examples/DescribeImagesUsingChatGPT.md) 
-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md) 

*Copyright 2024 The MathWorks, Inc.*

